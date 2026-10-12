# Share Probe device result

Tested on 2026-10-12 using [Share Probe 5](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38194298427), Windows, a free Apple Account, and AltServer 1.8.0.0 started through the [TEMP launcher](windows/start-altserver-long-temp.cmd).

One `NSExtensionItem` contained:

| Input | Content |
| --- | --- |
| Attachment 0: `public.plain-text` | Caption |
| Attachment 1: `public.url` | URL |
| Item text metadata | Same caption |

The patched controller preserved the complete caption, its line break, and the URL once. The host-extension-host App Group round trip succeeded.

This records the original caption/URL fix, before the additional encoding correction. Full-app observations are [recorded separately](../bluesky-build/build-validation.md).
