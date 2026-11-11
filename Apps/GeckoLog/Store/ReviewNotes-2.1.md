# 2.1 Information Needed への回答（2026-11-11）

2026-11-11 08:35 に 1.0 (1) が Guideline 2.1 - Information Needed - New App Submission で却下。
画面収録と 6 項目の説明を App Review 情報のメモに入れて再提出するよう求められた（ガツガツグルメ 1.0 と同じ文面）。
下の英文を ASC の審査メモに入れ、録画 `GeckoLog-review-1.0.mp4` を添付ファイル欄に付けた（メモには撮影環境を書かない）。
撮り直しは scheme `GeckoLogReviewWalkthrough` の UI テスト（`GeckoLog/UITests/ReviewWalkthrough.swift`）を
`simctl io recordVideo` で録画しながら Release で流す。アプリは先にアンインストールしておく（記録ゼロから始めるため）。

```
Regarding Guideline 2.1 - Information Needed:

1. Screen recording
The attached recording (GeckoLog-review-1.0.mp4, about 4 min) shows the Release build of this version from a fresh install: launching the app -> registering two geckos from the empty Cage screen -> opening one gecko and recording a feeding, a weight and a shed -> the feeding round ("ごはんをまとめて記録") where one gecko is marked as having refused food -> recording a clutch of eggs on the Eggs tab -> the Journal tab -> Settings, where the feeding-day notification is turned on (the system notification permission request appears) and the CSV export share sheet is opened -> back to the Cage screen. The app has no account registration, login, user-generated content shared with others, or paid content, so none of those flows exist.

2. Purpose and target audience
GeckoLog (げこログ) is a care log for people in Japan who keep leopard geckos (Eublepharis macularius) as pets. General pet diaries do not fit this animal: it eats live insects every 1-4 days depending on age, often refuses food for a while, sheds on a cycle, and its eggs hatch after a temperature-dependent period. The app decides the feeding interval from the hatch date (baby / young / adult), shows which geckos should be fed today, flags refusal streaks and weight loss, predicts the next shed from past sheds, and shows the expected hatch date and the sex tendency for a clutch from the incubation temperature. Keepers with several geckos can log one feeding round for all of them at once.

3. How to access the main features
No login, setup or sample files are needed. On first launch the Cage tab is empty; tap 「1匹目を登録する」 (Register your first gecko), enter a name and optionally the hatch date, then tap 「保存」 (Save).
- ケージ (Cage): one card per gecko with the next feeding day and warnings. 「ごはんをまとめて記録」 logs a feeding for every gecko that is due; tap 「食べた」 next to a gecko to switch it to 「拒食」 (refused). Tap a card to open the gecko.
- Gecko screen: 「記録する」 buttons for feeding, shed, weight, droppings, temperature/humidity, cleaning, vet visit and memo; the history and a weight chart are below.
- たまご (Eggs): 「産卵を記録する」 records a clutch with the laying date, egg count and incubator temperature; the card shows the day count, expected hatch date and sex tendency.
- きろく (Journal): all records by day, filterable by gecko.
- せってい (Settings): 「ごはんの日に知らせる」 turns on a single daily local notification on feeding days (the system permission request appears); 「記録をCSVで書き出す」 opens the share sheet with a CSV file.

4. External services
None. The app uses only Apple frameworks: SwiftUI, SwiftData for on-device storage, Swift Charts for the weight chart, PhotosUI for choosing a gecko photo, and UserNotifications for the local feeding-day reminder. There is no server, no account system, no analytics, no advertising SDK, no payment processor and no AI service, and the app makes no network requests. All records and photos stay on the device.

5. Regional differences
The app functions the same way in every region. The interface is in Japanese.

6. Regulated industry / third-party material
The app is not in a regulated industry and contains no protected third-party material. All text, the icon and the illustrations are my own work. The feeding intervals, shed cycle and incubation figures are general husbandry guidelines, and the app tells users to consult a reptile veterinarian when in doubt.

The app shares no source files with my other apps. There are no in-app purchases and no ads.
```
