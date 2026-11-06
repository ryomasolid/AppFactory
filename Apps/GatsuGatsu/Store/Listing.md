# App Store 掲載情報（下書き）

- 名前: ガツガツグルメ（Bundle ID `tech.sesame.gatsugatsu`・ASC の App ID 6829599230）
- 副題: 大盛りの量とカロリーがわかる
- カテゴリ: フード／ドリンク（サブ: ライフスタイル）
- 年齢制限: 広告「はい」。記事に飲み放題の話題があるため、アルコールの質問は「まれ／軽度」で答える
- プライバシーURL: https://ryomasolid.github.io/privacy-gatsugatsu.html
- サポートURL: https://ryomasolid.github.io/support-gatsugatsu.html
- マーケティングURL: https://ryomasolid.github.io/
- キーワード: デカ盛り,がっつり,二郎系,家系,つけ麺,カロリー,PFC,行列,待ち時間,割り勘,食べ放題,牛丼

## 説明文

大盛りって、何グラム？

ガツガツグルメは、外でお腹いっぱい食べたい人のための、量と数字のガイドです。麺やご飯のグラム数、チェーンの公式カロリー、運営者が自分で食べた店の記録を、電波がなくても読めるようにアプリに入れました。

【店の前で使えるツール】
・外食の量 早見表：麺300gは茹でると何g？ 茶碗何杯ぶん？
・カロリー＆PFC計算：チェーンの公式値を足し算
・行列の待ち時間：入店時刻を計算して、5分前に通知
・食べ放題の元取り：食べた分とコース料金を比較
・割り勘＆傾斜計算：結果をそのままLINEへ

【ガツログ】
食べたものを記録すると、1日と週のカロリーが積み上がり、今月ご飯何杯ぶん食べたかが分かります。記録は端末の中だけに保存します。

【駅と実食レポート】
東京・神奈川・埼玉・千葉の24駅のがっつり飯ガイドと、運営者の実食レポート。よく行く駅は登録しておくと、いつでもすぐ開けます。

無料でお使いいただけます（広告が表示されます）。動画広告を1本見ると、2時間広告を止められます。

## App のプライバシー（App Store Connect）

- トラッキング: はい（ATT を出すため）。使うデータ: デバイスID、広告データ
- 収集: デバイスID・おおよその位置情報・製品の操作・広告データ・診断（AdMob 経由）
- ガツログなどの記録: 端末の外へ出さないので収集に含めない

## 審査メモ（英語）

This app was written specifically for the Japanese food guide website gatsugatsu-gurume.com, which I operate. It is a native SwiftUI app, not a web view: all articles work offline, and it adds an on-device meal log and queue-time notifications that the website does not have. It shares no source files with my other apps. Ads are provided by Google AdMob; there are no in-app purchases. The meal log stays on the device.

## 提出の順番

サブスク帳は 2026-11-02 に取り下げたので、その返事は待たない。新規アプリの提出は月1本程度まで（アカウント単位の Extended Review 警告があるため）。

## 1.1 の新機能（下書き）

全国の駅から探せるようになりました。
・「駅」タブの検索で、全国およそ9,000駅を駅名や路線名から探せます
・記事のない駅でも、駅のまわりのデカ盛り・大盛り無料・食べ放題などを Google マップですぐ探せます
・近くに記事のある駅があれば、あわせて案内します

駅のデータは国土数値情報（鉄道データ・国土交通省）をもとに作成しています。
App のプライバシーの回答は変更なし（検索は端末の中だけで行い、外へ送らない）。
