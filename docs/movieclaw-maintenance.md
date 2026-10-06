# MovieClaw engine maintenance

Engine source is maintained here, not in a MovieClaw Vendor copy. MovieClaw owns
its AetherCore adapter, product behavior, dependency lock, and real-media tests.

## Branches and upstream changes

- `origin` is `yipengfei329/AetherEngine`; `upstream` is
  `superuser404notfound/AetherEngine`.
- `main` is the downstream maintenance line. Develop changes on a separate branch
  and merge selected upstream commits or tags using Git; do not overwrite sources.
- Inspect upstream additions against PATCHES.md. Resolve conflicts and update
  regressions when a downstream policy intentionally differs from upstream.
- Keep upstream contributions focused and reviewable. PR descriptions use English.
  The initial extension contribution is draft PR
  [#703](https://github.com/superuser404notfound/AetherEngine/pull/703).

## Validate before adoption

Use Xcode 27, matching the upstream tested toolchain. Run `swift build` and
`swift test`. Record the complete result: a filtered test pass does not establish
that the full suite passes. Existing downstream/upstream contract disagreements
and allocation-sensitive cache assertions are documented in PATCHES.md; they
remain visible and must be reconciled, not silently skipped.

Publish the candidate commit to this fork. In a MovieClaw work branch, update
`apps/apple/project.yml` to its full SHA and run
`apps/apple/scripts/prepare-project.py --update-lock`. Review the lock diff,
compile iOS, tvOS and macOS, and run consumer unit/UI tests plus
`apps/apple/scripts/playback-regression.py` against a real test library.
Commit the SHA and lock together after validation. Normal builds use only the
committed resolved versions. Updating this fork's main does not update a released
MovieClaw App; a dependency bump and its playback verification are deliberate.

The App's component source link is generated from the selected dependency and
points at that exact commit. Preserve LICENSE and the LGPL/App Store exception.
For App-side commands and sample requirements, see
[MovieClaw's player design](https://github.com/movieclaw/MovieClaw/blob/main/docs/design/player-engine.md).

## Rollback

Restore the previous engine SHA and Package.resolved together in MovieClaw,
regenerate the project, and rebuild. Keep published commits available so old
builds and their source links remain reproducible.
