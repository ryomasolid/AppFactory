# 1.0 の審査メモ（英語）

新規アプリは「2.1 Information Needed」（画面収録＋6項目）で止められやすいので、はじめから録画 `KokkiShuto-review-1.0.mp4` を添付し、6項目に答える。撮影環境は書かない。
撮り直しは scheme `KokkiShutoTour`（Release・UI テスト `Tour`）を `simctl io recordVideo` しながら流し、`avconvert --preset Preset960x540` で縮める。

```
1. Screen recording
The attached recording (KokkiShuto-review-1.0.mp4) shows the Release build of this version from a fresh install: launching the app -> a 10-question "flag -> country name" round, including wrong answers and the result screen -> a few "country name -> capital" questions -> a few "country name -> flag" questions -> the Dex (ずかん) tab, filtering by region and searching for a country. The app has no account registration, login, user-generated content, ads or paid content, so none of those flows exist.

2. Purpose and target audience
Kokki to Shuto (国旗と首都, "Flags and Capitals") is a study app for people in Japan, from students preparing for geography tests to adults, who want to memorize the names, capitals and flags of the world's 197 countries (193 UN member states plus Vatican City, Kosovo, the Cook Islands and Niue). Every question is multiple choice with 4 options. The wrong options are mostly taken from the same region so the user has to really tell them apart. A country counts as "learned" after 3 correct answers in a row, separately for flag and capital, and countries not yet learned or answered wrongly are asked first.

3. How to access the main features
No login, setup or sample data is needed; everything is available right after launch.
- クイズ (Quiz) tab: progress rings (learned flags / capitals), the region to ask about and the number of questions (10/20/30). The buttons start a round: 「国旗 → 国名」 flag to name, 「国名 → 国旗」 name to flag, 「国名 → 首都」 name to capital, 「首都 → 国名」 capital to name, 「4つの出し方をまぜる」 mixed, and 「にがてな国旗」/「にがてな首都」 (only countries answered wrongly before; these appear after the first mistake). In a round, tap an option; after a wrong answer, 「つぎへ」 goes on. 「やめる」 quits. The 「…」 menu at the top right resets the records.
- ずかん (Dex) tab: list of all countries with flag, name and capital; filter by region and search by name or capital.

4. External services
None. The app makes no network connections and uses no third-party SDK, analytics, ads, account system, payment processor or AI service. Progress is stored on the device only (UserDefaults).

5. Regional differences
The app functions the same way in every region. The interface is in Japanese.

6. Regulated industry / third-party material
The app is not in a regulated industry. Country names and capitals follow the notation of Japan's Ministry of Foreign Affairs. Flags are shown with the system's standard emoji (built from ISO country codes); the app contains no flag images. All text and the icon are my own work.

The app shares no source files with my other apps. There are no in-app purchases.
