# CarLog（カーログ）— 設計・画面構成

クルマの「給油」「維持費」「メンテナンス時期」を1つにまとめる記録アプリ。
掲載文は `Store/ASO.md` を参照。

## 1. 方針

- **入力が続くことが全て**。燃費アプリは「3回入れて放置」で死ぬ。給油の入力を
  日付・走行距離・給油量・金額の4項目に絞り、それ以外（満タン/スタンド名/メモ）は任意。
- **入れた分だけ勝手に賢くなる**。給油を記録すると燃費・走行ペース・1kmあたりのコストが
  自動で出て、距離ベースのメンテ予定日まで更新される。ユーザーは何も計算しない。
- **思い出させる役はアプリが持つ**。車検・オイル交換・タイヤ交換・保険更新は、
  忘れたときの損害が大きいわりに年1回未満なので記憶に残らない。ここを通知で取る。
- **端末内で完結**。アカウント登録も位置情報も不要。走行距離は生活圏が推測できる情報なので
  外部へ送らない（App Privacy で「データを収集しない」と宣言できる形を守る）。

## 2. 技術構成（既存アプリからの流用）

| 部品 | 流用元 | 備考 |
| --- | --- | --- |
| Tuist `Project.swift` / `Tuist/Package.swift` | GomiAlarm | iPhone 専用・縦固定・AdMob 依存 |
| SwiftData + `@Observable` | 全アプリ | iOS 17 / Swift 6.2 strict concurrency |
| `StoreManager`（StoreKit 2 買い切り） | TeikiCheck | プロダクトIDのみ差し替え |
| `ConsentManager`（UMP → ATT → AdMob） | GomiAlarm | そのまま |
| `BannerAdView` | GomiAlarm | ユニットIDのみ差し替え |
| `Launch`（起動引数によるデモ/スクショ） | GomiAlarm | 引数名を揃える |
| `NotificationScheduler` の「全消し→組み直し」方式 | GomiAlarm | 下記のとおり**大幅に簡略化** |

### BGTask を持たない理由

GomiAlarm は「毎週◯曜」の無限の繰り返しを64件の上限内に収める必要があり、
120日ぶんを先に積んで背景で組み直す仕組み（BGAppRefreshTask）が要った。

CarLog のメンテ予定は **1車両あたり数件・次の1回だけ** 通知すればよく、
同時に予約するローカル通知は多くても十数件にしかならない。
距離ベースの予測日がずれても、給油を記録した瞬間（＝アプリを開いた瞬間）に
組み直せば十分な精度になる。BGTask・`UIBackgroundModes` は入れない。

## 3. データモデル（SwiftData）

```
Vehicle 1 ──< FuelRecord        給油
        1 ──< ExpenseRecord     維持費（税金・保険・駐車場…）
        1 ──< MaintenanceItem   メンテ項目（オイル交換・車検…）
                     1 ──< MaintenanceLog   実施履歴
```

### Vehicle（クルマ）
| プロパティ | 型 | 意味 |
| --- | --- | --- |
| `id` | UUID | 通知識別子・CSV のキー |
| `name` | String | 「プリウス」「通勤用」など表示名 |
| `makerModel` | String | メーカー・車種（任意メモ） |
| `colorHex` / `symbolName` | String | 一覧・グラフの色分け |
| `fuelTypeRaw` | String | `FuelType`（レギュラー/ハイオク/軽油/EV） |
| `tankCapacity` | Double? | L。給油量の入力ミス検知に使う |
| `purchaseOdometer` | Double | 記録開始時点の走行距離 |
| `firstRegistrationDate` | Date? | 初度登録年月。車検の起算日 |
| `isDefault` / `sortOrder` | Bool / Int | 既定の1台・並び順 |

### FuelRecord（給油）
`date` / `odometer`(km, 総走行距離) / `liters` / `totalPrice`(円) /
`isFullTank` / `stationName` / `note`

単価は `totalPrice / liters` から常に導出する（入力させない。
レシートには単価も総額も載っているが、総額のほうが打ちやすく丸め誤差が出ない）。

### ExpenseRecord（維持費）
`date` / `categoryRaw`（`ExpenseCategory`） / `amount`(円) / `odometer`? / `note`

給油は `ExpenseRecord` に持たせず `FuelRecord` から集計時に合成する。
「燃費の計算に使う記録」と「お金の記録」を同じ行にすると、
片方だけ直したいときに必ず壊れる。

### MaintenanceItem（メンテ項目）
`title` / `symbolName` / `intervalMonths`? / `intervalDistance`?(km) /
`lastDoneDate`? / `lastDoneOdometer`? / `notifyDaysBefore` / `notifyHour` / `notifyMinute` / `isEnabled`

期間・距離は**両方入れてよい**。その場合は先に来るほうが次回予定になる
（オイル交換「6か月 または 5,000km」が実際の指定の形）。

