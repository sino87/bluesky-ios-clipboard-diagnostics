# Full Bluesky iPhone verification build

This build includes Bluesky's actual React Native composer and dependencies. It retains the Share Extension, App Groups, and existing image/video routes, and is separate from the small Share Probe.

On 2026-10-12, the [patched build and IPA checks](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38199595875) passed. The re-signed app launched on an iPhone and preserved the caption, line break, and URL once in the actual composer, with a link preview. Sharing from the same source app dropped the URL in the installed official app.

A single-photo share also succeeded. Ordinary paste succeeded in both apps using the same clipboard under the current conditions; paste handling is unchanged. See the [validation record](build-validation.md). Multiple-image/video transfer and post submission remain untested.

## Configuration

- Upstream: `bluesky-social/social-app` at `46d98dd457a197cee8502863b420222508f29fa6`.
- Display name: `Bluesky Share Test`.
- Bundle ID: `org.sino87.blueskysharetest`.
- URL scheme: `sino87blueskysharetest`.
- `fixed` applies `share-text-url.patch`; `baseline` uses the same configuration without that patch.
- The composer input file is unchanged and checked by SHA-256.
- App Group references use the single matching group assigned in AltServer's `ALTAppGroups` metadata.
- The Share Extension and notification-service target remain bundled. A bundled notification service does not mean remote push is available.

The free-signing configuration excludes remote push, App Clip, associated-domain launch, communication notifications, extra memory entitlements, the declared age-range entitlement, and OTA updates. Screens depending on those capabilities are outside this verification scope.

[Apple's capability table](https://developer.apple.com/help/account/reference/supported-capabilities-ios/) lists App Groups for free accounts. The small probe verified its container round trip; the full-app single-photo result exercises the existing group-based media transfer.

Verification adjustments are applied only to the disposable `upstream` checkout. They are outside the proposed application patch.

## Cloud build

Run `Bluesky iPhone verification build` manually and select `fixed` first. The workflow uses a standard macOS runner in this public repository. No Apple credentials, signing certificates, or Bluesky login are supplied to Actions.

[GitHub's billing documentation](https://docs.github.com/en/billing/concepts/product-billing/github-actions) states that standard-runner execution is free for public repositories. Artifact storage has separate limits. Only the IPA and logs are retained for one day; Pods and DerivedData are not uploaded.

The workflow pins Node.js, pnpm, and the upstream commit, installs using the upstream lockfile, generates the native project through Expo prebuild, installs CocoaPods dependencies, and archives a Release build. Git-referenced Pod dependencies from upstream are not separately locked in this repository.

Download `BlueskyShareTest-resign.ipa` from `bluesky-iphone-fixed`. It needs Apple Account re-signing before installation. Packaging checks the Release JavaScript bundle, iPhone executables, both extensions, App Group requests, and the isolated URL scheme.

## Install from Windows

1. Exit existing AltServer processes.
2. Start it with the [long-form TEMP launcher](../device-probe/windows/start-altserver-long-temp.cmd), the workaround confirmed during Share Probe signing.
3. Connect the iPhone and install `BlueskyShareTest-resign.ipa` through AltServer, entering Apple Account credentials locally.
4. Open `Bluesky Share Test` and sign in with an existing Bluesky account.

If signing fails because of an app-ID limit or another error, inspect that error before changing the build. Do not remove the Share Extension to bypass an installation failure.

## Device checks

Inspect the composer without submitting a post.

| Operation | Expected observation |
| --- | --- |
| Share a caption and a separate URL to `Bluesky Share Test` | Original caption and line break, URL once |
| Share text only | Original text retained |
| Share URL only | URL appears in the composer |
| Share a caption already containing the separate URL | No duplicate URL appended |
| Share an image | Image attachment appears; shared-container transfer exercised |
| Paste copied text and URL into an empty composer | Record the actual result independently; this path is not patched |

Use an app that still supplies separate text and URL attachments for the direct-share comparison. An app that now shares only a URL is a URL-only control, not the original caption/URL reproduction.

If needed, build `baseline` next and replace the verification app for a same-source comparison. Distinguish multiple pasteboard items from multiple share attachments. Redact invitation codes, account details, signing identifiers, and diagnostic tokens in published results.
