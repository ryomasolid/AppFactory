# といぷー日記（ToypooDiary）— 設計メモ

トイプードル専用の日記アプリ。2026-11-14 に新規作成（はむはむ日記のような写真日記・ニッチ飼育アプリの3本目）。
Bundle ID `tech.sesame.toypoodiary`・iOS 17+・iPhone 縦のみ。

## 0. 4.3 対策（はむはむ日記・げこログ・めだか帳と違う骨格）

- 中心は「トリミング」と「予防」：プードルは毛が抜けかわらず伸び続けるので、前回のカットからの日数・毛の伸び（月1cm）・次の目安を出す。
- 予防はシーズン制（フィラリア 5〜12月・ノミダニ 3〜12月を設定で変えられる）と1年ごと（狂犬病・混合・健康診断）。
- 日記は「1頭×1日=1ページ」。多頭飼い（画面上で切りかえ）。
- 他アプリと同一内容の Swift ファイルは 0（md5 で確認）。

## 1. 画面

| タブ | 中身 |
| --- | --- |
| 日記 | プロフィール（年齢・人でいうと何さい・記念日）→ 今日のページ → 7日の散歩・連続日数 → これまでの日記（詳細からシェア画像） |
| トリミング | 前回からの日数・毛の伸び・次の目安・今年の回数と金額 → スタイルの写真ギャラリー |
| けんこう | 体重（グラフ・前回差・1か月で -5%/+10% の声かけ。パピーは増えても言わない）→ 予防5種の次の予定 |
| 設定 | うちの子・お知らせ（朝8時 予防/トリミング・夜8時 日記）・お薬のシーズン・プライバシー |

## 2. 計算（`Sources/Rules/`・単体テストあり）

- `DogYears`: 2さいまで表（1か月=1・12か月=15・24か月=24）、以後1年+4。12か月未満パピー・7さい〜シニア。
- `TrimRhythm`: カット＋シャンプーだけを数える。直近5回の間隔の中央値（14〜90日・記録が1回なら30日）。あと7日以内「そろそろ」・過ぎたら「もじゃもじゃ注意」。
- `PreventionPlan`: 毎月の薬は前回+1か月。シーズン外にかかれば次のシーズンの1日。シーズン中の遅れは今シーズンの初めより前にしない。
- `DailyNudge`: 朝は7日先まで日ごと（過ぎた予防は今日に寄せる・過ぎたトリミングは言わない）。一度も記録していない予防は知らせない。

## 3. データ（SwiftData）

`Dog` 1—n `DayPage` / `Trim` / `CareShot` / `WeighIn`（cascade）。写真は externalStorage・長辺1600px JPEG。

## 4. 起動引数

- `-sample`（メモリ上の見本・あずき（レッド・主役）/むぎ・広告なし）、`-tab N`、`-openToday`
- `-demoPhotos <絶対パス>`：`Store/screenshots/photos` の本物の写真（portrait・today・day1〜3・trim0〜3）を見本に入れる。ユーザーの子の写真（2026-11-16 提供・6枚中5枚。見守りカメラの1枚はロゴ入りなので不使用）
- `-calm`（広告・同意・ATT を出さない。単体テストと審査用録画 scheme `ToypooDiaryWalkthrough`（Release）で使う）

## 5. AdMob（2026-11-16 登録・ストア未掲載で作成）

- アプリ ID: `ca-app-pub-6105029932689433~9897311863`（AdMob のアプリ番号 9897311863）
- バナー「ToypooDiary Banner」: `ca-app-pub-6105029932689433/4644985181`
- Debug と TestFlight（sandbox）は Google のテスト用ユニット。
- **公開後に AdMob の「アプリの設定」で App Store に紐づける**（未掲載で作ったため）→ そのあと app-ads.txt の Verify app。
- 流れ: UMP 同意 → ATT → SDK 開始 → 各タブ下にアダプティブバナー（届くまで高さ0）。

## 6. ストア・Web

- プライバシー: https://ryomasolid.github.io/privacy-toypoodiary.html ／ サポート: support-toypoodiary.html（ryomasolid.github.io 50bdbac・2026-11-16 公開）
- ASC: Apple ID **6835449914**・SKU toypoodiary・App ID tech.sesame.toypoodiary（2026-11-16 登録）。掲載文は `Store/ASO.md`、審査メモは `Store/ReviewNotes-1.0.md`、録画 `Store/ToypooDiary-review-1.0.mp4` を添付ずみ。
- スクショ: iPhone 17 Pro で `src/` に撮る（diary / detail -openToday / trim -tab 1 / health -tab 2 / settings -tab 3・起動後9秒待つ）→ `python3 Store/screenshots/generate.py` で `out/`（6.9）と `out-6.3/` に5枚。ASC には out-6.3 を入れた。
- アイコンの元は `Store/icon/icon.html`（Chrome ヘッドレス → JPEG 経由で透過なし PNG）。
