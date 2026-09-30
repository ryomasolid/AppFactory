# HamuhamuDiary（はむはむ日記）— 設計・画面構成

ハムスターの毎日のお世話（体重・ごはん・掃除・写真）を記録する飼育日記。
掲載文は `Store/ASO.md` を参照。

## 0. 経緯

- v1.0〜1.3 は React Native（Expo）製。ソースは `~/Documents/hamuhamu-diary`（GitHub: ryomasolid/hamuhamu-diary）。
- 2026 年に旧アカウント（ryomasolid / チーム 7AVSSF5RFN）から自分のアカウント（チーム ZP3T7MAT5U）へ **App 移管済み**。
- v2.0 で Swift / SwiftUI に作り直し、AppFactory に移した。**既存アプリのアップデート**として出すため、
  バンドルID `com.ryomasolid.hamuhamudiary`・App ID `6777478295` は旧版のまま。

## 1. 方針

- **旧版の日記を1件も落とさない**。アップデートした人の日記が消えて見えるのが最悪の失敗。
  初回起動時に旧版の保存データ（AsyncStorage）を読み、SwiftData に移す（下記 3）。
- **1日1件の記録**。旧版のバックアップ取り込みは日付で突き合わせていたので、その前提を守る。
  ホームのボタンは、今日の記録があれば「今日の記録を編集する」になる。
- **旧版とバックアップファイルを行き来できる**。同居人がまだ旧版でも「データを送る／取り込む」が使えるよう、
  ファイルの形（`BackupFile`, version 1）とキー名を変えない。
- **端末内で完結**。アカウント登録なし、データは外部に送らない。
- **広告はバナー1枠だけ**（全タブ共通の最下部）。旧版は記録の保存時とデータ送受信時にインタースティシャル広告を
  出していたが、評価を下げる原因になりやすいので Swift 版では出さない。

## 2. 技術構成（既存アプリからの流用）

| 部品 | 流用元 | 備考 |
| --- | --- | --- |
| Tuist `Project.swift` / `Tuist/Package.swift` | CarLog | iPhone 専用・縦固定・AdMob 依存・iOS 17 |
| SwiftData | 全アプリ | |
| 広告の同意（`AdPermission`）とバナー（`AdStrip`） | — | **流用せず書き起こし**（下記） |
| `Launch`（起動引数によるデモ/スクショ） | CarLog | `-demo -hideAds -startTab -showRecordEntry -showShareCard` |
| `NotificationScheduler` の「全消し→組み直し」 | CarLog | |
| シェア画像（`ImageRenderer`＋共有シート） | GeoHero | |

> SubsNote が「他アプリと同じ部品」で 4.3(a) Spam 却下になったため、広告まわりは他アプリのコピーにしない。
> `AdPermission` は UMP → ATT → AdMob を状態（idle/asking/ready/off）として持ち、`AdStrip` は ready になって
> 広告が届いてから高さを持つ。**TODO: バナーのユニットIDと GADApplicationIdentifier は、まだ移管前の旧 AdMob のもの。**

## 3. 旧版からの引き継ぎ（`LegacyStore` / `DiaryData.bootstrapIfNeeded`）

旧版は Zustand の状態を AsyncStorage に JSON 文字列で保存していた。iOS での実体は

```
Application Support/com.ryomasolid.hamuhamudiary/RCTAsyncLocalStorage_V1/
  manifest.json          { "hamu-records": "<JSON>" | null, "hamu-profile": …, "hamu-reminders": … }
  <md5(キー)>             1024文字を超えた値（manifest 側は null）
```

（さらに古い版は `Documents/RCTAsyncLocalStorage_V1/`。両方を見る。）値は `{"state": {...}, "version": 0}`。

- 初回起動で1回だけ（`hd.didBootstrap`）。旧データが無ければ既定の項目を入れる。
- 失敗したら印を付けず、次回起動でやり直す。旧データは**消さない**。
- 写真は旧版も `Documents/photos/` に置いて相対パスを保存していたので、**ファイルは動かさない**。
  ごく初期の絶対パス保存（`file:///…/Documents/photos/x.jpg`）は相対に直す（`PhotoStore.normalizedPath`）。
- 旧版の「今日のタスク」（hamu-tasks）は画面から使われていなかったので移さない。

## 4. データモデル（SwiftData）

| モデル | 中身 | 旧版の対応 |
| --- | --- | --- |
| `DiaryRecord` | 日付・体重・ごはん・掃除キー・メモ・写真パス | `DailyRecord` |
| `HamsterProfile` | 名前・種類・誕生日・お迎え日・写真（1匹） | `HamsterProfile` |
| `SupplyReminder` | 消耗品の交換サイクルと前回の交換日 | `Reminder` |
| `PresetMeal` / `SingleFood` / `CleaningOption` | 記録フォームの選択肢 | 同名 |

どれも旧版の `id` を `key` として持つ（バックアップの突き合わせに使う）。

## 5. 画面

| タブ | 中身 |
| --- | --- |
| ホーム | 今日の記録ボタン、最新体重（前回比）・最後の掃除、交換時期が近いもの、思い出フォト（シェア） |
| 日記 | 体重グラフ（1ヶ月/3ヶ月/全期間、Swift Charts）、記録の一覧（タップで編集・長押しでシェア/削除） |
| プロフィール | 年齢の自動計算、お迎えからの日数、消耗品の交換サイクル（「交換した」で今日に） |
| 設定 | 掃除項目・献立・フードの編集、通知、データを送る/取り込む、レビュー・紹介 |

## 6. インストールを増やす仕掛け

- **レビュー依頼**（`ReviewPolicy`）: 記録が 3・15・50 件に届いたとき。前回から60日あける。
- **シェアカード**: 写真・日付・体重・年齢入りの 4:5 画像（1080px 幅）に #はむはむ日記 を添えて共有。
- **通知**: 交換予定日の朝9時、毎日の記録リマインド（時刻を選べる）。続けて使う人を増やす。
- 設定の「レビューを書く」「ハム友にすすめる」。

## 7. ビルドと提出

```
cd Apps/HamuhamuDiary
mise exec -- tuist install && mise exec -- tuist generate --no-open
xcodebuild test -workspace HamuhamuDiary.xcworkspace -scheme HamuhamuDiary \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

提出は他のアプリと同じ `xcodebuild archive` → `-exportArchive`（method `app-store-connect` / destination `upload`）。
バージョンは 2.0 から（ストアの公開版が 1.3 のため、これより小さくできない）。
