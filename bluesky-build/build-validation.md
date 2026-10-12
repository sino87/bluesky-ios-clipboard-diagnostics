# Bluesky本体IPAのビルド検証

2026-10-12に修正版のiPhone用IPAを作成した。独立したShare Probeとは別の、実際のReact Nativeアプリのビルド結果。

| 項目 | 結果 |
| --- | --- |
| Actions | [38199595875](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38199595875) — success |
| ビルド設定のコミット | `ee2e2cddad58aa0a036187b51d9fdf0f9749ac38` |
| 元コード | `46d98dd457a197cee8502863b420222508f29fa6` + `share-text-url.patch` |
| アプリの版 | `1.135.0` |
| Xcode | `26.6`、ビルド `17F113` |
| ジョブの所要時間 | 38分49秒 |
| IPA | `BlueskyShareTest-resign.ipa`、50,970,015 bytes |
| SHA-256 | `d534da60453b3477494779eba2d2fa7c582e8671c2da19ec8a434becaf8d01ab` |

## 確認済み

- Expo設定の読み込み、独自URLスキームの投稿リンク解析、拡張ターゲット保持のチェックに成功。
- XcodeのiPhone向けReleaseアーカイブに成功。本体・共有拡張・通知サービス拡張を保持。
- 実行ファイルのビルド先がiOSであり、Simulator用ではないことを検査。
- Release用 `main.jsbundle` を同梱。PCの開発サーバーを前提とする構成ではない。
- App Groupsの要求を仮署名に保持し、署名の整合性検査に成功。Apple Accountによる再署名前の状態。
- 投稿入力ファイルのSHA-256が元コードのGit blobと一致。`21a7d6cd9b9073581c4b7e224b19d36dca5bcbe5b76813223669754ccaa19343`。
- 共有拡張の `MainAppScheme` が `sino87blueskysharetest` であることを検査。
- Windowsへ取得したIPAのハッシュがビルド記録と一致。ZIP内の本体・2拡張・JavaScriptも確認。

## 実機での確認待ち

Apple Accountによる再署名、iPhoneへのインストールと起動、既存アカウントのログイン、本文＋URLの共有、画像共有、通常ペースト。このビルド成功だけでは、これらの成功を示さない。

無料署名用の構成差は[README](README.md)を参照。Push通知など、その構成で外した機能の動作は検証対象外。
