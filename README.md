# Bluesky iOS sharing diagnostics

Test harness and iPhone verification builds for [Bluesky PR #11948](https://github.com/bluesky-social/social-app/pull/11948).

[24 XCTest cases and five Swift-to-JavaScript URL checks pass](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38277353770/job/114905969712). The [prior controller fails four encoding cases](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38277353770/job/114905968336).

To reproduce, run **iOS clipboard diagnostics** from [Actions](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/workflows/ios-diagnostics.yml). The overall run is expected to be red because it includes the failing comparison job.

[Lint and type checks pass](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38277511599/job/114906489458); native lint retains the same 25 upstream SwiftLint violations.

Device tools: [small Share Probe](device-probe/README.md) · [full Bluesky build](bluesky-build/README.md).

Ordinary paste is unchanged. The latest encoding correction is verified in Simulator, not yet on an iPhone.
