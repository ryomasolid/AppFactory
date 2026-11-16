# 1.0 の審査メモ（英語）

新規アプリの 1.0 は「2.1 Information Needed」（画面収録＋6項目）で止められやすいので、はじめから録画 `ToypooDiary-review-1.0.mp4` を添付し、6項目に答える。撮影環境は書かない。
撮り直しは scheme `ToypooDiaryWalkthrough`（Release・`-calm`）を `simctl io recordVideo` しながら流して縮める。

```
1. Screen recording
The attached recording (ToypooDiary-review-1.0.mp4) shows the Release build of this version from a fresh install: launching the app -> registering a dog from the welcome screen -> writing today's diary page (mood, number of walks and walking time) -> recording a grooming visit in the Trimming tab -> recording a weight and a heartworm medicine dose in the Health tab -> the Settings tab. The app has no account registration, login, user-generated content shared with others, or paid content, so none of those flows exist. Ads are not shown in the recording; in normal use a banner appears at the bottom of each tab after the consent and App Tracking Transparency prompts.

2. Purpose and target audience
Toypoo Diary (といぷー日記) is a photo diary for owners in Japan of toy poodles, one of the most popular dog breeds in Japan. Besides a daily page (photo, mood, walks, meals, tooth brushing, stool, tear stains, weight, note), it covers care that is specific to poodles: their coat never sheds and keeps growing, so the app shows the days since the last haircut, the estimated coat growth (about 1 cm per month) and the next grooming date from the owner's usual interval, with a gallery of past cut styles. It also shows a weight chart with a gentle warning on a sudden monthly change, and the next dates for rabies and combination vaccines, health checks, and monthly heartworm / flea-and-tick medicine within a configurable season. Several dogs can be registered.

3. How to access the main features
No login, setup or sample files are needed. On first launch, tap 「うちの子を登録する」 (Register my dog), enter a name and tap 「保存」 (Save).
- 日記 (Diary): profile with age (and the age in human years), today's page, the last 7 days of walks, and past pages. Tap 「きょうの日記を書く」 to write today's page; tap a past page to read it and share it as an image.
- トリミング (Trimming): days since the last cut, coat growth, next grooming date, and the cut-style gallery. Tap 「トリミングを記録」 to add a visit.
- けんこう (Health): weight chart (「体重を記録」 adds a weight) and the next date for each preventive care item; tap an item, then 「今日のませた・つけた」 / 「今日うけた」 to record it.
- 設定 (Settings): add another dog, turn on the morning reminder (care and grooming days) and the evening diary reminder (the system permission request appears), and change the medicine seasons.
Photos can be added from the camera or the photo picker; the camera permission is requested only when the camera is used.

4. External services
The only third-party service is Google AdMob (Google Mobile Ads SDK with Google's User Messaging Platform) for a banner ad at the bottom of each tab. The App Tracking Transparency prompt is shown before ads are requested. There is no server of our own, no account system, no analytics SDK, no payment processor and no AI service. All records and photos stay on the device (SwiftData); notifications are local.

5. Regional differences
The app functions the same way in every region. The interface is in Japanese. In regions where Google requires it, the consent form is shown before ads.

6. Regulated industry / third-party material
The app is not in a regulated industry and contains no protected third-party material. All text, the icon and the illustrations are my own work, and the photos in the screenshots are of my own dog. The grooming interval, coat growth, preventive care schedule and weight warnings are general guidelines; the app tells users to follow their veterinarian's advice.

The app shares no source files with my other apps. There are no in-app purchases.
```
