# 1.1 (6) の審査メモ（2026-11-06 11:10 提出・ASC に入れた文面）

新機能の文は Listing.md の下書きから「★」を外したもの（★は ASC で無効な文字）。プロモーション用テキストも 1.1 で入れ直した。

```
What's new in 1.1:
- Nationwide station search (about 9,000 stations), built from the Japanese government's open railway data (National Land Numerical Information, MLIT, CC BY 4.0; credited in the app). Stations with my own articles open the article as before. Other stations open a simple page that clearly says there is no article yet, with buttons that open Google Maps searches around the station and links to nearby stations that have articles. The app has no restaurant data of its own for these stations.
- New colors and a clearer Home screen with the station search at the top.
- Any station can be saved as a favorite.
No accounts, login, user-generated content or paid content.

Purpose and target audience
GatsuGatsu Gourmet is the app version of gatsugatsu-gurume.com, a Japanese food guide that I operate myself. It is for people in Japan who want to eat a big, filling meal when eating out (large ramen, rice bowls, all-you-can-eat). It offers portion-size tables, official calorie figures from restaurant chains, station-by-station guides for 24 stations in Tokyo, Kanagawa, Saitama and Chiba, a nationwide station search, and my own first-hand restaurant reports with photos I took. Everything is bundled in the app, so it works without signal while standing in a queue. App-only features: a meal log (GatsuLog) that totals daily and weekly calories, and a queue-time estimate that sends a local notification 5 minutes before the expected seating time.

How to access the main features
No login, setup or sample files are needed. Use the five tabs at the bottom:
- ホーム (Home): station search at the top, the three main tools, today's meal totals, first-hand reports and today's article.
- 駅で探す (Stations): search any station in Japan; the star button saves it as a favorite.
- 記事 (Articles): portion guides, columns and first-hand reports, with search.
- ツール (Tools): portion converter, calorie and PFC calculator, queue-time estimate (tap 「入店の5分前に通知する」 to schedule the reminder), all-you-can-eat break-even, and bill splitter (result can be shared through the share sheet).
- 記録 (GatsuLog): log a meal and see daily and weekly totals. The log is stored only on the device.
A rewarded video ad is optional: in Settings it hides ads for 2 hours, and on the monthly summary it unlocks the summary for 24 hours. Logging and the tools never require watching an ad.

External services
- Google Mobile Ads SDK (AdMob) for banner, native, interstitial, app open and rewarded ads, and Google's User Messaging Platform for the consent and tracking explanation.
- Apple's local notifications (UserNotifications) for the queue reminder.
There is no server, no account system, no payment processor and no AI service. Links to maps or official chain websites open in Safari or the Maps app.

Regional differences
The app is distributed only in Japan and its content is in Japanese. It functions the same way for every user. The only difference is handled by Google's UMP SDK: the GDPR consent form appears only for users in the EEA and UK.

Regulated industry / third-party material
The app is not in a regulated industry. All articles and photos were written and taken by me as the operator of gatsugatsu-gurume.com. Calorie and portion figures for chains are factual values taken from each chain's official published nutrition information, with the source and the date checked shown under each figure. Restaurant and chain names are used only to identify the places described.

The app shares no source files with my other apps. Ads are provided by Google AdMob, and there are no in-app purchases.
```
