# iOS共有・ペーストの診断用テスト

状態: **Windowsで作成・静的確認済み。XcodeコンパイルとSimulator実行は未実施。**

Blueskyの修正PRに含めず、専用の公開検証リポジトリで使う。Apple Account、署名証明書、Blueskyのログインは不要。Workflowは手動実行だけで、GitHubへの作成・Push・実行はユーザーの確認後に行う。

## 調べる範囲

- 本物の`UITextView.paste`に、テキストのみ・URLのみ・別アイテムのテキストとURL・単一アイテムの統合テキストを渡す。
- 公式の`ShareViewController.swift`をそのままテスト用ホストへコピーする。入力の`NSExtensionItem`と出力のディープリンクだけをテスト用のオブジェクトで置き換え、実際の共有処理を呼ぶ。
- 共有のテキストのみ・URLのみ・別添付・別共有アイテム・添付順序・既に本文へ含まれるURLを検証する。
- ファイルURLとWeb画像URLの既存分類を確認する。

テストは「URLを含むべき」と判定するため、現行コードでの失敗が想定される。失敗を成功扱いする設定はない。ビルド失敗とアサーション失敗はログで区別する。ランナーのSimulatorバージョンを出力するが、iOS 26.6.2と一致する保証はない。

`UITextView`テストにはReact Nativeや`expo-paste-input`を組み込んでいない。ネイティブの標準ペーストで欠落するかを切り分ける最初の比較試験であり、Blueskyの投稿欄全体のテストではない。成功した場合は実際のReact Native投稿欄と依存ライブラリを含めた検証を追加する。

`public.url`は`URL`オブジェクトとして設定する。スクショのViewerが表示したXMLバイト列をそのまま再現したとは扱わない。実際のTVer入力での検証は別に必要。

## 実行

このディレクトリの内容を専用公開リポジトリのルートへ配置し、Actionsの`iOS clipboard diagnostics`を手動実行する。Workflowは1.129.0の公式タグと調査時点の最新SHAをそれぞれ取得する。公式リポジトリを変更しない。

Macで直接実行する場合:

```bash
gem install xcodeproj --version 1.28.1 --user-install --no-document
ruby generate-project.rb /absolute/path/to/social-app
xcrun simctl list devices available
xcodebuild test \
  -project generated/ClipboardDiagnostics.xcodeproj \
  -scheme ClipboardDiagnostics \
  -destination 'platform=iOS Simulator,id=<available-device-uuid>' \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

WindowsではXcodeを実行できない。GitHub ActionsのArtifactから`xcodebuild.log`と`.xcresult`を取得し、こちらで結果を解析する。Simulator用のテストホストはiPhoneへインストールするIPAではない。

## 判定後の作業

共有テストのURL欠落を実際に確認してから、テキストとWeb URLの読み込み・統合を修正する。画像と動画の既存経路や共有の有効化条件を変更しない。通常ペーストの修正先は、標準`UITextView`と実際の投稿欄の比較結果から選ぶ。

このテストホストには共有拡張ターゲットとApp Groupsがないため、無料署名・共有シート・共有コンテナーの動作は検証できない。それらには別の実機用最小検証アプリが必要。このホストを共有機能を維持した実機テストの代わりにしない。
