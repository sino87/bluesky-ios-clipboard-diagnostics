# iPhone実機用の共有検証アプリ

この検証アプリは、修正済みBlueskyの共有コントローラーを実際のShare Extensionへ組み込み、送信元アプリの共有データと生成された本文を本体で表示する。Bluesky全体の実機テストや投稿成功を確認するアプリではない。現在のビルド5の表示名は「Share Probe 5」。

## ビルド結果

[ビルド5のWorkflow 38194298427](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38194298427)で、プロファイル・ID選択テスト、iPhone用archive、署名解析テスト、ASCII名と両署名のApp Groups要求の確認、IPA保存が成功した。ソース`01c48b5`。署名解析は宣言あり・なし、XMLなし、破損データと、生成した本体・拡張の両実バイナリで確認した。Windowsへ取得したIPAのSHA-256は`21d9771350f2ba00253a661cb028dd3c4d187a5cc20626e480fd1c058a5a9374`で一致し、両方の表示名・ビルド番号5・グループ要求も確認した。これは生成時の仮署名の検証で、AltServerによる再署名後の宣言と実機連携は未確認。Simulatorの追加確認より先にIPAを保存するため、Workflow全体の結果とは区別する。

[ビルド4のWorkflow 38192887324](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38192887324)で、プロファイル・ID選択テスト、iPhone用archive、ASCII名と両署名のApp Groups要求の確認、IPA保存が成功した。ソース`3130ad1`。Windowsへ取得したIPAのSHA-256は`85e37a75d653904d63a289649267341301c3e71e3f0237e5028ef565a534670a`で一致。本体と共有拡張の表示名「Share Probe 4」、ビルド番号4、起動スキーム、グループ要求も読み返した。実機の登録エラー解消とApp Groups連携は未検証。IPAはSimulatorの追加確認に先立って保存するため、IPA生成の成功とWorkflow全体の結果を区別する。

[ビルド3のWorkflow 38191563307](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38191563307)では、プロファイル解析・グループID選択のテスト、iPhone用archive、両方の仮署名のApp Groups要求確認、IPA生成とArtifact保存が成功した。ソースは`2e82c2a`。取得したIPAのSHA-256は`c10c1a7138515ea967470bc8658dc8f832c23cf6fba93588fd95c35068ee37d8`で、ビルド側の記録と一致した。Windows上でも、本体・共有拡張のビルド番号3、表示名・起動スキーム・グループ要求を読み返した。AltServerでの再署名と実機連携は未検証。

ビルド3の初回Workflow `38190810251`は、iPhone用IPA生成とSimulator用コンパイルまで成功したが、Simulatorの起動待ちが長時間完了せず、実行を停止した。生成済みIPAは保存できた。再実行ではIPAをSimulator確認より先に保存し、Simulator工程を5分で打ち切る構成にした。IPAはArtifact `iphone-share-probe`、Simulatorのログと取得できた画面は別の`iphone-share-probe-ui`へ保存する。

再実行のSimulator工程も制限内に成功し、画面を取得・確認できた。表示名、要求ID・使用ID、署名診断の配置を確認した。Appleの署名・プロファイルなしで起動したため、App Groupsアクセスは失敗し、本体・拡張のプロファイルは見つからない表示だった。この結果で実機のグループ許可や共有連携が成功したとは扱わない。

[ビルド 38140504618](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38140504618)は成功した。ソースは診断リポジトリの`6118443`。本体と共有拡張のiPhone用バイナリ、両方の仮署名に同じApp Groups要求があること、署名の整合性、IPA生成を確認した。生成IPAのSHA-256は`bb8c4d9a7e8bcfde11ee46b436f51cc1274c47f1f5060edfe8b317c005c04baa`。Windowsへダウンロード後も一致した。

Simulator用のビルドと起動・スクリーンショット取得も成功した。Simulatorは`CODE_SIGNING_ALLOWED=NO`で起動しており、画面は「App Groups：確認失敗」だった。この実行で共有コンテナーの連携が成功したとは扱わない。その後、Sideloadlyでの再署名・iPhoneへのインストールと起動はユーザーが確認したが、本体のApp Groupsアクセスは失敗した。直接共有と修正後の本文は未検証。

## 構成と判定

