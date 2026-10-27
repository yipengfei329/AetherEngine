// [MovieClaw P29] The disc reader prefetches the next range once sequential reads reach the full
// window. Its completion closure captured the range delegate, and the delegate kept the closure, so
// every prefetched body stayed alive after it was consumed: a remote UHD Blu-ray grew the process by
// its bitrate (~8 MB/s, 544 MB live in 63 range bodies after 60 s) and never gave it back.
//
// Measured, not asserted structurally: the delegate is private. A reader that releases its ranges
// leaves ~nothing behind once it is closed and gone; the leaking reader left one byte per byte read.
import Foundation
import Testing
@testable import AetherEngine

@Suite("Disc reader prefetch releases each range once consumed", .serialized, .offCooperativePool)
struct DiscPrefetchRetentionTests {

    private static func mallocInUseBytes() -> Int64 {
        var stats = malloc_statistics_t()
        malloc_zone_statistics(nil, &stats)
        return Int64(stats.size_in_use)
    }

    /// Reads the whole fixture sequentially with a full-size window, so every refill after the first
    /// is served by a prefetch, then closes the reader.
    private static func readThrough(url: URL, config: URLSessionConfiguration, chunk: Int) throws -> Int64 {
        let reader = try #require(HTTPDiscIOReader(
            url: url, baseChunkSize: chunk, maxChunkSize: chunk,
            requestTimeout: 5, sessionConfiguration: config))
        defer { reader.close() }
        let out = UnsafeMutablePointer<UInt8>.allocate(capacity: chunk)
        defer { out.deallocate() }
        var total: Int64 = 0
        while true {
            let n = reader.read(out, size: Int32(chunk))
            if n <= 0 { break }
            total += Int64(n)
        }
        return total
    }

    @Test("Prefetched ranges do not outlive the reader")
    func prefetchedRangesAreReleased() throws {
        let url = URL(string: "http://prefetch-retention.test/title.iso")!
        let fixture = 48 * 1024 * 1024
        RetentionRangeURLProtocol.bytesByURL[url.absoluteString] = Data(count: fixture)
        defer { RetentionRangeURLProtocol.bytesByURL[url.absoluteString] = nil }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RetentionRangeURLProtocol.self]

        // The malloc figure is process-wide: keep the smallest of up to three attempts, since the
        // defect retains about the whole fixture on every attempt and a stray allocation lands on one.
        var smallest = Int64.max
        for _ in 0..<3 {
            let before = Self.mallocInUseBytes()
            var moved: Int64 = 0
            try autoreleasepool { moved = try Self.readThrough(url: url, config: config, chunk: 1024 * 1024) }
            #expect(moved == Int64(fixture))
            // Session invalidation releases its tasks asynchronously.
            var retained = Self.mallocInUseBytes() - before
            let deadline = Date().addingTimeInterval(3)
            while retained >= Int64(fixture / 10), Date() < deadline {
                Thread.sleep(forTimeInterval: 0.05)
                retained = Self.mallocInUseBytes() - before
            }
            smallest = min(smallest, max(0, retained))
            if smallest < Int64(fixture / 10) { break }
        }
        #expect(smallest < Int64(fixture / 10),
                "\(smallest / 1024 / 1024) MB still allocated after reading \(fixture / 1024 / 1024) MB through a closed reader; prefetched ranges are being retained")
    }
}
