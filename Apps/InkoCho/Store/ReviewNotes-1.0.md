# 1.0 の審査メモ（英語）

新規アプリは「2.1 Information Needed」（画面収録＋6項目）で止められやすいので、はじめから録画 `InkoCho-review-1.0.mp4` を添付し、6項目に答える。撮影環境は書かない。
撮り直しは scheme `InkoChoTour`（Release・`-noAds`）を `simctl io recordVideo` しながら流し、`avconvert --preset Preset960x540` で縮める。

```
1. Screen recording
The attached recording (InkoCho-review-1.0.mp4) shows the Release build of this version from a fresh install: launching the app -> registering a budgie from the welcome screen -> entering today's weight in grams on the Today tab -> writing today's record (mood and time outside the cage) -> the weight chart -> adding a learned word in the Words tab -> marking a cage cleaning as done in the Care tab -> the Settings tab. The app has no account registration, login, user-generated content shared with others, or paid content, so none of those flows exist. Ads are not shown in the recording; in normal use a banner appears at the bottom of each tab after the consent and App Tracking Transparency prompts.

2. Purpose and target audience
Inko-cho (インコ帳) is a care log for people in Japan who keep budgerigars (budgies), one of the most common pet birds in Japan. Small birds tend to hide illness, and a drop in body weight is often the earliest sign, so owners are advised to weigh them daily on a 0.1 g scale. The app compares each day's weight with the bird's usual weight (the average of the previous 7 days) and gently warns on a 5% or 10% drop or three declines in a row. It also gathers other signs on one screen (fluffed-up feathers, unusual droppings on consecutive days, room temperature that is too cold or hot, with a warmer target for young birds, repeated egg laying by females, and molting), keeps a list of words the bird has learned with the date it first said them, and shows when routine care (cage cleaning, perch washing, nail trimming, bathing, health checks) is next due. Several birds can be registered.

3. How to access the main features
No login, setup or sample files are needed. On first launch, tap 「うちの子を登録する」 (Register my bird), enter a name and tap 「保存」 (Save).
- きょう (Today): profile, the watch cards, today's weight (type the grams and tap 「記録」), today's record (「きょうの記録をつける」 opens the form), and recent days.
- 体重 (Weight): weight chart with the usual-weight line, and the list of weights (swipe to delete).
- ことば (Words): number of learned words and the list; 「言葉を追加」 adds one.
- おせわ (Care): last and next date for each care item; 「した」 records it for today.
- 設定 (Settings): add another bird, and turn on the morning reminder (the system permission request appears).
Photos can be added from the camera or the photo picker; the camera permission is requested only when the camera is used.

4. External services
The only third-party service is Google AdMob (Google Mobile Ads SDK with Google's User Messaging Platform) for a banner ad at the bottom of each tab. The App Tracking Transparency prompt is shown before ads are requested. There is no server of our own, no account system, no analytics SDK, no payment processor and no AI service. All records and photos stay on the device (SwiftData); notifications are local.

5. Regional differences
The app functions the same way in every region. The interface is in Japanese. In regions where Google requires it, the consent form is shown before ads.

6. Regulated industry / third-party material
The app is not in a regulated industry and contains no protected third-party material. All text, the icon and the illustrations are my own work. The weight thresholds, temperature ranges and care intervals are general husbandry guidelines; the app tells users to consult an avian veterinarian when they are worried.

The app shares no source files with my other apps. There are no in-app purchases.
```
