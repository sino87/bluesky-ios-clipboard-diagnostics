# 共有処理のiPhone実機検証

検証日: 2026-10-12 11:37（日本時間）。ユーザーが提供した画面と処理結果に基づく。

## 検証対象

Share Probe 5、ソース`01c48b5`、[IPAビルド38194298427](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38194298427)。公式`46d98dd`へ共有修正`70271fa`と同じ差分を適用したコントローラーを、実際のShare Extensionに組み込んだ。検証用のグループ参照と起動スキーム、追加観測・保存処理はBluesky本体との差分である。

Windows、無料Apple Account、AltServer 1.8.0.0で再署名・インストールした。短縮名を避けたTEMP/TMPでAltServerを起動した後、前回なかった拡張の署名XMLにグループ宣言が入り、DER宣言ブロックも存在する状態になった。DERの値は解析していない。共有拡張とApp Groupsを削除せずに試験した。

## 実入力と結果

送信元の共有は1つの`NSExtensionItem`、2つの添付だった。

| 場所 | 型・実行時型 | 内容 |
|---|---|---|
| アイテムの`attributedContentText` | 本文メタデータ | 本文 |
| 添付0 | `public.plain-text`、`__NSCFString` | 同じ本文 |
| 添付1 | `public.url`、`NSURL` | Web URL |

確認できた結果は以下のとおり。

- 本体で作った確認トークンを拡張が読み、拡張の保存結果を本体が読み返した。「本体 → 拡張 → 本体の連携成功」と表示された。
- 修正済みコントローラーの生成したcomposeリンクから、本文とURLを一度ずつ含む`composeText`を取得できた。本文中の改行も残った。
- `openDispatched`は`true`だった。これは元コントローラーが起動要求を渡した結果で、Bluesky本体での投稿完了を意味しない。

以下は実機JSONの主要項目を一般化した例。本文・招待コード・URL・確認トークンを置き換え、個人に紐づくグループ接尾辞と受信時刻の数値は載せていない。元の画面や未加工JSONは公開していない。

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

## 回帰テストと未検証事項

同じ添付構造と重複する本文メタデータを一般化した`testSharePlainTextAndURLWithContentMetadata`は、[未修正版](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38195607360/job/114637433920)で失敗し、[修正版](https://github.com/sino87/bluesky-ios-clipboard-diagnostics/actions/runs/38195607360/job/114637433883)で成功した。修正版は19テストすべて成功。比較Workflow全体のfailureは、未修正版の失敗を含むためで、修正版ジョブの失敗ではない。

実機で確認したのはこの1件の直接共有と診断アプリ内の本文生成。フルBlueskyの投稿画面・投稿完了、画像・動画の実機転送、通常ペーストの修正は未検証。更新後にURLだけを共有するようになった別アプリの結果は、この本文＋URLの試験と分けて扱う。
