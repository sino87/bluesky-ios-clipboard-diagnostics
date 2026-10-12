# Full-app device results

Tested on 2026-10-12 with the [verification IPA build](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38199595875): upstream `46d98dd` plus the original caption/URL patch, re-signed using AltServer on Windows.

The app launched on an iPhone. Its React Native composer input matched upstream, and the Share Extension and App Groups were retained.

| Operation | Installed official app | Patched test app |
| --- | --- | --- |
| Share separate caption and URL | Caption only | Both retained, URL once, link preview |
| Paste the same clipboard | Both retained | Both retained |
| Share one photo | Not compared | Photo attached |

The original paste failure was not reproduced in this clipboard trial; paste handling is unchanged.

Multiple images, video transfer, post submission, and the additional encoding correction have not been verified on device.

[Build and installation instructions](README.md).