## 4. 計算ロジック（アプリの中身）

すべて純粋関数として `Sources/Services` に置き、SwiftData に依存させない。
（macOS 上の SwiftPM ハーネスでテストするため）

### 4.1 燃費 — 満タン法（`FuelEconomy`）

満タン給油から次の満タン給油までの距離を、その間に入れた**全て**の給油量で割る。

```
区間燃費 = (今回の odometer - 前回満タンの odometer) ÷ (前回満タンの次から今回までの liters 合計)
```

- 最初の給油は「満タンにした基準点」にしかならないので燃費は出ない。これは正しい挙動なので
  UI でも「次の満タン給油で燃費が出ます」と明示する。
- 途中の部分給油（`isFullTank == false`）は区間を切らず、給油量だけ足す。
- 通算燃費は「最初の満タン〜最後の満タン」の総距離 ÷ その間の総給油量。
  区間燃費の単純平均ではない（距離の長い区間の重みが正しく乗る）。
- 走行距離計（odometer）の巻き戻り・重複日付があっても落ちないよう、
  計算前に `odometer` 昇順に並べ替え、前回以下の距離の記録は区間から除く。

### 4.2 走行ペースと距離の予測（`OdometerProjection`）

直近の記録から「1日あたり何km走るか」を出し、指定距離に到達する日を予測する。

- ペース = (最新 odometer - 基準 odometer) ÷ 経過日数。
  基準は「最新から遡って90日以内の最も古い記録」。
  それが取れなければ全期間。記録が1件以下ならペースは出さない（nil）。
- 予測日 = 今日 + (目標距離 - 現在距離) ÷ ペース。
  ペースが 0 以下、または予測が10年より先になるときは nil（「予測できない」と表示する）。

### 4.3 メンテの次回予定（`MaintenanceDue`）

`lastDone`（日付・距離）＋ インターバルから次回を出し、日付と距離の**早いほう**を採用する。

| 状態 | 条件 |
| --- | --- |
| `.overdue` | 予定日を過ぎた、または予定距離を超えた |
| `.soon` | 予定日まで `notifyDaysBefore` 以内、または残り距離が インターバルの10%以内 |
| `.ok` | それ以外 |

`lastDone` が未入力の項目は、車両の `firstRegistrationDate` と `purchaseOdometer` を起点にする。

### 4.4 コスト集計（`CostSummary`）

期間（今月/今年/全期間/任意）で、カテゴリ別合計・総額・月平均・**1kmあたりコスト**を出す。
1kmあたり = 期間内の総支出 ÷ 期間内の走行距離（期間内の odometer 最大 - 最小）。
走行距離が 0 のときは nil（0除算を返さない）。

## 5. 通知設計

- 予定のあるメンテ項目それぞれについて、**次の1回だけ** `UNCalendarNotificationTrigger`（非繰り返し）で予約。
- 予約日時 = 次回予定日の `notifyDaysBefore` 日前の `notifyHour:notifyMinute`。
  すでに過ぎている場合は当日の同時刻、それも過ぎていれば予約しない（画面の `.overdue` バッジで伝える）。
- アプリ起動時・給油記録時・メンテ項目編集時に `removeAllPendingNotificationRequests()` → 組み直し。
- 通知本文は「オイル交換の時期です（前回から 5,240km / 6か月）」のように**根拠を書く**。
  根拠のない通知はオフにされる。

## 6. 画面構成

タブ5つ（ホーム／給油／費用／メンテ／設定）。`ContentView` が `TabView` を持ち、バナー広告は全タブ共通で最下部に1つ。
各タブのナビゲーションバー右上に**クルマの切り替えメニュー**（`vehicleSwitcher`）を置き、
選択中の車両IDは `@AppStorage("cl.selectedVehicleID")` でタブ間に共有する。

### 6.1 オンボーディング（`fullScreenCover`／初回のみ）
1. クルマを1台登録（名前・燃料種別だけ。車種や初度登録は後から）
2. 現在の走行距離を入力（ここが全ての起点）
3. メンテ項目のテンプレを選ぶ（オイル交換／車検／タイヤ交換／保険更新）
4. 通知の許可

### 6.2 ホーム（`HomeView`）
- タイトル: 選択中のクルマの名前（切り替えは右上のメニュー）
- 主役カード: **平均燃費 km/L**（直近区間と通算を並べる）と 総走行距離
- 「今月の出費」「1kmあたり」の2枚
- 期限が近い／過ぎたメンテを上位3件（`.soon` / `.overdue` のみ）
- 大きな「給油を記録」ボタン（このアプリで最も押されるボタン）

### 6.3 給油（`FuelListView` / `FuelEntryView`）
- 一覧: 日付・距離・給油量・金額・区間燃費。燃費は右寄せで大きく
- 入力: 走行距離と給油量はテンキー。前回からの走行距離を即時プレビュー
- 入力ミス検知: タンク容量超え、前回より小さい odometer は警告を出す（保存はできる）

