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
| バージョン / ビルド | 1.1 / 6（1.0 / 1 は公開ずみ） |
| プライマリ言語 | 日本語 |
| カテゴリ | ゲーム → ロールプレイング（第2カテゴリ: アドベンチャー） |
| 価格 | 無料（アプリ内課金なし） |
| 公開国 | 全世界 |

名前は30文字まで。「地理の勇者 RPG」は9文字なので余裕がある。
同名のアプリがあると登録できないので、App Store Connect で先に名前を押さえる。

## 1.2 で 変えるもの（1.1 の 承認後に 提出）

- **副題**: 遊んで覚える 北海道の地理RPG（アプリ情報で 保存ずみ・1.2 の 公開で 反映）
- **カテゴリ**: ゲーム（ロールプレイング・トリビア）／ 2つ目 教育（同上）
- **スクショ**: 見出し入り `Docs/Store/screenshots_captioned/`（`swift Tools/caption_screenshots.swift` で 作る）
- **このバージョンの新機能**:

```
・冒険の きろくを 画像で シェアできるように（エンディング・つよさ画面）
・アプリ内イベント「北海道 めいしょスタンプラリー」に 対応
・こまかな 不具合を 直しました
```

- **アプリ内イベント**: 「北海道 めいしょスタンプラリー」（10/3〜10/31、下書きずみ）。
  1.2 公開後に ディープリンク `geohero://stamp-rally` を 入れて 審査へ。画像は `Docs/Store/event/`（`Tools/make_event_art.swift`）。

## 説明文（4000文字まで）

1.1 で 3地方・9つの街に広げたので書き直した（2026-09-26）。

```
北海道を旅して、まおうに あやつられた守護神を解きはなつ——
歩いて 話して 地理を おぼえる、ドット絵のコマンドRPGです。

■ 3つの地方を 飛行機でめぐる
函館エリア（道南）→ 札幌・小樽 → 知床。
地方ごとに 広いフィールドがあり、ボスを倒して もらう きっぷで
空港から 次の地方へ 飛びます。

■ 9つの街と 6つのほらあな
函館・松前・大沼、札幌・小樽・定山渓、中標津・ウトロ・羅臼。
五稜郭、松前城、大沼の島めぐり、小樽運河、定山渓の足湯、知床五湖……
街を歩いて 人と話し、家に入り、名所の看板を読んで 物語を進めます。

■ 地理の知識が 武器になる「ちしきの チャンス」
こうげきすると ときどき 地理の問題が出ます。正解すれば おいうち！
答えは 街の人や 看板が 教えてくれます。

■ 寄り道も たっぷり
ラーメンの出前、まいごの 白鳥のひな・ネコ・キツネの子さがし、
名所をめぐる「めいしょスタンプ」、宝箱のある家。

■ 名産の 道具と 装備
ハスカップ、いかめし、みそラーメン、いくら丼。
五稜郭の槍、松前の刀、小樽ガラスの剣、アットゥシ……
お金をためて 上等な装備を ねらいましょう。

■ 北海道の魔物たち
ポテトー、こんぶスライム、さくらのせい、ななえりんご、ラーメンおばけ、
シャチまる、りゅうひょうゴーレム。
ボスは イカのぬし、駒ヶ岳のぬし、天狗、ヒグマのぬし、トドのぬし、そして 知床の守護神。

■ 絵も音も、すべてコードで
ドット絵は文字列から、BGMと効果音は その場で合成しています。
外部の素材は使っていません。

広告なし・課金なし・通信なし。オフラインで遊べます。
```

## このバージョンの新機能（1.1）

```
大型アップデート！
・北海道を 函館エリア／札幌・小樽／知床の 3地方に分け、空港から 飛行機で 旅するように
・街が 3つから 9つに（松前・大沼・小樽・定山渓・中標津・ウトロ など）。家にも 入れます
・新しいボス（駒ヶ岳のぬし・天狗・トドのぬし）と 新しい魔物
・こうげき中に ときどき出る「ちしきの チャンス」。正解で おいうち
・名産に ちなんだ 道具・装備が 22しゅるいに
・寄り道の 頼まれごとと「めいしょスタンプ」
・会話の 読みやすさや 戦いの バランスを 見なおしました
```

## キーワード（100文字まで、カンマ区切り）

