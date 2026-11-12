# 1.0 の審査メモ（英語）

げこログ・ガツガツグルメの 1.0 が「2.1 Information Needed - New App Submission」（画面収録＋6項目）で一度却下されたので、
はじめから録画 `MedakaCho-review-1.0.mp4` を添付し、6項目に答えたメモを入れる。撮影環境は書かない。
撮り直しは scheme `MedakaChoReviewTour`（Release・`-quiet`）を `simctl io recordVideo` しながら流し、`avconvert --preset Preset960x540` で縮める。

```
1. Screen recording
The attached recording (MedakaCho-review-1.0.mp4, about 75 seconds) shows the Release build of this version from a fresh install: launching the app -> registering a container ("vessel") from the empty home screen -> opening it and logging a feeding with one tap -> logging a water change (percentage) -> logging collected eggs, which are also added to the Eggs tab -> the Eggs, Breeds and Settings tabs. The app has no account registration, login, user-generated content shared with others, or paid content, so none of those flows exist. Ads are not shown in the recording; in normal use a banner appears at the bottom of each tab after the consent and App Tracking Transparency prompts.

2. Purpose and target audience
Medaka-cho (めだか帳) is a care log for people in Japan who keep medaka (Japanese rice fish, Oryzias latipes), a very popular hobby fish usually kept outdoors in several ceramic bowls, styrofoam boxes or tanks at once. Unlike pet diaries that track one animal, records are kept per container: the app estimates when each container needs a water change from the water volume, fish count, indoor/outdoor placement and the latest water temperature, shows feeding guidance for the season from the water temperature, warns about overcrowding, and estimates the hatching date of collected eggs from the water temperature (medaka eggs hatch after about 250 degree-days). It also summarizes fish counts and hatch rates per breed.

3. How to access the main features
No login, setup or sample files are needed. On first launch the 容器 (Containers) tab is empty; tap 「容器を登録する」 (Register a container), enter a name and tap 「保存」 (Save).
- 容器 (Containers): today's checklist (containers due for a water change, eggs about to hatch) and one card per container. Tap a card to open it.
- Container screen: status (next water change, water temperature and feeding guidance, water per fish) and 11 record buttons. Feed / top-up / cleaning are saved with one tap; the others open a short form. Swipe a history row to delete it.
- 卵 (Eggs): collected eggs with progress and the expected hatching date; tap one to record how many hatched.
- 品種 (Breeds): fish counts and hatch rates per breed.
- 設定 (Settings): 「朝のお知らせ」 turns on one local notification per day (the system permission request appears); 「記録をCSVで書き出す」 opens the share sheet with a CSV file.

4. External services
The only third-party service is Google AdMob (Google Mobile Ads SDK with Google's User Messaging Platform) for a banner ad at the bottom of each tab. The App Tracking Transparency prompt is shown before ads are requested. There is no server of our own, no account system, no analytics SDK, no payment processor and no AI service. All records stay on the device (SwiftData); notifications are local.

5. Regional differences
The app functions the same way in every region. The interface is in Japanese. In regions where Google requires it, the consent form is shown before ads.

6. Regulated industry / third-party material
The app is not in a regulated industry and contains no protected third-party material. All text, the icon and the illustrations are my own work. The water-change intervals, feeding guidance and hatching figures are general husbandry guidelines, and the app says so.

The app shares no source files with my other apps. There are no in-app purchases.
```
