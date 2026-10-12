# Full Bluesky build and device validation

A patched iPhone IPA was built on 2026-10-12. This is the actual React Native application, separate from the small Share Probe.

## Build evidence

| Item | Result |
| --- | --- |
| Actions run | [38199595875](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38199595875) — success |
| Build-configuration commit | `ee2e2cddad58aa0a036187b51d9fdf0f9749ac38` |
| Upstream | `46d98dd457a197cee8502863b420222508f29fa6` plus `share-text-url.patch` |
| App version | `1.135.0` |
| Xcode | `26.6`, build `17F113` |
| Job duration | 38 minutes 49 seconds |
| IPA | `BlueskyShareTest-resign.ipa`, 50,970,015 bytes |
| SHA-256 | `d534da60453b3477494779eba2d2fa7c582e8671c2da19ec8a434becaf8d01ab` |

Checks passed for Expo configuration, isolated compose-link parsing, and extension retention. The iPhone Release archive contains the main app, Share Extension, notification-service extension, and `main.jsbundle`; it does not require a PC development server.

Packaging verified iOS rather than Simulator executables, requested App Groups in ad-hoc signatures, signature consistency, and the extension's `MainAppScheme` value `sino87blueskysharetest`. These were build-time checks before Apple Account re-signing.

The composer input matches the pinned upstream Git blob: SHA-256 `21a7d6cd9b9073581c4b7e224b19d36dca5bcbe5b76813223669754ccaa19343`. The Windows download matched the IPA hash, and its app, both extensions, and JavaScript bundle were inspected.

## Physical-device results

The tester re-signed and installed the IPA using AltServer on Windows and reported successful launch. A screenshot then confirmed a direct share from the native source app in the actual Bluesky composer. The caption and line break were retained, the separate URL appeared once, and a link preview was generated.

That source app had already been observed in Share Probe to supply `public.plain-text` as one attachment and `public.url` as another. Original screenshots contain invitation codes and account imagery and are kept outside this public repository.

The tester then repeated the direct share to the installed official app and reported that only the caption appeared, with the URL missing.

| Operation | Installed official Bluesky | Patched verification build |
| --- | --- | --- |
| Direct share from the same source app | Caption only; URL missing | Caption and URL once, with link preview |
| Ordinary paste using the same clipboard | Caption and URL | Caption and URL |
| One photo shared from Photos | Not compared in this trial | Tester reports successful attachment |

### Single-photo transfer

The tester shared one image from Photos to `Bluesky Share Test` and reported that it appeared as an attachment. The existing image route writes into the App Group container and passes its URI to the main app, so this result exercises that media-transfer path. It is separate from the link preview's image and does not establish successful post submission.

### Ordinary paste

The tester copied from the source app's share sheet and pasted into an empty verification composer. The caption and URL both appeared. Without copying again, the same clipboard was pasted into the installed official app, which also preserved both.

The patch changes only the Share Extension, not paste handling or the composer input. The pasteboard item layout for this trial was not captured. The original ordinary-paste failure is not reproduced under the current conditions; no paste-specific fix is claimed, and the difference from the original conditions has not been identified.

## Remaining checks

Multiple-image transfer, video transfer, and post submission are untested. Do not generalize the single-photo result to every media format or source app.

See the [configuration guide](README.md) for verification-only differences. Capabilities excluded for free signing, including remote push, are outside the test scope.
