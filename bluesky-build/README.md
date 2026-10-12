# Full Bluesky iPhone test build

Includes the actual React Native composer, Share Extension, and App Groups. Uses separate app identifiers and requires local Apple Account re-signing.

## Build and install from Windows

1. Run **Bluesky iPhone verification build** in Actions with `fixed` selected.
2. Download `BlueskyShareTest-resign.ipa` from the `bluesky-iphone-fixed` artifact.
3. Exit AltServer and start it with the [TEMP launcher](../device-probe/windows/start-altserver-long-temp.cmd).
4. Connect the trusted iPhone and install the IPA through AltServer using an Apple Account locally. Retain the Share Extension and App Groups.
5. Trust the certificate and enable Developer Mode if prompted.
6. Open **Bluesky Share Test**, sign in, and inspect the composer without posting.

Check separate text/URL shares, text-only and URL-only shares, duplicate URLs, and one photo. For encoding checks, include query parameters, literal `+`, and percent escapes. Test ordinary paste separately. Select `baseline` for an otherwise identical build without the patch.

The test configuration disables push, App Clip, associated domains, communication notifications, extra-memory and age-range entitlements, and OTA updates. Build adjustments stay outside the PR.

[Recorded device results](build-validation.md). The encoding correction still needs a new device test.
