# Physical-device validation of the share controller

Validation date: 2026-10-12, based on tester-supplied screenshots and processing output.

## Tested configuration

Share Probe 5, source `01c48b5`, [IPA build 38194298427](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38194298427). Its real Share Extension contains upstream `46d98dd` with the same controller patch as `70271fa`. The probe uses its own App Group and URL scheme and adds input observation and result storage.

The IPA was re-signed and installed using Windows, a free Apple Account, and AltServer 1.8.0.0. After AltServer was launched with long-form TEMP/TMP paths, the extension's previously missing XML group declaration and DER entitlement block were present. DER values were not decoded. The Share Extension and App Groups were retained.

## Observed input and output

The source supplied one `NSExtensionItem` with two attachments:

| Location | Type / runtime type | Content |
| --- | --- | --- |
| Item `attributedContentText` | Text metadata | Caption |
| Attachment 0 | `public.plain-text` / `__NSCFString` | Same caption |
| Attachment 1 | `public.url` / `NSURL` | Web URL |

The extension read the host's test token, saved its processing result, and the host read it back. The host-extension-host round trip succeeded.

The compose link decoded to text containing the caption and URL exactly once, with the original line break preserved. `openDispatched` was `true`, indicating URL dispatch rather than successful post submission.

The following example substitutes generic text, an invitation code, URL, and token. The personal signing-group suffix and raw receipt timestamp are omitted. Original screenshots and unsanitized JSON are not committed.

```json
{
  "composeText": "A shared caption\nJoin code: EXAMPLE https://example.com/invite",
  "hostToken": "MATCHED_HOST_TOKEN",
  "openDispatched": true,
  "items": [{
    "itemIndex": 0,
    "contentText": "A shared caption\nJoin code: EXAMPLE"
  }],
  "providers": [{
    "itemIndex": 0,
    "attachmentIndex": 0,
    "identifiers": ["public.plain-text"],
    "text": {"runtimeType": "__NSCFString", "value": "A shared caption\nJoin code: EXAMPLE"}
  }, {
    "itemIndex": 0,
    "attachmentIndex": 1,
    "identifiers": ["public.url"],
    "url": {"runtimeType": "NSURL", "value": "https://example.com/invite"}
  }]
}
```

## Regression coverage and limits

The generalized `testSharePlainTextAndURLWithContentMetadata` fixture matches the attachment layout and duplicate caption metadata. It [fails without the patch](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38195607360/job/114637433920) and [passes with it](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38195607360/job/114637433883). All 19 patched tests pass. The comparison workflow's overall failure includes expected unpatched assertion failures.

This probe result establishes one direct share and controller-generated text, not full-app composition, media transfer, ordinary-paste behavior, or post submission. Later full-app observations are recorded [separately](../bluesky-build/build-validation.md). A different source app's updated URL-only behavior is not part of this caption/URL trial.
