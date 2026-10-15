import Testing
@testable import AetherEngine

/// [MovieClaw P62] 记录写 P5、VUI 声明 YCbCr HDR、RPU 没纠正：自动放基础层。
@Suite("P62: a contradicted Profile 5 record the RPU does not correct presents its base layer")
struct MovieClawP62BaseLayerTests {

    private static func decide(
        enabled: Bool = true, handling: DolbyVisionHandling = .automatic,
        contradicted: Bool = true, record: Int? = 5, rpu: Int?
    ) -> Bool {
        DolbyVisionRecordAudit.presentsBaseLayerAutomatically(
            enabled: enabled, handling: handling, contradicted: contradicted, record: record, rpu: rpu)
    }

    @Test("a Profile 5 RPU injected into an HDR10 base presents the base layer")
    func profile5RPUOverHDR10Base() {
        #expect(Self.decide(rpu: 5))
    }

    @Test("an RPU that could not be read presents the base layer: the VUI alone says YCbCr")
    func unreadableRPU() {
        #expect(Self.decide(rpu: nil))
    }

    @Test("an RPU that corrects the record to 7 or 8 keeps Dolby Vision (AE#532)")
    func correctedRecordKeepsDolbyVision() {
        #expect(!Self.decide(rpu: 7))
        #expect(!Self.decide(rpu: 8))
    }

    @Test("a genuine Profile 5 (VUI unspecified) is not contradicted and keeps its route")
    func genuineProfile5() {
        #expect(!Self.decide(contradicted: false, rpu: nil))
    }

    @Test("off by default and never overrides a host's own choice")
    func gatedAndHostWins() {
        #expect(!Self.decide(enabled: false, rpu: 5))
        #expect(!Self.decide(handling: .baseLayerOnly, rpu: 5))
        #expect(AetherEngine.presentsBaseLayerOfContradictedProfile5 == false)
    }
}
