# カメ帳（KameCho）— 設計メモ

ミズガメ・リクガメの世話と成長をつける飼育アプリ。2026-11-19 に新規作成（ニッチ飼育アプリの5本目・インコ帳／といぷー日記の次）。
Bundle ID `tech.sesame.kamecho`・iOS 17+・iPhone 縦のみ・SwiftData・AdMob バナー。

## 0. 4.3 対策（ほかのペットアプリと違う骨格）

- 中心は「世話の間隔」：ごはん・水換え（ミズガメ）／温浴・床材（リクガメ）を、種類と年齢（1歳まで＝子ガメ）の目安で予定にし、すぎた日数を出す。間隔はカメごとに変えられる。
- 「成長」：甲長（mm）と体重（g）を2週間に1回。前回からの差・1年あたりの伸び・冬眠期間の帯つきグラフ。
- 「冬眠」：始めた日の体重から、ひと月あたり 1% を超える減りで注意、2% 超または合計 10% で「起こして温める」。冬眠中は世話の予定を止めて、週1回の計測だけ。熱帯の種類（ケヅメ・ヒョウモン・ホシガメ・アカアシ）は冬眠させない。
- 「器具」：UVB ライト（180日）・メタハラ（365日）・水中ヒーター・ろ材（30日）などの交換時期。カメではなく置き場所ごと。
- 見守り：3回つづけて食べない・体のサイン（目の腫れ・口を開けた呼吸・甲羅がやわらかい は急ぐ）・温度の目安外（水温/バスキング、ケージ/ホットスポット）。
- 他アプリと同一内容の Swift ファイルは 0（md5 で確認）。

## 1. 画面

| タブ | 中身 |
| --- | --- |
| きょう | プロフィール → 見守り → きょうの世話（した／計る）＋日光浴 → 温度 → 体のようす → さいきん7日（長押しで削除） |
| 成長 | 甲長/体重・半年/1年/すべて のグラフ → 冬眠カード → 計った記録 |
| 器具 | 交換が近い順のカード（残り14日から「交換した」） |
| 設定 | うちのカメ（並べ替え）・朝のお知らせ（5〜11時・7日ぶん）・プライバシー |

## 2. 起動引数

- `-sample`（メモリ上の見本：かめきち（クサガメ・3歳）/ぽんず（ロシアリクガメ）・器具5つ・広告なし）、`-tab N`、`-samplePhotos <絶対パス>`（portrait・check）、`-sampleWinter`（かめきちが冬眠中）、`-pickSecond`（ぽんずを開く）
- `-noAds`（広告・同意・ATT を出さない。単体テストと録画 scheme `KameChoWalkthrough`（Release））

## 3. AdMob

- 2026-11-19 登録（ストア未掲載で作成）。アプリ ID `ca-app-pub-6105029932689433~1228798985`・バナー「KameCho Banner」`ca-app-pub-6105029932689433/4935788906`。
- Debug と TestFlight（sandbox）は Google のテスト用ユニット。
- **公開後に AdMob の「アプリの設定」で App Store に紐づける** → app-ads.txt の Verify app。

## 4. ストア・Web

- プライバシー: https://ryomasolid.github.io/privacy-kamecho.html ／ サポート: support-kamecho.html（ryomasolid.github.io 95e2d8e・2026-11-19 公開）
- ASC: Apple ID **6836622400**・SKU kamecho・App ID tech.sesame.kamecho（2026-11-19 登録）。掲載文 `Store/ASO.md`、審査メモ `Store/ReviewNotes-1.0.md`、録画 `Store/KameCho-review-1.0.mp4` を添付ずみ。配信は中国本土以外の174地域・無料・4+（広告あり）・プライバシーはインコ帳と同じ16行。
- **2026-11-19 12:55 ごろ JST に 1.0 (1) を審査提出**（承認後に自動公開）。
- スクショ: iPhone 17 Pro で `-sample`（today `-tab 0` / growth `-tab 1` / winter `-tab 1 -sampleWinter` / gear `-tab 2` / land `-tab 0 -pickSecond`・起動後8秒）を `src/` に撮る → `python3 Store/screenshots/generate.py` で out/（6.9）・out-6.3/。ASC には out-6.3 を入れた。
- アイコンの元は `Store/icon/icon.html`（Chrome headless で 1024 を撮り、JPEG 経由で透過なし PNG に）。
