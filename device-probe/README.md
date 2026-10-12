# iPhone実機用の共有検証アプリ

この検証アプリは、修正済みBlueskyの共有コントローラーを実際のShare Extensionへ組み込み、送信元アプリの共有データと生成された本文を本体で表示する。Bluesky全体の実機テストや投稿成功を確認するアプリではない。

## ビルド結果

[ビルド 38140504618](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38140504618)は成功した。ソースは診断リポジトリの`6118443`。本体と共有拡張のiPhone用バイナリ、両方の仮署名に同じApp Groups要求があること、署名の整合性、IPA生成を確認した。生成IPAのSHA-256は`bb8c4d9a7e8bcfde11ee46b436f51cc1274c47f1f5060edfe8b317c005c04baa`。Windowsへダウンロード後も一致した。

Simulator用のビルドと起動・スクリーンショット取得も成功した。Simulatorは`CODE_SIGNING_ALLOWED=NO`で起動しており、画面は「App Groups：確認失敗」だった。この実行で共有コンテナーの連携が成功したとは扱わない。無料Apple Accountでの再署名、iPhoneへのインストール、実機でのApp Groupsと直接共有は未確認。

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

### 実機でApp Groupsの確認が失敗した場合

2026-10-12、ユーザーがSideloadlyで署名・インストールし、開発元の信頼設定とDeveloper Modeを有効にした後、実機でアプリを起動できた。一方、本体の画面は「App Groups：確認失敗」だった。インストールと起動まで進めたが、共有連携と修正後の本文は未検証。

PCのSideloadlyキャッシュにはプロファイルのないIPAしか見つからず、インストール済みの署名情報はそこから確認できなかった。ビルド2に、本体と同梱共有拡張の`embedded.mobileprovision`からApp Groupsの宣言だけを表示する診断を追加した。CMS内のplistを読む処理で、署名・証明書の検証を代行しない。読み取れない場合は「権限なし」と扱わず、未判定として表示する。証明書、Apple Account、端末IDは表示しない。

表示する「設定IDの許可」はプロファイル内の配列との一致判定で、コード署名や共有領域の実動作を保証しない。ここでApp Groupsがないのか、IDが異なるのかを確認し、実際の署名情報と照合する。診断を追加しただけで権限不足が解消するわけではない。同じIPAを繰り返しインストールする前に、この表示を確認する。

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

### iCloudインストーラーがMedia Feature Packを要求する場合

Media Feature Packは[Windows N版向け](https://support.microsoft.com/en-us/windows/experience/platform-variants/media-feature-pack-for-windows-n)で、通常のPro版へ追加する対象ではない。Appleは[Windows Media Playerがない場合にiCloudをインストールできない](https://support.apple.com/en-ie/102361)と案内している。

2026-10-12のユーザーPCの読み取り確認では、EditionIDは`Professional`（N版ではない）、`MediaPlayback`と`WindowsMediaPlayer`はWMIの`InstallState = 2`（無効）だった。[WMIの公式定義](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-optionalfeature)では2はDisabled、3がAbsentである。Media FoundationのDLLは存在していた。管理者権限が必要なDISMの詳細照会は実行できなかったため、コンポーネント修復が必要かまでは未確認。

次に試す対象は「Windows Media Player 従来版」の追加・有効化。[Microsoftの手順](https://support.microsoft.com/en-us/windows/apps/windowsmediaplayer/troubleshoot-windows-media-player-errors?id=8163)では、Windows 11の設定 → システム → オプション機能 → 機能の追加から従来版を追加する。必要ならコントロールパネルの「Windowsの機能の有効化または無効化」でメディア機能を有効にする。この追加とiCloudの再インストールの成功は、まだ確認していない。

- インストール失敗: Sideloadlyのエラー本文（Apple Account、端末ID、署名情報を伏せる）。
- App Groups失敗: 本体または共有拡張の状態表示。インストールできただけで署名要件を満たしたとは判断しない。
- 共有のみ失敗: 受信providerの型一覧、本文とURLの有無、composeリンク取得の有無。結果のJSONは内容を確認してから必要な部分だけ共有する。

署名に必要な権限が無料構成で維持できない場合、別ツールの対応を確認するか、公式側の署名済みTestFlightビルドで検証する。共有機能を除いて成功扱いにはしない。