- 本体: `org.sino87.clipboardprobe`
- Share Extension: `org.sino87.clipboardprobe.share`
- App Group: `group.org.sino87.clipboardprobe`
- ビルド5の起動スキーム: `sino87clipboardprobe5`（旧ビルドと区別する）
- ソース: 公式 `46d98dd457a197cee8502863b420222508f29fa6` に `share-text-url.patch` を適用する。

本体と共有拡張は同じApp Groupを要求する。共有コントローラーのグループ参照だけを検証アプリの`ProbeStore.groupIdentifier`へ置き換え、投稿本文の処理はそのまま使用する。AltServerが書く`ALTAppGroups`がある場合は、要求IDと同じか、要求ID＋ドットで始まる署名先IDが一つだけ一致したときに使う。一致なし・複数一致は拒否する。これにより署名ツールが付けるチームIDを本体・共有拡張ともに使用できる。メタデータのない生成直後のビルドは要求IDを使う。グループがOSから許可されるかは実際の読み書きで判定する。

拡張のラッパーは同じ実際のproviderを先に読み、入力とcomposeリンクを共有領域へ記録する。この観察用の追加読み込み・保存と、Blueskyを含まない本体は検証構成特有の差分であり、フルアプリとの同等性は保証しない。

デバイス用の未署名archiveを作った後、本体と拡張へApp Groupsの要求を含むローカルの仮署名（ad-hoc signature）を付ける。署名ツールへ必要な権限を伝えるためで、Appleの証明書・プロファイルは使わない。この状態でiPhoneへインストールできることを意味せず、Apple Accountでの再署名と権限の許可が必要。生成時に両方の仮署名のEntitlementsを読み返して確認する。

本体の確認データを拡張が読み、拡張の結果を本体が読み返したとき「本体 → 拡張 → 本体の連携成功」と表示する。`openDispatched`は元のコントローラーが起動を要求できるresponderを見つけた結果であり、アプリ起動完了の保証ではない。本体が自動で開かない場合は、手動で開いて「結果を更新」を押す。

## Windowsからインストール

