# PhotoCleaner — App Store 掲載文（下書き）

> 文字数は全角=1, 半角=1 で概算。App Store Connect 入力時に各上限を最終確認すること。

## App 名（最大30字）
案A: `PhotoCleaner 写真容量整理`
案B: `写真整理 PhotoCleaner 容量削除`
※ アプリ名は最重要のASO枠。主要KW（写真整理/容量）を入れる。

## サブタイトル（最大30字）
`重複・スクショ・動画をまとめて削除`

## キーワード（最大100字・カンマ区切り・スペース不要・アプリ名/サブタイトルの語は入れない）
```
ストレージ,空き容量,容量不足,重複写真,スクリーンショット,動画整理,削除,クリーナー,掃除,iphone,写真削除,似た写真,連写,整理整頓
```

## プロモーションテキスト（最大170字・審査なしで随時変更可）
`重複・連写・スクショ・大きい動画をまとめて検出。残す1枚を選んでサッと整理。写真はすべて端末内で処理し、外部に送信しません。`

## 説明文（最大4000字）
```
ストレージがいっぱい…の原因を、まとめて整理。

PhotoCleaner は、重複・類似した写真、溜まったスクリーンショット、容量を食う大きな動画を見つけて、まとめて削除できる容量クリーナーです。

■ こんな人に
・「ストレージの空き容量がありません」が出る
・連写やほぼ同じ写真が大量にある
・スクショが溜まりっぱなし
・どの動画が容量を食っているか分からない

■ 主な機能
・重複・類似写真の自動グループ化（残す1枚を選んで一括削除）
・スクリーンショットだけを抽出してまとめて削除
・大きい動画をサイズ順に表示して削除（どれだけ空くか一目で分かる）
・削除前のプレビューと「約◯◯削減」の表示

■ 安心・プライバシー
・写真の解析はすべて端末内（オンデバイス）で完結
・写真が外部サーバーに送信されることはありません

■ 削除について
削除した写真は iOS の「最近削除した項目」に30日間残ります。空き容量をすぐに増やしたい場合は、写真アプリの「最近削除した項目」から完全に削除してください。

※ 一部機能は Pro（買い切り）で解放されます。
```

## スクリーンショット構成（6.7" と 6.5"/5.5" を用意）
1. フック: 「写真の容量、まとめてすっきり」＋ 約◯GB削減のイメージ
2. 重複・類似のグループ表示（残す/削除の選択）
3. スクリーンショット整理
4. 大きい動画（サイズ順・○GB）
5. 「完全オンデバイス／外部送信なし」の安心訴求
6. Pro 紹介（広告非表示＋動画解除）

## メモ
- 競合は「Apple純正の重複」。差別化＝スクショ＋動画＋一括＆削減量可視化を前面に。
- ローカライズはまず日本語。英語も用意すると幅が広がる。

## 審査の経過

- 2026-09-14: 1.0 (2) が 2.1(b)「課金プランが読み込めない」で却下。有料アプリ契約が保留中だったため（9/15 に再提出）。
- 2026-10-01: 1.0 (2) が 2.1 Information Needed で却下（iPad Air 11-inch M3 / iPadOS 27.2）。
  「ATT の許可要求が見当たらない」。実機の画面収録を返信と App Review 情報のメモに添えるよう求められた。
  - 契約・口座・納税フォームは 10/1 時点ですべて有効（2.1(b) は解消）。
  - a58b334 で同意フローをオンボーディング後に開始し、ATT はアプリが active になってから要求するよう修正。
  - 1.0 (3) をアップロード（Project.swift は 3 だったが Xcode プロジェクトが古く 2 でアーカイブされていた → `tuist generate` で解消）。
  - TestFlight に内部グループ「PhotoCleaner テスター」を作り、自分を追加（招待済み）。実機の画面収録はこのビルドで撮る。

### 再提出時の App Review 情報のメモ（英語）

```
Regarding Guideline 2.1 (App Tracking Transparency):

The ATT permission request is shown on first launch, right after the short introduction screen ("はじめる" button). It appears before the Google Mobile Ads SDK is started, so no tracking data is collected before the user responds.

In build 1.0 (3) we also made the request wait until the app is fully active, so it is not skipped while the introduction screen is being presented.

Note: if "Allow Apps to Request to Track" is turned off in Settings > Privacy & Security > Tracking on the review device, iOS does not show the dialog at all.

A screen recording from a physical device is attached: fresh install → introduction → ATT request → photo library permission → main screen.
```
