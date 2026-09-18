# App Store 登録用メモ（地理の勇者 RPG）

提出前に App Store Connect へ入れる中身の下書き。
価格・公開国・URL は 2026-09-17 に決まったので、あとは Apple のアカウントで入力するだけ。

## アプリの基本

| 項目 | 値 |
| --- | --- |
| 名前（App Store） | 地理の勇者 RPG |
| サブタイトル | 北海道を歩く ドット絵のコマンドRPG |
| ホーム画面の名前 | 地理の勇者（`CFBundleDisplayName`） |
| バンドルID | `tech.sesame.geohero` |
| バージョン / ビルド | 1.0 / 1 |
| プライマリ言語 | 日本語 |
| カテゴリ | ゲーム → ロールプレイング（第2カテゴリ: アドベンチャー） |
| 価格 | 無料（アプリ内課金なし） |
| 公開国 | 全世界 |

名前は30文字まで。「地理の勇者 RPG」は9文字なので余裕がある。
同名のアプリがあると登録できないので、App Store Connect で先に名前を押さえる。

## 説明文（4000文字まで）

```
北海道を歩いて、あやつられた守護神を解きはなつ——
ドット絵とコマンド戦闘の、ちいさな一本道RPGです。

■ 30分〜1時間で終わる、ちょうどいい冒険
函館から札幌、そして知床へ。街で装備をととのえ、近くの山のほらあなへ。
奥のぬしを倒すと 次の道がひらけます。これを3回くりかえすと結末です。

■ 実在の地名を歩く
舞台は北海道のかたちをした1枚の広いフィールド。
函館・函館山・札幌・藻岩山・知床・羅臼岳を、街道づたいにたどります。
次の目印へ近づくほど、出てくる魔物も手ごわくなります。

■ 北海道の魔物たち
ポテトー、こんぶスライム、ホタテキッド、きたきつね、タラこぞう、
ゆきおとこ、りゅうひょうゴーレム。1〜3体で出てきます。

■ なつかしいコマンド戦闘
こうげき・まほう・どうぐ・にげる。会心の一撃も出ます。
レベルが上がると どこが伸びたか ひと目でわかり、
ヒール・ファイア・ハイヒール・フレイムの4つを順に覚えます。
やどやに泊まると自動でセーブします。

■ 絵も音も、すべてコードで
ドット絵は16×16の文字列から、BGMと効果音はその場で合成しています。
外部の素材は使っていません。

広告なし・課金なし・通信なし。オフラインで遊べます。
```

## キーワード（100文字まで、カンマ区切り）

```
RPG,ロールプレイング,ドット絵,レトロ,北海道,コマンドバトル,オフライン,広告なし,短編,冒険
```

## 英語（English (U.S.)）の掲載情報

全世界に出すので、日本語以外の国では英語の掲載情報が使われる。入れておかないと
日本語のままになる。ゲーム本編は日本語のみなので、そのことを1行目で断っておく。

| 欄 | 値 |
| --- | --- |
| Name | Geo Hero RPG |
| Subtitle | Pixel-art RPG across Hokkaido |

```
A small, hand-made RPG set on the island of Hokkaido, Japan.
Note: the game text is in Japanese only.

- A one-hour adventure. Three towns, three caves, three bosses.
- Real places: Hakodate, Mt. Hakodate, Sapporo, Mt. Moiwa, Shiretoko, Mt. Rausu.
- Monsters get tougher the closer you walk to the next landmark.
- Classic turn-based battles: Fight, Magic, Item, Run.
- Every sprite and every note is generated in code. No external assets.

No ads. No in-app purchases. No network access. Plays fully offline.
```

キーワード（英語, 100文字）:

```
rpg,pixel,retro,turn-based,jrpg,offline,no ads,hokkaido,japan,adventure,short
```

## URL

他のアプリと同じ `ryomasolid.github.io`（別リポジトリ `git@github.com:ryomasolid/ryomasolid.github.io.git`、
ブランチ `master`）に置いた。全世界配信なので、どちらも日本語と英語を1ページに入れてある。

