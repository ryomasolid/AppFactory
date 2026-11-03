# 2.1 Information Needed への回答（2026-11-03）

2026-11-03 06:38 に 1.0 (2) が Guideline 2.1 - Information Needed で却下。実機の画面収録と 6 項目の説明を App Review 情報のメモに入れて再提出するよう求められた。下の英文を ASC の審査メモに入れる（メモにはシミュレーターと書かない・ユーザーの指示）。画面収録はユーザーの判断でシミュレーター（iPhone 17 Pro / iOS 26.0・Release）で撮り、添付ファイル欄に付けた。撮り直しは scheme GatsuGatsuReviewWalkthrough の UI テストを `simctl io recordVideo` で録画しながら流す。

```
Regarding Guideline 2.1 - Information Needed:

1. Screen recording
The attached recording (GatsuGatsu-review-1.0.mp4, 4.5 min) shows the Release build of this version, starting right after a fresh install: Google's tracking explanation -> the ATT permission request -> Home -> scheduling a reminder in the queue-time tool -> a station guide -> a restaurant report -> logging a meal in GatsuLog -> the reminder notification arriving about 3 minutes later. Ads in the recording are Google test ads; the App Store build shows live AdMob ads in the same places. No accounts, login, user-generated content or paid content.

2. Purpose and target audience
GatsuGatsu Gourmet is the app version of gatsugatsu-gurume.com, a Japanese food guide that I operate myself. It is for people in Japan who want to eat a big, filling meal when eating out (large ramen, rice bowls, all-you-can-eat). It offers portion-size tables, official calorie figures from restaurant chains, station-by-station guides for 24 stations in Tokyo, Kanagawa, Saitama and Chiba, and my own first-hand restaurant reports with photos I took. Everything is bundled in the app, so it works without signal while standing in a queue. App-only features: a meal log (GatsuLog) that totals daily and weekly calories, and a queue-time estimate that sends a local notification 5 minutes before the expected seating time.

3. How to access the main features
No login, setup or sample files are needed. Use the five tabs at the bottom:
- ホーム (Home): today's meal totals, favorite stations, first-hand reports, today's article and shortcuts to the tools.
- 駅 (Stations): choose a station to read its guide; the star button saves it as a favorite.
- 読む (Read): portion guides, columns and first-hand reports, with search.
- ツール (Tools): portion converter, calorie and PFC calculator, queue-time estimate (tap 「入店の5分前に通知する」 to schedule the reminder), all-you-can-eat break-even, and bill splitter (result can be shared through the share sheet).
- ガツログ (GatsuLog): log a meal and see daily and weekly totals. The log is stored only on the device.
A rewarded video ad is optional: in Settings it hides ads for 2 hours, and on the monthly summary it unlocks the summary for 24 hours. Logging and the tools never require watching an ad.

4. External services
- Google Mobile Ads SDK (AdMob) for banner, native, interstitial, app open and rewarded ads, and Google's User Messaging Platform for the consent and tracking explanation.
- Apple's local notifications (UserNotifications) for the queue reminder.
There is no server, no account system, no payment processor and no AI service. Links to maps or official chain websites open in Safari or the Maps app.

5. Regional differences
The app is distributed only in Japan and its content is in Japanese. It functions the same way for every user. The only difference is handled by Google's UMP SDK: the GDPR consent form appears only for users in the EEA and UK.

6. Regulated industry / third-party material
The app is not in a regulated industry. All articles and photos were written and taken by me as the operator of gatsugatsu-gurume.com. Calorie and portion figures for chains are factual values taken from each chain's official published nutrition information, with the source and the date checked shown under each figure. Restaurant and chain names are used only to identify the places described.

The app shares no source files with my other apps. Ads are provided by Google AdMob, and there are no in-app purchases.
```
