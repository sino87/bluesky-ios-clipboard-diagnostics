# Share Probe

A small app with the patched controller, a real Share Extension, and App Groups. It displays shared input and compose text; the full Bluesky composer is in the [separate build](../bluesky-build/README.md).

## Install and test on Windows

Requires AltServer, its Apple drivers, and a connected, trusted iPhone.

1. Run **iPhone share probe IPA** in Actions and download the `iphone-share-probe` artifact.
2. Exit AltServer, then start it with the [TEMP launcher](windows/start-altserver-long-temp.cmd).
3. Install `ClipboardDeviceProbe-resign.ipa` through AltServer using an Apple Account locally. Retain the Share Extension and App Groups.
4. Trust the developer certificate and enable Developer Mode if prompted.
5. Open the probe, confirm group access, and select it from another app's share sheet.
6. Confirm the host-extension-host round trip and that the caption and URL appear once.

The launcher sets long-form TEMP/TMP paths for AltServer; this resolved the observed extension-signing problem on the tested PC.

[Recorded device result](device-validation.md). Remove personal URLs, tokens, and signing identifiers before publishing diagnostic output.
