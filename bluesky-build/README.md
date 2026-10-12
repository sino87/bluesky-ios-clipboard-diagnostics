# Bluesky本体でのiPhone検証

公式アプリのReact Native投稿画面と依存ライブラリを含む検証用IPAを、専用リポジトリでビルドする。Share Probeとは別のアプリであり、Share Extension・App Groups・画像/動画の共有経路を残す。

2026-10-12、[修正版のビルドとIPA検査](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38199595875)が成功した。無料署名したIPAをiPhoneで起動し、実際の投稿画面に本文とURLが1回ずつ表示され、リンクプレビューが生成されることを確認した。画像1枚の共有も成功報告を得た。通常ペーストは、同じコピー内容を使って検証版と公式アプリの両方で成功し、今回の条件ではURL欠落を再現していない。ペースト処理には修正を加えていない。[検証記録](build-validation.md)を参照。複数画像・動画の共有と投稿送信は未確認。

## ビルド構成

- 元コード: `bluesky-social/social-app` の `46d98dd457a197cee8502863b420222508f29fa6`。
- 表示名: `Bluesky Share Test`。ID: `org.sino87.blueskysharetest`。URLスキーム: `sino87blueskysharetest`。
- `fixed`: このリポジトリの `share-text-url.patch` を適用。`baseline`: 同じ設定で修正前をビルド。
- 投稿入力コードは変更せず、SHA-256で確認する。名前、ID、共有領域、リンクの解析先だけを検証用に調整する。
- AltServerが割り当てたApp Groupを、署名後の `ALTAppGroups` から本体と拡張で取得する。割り当てが曖昧な場合は停止する。
- Share Extensionと通知サービス拡張を同梱する。通知サービス拡張の存在は、Push通知が使えることを意味しない。

無料アカウントの機能制約に合わせ、Push通知、App Clip、関連ドメインによる起動、通知のコミュニケーション機能、追加メモリー権限を検証対象から外す。年齢範囲の権限とOTA更新も含めない。年齢確認など、これらの機能に依存する画面の検証には使用できない。

[Appleの対応機能表](https://developer.apple.com/help/account/reference/supported-capabilities-ios/)では、無料アカウントでもApp Groupsを利用できる。既存のShare ProbeではAltServer署名後の共有コンテナー連携に成功した。本体IPAでも、App Groupsを使う画像1枚の転送に成功したとの利用者報告を得た。

検証用の変更は使い捨ての `upstream` checkoutにのみ適用する。公式リポジトリ向けの修正差分には、これらのビルド設定を含めない。

## クラウドビルド

Actionsの `Bluesky iPhone verification build` を手動実行し、まず `fixed` を選ぶ。公開リポジトリの標準macOSランナーを使用する。Appleの認証情報・署名証明書・Blueskyのログイン情報はActionsに渡さない。

[GitHubの料金説明](https://docs.github.com/en/billing/concepts/product-billing/github-actions)では公開リポジトリの標準ランナー実行は無料。Artifactの保存容量には別の上限があるため、IPAとログのみを1日保存し、DerivedDataやPodsをアップロードしない。

Node.js、pnpm、元ソースのSHAを固定し、依存関係は元のlockfileでインストールする。Expoのprebuildでネイティブプロジェクトを自動生成し、CocoaPodsで依存関係を解決してReleaseビルドを作る。元設定のGit参照を含むPod依存関係については、lockfileをこの検証リポジトリで固定していない。

成果物 `bluesky-iphone-fixed` の `BlueskyShareTest-resign.ipa` をダウンロードする。Appleの署名前のIPAであり、これだけでインストール成功とは扱わない。Release用JavaScript、iPhone用の実行ファイル、2つの拡張、App Groupsの要求、公式アプリとは異なるURLスキームをパッケージ時に確認する。Artifactの保存期間は1日。

## Windowsからインストール

1. 既存のAltServerを終了する。
2. [長いTEMPパスで起動するランチャー](../device-probe/windows/start-altserver-long-temp.cmd)から起動する。Share Probeで確認した、共有拡張の署名権限が欠落する問題を避けるため。
3. iPhoneを接続し、AltServerのIPAインストールから `BlueskyShareTest-resign.ipa` を選び、手元でApple Accountによる署名を行う。
4. iPhoneで `Bluesky Share Test` を開く。公式Blueskyと区別し、既存アカウントでログインする。新規アカウント作成の検証は不要。

署名時にアプリIDの上限などで失敗したら、そのエラーを確認してから対処する。共有拡張を削除してインストールを通さない。

## 実機テスト

最初は投稿の送信をせず、投稿欄で確認する。

| 操作 | 確認する結果 |
| --- | --- |
| Setlogの共有シートから `Bluesky Share Test` | 元の本文・改行とURLを含む投稿画面が開く。URLは1回だけ |
| テキストのみを共有 | 元のテキストを保持 |
| URLのみを共有 | URLを含む投稿画面が開く |
| 本文に既に含まれるURLを別添付でも共有 | 同じURLを重複して追加しない |
| 画像を共有 | 添付画像を投稿画面で確認。画像の共有領域へのアクセスも検証する |
| コピーしたテキストと別URLアイテムを投稿欄に通常ペースト | 本文とURLが両方入るかを記録する。この経路には今回の修正を加えていない |

TVerの現在の共有内容がURLのみなら、URLのみの確認に使う。以前のテキスト＋URLの再現例と区別する。

必要なら次に `baseline` を作り、同じ検証アプリを上書きして比較する。コピーされた複数アイテムと、共有シートの複数添付は別の経路として記録する。招待コード、署名者ID、トークンを公開の検証記録にそのまま載せない。
