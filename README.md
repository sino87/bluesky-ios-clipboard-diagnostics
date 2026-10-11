# iOS共有・ペーストの診断用テスト

状態: **Xcode 26.6 / iOS 26.4.1 Simulatorでコンパイルとテストを実行済み。共有の別添付・別アイテムの欠落を再現。修正差分は検証中。**

Blueskyの修正PRに含めず、専用の公開検証リポジトリで使う。Apple Account、署名証明書、Blueskyのログインは不要。Workflowは手動実行だけで、GitHubへの作成・Push・実行はユーザーの確認後に行う。

## 調べる範囲

- 本物の`UITextView.paste`に、テキストのみ・URLのみ・別アイテムのテキストとURL・単一アイテムの統合テキストを渡す。
- 公式の`ShareViewController.swift`をそのままテスト用ホストへコピーする。入力の`NSExtensionItem`と出力のディープリンクだけをテスト用のオブジェクトで置き換え、実際の共有処理を呼ぶ。
- 共有のテキストのみ・URLのみ・別添付・別共有アイテム・添付順序・既に本文へ含まれるURLを検証する。
- ファイルURLとWeb画像URLの既存分類を確認する。
- URLの重複・部分一致・複数URL、テキスト経路での画像混在を確認する。

テストは「URLを含むべき」と判定するため、現行コードでの失敗が想定される。失敗を成功扱いする設定はない。ビルド失敗とアサーション失敗はログで区別する。ランナーのSimulatorバージョンを出力するが、iOS 26.6.2と一致する保証はない。

`UITextView`テストにはReact Nativeや`expo-paste-input`を組み込んでいない。初回の両バージョンで4ケースは成功し、別アイテムのテキストとURLを両方挿入できた。Blueskyの投稿欄全体のテストではなく、実際のReact Native投稿欄と依存ライブラリを含めた検証が必要。初回の共有データでは正常系も失敗したため、型付きの`NSItemProvider(item:typeIdentifier:)`へ変更して確認し直した。型付きデータでは共有の正常系が成功し、別添付・別アイテムと添付順序のテストが失敗した。

`public.url`は`URL`オブジェクトとして設定する。スクショのViewerが表示したXMLバイト列をそのまま再現したとは扱わない。実際のTVer入力での検証は別に必要。

## 実行

このディレクトリの内容を専用公開リポジトリのルートへ配置し、Actionsの`iOS clipboard diagnostics`を手動実行する。Workflowは1.129.0の公式タグ、調査時点の最新SHA、その最新SHAへ`share-text-url.patch`を適用した版を比較する。修正差分は診断ジョブ内のcheckoutだけに適用し、公式リモートを変更しない。baselineの失敗とfixedの成功をそれぞれ確認し、Workflow全体が赤いだけで修正失敗と判定しない。

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

WindowsではXcodeを実行できない。GitHub ActionsのArtifactから`xcodebuild.log`を取得し、こちらで結果を解析する。初回・2回目は`.xcresult`も保存したが、以後は保存容量を抑えるためログだけをアップロードする。Simulator用のテストホストはiPhoneへインストールするIPAではない。

## 判定後の作業

共有テストのURL欠落を実際に確認してから、テキストとWeb URLの読み込み・統合を修正する。画像と動画の既存経路や共有の有効化条件を変更しない。通常ペーストの修正先は、標準`UITextView`と実際の投稿欄の比較結果から選ぶ。

このテストホストには共有拡張ターゲットとApp Groupsがないため、無料署名・共有シート・共有コンテナーの動作は検証できない。それらには別の実機用最小検証アプリが必要。このホストを共有機能を維持した実機テストの代わりにしない。