```
RPG,ドット絵,レトロ,北海道,地理,クイズ,函館,札幌,小樽,知床,コマンドバトル,オフライン,広告なし,冒険
```

## 英語（English (U.S.)）の掲載情報

全世界に出すので、日本語以外の国では英語の掲載情報が使われる。入れておかないと
日本語のままになる。ゲーム本編は日本語のみなので、そのことを1行目で断っておく。

| 欄 | 値 |
| --- | --- |
| Name | Geo Hero RPG |
| Subtitle | Pixel-art RPG across Hokkaido |

```
A hand-made RPG that travels across Hokkaido, Japan.
Note: the game text is in Japanese only.

- Three regions: Hakodate, Sapporo & Otaru, and Shiretoko. Fly between them from real airports.
- Nine towns to explore: talk to people, enter houses, read landmark signs.
- Geography quizzes pop up during attacks. Answer right for a bonus hit.
- Side quests, a landmark stamp rally, and local-specialty items and gear.
- Six bosses, including the Squid Lord, a Tengu, and the Guardian of Shiretoko.
- Every sprite and every note is generated in code. No external assets.

No ads. No in-app purchases. No network access. Plays fully offline.
```

What's New（英語, 1.1）:

```
Big update! Hokkaido is now three regions (Hakodate, Sapporo & Otaru, Shiretoko) linked by flights.
Nine towns with houses to enter, three new bosses, geography quiz chances during battle,
22 local-specialty items and gear, side quests and a landmark stamp rally.
```

キーワード（英語, 100文字）:

```
rpg,pixel,retro,turn-based,jrpg,offline,no ads,hokkaido,japan,geography,quiz,adventure
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
`Docs/Store/screenshots/` に6枚（1.1 で撮り直した）。

| ファイル | 中身 |
| --- | --- |
| `65_1_title.jpg` | タイトル画面 |
| `65_2_field.jpg` | 函館エリアのフィールド（函館の街・宝箱） |
| `65_3_town.jpg` | 大沼の街（島を はしで わたる 湖） |
| `65_4_quiz.jpg` | 戦闘の「ちしきの チャンス！」（松前の魔物3体） |
| `65_5_boss.jpg` | ボス「天狗」 |
| `65_6_shop.jpg` | 小樽の道具屋（名産の品ぞろえ） |

**6.9インチ（1320×2868）は出さない。** 以前 別アプリで弾かれている。
6.5インチだけ入れておけば、他のサイズは App Store 側が縮小して使う。

## 登録の進みぐあい（2026-09-19 提出ずみ）

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

11. ✅ ビルド 1（1.0）をアップロードして バージョンに紐づけた
12. ✅ リリース方法: App Review 承認後に自動でリリース

13. ✅ 「審査用に追加」→「審査へ提出」（2026-09-19 提出、**審査待ち**）

審査には最大48時間。結果はメールで届く。承認されるとそのまま自動で公開される。

### ビルドの上げかた（コマンドライン）

Xcode の Apple ID がサインインずみなら、これで通る:

```
mise exec -- tuist generate --no-open
xcodebuild archive -workspace GeoHero.xcworkspace -scheme GeoHero \
  -destination 'generic/platform=iOS' -archivePath <path>/GeoHero.xcarchive \
  -allowProvisioningUpdates
xcodebuild -exportArchive -archivePath <path>/GeoHero.xcarchive \
  -exportOptionsPlist <path>/ExportOptions.plist -exportPath <path>/export \
  -allowProvisioningUpdates
```

`ExportOptions.plist` は method `app-store-connect` / destination `upload` /
teamID `ZP3T7MAT5U` / signingStyle `automatic`。
**Xcode のセッションが切れていると「Your session has expired」で落ちる**ので、
そのときは Xcode → Settings → Accounts でサインインし直す。

### 年齢制限指定の答え

- アニメまたはファンタジーバイオレンス: **頻繁**（戦闘がゲームの中心で、何歩か歩くたびに起きる）
- 銃またはその他の武器: **まれ**（どうのつるぎ・はがねのつるぎ）
- そのほかは全部なし／いいえ

「頻繁」を「まれ」にすると 9+ まで下がる。ただし実際に戦闘は定期的に起きるので、
正確さを取って「頻繁」にしてある。