1. [Sideloadly公式サイト](https://sideloadly.io/)のWindows向けセットアップに従い、Sideloadlyと必要なAppleドライバーを用意する。
2. iPhoneをUSB接続し、iPhone側でPCを信頼する。
3. GitHub Actionsの「iPhone share probe IPA」からArtifact `iphone-share-probe` をダウンロード・展開する。
4. `ClipboardDeviceProbe-resign.ipa` をSideloadlyへ読み込む。これはAppleの開発署名・プロファイルがないデバイス用ビルドで、ダウンロードしただけではインストールできない。
5. 無料Apple AccountをSideloadlyの画面で入力し、署名・インストールする。パスワードや確認コードはGitHub、Workflow、チャットへ渡さない。
6. **共有拡張を削除するオプションは使用しない。** App Groupsも必要なので、削除してインストール成功と扱わない。テスト用Bundle IDは既に本番と分けている。
7. iPhoneで開発元の信頼設定を行い、要求される場合はDeveloper Modeを有効にして再起動する。Apple公式手順: [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)。

無料署名は通常7日で期限切れになる。今回のSideloadly署名では本体のプロファイルにApp Groupsがなく、実機の共有領域アクセスも失敗した。以下の診断結果を確認し、同じ設定での再インストールだけでは解決済みと扱わない。公式情報: [無料アカウントの制限](https://developer.apple.com/help/account/basics/about-your-developer-account/)、[App Groupsの対応表](https://developer.apple.com/help/account/reference/supported-capabilities-ios/)。

### 実機でApp Groupsの確認が失敗した場合

2026-10-12、ユーザーがSideloadlyで署名・インストールし、開発元の信頼設定とDeveloper Modeを有効にした後、実機でアプリを起動できた。一方、本体の画面は「App Groups：確認失敗」だった。インストールと起動まで進めたが、共有連携と修正後の本文は未検証。

PCのSideloadlyキャッシュにはプロファイルのないIPAしか見つからず、インストール済みの署名情報はそこから確認できなかった。ビルド2に、本体と同梱共有拡張の`embedded.mobileprovision`からApp Groupsの宣言だけを表示する診断を追加した。CMS内のplistを読む処理で、署名・証明書の検証を代行しない。読み取れない場合は「権限なし」と扱わず、未判定として表示する。証明書、Apple Account、端末IDは表示しない。

診断ビルド2の[Workflow 38189236939](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38189236939)は成功した。ソースは`54a8559`。App Groupsあり・なし・不正データと、OpenSSLで生成したCMSのパーサー検証、iPhone用archive、仮署名内のグループ要求、Simulator起動と追加表示を確認した。ダウンロードしたIPAのSHA-256は`c78d4d26e98f75de8fc0c16fc698c5d2c24d9a49fb25d9d28bc3cbc6dad56add`で、クラウド側の記録と一致する。再署名後の実機プロファイルの表示と共有コンテナーの成功は未確認。同じApple AccountとBundle IDで既存の検証アプリへ上書きし、「署名後のApp Groups許可」を確認する。

表示する「設定IDの許可」はプロファイル内の配列との一致判定で、コード署名や共有領域の実動作を保証しない。ここでApp Groupsがないのか、IDが異なるのかを確認し、実際の署名情報と照合する。診断を追加しただけで権限不足が解消するわけではない。同じIPAを繰り返しインストールする前に、この表示を確認する。

追加の実機画面で、本体のプロファイルには「App Groupsなし」「設定IDの許可なし」と表示された。拡張のプロファイルは見つからず未判定だった。したがって、現在のSideloadly署名では少なくとも本体が要求するグループが許可されていない。無料Apple Account一般の不可能性や、拡張自体の削除まではこの画面から断定しない。

## AltServerによる次の署名候補

[Windows版AltServerのソース](https://github.com/rileytestut/AltServer-Windows/blob/41fb42bc78056f59e64566f7561ba405ef59b5d9/AltServer/AltServerApp.cpp)では、本体と各拡張について、App Groupsを有効化・登録・割り当てた後にプロファイルを取得する処理を確認した。グループIDへチームIDを付け、署名時に各Info.plistの`ALTAppGroups`へ割り当て後のIDを記録する。ビルド3はこのメタデータに対応する。今回の端末・アカウントでの署名成功は未検証。

1. [公式Windows手順](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows)からAltServerを導入する。既に導入したWeb版iTunesとiCloudを使う。対象はAltStore Classicで、地域限定の別配布方式ではない。
2. 承認後、iPhoneをUSB接続し、Shiftキーを押しながらWindowsの通知領域にあるAltServerアイコンをクリックする。
3. 「Sideload .ipa」からiPhoneを選び、Windowsにあるビルド5のIPAを選択する。認証はAltServerの画面で行い、共有拡張を含む構成を保持する。この直接インストール機能は[公式リリースノート](https://faq.altstore.io/release-notes/altserver)と公開Windowsコードで確認した。iPhoneにAltStoreアプリを先に追加する必要はない。
4. 「Share Probe 5」を開き、本体のApp Groups読み書きと、本体・拡張それぞれのプロファイル・コード署名XML表示を確認する。

AltStore側でBundle IDが変わる可能性があるため、旧Sideloadly版と区別する表示名・起動スキームを使用する。確認した公開コードの`FetchCertificate`には、新規証明書を準備する際に既存の開発証明書を取り消して再試行する経路がある。これにより、取り消した証明書で署名されたSideloadlyのアプリなどが起動できなくなる可能性がある。AltServerでのApple Account認証・署名は、この影響を説明してユーザーの確認を得るまで実行しない。こちらではアプリ削除・証明書取り消し・AltServer導入・Apple Account認証を行っていない。

ユーザーは証明書への影響を了承してAltServerでの署名を試したが、ビルド3では「The name for this app is invalid.」と表示された。[公式FAQの3009](https://faq.altstore.io/altstore-classic/error-codes)は、非ASCIIのアプリ名によるApp ID登録失敗と説明している。ビルド3の本体・拡張ともに`CFBundleDisplayName`が「共有テスト3」だったため、ビルド4では両方をASCIIの「Share Probe 4」に変更した。共有処理、グループID、Bundle ID、拡張の有効化条件は同じ。今回の登録エラーが解消するかは実機で再試行して確認する。

ビルド4はAltServerでインストール・起動でき、本体のApp Groups読み書きが成功した。本体から読んだ本体・拡張のプロファイルには、同じチーム接尾辞付きグループの許可があった。しかし他のアプリから共有すると、実行中の拡張では`containerURL`がnilとなり、受信記録の保存前に停止した。プロファイルの宣言が揃うことだけでは、拡張の実際のアクセス成功を保証しない。修正済み共有コントローラーを呼ぶ前の診断用保存で止まったため、投稿本文の実機検証はまだ完了していない。

ビルド5は、本体・拡張のMach-Oコード署名にあるXMLのApp Groups宣言と、DER宣言ブロックの有無を表示する。拡張が失敗した画面でも、実行中の拡張自身のビルド番号・Bundle ID・プロファイル・署名XMLを表示する。形式を読めない場合は未判定とし、権限なしとは扱わない。診断は[AppleのMach-O定義](https://github.com/apple-oss-distributions/xnu/blob/main/EXTERNAL_HEADERS/mach-o/loader.h)と[署名形式](https://github.com/apple-oss-distributions/xnu/blob/main/osfmk/kern/cs_blobs.h)に従って宣言を読むだけで、証明書・署名ハッシュの検証やOSの実効権限の照会はしない。DERの値は解析せず、その有無をXMLと区別して表示する。

ビルド4で記録された共有の添付は`public.url`の1件だけだったが、共有アイテム本体の本文・タイトルは未記録だった。ビルド5では`attributedContentText`・`attributedTitle`とuserInfoのキー一覧も記録する。添付に本文がないことだけで、送信元が本文を渡していないとは断定しない。通常ペーストのクリップボード構成とも別の観測である。

ビルド5の実機診断でも、実行中の拡張のプロファイルにはグループ許可があったが、署名XML・DERブロックはなかった。Windowsの公開署名コードは、元の拡張パスで権限を保存し、正規化したパスで検索する。ユーザーPCの8.3短縮TEMPパスを使った同じC++処理はキー照合に失敗し、通常名を使うと成功した。AltServerと同じ`GetTempPathW`を使う比較でも再現した。配布AltServer自体の原因確定ではなく、次の実機比較に用いる候補である。

このPCで確認した標準インストール先へ起動する[Windows用起動ファイル](windows/start-altserver-long-temp.cmd)を用意した。ユーザーが既存AltServerを終了してから管理者として起動する。起動プロセスだけに通常名のTEMP/TMPを設定し、Windowsの恒久設定は変更しない。同じビルド5を再署名し、拡張の署名宣言・グループアクセスを比較する。新しいIPAの再ビルドは不要で、実機での改善は未検証。

ユーザーはTVer更新後の共有内容がURLのみになったことを確認した。以前の本文＋URLの再現とは分ける。Setlogの共有では、アイテムの`contentText`と添付0の`public.plain-text`に同じ本文、添付1に`public.url`があった。現行の全添付を読む修正の対象と一致する。本文メタデータの別読み込みは追加せず、同じ構造の一般化した回帰入力を診断テストへ追加した。

## iPhoneで確認する順序

1. ビルド5では「Share Probe 5」を一度開く。App Groupsが「本体から読み書き可能」になることを確認する。ここで失敗する場合は、まだ共有の修正判定へ進まない。
2. 送信元アプリの共有シートで「Share Probe 5」を選ぶ。見えない場合は共有先一覧の編集から探す。
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

この状態では「Windows Media Player 従来版」の追加・有効化を確認する。[Microsoftの手順](https://support.microsoft.com/en-us/windows/apps/windowsmediaplayer/troubleshoot-windows-media-player-errors?id=8163)では、Windows 11の設定 → システム → オプション機能 → 機能の追加から従来版を追加する。必要ならコントロールパネルの「Windowsの機能の有効化または無効化」でメディア機能を有効にする。案内後、ユーザーはiCloudのインストール成功とSideloadlyによる端末認識を報告した。

- インストール失敗: Sideloadlyのエラー本文（Apple Account、端末ID、署名情報を伏せる）。
- App Groups失敗: 本体または共有拡張の状態表示。インストールできただけで署名要件を満たしたとは判断しない。
- 共有のみ失敗: 受信providerの型一覧、本文とURLの有無、composeリンク取得の有無。結果のJSONは内容を確認してから必要な部分だけ共有する。

署名に必要な権限が無料構成で維持できない場合、別ツールの対応を確認するか、公式側の署名済みTestFlightビルドで検証する。共有機能を除いて成功扱いにはしない。
