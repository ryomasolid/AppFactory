# 1.0 の審査メモ（英語）

新規アプリは「2.1 Information Needed」（画面収録＋6項目）で止められやすいので、はじめから録画 `KameCho-review-1.0.mp4` を添付し、6項目に答える。撮影環境は書かない。
撮り直しは scheme `KameChoWalkthrough`（Release・`-noAds`）を `simctl io recordVideo` しながら流し、`avconvert --preset Preset640x480` で縮める（10MB 未満にする）。

```
1. Screen recording
The attached recording (KameCho-review-1.0.mp4) shows the Release build of this version from a fresh install: launching the app -> registering a turtle from the welcome screen -> recording a feeding and a water change on the Today tab -> measuring shell length and weight -> recording the water and basking temperatures -> recording a health check -> the growth chart -> adding a UVB lamp on the Equipment tab -> starting hibernation on the Growth tab -> the Settings tab. The app has no account registration, login, user-generated content shared with others, or paid content, so none of those flows exist. Ads are not shown in the recording; in normal use a banner appears at the bottom of each tab after the consent and App Tracking Transparency prompts.

2. Purpose and target audience
Kame-cho (カメ帳) is a care log for people in Japan who keep pet turtles and tortoises, such as Reeves' turtles, red-eared sliders, Japanese pond turtles and Russian or Hermann's tortoises. It schedules routine care from the species type (aquatic or terrestrial) and age (feeding and water changes for aquatic turtles; feeding, soaking and substrate changes for tortoises), tracks shell length and weight on a growth chart, watches weight loss during hibernation (about 1% per month is the usual guideline), reminds owners when UVB lamps, heaters and filter media are due for replacement, and flags temperatures outside the usual range, repeated refusal of food and common signs of illness. Several turtles can be registered.

3. How to access the main features
No login, setup or sample files are needed. On first launch, tap 「うちのカメを登録する」 (Register my turtle), enter a name and tap 「保存」 (Save).
- きょう (Today): profile, alerts, today's care with 「した」 (Done) / 「計る」 (Measure) buttons, temperatures (type values and tap 「記録」), 「体のようすを記録」 (health check), and the last 7 days.
- 成長 (Growth): shell length / weight chart, hibernation card (「冬眠を始める」 starts hibernation), and the list of measurements. The + button adds a measurement.
- 器具 (Equipment): UVB lamps, heaters and filter media with the days left until replacement; + adds one.
- 設定 (Settings): add or edit turtles, and turn on the morning reminder (the system permission request appears).
Photos are chosen with the system photo picker; no camera or photo library permission is requested.

4. External services
The only third-party service is Google AdMob (Google Mobile Ads SDK with Google's User Messaging Platform) for a banner ad at the bottom of each tab. The App Tracking Transparency prompt is shown before ads are requested. There is no server of our own, no account system, no analytics SDK, no payment processor and no AI service. All records and photos stay on the device (SwiftData); notifications are local.

5. Regional differences
The app functions the same way in every region. The interface is in Japanese. In regions where Google requires it, the consent form is shown before ads.

6. Regulated industry / third-party material
The app is not in a regulated industry and contains no protected third-party material. All text, the icon and the illustrations are my own work. The care intervals, temperature ranges, hibernation weight guideline and equipment lifetimes are general husbandry guidelines; the app tells users to consult a reptile veterinarian when they are worried.

The app shares no source files with my other apps. There are no in-app purchases.
