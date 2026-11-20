# 1.0.1 の審査メモ（英語）

1.0 のメモ（`ReviewNotes-1.0.md`）の 1・4 を広告ありに書き換えたもの。録画は 1.0 のものをそのまま使う（録画は -noAds で撮るので画面は同じ）。

```
Version 1.0.1 adds a banner ad (Google AdMob) at the bottom of the クイズ (Quiz) and ずかん (Dex) tabs. Nothing else changes. Ads are never shown on the full-screen quiz itself.

1. Screen recording
The attached recording shows the main flow (unchanged from 1.0): launching the app -> a 10-question "flag -> country name" round with the result screen -> a few "country name -> capital" and "country name -> flag" questions -> the Dex tab with region filter and search. The app has no account registration, login, user-generated content or paid content.

4. External services
Google AdMob (Google Mobile Ads SDK) only, for the banner ad. Because children may use this study app, every ad request is tagged as child-directed (COPPA) and under the age of consent, with the max ad content rating set to G. The app does not ask for App Tracking Transparency permission and does not use the IDFA. The Advertising age rating descriptor is set to Yes. There is no analytics, account system, payment processor or AI service. Progress is stored on the device only (UserDefaults).

Items 2, 3, 5 and 6 are the same as for version 1.0. There are no in-app purchases.
```
