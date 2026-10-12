# iPhone Share Extension probe

Share Probe 5 embeds the patched Bluesky controller in a real Share Extension and displays the received provider data and generated compose text in a small host app. It verifies controller output and the App Group round trip; it does not contain the full Bluesky composer or submit posts.

On 2026-10-12, re-signing the same build with AltServer started under long-form TEMP/TMP paths enabled the host-extension-host round trip. A real source app's separate caption and URL were preserved exactly once. See the [sanitized device results](device-validation.md). Full-app testing is recorded [separately](../bluesky-build/build-validation.md).

## Build provenance

| Build | Source | Run | Result |
| --- | --- | --- | --- |
| 5 | `01c48b5` | [38194298427](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38194298427) | Profile/ID tests, signature tests, iPhone archive, IPA checks, and Simulator UI completed |
| 4 | `3130ad1` | [38192887324](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38192887324) | ASCII display names and App Group requests verified |
| 3 | `2e82c2a` | [38191563307](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38191563307) | Profile/ID tests and IPA generation completed |
| 2 | `54a8559` | [38189236939](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38189236939) | Added provisioning-profile diagnostics and CMS parser tests |
| Initial | `6118443` | [38140504618](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38140504618) | Archive, IPA, and Simulator launch completed |

The first build-3 run, [38190810251](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38190810251), produced an IPA but was cancelled during a prolonged Simulator startup. Subsequent jobs save the IPA before the separately limited Simulator stage.

The build-5 IPA SHA-256 is `21d9771350f2ba00253a661cb028dd3c4d187a5cc20626e480fd1c058a5a9374`. The downloaded file matched, and both bundles' ASCII display names, build numbers, and App Group requests were checked. Build-time ad-hoc signatures are not Apple development signatures.

## Configuration and diagnostics

- Host bundle: `org.sino87.clipboardprobe`
- Extension bundle: `org.sino87.clipboardprobe.share`
- Requested group: `group.org.sino87.clipboardprobe`
- Build-5 URL scheme: `sino87clipboardprobe5`
- Upstream source: `46d98dd457a197cee8502863b420222508f29fa6` plus `share-text-url.patch`

The host and extension request the same App Group. The controller's group reference is adapted to `ProbeStore.groupIdentifier`; its caption/URL handling is retained. If AltServer supplies `ALTAppGroups`, exactly one group matching the requested ID or its dot-separated suffix is selected. Missing or ambiguous matches are rejected. Without that metadata, the build uses its requested group.

The wrapper reads the actual providers, records their runtime types, and saves the compose link in the shared container. These extra observations and the small host are differences from the full app.

A device archive is built without Apple signing, then ad-hoc signed with the requested App Group to communicate the requirement to the re-signing tool. Apple Account re-signing and permitted entitlements are still required before installation.

The host creates a token, the extension reads it, and the host reads back the extension's saved result. The round-trip success indicator requires that exchange. `openDispatched` reports the controller's attempt to hand off its URL through a responder; it does not guarantee app launch or post submission.

Provisioning-profile diagnostics read the embedded CMS plist and display group declarations only. They do not validate certificates or replace Apple's signature verification. Unreadable data is reported as unknown, not as proof that permission is absent. Mach-O diagnostics inspect XML entitlement declarations and the presence of a DER entitlement block; they do not decode DER values.

## Windows installation

1. Download and extract `iphone-share-probe` from the manual `iPhone share probe IPA` workflow.
2. Connect and trust the iPhone, with the required Apple drivers installed.
3. Exit existing AltServer processes, then use the [long-form TEMP launcher](windows/start-altserver-long-temp.cmd) at the standard installation path.
4. Re-sign and install `ClipboardDeviceProbe-resign.ipa` with an Apple Account entered locally in AltServer.
5. Keep the Share Extension and App Groups. Removing them would bypass the feature being tested.
6. Trust the development certificate and enable [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) if requested.

Do not enter passwords or verification codes into GitHub, a workflow, or a public report. Free provisioning has expiration and app-ID constraints; consult [Apple's account overview](https://developer.apple.com/help/account/basics/about-your-developer-account/) and [capability table](https://developer.apple.com/help/account/reference/supported-capabilities-ios/).

### Re-signing observations

Sideloadly installation and launch succeeded on the test device, but the host profile lacked App Groups and container access failed. AltServer later supplied matching group declarations in both profiles, while the extension still lacked XML and DER signature entitlement declarations.

A Windows source-code reproducer found a mismatch between original-path storage and canonical-path lookup when TEMP used an 8.3 short name. Repeating the lookup with long-form TEMP succeeded. Starting AltServer with the launcher and re-signing the same build then produced the extension's XML group declaration and DER block, followed by successful real-device sharing.

This workaround was confirmed on the tested PC with AltServer 1.8.0.0. It is not a direct trace of the released binary or a permanent AltServer fix. The launcher changes only the new process's TEMP/TMP variables, not persistent Windows settings.

Earlier Japanese display names were rejected during AltServer installation. Build 4 and later use ASCII names. Earlier unsigned Simulator launches showed App Group access failure and missing profiles; those observations did not establish device-signing behavior.

### Apple driver setup

Follow the official Windows setup instructions for [Sideloadly](https://sideloadly.io/) or AltServer and its required Apple components.

If an iCloud installer requests Media Feature Pack, distinguish [Windows N editions](https://support.microsoft.com/en-us/windows/experience/platform-variants/media-feature-pack-for-windows-n) from standard Windows editions. Apple documents [iCloud installation issues when Windows Media Player is missing](https://support.apple.com/en-ie/102361). Check the legacy Windows Media Player component using [Microsoft's troubleshooting guidance](https://support.microsoft.com/en-us/windows/apps/windowsmediaplayer/troubleshoot-windows-media-player-errors?id=8163), rather than assuming every machine needs Media Feature Pack.

## Device checks

1. Open Share Probe 5 and confirm that the host can read and write the group container.
2. Select Share Probe 5 in the source app's share sheet.
3. Return to the host and refresh the result if needed.
4. Confirm the host-extension-host round trip and captured compose link.
5. Check that the caption and URL appear once, with line breaks preserved.
6. Test text-only, URL-only, and already-combined input. Media provider observations do not establish full Bluesky attachment or posting behavior.
7. For a standard-input comparison, paste into the probe's `UITextView`. Its explicit clipboard-inspection control reads only the item type list.

Share content and invitation URLs are stored in the device's group container. The probe does not send them over the network. Sanitize invitation codes, account details, signing-group suffixes, and tokens before sharing results. Share errors and provider types without credentials, certificates, or device identifiers.

If container access fails, inspect profile declarations, signature declarations, and the selected group before reinstalling. Do not claim success by removing the extension or shared-container requirement.
