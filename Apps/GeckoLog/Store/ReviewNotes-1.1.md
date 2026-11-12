# 1.1 の審査メモ（2026-11-12）

1.0 の 2.1 回答（`ReviewNotes-2.1.md`）をもとに、広告 SDK を入れたぶんだけ書き換えた。1.0 の録画は 1.1 の提出物には付け直していない
（もう一度 2.1 で求められたら `GeckoLogReviewWalkthrough` を `-noAds` 付きで撮り直して添付する）。

```
GeckoLog (げこログ) 1.1 — what changed since 1.0

The only functional change in this version is a small banner ad (Google AdMob) at the bottom of each tab, above the tab bar, so that the app can stay free. Nothing about recording, storage or notifications changed. On first launch the app shows the Google UMP consent form where required by region, then the App Tracking Transparency prompt; declining both keeps every feature available.

1. Purpose and target audience
GeckoLog is a care log for people in Japan who keep leopard geckos (Eublepharis macularius). The app decides the feeding interval from the hatch date (baby / young / adult), shows which geckos should be fed today, flags refusal streaks and weight loss, predicts the next shed from past sheds, and shows the expected hatch date and sex tendency for a clutch from the incubation temperature. Keepers with several geckos can log one feeding round for all of them at once.

2. How to access the main features
No login, setup or sample files are needed. On first launch the Cage tab is empty; tap 「1匹目を登録する」 (Register your first gecko), enter a name and optionally the hatch date, then tap 「保存」 (Save).
- ケージ (Cage): one card per gecko with the next feeding day and warnings. 「ごはんをまとめて記録」 logs a feeding for every gecko that is due. Tap a card to open the gecko.
- Gecko screen: 「記録する」 buttons for feeding, shed, weight, droppings, temperature/humidity, cleaning, vet visit and memo; the history and a weight chart are below.
- たまご (Eggs): 「産卵を記録する」 records a clutch; the card shows the day count, expected hatch date and sex tendency.
- きろく (Journal): all records by day, filterable by gecko.
- せってい (Settings): feeding-day local notification, CSV export, and a link to the privacy policy.

3. External services
Google Mobile Ads SDK (AdMob banner ads) with the Google User Messaging Platform for consent. This is the only third-party SDK and the only network access. There is no server, no account system, no analytics, no payment processor and no AI service. All records and photos stay on the device. The privacy policy (https://ryomasolid.github.io/privacy-geckolog.html) and the App Privacy answers were updated for the ad SDK.

4. Regional differences
The app functions the same way in every region. The interface is in Japanese.

5. Regulated industry / third-party material
Not in a regulated industry; no protected third-party material. All text, the icon and the illustrations are my own work. The husbandry figures are general guidelines, and the app tells users to consult a reptile veterinarian when in doubt.

The app shares no source files with my other apps. There are no in-app purchases.
```
