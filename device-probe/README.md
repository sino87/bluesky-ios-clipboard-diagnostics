# iPhone実機用の共有検証アプリ

この検証アプリは、修正済みBlueskyの共有コントローラーを実際のShare Extensionへ組み込み、送信元アプリの共有データと生成された本文を本体で表示する。Bluesky全体の実機テストや投稿成功を確認するアプリではない。

## 構成と判定

- 本体: `org.sino87.clipboardprobe`
- Share Extension: `org.sino87.clipboardprobe.share`
- App Group: `group.org.sino87.clipboardprobe`
- 起動スキーム: `sino87clipboardprobe`
- ソース: 公式 `46d98dd457a197cee8502863b420222508f29fa6` に `share-text-url.patch` を適用する。

本体と共有拡張は同じApp Groupを要求する。共有コントローラーのグループIDだけをテスト用に置き換え、投稿本文の処理はそのまま使用する。拡張のラッパーは同じ実際のproviderを先に読み、入力とcomposeリンクを共有領域へ記録する。この観察用の追加読み込み・保存と、Blueskyを含まない本体は検証構成特有の差分であり、フルアプリとの同等性は保証しない。

デバイス用の未署名archiveを作った後、本体と拡張へApp Groupsの要求を含むローカルの仮署名（ad-hoc signature）を付ける。署名ツールへ必要な権限を伝えるためで、Appleの証明書・プロファイルは使わない。この状態でiPhoneへインストールできることを意味せず、SideloadlyによるApple Accountでの再署名と権限の許可が必要。生成時に両方の仮署名のEntitlementsを読み返して確認する。

本体の確認データを拡張が読み、拡張の結果を本体が読み返したとき「本体 → 拡張 → 本体の連携成功」と表示する。`openDispatched`は元のコントローラーが起動を要求できるresponderを見つけた結果であり、アプリ起動完了の保証ではない。本体が自動で開かない場合は、手動で開いて「結果を更新」を押す。

## Windowsからインストール

1. [Sideloadly公式サイト](https://sideloadly.io/)のWindows向けセットアップに従い、Sideloadlyと必要なAppleドライバーを用意する。
2. iPhoneをUSB接続し、iPhone側でPCを信頼する。
3. GitHub Actionsの「iPhone share probe IPA」からArtifact `iphone-share-probe` をダウンロード・展開する。
4. `ClipboardDeviceProbe-resign.ipa` をSideloadlyへ読み込む。これはAppleの開発署名・プロファイルがないデバイス用ビルドで、ダウンロードしただけではインストールできない。
5. 無料Apple AccountをSideloadlyの画面で入力し、署名・インストールする。パスワードや確認コードはGitHub、Workflow、チャットへ渡さない。
6. **共有拡張を削除するオプションは使用しない。** App Groupsも必要なので、削除してインストール成功と扱わない。テスト用Bundle IDは既に本番と分けている。
7. iPhoneで開発元の信頼設定を行い、要求される場合はDeveloper Modeを有効にして再起動する。Apple公式手順: [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)。

無料署名は通常7日で期限切れになる。Sideloadlyが今回のApp Groupを無料署名できるかは未確認であり、インストールログと実際の画面で判定する。公式情報: [無料アカウントの制限](https://developer.apple.com/help/account/basics/about-your-developer-account/)、[App Groupsの対応表](https://developer.apple.com/help/account/reference/supported-capabilities-ios/)。

## iPhoneで確認する順序

1. 「共有テスト」を一度開く。App Groupsが「本体から読み書き可能」になることを確認する。ここで失敗する場合は、まだ共有の修正判定へ進まない。
2. 送信元アプリの共有シートで「共有テスト」を選ぶ。見えない場合は共有先一覧の編集から探す。
3. 本体へ戻り、必要なら「結果を更新」を押す。
4. 「本体 → 拡張 → 本体の連携成功」と「composeリンク取得済み」を確認する。
5. 「修正済み共有処理が作った本文」に元の本文とURLが両方あるか、URLが重複していないかを確認する。
6. テキストのみ、URLのみ、既にURLを含むテキストも試す。画像を含む場合は、受信データの識別子とcomposeリンクを観察できるが、Blueskyのメディア投稿成功までは検証できない。
7. 通常ペーストの比較には、送信元でコピーして標準UITextViewへ貼り付ける。「クリップボードの構成を見る」は明示操作時に型一覧だけを読み出す。React Native/Expoの投稿欄の修正確認にはならない。

共有内容と招待URLは端末内の共有領域に保存される。アプリはネットワークへ送信しない。結果を共有する際は、招待コード・アカウント情報を伏せ、パスワード・確認コード・署名証明書は送らない。

## 失敗時に必要な情報

- インストール失敗: Sideloadlyのエラー本文（Apple Account、端末ID、署名情報を伏せる）。
- App Groups失敗: 本体または共有拡張の状態表示。インストールできただけで署名要件を満たしたとは判断しない。
- 共有のみ失敗: 受信providerの型一覧、本文とURLの有無、composeリンク取得の有無。結果のJSONは内容を確認してから必要な部分だけ共有する。

署名に必要な権限が無料構成で維持できない場合、別ツールの対応を確認するか、公式側の署名済みTestFlightビルドで検証する。共有機能を除いて成功扱いにはしない。
