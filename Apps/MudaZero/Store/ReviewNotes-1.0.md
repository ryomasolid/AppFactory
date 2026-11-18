# 1.0 の審査メモ（英語）

新規アプリは「2.1 Information Needed」（画面収録＋6項目）で止められやすいので、はじめから録画 `MudaZero-review-1.0.mp4` を添付し、6項目に答える。撮影環境は書かない。
撮り直しは scheme `MudaZeroTour`（Release・`-noAds`）を `simctl io recordVideo` しながら流し、`avconvert --preset Preset960x540` で縮める。

```
1. Screen recording
The attached recording (MudaZero-review-1.0.mp4) shows the Release build of this version from a fresh install: launching the app -> choosing the usual daily impulse spending and the monthly budget on the welcome screen -> closing today as a no-spend day on the Today tab -> adding a necessary expense (groceries) -> adding an impulse expense (cafe) -> the Calendar tab with the monthly review -> the Settings tab. The app has no account registration, login, user-generated content shared with others, or paid content, so none of those flows exist. Ads are not shown in the recording; in normal use a banner appears at the bottom of each tab after the consent and App Tracking Transparency prompts.

2. Purpose and target audience
MudaZero (ムダゼロ, "zero waste spending") is a simple saving habit app for people in Japan who want to cut down on impulse spending but find full household account books hard to keep up. Instead of logging every expense, the user taps once at night to close a day without impulse purchases ("no-money day"). On days they did spend, they enter the amount and choose whether it was an impulse purchase (convenience store, cafe, snacks, online shopping, etc.) or a necessary expense (groceries, daily goods, transport, etc.). The app shows the streak of days without impulse spending, how much of the monthly impulse budget is left and how much can be spent per day for the rest of the month, a color-coded calendar with a monthly review, and the money "saved" toward a goal the user sets (for example a trip), counted from the user's usual daily impulse spending.

3. How to access the main features
No login, setup files or sample data are needed. On first launch, pick the amounts and tap 「はじめる」 (Start).
- きょう (Today): streak, 「ムダ遣いしなかった」 (No impulse spending) closes today, 「お金を使った」 (I spent money) adds an expense, the monthly budget card, and the saving goal card (「ためる もくひょうを決める」 sets a goal).
- カレンダー (Calendar): month view; tap a past day to add expenses or close that day; the arrows switch months; the monthly review is below.
- 設定 (Settings): usual daily impulse spending, monthly budget, saving goal, and the evening reminder (the system permission request appears when it is turned on).

4. External services
The only third-party service is Google AdMob (Google Mobile Ads SDK with Google's User Messaging Platform) for a banner ad at the bottom of each tab. The App Tracking Transparency prompt is shown before ads are requested. The app does not connect to banks, cards or any financial service, and there is no server of our own, no account system, no analytics SDK, no payment processor and no AI service. All records stay on the device (SwiftData); notifications are local.

5. Regional differences
The app functions the same way in every region. The interface is in Japanese and amounts are in yen. In regions where Google requires it, the consent form is shown before ads.

6. Regulated industry / third-party material
The app is not a financial service: it does not handle money, give financial advice or connect to accounts; it is a personal log of the user's own spending. It contains no protected third-party material. All text and the icon are my own work.

The app shares no source files with my other apps. There are no in-app purchases.
```
