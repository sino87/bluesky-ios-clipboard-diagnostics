# Bluesky iOS sharing and paste diagnostics

This repository contains an isolated test harness and device verification builds for a focused iOS Share Extension fix. The proposed application change is maintained separately in [Bluesky PR #11948](https://github.com/bluesky-social/social-app/pull/11948).

**Last verified result:** the original text/URL patch passes 19 native tests. On an iPhone, sharing from the same source app drops the URL in the installed official app but preserves the caption and URL in the patched full-app build. A single-photo share also succeeded. Ordinary paste succeeded in both apps using the same clipboard under the current conditions; the patch does not change paste handling. The additional encoding revision below still needs native and device execution.

## Verification paths

| Component | Purpose | Evidence |
| --- | --- | --- |
| Isolated UIKit tests | Exercise the actual Swift controller with typed item providers; compare ordinary `UITextView.paste` behavior | [19 passing tests](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38195607360/job/114637433883) |
| Share Probe 5 | Observe real Share Extension input and verify the App Group container round trip | [Setup](device-probe/README.md), [device results](device-probe/device-validation.md) |
| Full Bluesky verification app | Test the actual React Native composer, Share Extension, and media transfer on an iPhone | [Setup](bluesky-build/README.md), [device results](bluesky-build/build-validation.md) |

All workflows run manually. Simulator tests and cloud builds require no Apple Account, signing certificate, or Bluesky login. Installing a device build requires re-signing locally. These diagnostic files and verification-only build adjustments are outside the proposed Bluesky PR.

## Native regression tests

The harness copies the upstream `ShareViewController.swift` into an isolated UIKit host. It substitutes the extension input and captures the generated compose link while running the controller's actual logic.

Cases cover text-only and URL-only input, separate attachments and extension items, reversed attachment order, duplicate URLs, distinct URLs with a shared prefix, multiple URLs, empty or unreadable text, text mixed with images or file URLs, and existing file/media URL classification. A regression also covers a caption duplicated in item metadata and a text attachment.

Earlier runs compared the official 1.129.0 tag, pinned upstream commit `46d98dd457a197cee8502863b420222508f29fa6`, and that commit with the original patch. The [unpatched regression fails](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38195607360/job/114637433920); the original patched job passes all 19 tests. The overall workflow is expected to fail when it includes failing baseline jobs. Build failures and assertion failures are recorded separately.

Fixtures use typed `NSItemProvider` values, including a URL object for `public.url`. They do not reproduce a pasteboard viewer's XML byte representation. The Simulator runtime is printed by the workflow and need not match the physical device's OS.

The four ordinary-paste fixtures use a standard `UITextView`, not React Native or `expo-paste-input`. They preserve text and URL items, but do not establish behavior in the full Bluesky composer. Current device paste observations are recorded separately.

### Encoding revision awaiting native execution

Five additional tests bring the suite to 24 cases. They cover query separators, literal plus signs, Japanese text and line breaks, separate text/URL attachments, fragments, and percent escapes. The prepared workflow compares PR commit `70271fa73dc593bc53a96a1c4d05e4a7f1ac73a4` before the encoding correction with the updated patch applied to the pinned upstream commit.

The tests emit the actual Swift-generated compose links. `verify-compose-links.mjs` passes those links through the corresponding Bluesky `parseLinkingUrl.ts` and checks that `searchParams.get('text')` exactly matches the expected text. Missing native records fail verification; synthetic links are not substituted for native output.

The receiver verifier also has four local tests using literal control links. These check the verifier and the JavaScript receiver, not Swift execution. Run them on Windows with the bundled or installed Node 24 runtime:

```powershell
$env:BLUESKY_SOURCE_ROOT = 'C:\path\to\social-app'
node --test verify-compose-links.test.mjs
```

After a native run, verify its recorded links with:

```powershell
node verify-compose-links.mjs results/xcodebuild.log $env:BLUESKY_SOURCE_ROOT
```

## Project checks

[Lint and iOS/Android/Web TypeScript checks](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38123425316/job/114422695781) pass. Native lint reports the same 25 SwiftLint diagnostics, including 12 errors, before and after the patch. Existing violations fail that job; ktlint is not reached.

The [earlier 18-case run](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38123423399/job/114422690014) predates the metadata regression. Use the 19-case run for the current result.

## Run the isolated tests

On GitHub Actions, select `iOS clipboard diagnostics` and run it manually. The patch is applied only to the job's disposable checkout.

On a Mac:

```bash
gem install xcodeproj --version 1.28.1 --user-install --no-document
ruby generate-project.rb /absolute/path/to/social-app
xcrun simctl list devices available
xcodebuild test \
  -project generated/ClipboardDiagnostics.xcodeproj \
  -scheme ClipboardDiagnostics \
  -destination 'platform=iOS Simulator,id=<available-device-uuid>' \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

Windows cannot run Xcode. Use the macOS workflow and download its logs. Current jobs upload logs rather than DerivedData or full test-result bundles to limit artifact storage.

The isolated test host has no Share Extension or App Groups. It cannot validate signing, installation, share-sheet integration, or the shared container. Use the device probe or full-app build for those paths.

## Scope and remaining checks

The proposed fix handles shared text and non-file URLs while preserving existing image/video routes and activation limits. Multiple-image transfer, video transfer, and post submission still need device validation. The original ordinary-paste failure was not reproduced in the current same-clipboard comparison; no paste-specific fix is claimed.

Publish only sanitized device evidence. Keep invitation codes, account details, signing profiles, private keys, and raw personal screenshots outside the repository.