| 欄 | 値 |
| --- | --- |
| サポートURL | `https://ryomasolid.github.io/support-geohero.html` |
| プライバシーポリシーURL | `https://ryomasolid.github.io/privacy-geohero.html` |
| マーケティングURL | `https://ryomasolid.github.io/`（任意。広告を入れていないので app-ads.txt の検証には関係ない） |

## 年齢レーティング

想定回答（ユーザーが最終確認する）:

- 暴力（漫画・ファンタジー）: **まれ／軽度**（魔物とのコマンド戦闘があるため）
- 上記以外の項目（現実的な暴力、性的表現、下品なユーモア、ホラー、ギャンブル、
  アルコール・タバコ・薬物、医療・治療情報、コンテスト、ユーザー生成コンテンツ）: **なし**
- 無制限のWebアクセス: **なし**
- 結果の見込み: 9+ または 12+

## プライバシー

このアプリは**何も集めていない**。通信もしない。

- データ収集: **なし**（「データを収集していません」を選ぶ）
- トラッキング: なし
- サードパーティSDK: なし（広告・解析とも入れていない）
- プライバシーポリシーURL: `https://ryomasolid.github.io/privacy-geohero.html`
  （収集なしでも入力欄は必須）

## 輸出コンプライアンス

`ITSAppUsesNonExemptEncryption = false` を Info.plist に入れてあるので、
アップロードのたびに聞かれることはない。

## スクリーンショット

`Tools/make_screenshots.sh` で撮り直せる。6.5インチ（1242×2688・透過なしJPEG）を
`Docs/Store/screenshots/` に5枚。

| ファイル | 中身 |
| --- | --- |
| `65_1_title.jpg` | タイトル画面 |
| `65_2_field.jpg` | 函館のまわり（街・ほらあな・宝箱・十字キー） |
| `65_3_battle.jpg` | 魔物3体との戦闘 |
| `65_4_boss.jpg` | ラスボス「知床の守護神」 |
| `65_5_shop.jpg` | 道具屋（そうびの伸びしろが見える） |

**6.9インチ（1320×2868）は出さない。** 以前 別アプリで弾かれている。
6.5インチだけ入れておけば、他のサイズは App Store 側が縮小して使う。

## 登録の進みぐあい（2026-09-19）

Apple ID: **6813561253** / SKU: `geohero`

すんだもの:

1. ✅ Apple Developer に App ID `tech.sesame.geohero`（名前 GeoHero）を登録
2. ✅ App Store Connect にアプリを作成（地理の勇者 RPG / 日本語 / iOS）
3. ✅ サブタイトル・カテゴリ（ゲーム → ロールプレイング／アドベンチャー）
4. ✅ 説明文・プロモーション用テキスト・キーワード・サポートURL・マーケティングURL・著作権
5. ✅ スクリーンショット5枚（タイトル→フィールド→戦闘→ボス→道具屋の順）
6. ✅ App Review の連絡先・メモ（サインイン不要）
7. ✅ 年齢制限指定 → **13+**（172の国と地域。ベトナム・ブラジルと OS 26 未満は 12+）
8. ✅ コンテンツ配信権: サードパーティ製コンテンツなし
9. ✅ プライバシー: データ収集なし／プライバシーポリシーURL を設定して公開
10. ✅ 価格: 無料（175の国と地域）／配信状況: すべての国または地域

のこり:

11. ⬜ ビルドのアップロード → **Xcode のApple IDのセッション切れで止まっている。**
    Xcode → Settings → Accounts で `oga.sesame.tech@gmail.com` にサインインし直すと動く。
    アーカイブ自体は `xcodebuild archive` で通る（署名は自動）。
12. ⬜ バージョン画面でビルドを選ぶ
13. ⬜ 「審査用に追加」→「App Storeに提出」

### 年齢制限指定の答え

- アニメまたはファンタジーバイオレンス: **頻繁**（戦闘がゲームの中心で、何歩か歩くたびに起きる）
- 銃またはその他の武器: **まれ**（どうのつるぎ・はがねのつるぎ）
- そのほかは全部なし／いいえ

「頻繁」を「まれ」にすると 9+ まで下がる。ただし実際に戦闘は定期的に起きるので、
正確さを取って「頻繁」にしてある。
