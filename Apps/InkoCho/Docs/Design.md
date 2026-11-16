# インコ帳（InkoCho）— 設計メモ

セキセイインコの体重と様子を毎日つける飼育アプリ。2026-11-16 に新規作成（ニッチ飼育アプリの4本目・トイプーの次）。
Bundle ID `tech.sesame.inkocho`・iOS 17+・iPhone 縦のみ。

## 0. 4.3 対策（ほかのペットアプリと違う骨格）

- 中心は「毎日のグラム体重」：小鳥は具合の悪さを隠すので、直前7日の平均（ふだん）からの減り（-5% 注意・-10% 急ぐ）と3回連続の減少を見る。
- 「きょうの見守り」：体重・ふくらみ（体重減と重なれば急ぐ）・フン2日つづけて異常・室温（ヒナは高め）・メスの産卵（14日で3こ）・換羽日数をまとめて並べる。
- 「ことば」タブ：おぼえた言葉・鳴きまねを、はじめて聞いた日と。
- 「おせわ」：大掃除7日・止まり木14日・爪切り45日・水浴び3日・健康診断180日の目安。
- 他アプリと同一内容の Swift ファイルは 0（md5 で確認）。

## 1. 画面

| タブ | 中身 |
| --- | --- |
| きょう | プロフィール → 見守りカード → きょうの体重（その場で入力）→ きょうの記録 → さいきんの記録 |
| 体重 | ふだん（7日平均）の点線つきグラフ（2週間/1か月/3か月）と一覧（スワイプで消す） |
| ことば | 言葉の数・さいしょの言葉・一覧 |
| おせわ | 5種の前回と次の目安・「した」ボタン・履歴 |
| 設定 | うちの子・朝のお知らせ（5〜11時・体重とおせわを1通）・プライバシー |

## 2. 起動引数

- `-demo`（メモリ上の見本・ソラ（ブルー・オス）/キウイ・広告なし）、`-tab N`、`-demoPhotos <絶対パス>`（portrait・today・day1〜3）
- `-noAds`（広告・同意・ATT を出さない。単体テストと録画 scheme `InkoChoTour`（Release））

## 3. AdMob

- 2026-11-17 登録（ストア未掲載で作成）。アプリ ID `ca-app-pub-6105029932689433~5697232465`・バナー「InkoCho Banner」`ca-app-pub-6105029932689433/8588274637`。
- Debug と TestFlight（sandbox）は Google のテスト用ユニット。
- **公開後に AdMob の「アプリの設定」で App Store に紐づける** → app-ads.txt の Verify app。

## 4. ストア・Web

- プライバシー: https://ryomasolid.github.io/privacy-inkocho.html ／ サポート: support-inkocho.html（ryomasolid.github.io ffc3ee5・2026-11-17 公開）
- ASC: Apple ID **6835493563**・SKU inkocho・App ID tech.sesame.inkocho（2026-11-17 登録）。掲載文 `Store/ASO.md`、審査メモ `Store/ReviewNotes-1.0.md`、録画 `Store/InkoCho-review-1.0.mp4` を添付ずみ。
- スクショ: iPhone 17 Pro で `-demo -tab N`（today 0 / weight 1 / words 2 / chores 3 / settings 4・起動後9秒）を `src/` に撮る → `python3 Store/screenshots/generate.py` で out/（6.9）・out-6.3/。ASC には out-6.3 を入れた（イラストのまま・写真なし）。
- アイコンの元は `Store/icon/icon.html`。