### 6.4 費用（`ExpenseListView` / `CostSummaryView`）
- 期間トグル（今月／今年／全期間）
- カテゴリ別の横棒（金額順）。給油ぶんは「ガソリン代」として合成表示
- 月別の推移（棒グラフ・Swift Charts）

### 6.5 メンテ（`MaintenanceListView` / `MaintenanceEditorView`）
- 項目ごとに次回予定（日付 or 距離の早いほう）と残り、状態バッジ
- 「実施した」で `MaintenanceLog` を追加し、`lastDone` を更新 → 通知を組み直す
- 実施時に費用を入れた場合は「費用にも記録する」（既定オン）で `ExpenseRecord` も作る。
  集計は `ExpenseRecord` だけを見るので、履歴の `cost` と二重に数えない
- テンプレ: オイル交換(6か月/5,000km)・オイルフィルタ(12か月/10,000km)・
  タイヤ交換(--/30,000km)・車検(24か月)・自動車税(12か月)・保険更新(12か月)・
  バッテリー(36か月)・ワイパー(12か月)

### 6.6 設定
通知時刻の既定、距離/燃費の単位（km/L 固定・v1）、CSV書き出し（Pro）、
Pro 購入・復元、プライバシーポリシー、問い合わせ。

## 7. 無料 / Pro の境界

| | 無料 | Pro（買い切り ¥480） |
| --- | --- | --- |
| クルマの登録 | 1台 | 無制限 |
| 給油・費用の記録 | **無制限** | 無制限 |
| 燃費・コスト計算 | **全部使える** | 同じ |
| メンテ項目 | 3件まで | 無制限 |
| CSV 書き出し | × | ○ |
| 広告 | 表示 | 非表示 |

記録件数と計算には**一切上限を置かない**。ここを塞ぐとデータが貯まらず、
貯まらないアプリは課金にも継続にも繋がらない。
課金の引き金は「2台目のクルマ」「4つ目のメンテ項目」「貯めた記録の書き出し」。

## 8. スクショ用の起動引数（`Launch.swift`）

| 引数 | 効果 |
| --- | --- |
| `-demo` | デモ車両＋給油14件・費用・メンテ項目を投入 |
| `-hideAds` | バナーと同意/ATT フローを止める |
| `-showPaywall` | 起動直後にペイウォール |
| `-forceOnboarding` | オンボーディングを強制表示 |
| `-onboardingStep <name>` | オンボーディングの開始ページ（`vehicle` / `odometer` / `templates` / `notifications`） |
| `-startTab <name>` | `fuel` / `cost` / `maintenance` / `settings` |
| `-showFuelEntry` | 給油入力シートを開いた状態 |

## 9. v1 スコープ

**入れる**: 複数車両・給油と燃費・維持費とカテゴリ別集計・メンテ予定と通知・
Swift Charts のグラフ・CSV書き出し（Pro）・課金・広告・オンボーディング。

**入れない（v1.1 以降）**: レシートOCR、ガソリン価格の取得、iCloud 同期、
Widget（次の給油/メンテ）、Apple Watch、走行ログの自動記録（位置情報を使いたくない）。

## 10. リスクと対策

| リスク | 対策 |
| --- | --- |
| 入力が続かない | 必須項目を4つに絞る。ホームの主役を「給油を記録」ボタンにする |
| 走行距離の打ち間違いで燃費が壊れる | 前回以下の距離は警告。計算側も昇順ソート＋異常区間の除外で落ちない |
| 競合が多い（燃費管理アプリは既存多数） | 「燃費」だけでなく**維持費とメンテ通知**を1つにまとめた点で差別化。ASO も3語で取る |
| 車検の起算がわからない | 初度登録年月を入れれば自動。未入力なら「前回実施日」から24か月で代替 |

## 11. ビルド・テスト

```sh
cd Apps/CarLog
tuist install && tuist generate --no-open
xcodebuild -workspace CarLog.xcworkspace -scheme CarLog \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

- `Tuist.swift` の `fullHandle` があるため、`tuist generate` には **`tuist auth login` 済みであること**が必要
  （未ログインだと "Token for Tuist was not found" で止まる）。
- テストは Swift Testing（`CarLog/Tests`）。燃費・走行ペース・メンテ予定・コスト集計・通知計画・
  無料版の上限・CSV を純粋関数として固定している。
- アイコンは `swift Store/makeicon.swift CarLog/Resources/Assets.xcassets/AppIcon.appiconset/icon.png` で再生成。
- スクショは `-demo -hideAds` 系の起動引数で iPhone 17 Pro Max（6.9"）から撮り、
  `sips -z 2688 1242` で `Store/screenshots-65/` を作る。IAP 審査用は同じサイズの JPEG（`Store/iap-review/`）。
