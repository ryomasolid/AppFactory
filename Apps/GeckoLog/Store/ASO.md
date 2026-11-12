# げこログ — App Store 掲載情報（v1.0）

ASC 入力済み（2026-11-06・Apple ID 6831492029）。プライバシー: https://ryomasolid.github.io/privacy-geckolog.html ／ サポート: https://ryomasolid.github.io/support-geckolog.html ／ マーケティング: https://ryomasolid.github.io/
スクショは `screenshots/generate.py`（ASC には out-6.3/ の 1206x2622 を入れた）。

## アプリ名（30文字以内）

```
げこログ - レオパの給餌・脱皮記録
```

## サブタイトル（30文字以内）

```
拒食チェック・孵化日数もわかる飼育帳
```

## キーワード（100文字以内・カンマ区切り・スペースなし）

```
ヒョウモントカゲモドキ,レオパードゲッコー,爬虫類,トカゲ,ヤモリ,飼育,記録,体重,エサ,コオロギ,デュビア,拒食,産卵,孵化,モルフ,多頭飼い
```

## プロモーションテキスト（170文字以内・絵文字不可）

```
ごはんの日・拒食・脱皮の時期を、レオパごとに自動で見守ります。多頭飼いでも、ごはんの記録はまとめて1回。産卵したら温度から孵化予定日もわかります。
```

## 説明文

```
げこログは、レオパ（ヒョウモントカゲモドキ）のための飼育記録アプリです。
何匹いても、ごはん・脱皮・体重をかんたんに残して「次はいつ？」「いつもと違う？」をアプリが見守ります。

■ ごはんの日がひと目でわかる
ハッチ日から ベビー・ヤング・アダルト を判断して、給餌の間隔を自動で決めます（自分で日数を決めることもできます）。
ケージ画面に「今日ごはん」の子が並び、「ごはんをまとめて記録」で全員ぶんを一度に記録できます。
食べなかった子だけ「拒食」に切り替えるだけ。

■ 拒食・体重の減りに気づける
2回つづけて食べない、2週間なにも食べていない、1か月で体重が1割へった。そんなときはカードに印が出ます。

■ 脱皮の時期を予想
脱皮を記録すると、これまでの間隔から次の脱皮日を予想します。指先やしっぽの先の皮残りも記録できます。

■ 産卵・孵化の見守り
産卵日とインキュベーターの温度を入れると、孵化予定日と、オス・メスの傾向の目安を表示します。

■ そのほかの記録
体重グラフ／うんち／温湿度（ホットスポット・湿度）／そうじ／通院／メモ
エサはコオロギ・デュビア・レッドローチ・ミルワーム・人工フードなどから選べ、ダスティングの有無も残せます。

■ お知らせ
ごはんの日の夜に、その日ごはんの子をまとめて1通でお知らせします。

■ 安心して使える
記録と写真は iPhone の中だけに保存されます。アカウント登録はありません。
記録は CSV で書き出せるので、動物病院に見せるときにも便利です。

■ 料金
すべての機能を無料で使えます（画面の下に小さな広告が表示されます）。

※ 給餌間隔・脱皮・孵化日数は一般的な目安です。体調が心配なときは爬虫類を診られる動物病院にご相談ください。
```

## このバージョンの新機能（What's New）

### 1.1

```
・アプリを無料のまま続けるため、画面の下に小さな広告を表示するようにしました。記録の操作や保存場所は変わりません
・「せってい」にプライバシーポリシーへのリンクを足しました
```

## App Review メモ（英語・提出時に貼る）

```
GeckoLog is a care log built specifically for leopard geckos (Eublepharis macularius), a reptile with care needs that general pet diaries do not cover: age-based feeding intervals with live insects, refusal (anorexia) streak tracking, shed-cycle prediction with stuck-shed records, enclosure temperature/humidity, and egg incubation where hatch time and sex depend on temperature.

It shares no source code with other apps on this account. The only third-party SDK is Google Mobile Ads (a banner at the bottom of each tab, added in 1.1); there are no accounts and no analytics, and all records stay on device. The app icon is drawn in code.

To see sample data quickly: add a gecko from the + button on the Cage tab, then tap it and record a feeding.
```

## カテゴリ

ライフスタイル（サブ: 教育 は不要）

## 年齢区分

4+

## App Store Connect の状況

- 2026-11-06: ASC に登録（Apple ID 6831492029）。掲載情報・審査メモ・スクショ5枚・4+・データ収集なし・無料。
- 2026-11-10: 1.0 (1) をアップロードし、TestFlight の内部グループ「開発者」に配信。実機で確認して OK。
- 2026-11-10 16:35: 1.0 (1) を紐付けて審査提出（審査待ち・承認後に自動で公開）。
- 2026-11-11 08:35: 1.0 (1) が 2.1 Information Needed（画面収録＋6項目）で却下 → 録画 `Store/GeckoLog-review-1.0.mp4` を添付し、審査メモを `Store/ReviewNotes-2.1.md` の英文に差し替えて 18:19 に再提出。
- 2026-11-11 17:00 ごろ: 1.0 が公開。2026-11-12 に AdMob へ登録（ID は `Docs/Design.md`）。
- 1.1 (2) で広告を入れる。ASC で要る変更: 説明文の「安心して使える」「料金」、審査メモの SDK の文、
  **App のプライバシー（栄養ラベル）を「データ収集なし」から AdMob 分に変える**（識別子＝デバイス ID・使用状況データ＝広告データ・診断／トラッキングに使用＝はい。はむはむ日記と同じ申告）。
  プライバシーポリシー（ryomasolid.github.io/privacy-geckolog.html）は広告の記述に書き換えて公開ずみ。
- 2026-11-12: ASC で 1.1 を作成。新機能・説明文（料金の項）・審査メモ（`Store/ReviewNotes-1.1.md`）を入力、年齢制限の「広告」を はい、
  App のプライバシーを「データ収集なし」→ おおよその場所・デバイスID・製品の操作・広告データ（トラッキングあり）／クラッシュ・パフォーマンス（トラッキングなし）、
  目的はすべて サードパーティ広告＋アナリティクス、ユーザに関連付けない で公開。
  ビルド 1.1 (2) はアーカイブ済みだが、Xcode のアカウントのセッション切れ（Your session has expired）でアップロード失敗。再ログイン待ち。
