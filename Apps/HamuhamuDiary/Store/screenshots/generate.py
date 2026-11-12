#!/usr/bin/env python3
"""App Store 用スクリーンショット（6.9インチ: 1320x2868）を生成する。

src/ にシミュレーターで撮った素のスクショを置き、
  python3 Store/screenshots/generate.py
を実行すると out/ に書き出す（Google Chrome のヘッドレスモードを使用）。
  python3 Store/screenshots/generate.py b
で、プロダクトページの最適化（A/Bテスト）用の B 案を out-b/ に書き出す。
"""
import sys
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).parent
SRC = ROOT / "src"
PHOTOS = ROOT / "photos"
OUT = ROOT / "out"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1320, 2868

SLIDES = [
    {
        "file": "01_watch",
        "shot": "weight-alert.png",
        "eyebrow": "ハムスターの飼育記録アプリ",
        "title": "体重の変化に<br><mark>早く気づく</mark>",
        "sub": "1週間で1割以上減ると<br>ホームでお知らせ",
        "bg": ("#FFF4E8", "#FFD9BF"),
        "icon": True,
    },
    {
        "file": "02_weight",
        "shot": "diary.png",
        "eyebrow": "体重グラフ",
        "title": "体重の変化が<br><mark>ひと目でわかる</mark>",
        "sub": "1ヶ月・3ヶ月・全期間で<br>健康チェック",
        "bg": ("#FFF8EC", "#FFE6A8"),
    },
    {
        "file": "03_reminder",
        "shot": "profile.png",
        "eyebrow": "通知でお知らせ",
        "title": "床材・フードの<br><mark>交換時期</mark>を忘れない",
        "sub": "消耗品の交換日を<br>プッシュ通知でリマインド",
        "bg": ("#F1F8EE", "#CDEBC4"),
    },
    {
        "file": "04_home",
        "shot": "home.png",
        "eyebrow": "毎日の記録",
        "title": "毎日のお世話を<br><mark>かんたん記録</mark>",
        "sub": "体重・ごはん・お掃除を<br>ワンタップで残せる",
        "bg": ("#EEF5FF", "#C9DEFF"),
        "chips": ["体重", "ごはん", "お掃除", "写真"],
    },
    {
        "file": "05_share",
        "shot": "share.png",
        "eyebrow": "シェアカード",
        "title": "うちの子の成長を<br><mark>SNSでシェア</mark>",
        "sub": "日付・体重入りのかわいい画像を<br>Instagram・X・LINEへ",
        "bg": ("#FFF1F0", "#FFC9C2"),
    },
]

# B 案（2026-11-10）: 検索結果の一覧で開いてもらう率を上げるため、1枚目は本物のハムスターの写真を大きく見せる。
# 体重の2枚（01・02）は1枚にまとめ、3枚目までに「記録・体重・交換時期」がそろうようにする。
SLIDES_B = [
    {
        "file": "01_hero",
        "photo": "memory-4.jpg",
        "eyebrow": "ハムスターの飼育記録アプリ",
        "title": "うちの子の毎日を<br><mark>かんたん記録</mark>",
        "bg": ("#FFF4E8", "#FFD9BF"),
        "icon": True,
        "chips": ["体重", "ごはん", "お掃除", "写真"],
    },
    {
        "file": "02_weight",
        "shot": "diary.png",
        "eyebrow": "体重グラフ・体重の見守り",
        "title": "体重の変化に<br><mark>早く気づける</mark>",
        "sub": "グラフで推移をチェック<br>1週間で1割減るとお知らせ",
        "bg": ("#FFF8EC", "#FFE6A8"),
    },
    SLIDES[2],
    {
        **SLIDES[3],
        "title": "ごはん・お掃除も<br><mark>ワンタップ</mark>",
        "sub": "今日のお世話がすんだか<br>ホームでひと目でわかる",
        "chips": None,
    },
    SLIDES[4],
]

TEMPLATE = """<!doctype html>
<html lang="ja"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Zen+Maru+Gothic:wght@500;700;900&display=block" rel="stylesheet">
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  html, body {{ width: {W}px; height: {H}px; overflow: hidden; }}
  body {{
    font-family: 'Zen Maru Gothic', 'Hiragino Maru Gothic ProN', sans-serif;
    background: linear-gradient(165deg, {bg0} 0%, {bg1} 100%);
    color: #3A2A20;
    position: relative;
  }}
  .blob {{ position: absolute; border-radius: 50%; filter: blur(4px); opacity: .55; }}
  .b1 {{ width: 620px; height: 620px; background: #fff; top: -180px; right: -220px; }}
  .b2 {{ width: 420px; height: 420px; background: #fff; top: 780px; left: -240px; opacity: .35; }}
  .copy {{ position: absolute; top: 190px; left: 0; right: 0; text-align: center; padding: 0 80px; }}
  .icon {{ display: block; margin: 0 auto; width: 150px; height: 150px; border-radius: 34px; box-shadow: 0 16px 40px rgba(120,60,20,.22); margin-bottom: 36px; }}
  .eyebrow {{
    display: inline-block; font-size: 42px; font-weight: 700; color: #C8642E;
    background: rgba(255,255,255,.75); padding: 12px 34px; border-radius: 999px; margin-bottom: 40px;
  }}
  h1 {{ font-size: 118px; font-weight: 900; line-height: 1.28; letter-spacing: .01em; }}
  mark {{
    background: linear-gradient(transparent 62%, rgba(255,160,90,.55) 62%);
    color: #E0702F; padding: 0 6px;
  }}
  .sub {{ margin-top: 40px; font-size: 50px; font-weight: 700; line-height: 1.55; color: #7A6252; }}
  .chips {{ margin-top: 44px; display: flex; gap: 20px; justify-content: center; }}
  .chip {{ font-size: 40px; font-weight: 700; background: #fff; color: #C8642E; padding: 12px 30px; border-radius: 999px; box-shadow: 0 6px 16px rgba(120,60,20,.10); }}
  .phone {{
    position: absolute; left: 50%; transform: translateX(-50%);
    top: {phone_top}px; width: 1000px; padding: 22px;
    background: #1D1A18; border-radius: 132px;
    box-shadow: 0 50px 120px rgba(90,40,10,.28), 0 0 0 4px rgba(255,255,255,.35) inset;
  }}
  .phone img {{ display: block; width: 100%; border-radius: 112px; }}
  .photo {{
    position: absolute; left: 50%; transform: translateX(-50%) rotate(-1.5deg);
    top: {phone_top}px; width: 1120px; height: 1560px; padding: 26px; background: #fff;
    border-radius: 96px; box-shadow: 0 50px 120px rgba(90,40,10,.28);
  }}
  .ui {{
    position: absolute; left: 50%; transform: translateX(-50%); top: 2330px;
    width: 1000px; height: 392px; overflow: hidden; border-radius: 64px;
    box-shadow: 0 30px 80px rgba(90,40,10,.30);
  }}
  .ui img {{ display: block; width: 1081px; margin: -673px 0 0 -40px; }}
  .photo img {{ display: block; width: 100%; height: 100%; object-fit: cover; object-position: 50% 42%; border-radius: 74px; }}
</style></head>
<body>
  <div class="blob b1"></div><div class="blob b2"></div>
  <div class="copy">
    {icon}
    <div class="eyebrow">{eyebrow}</div>
    <h1>{title}</h1>
    <div class="sub">{sub}</div>
    {chips}
  </div>
  {visual}
</body></html>
"""


def render(slide: dict, out: pathlib.Path) -> None:
    has_icon = slide.get("icon", False)
    chips = slide.get("chips")
    html = TEMPLATE.format(
        W=W,
        H=H,
        bg0=slide["bg"][0],
        bg1=slide["bg"][1],
        icon=f'<img class="icon" src="{(SRC / "icon.png").as_uri()}">' if has_icon else "",
        eyebrow=slide["eyebrow"],
        title=slide["title"],
        sub=slide.get("sub", ""),
        chips=(
            '<div class="chips">' + "".join(f'<span class="chip">{c}</span>' for c in chips) + "</div>"
            if chips
            else ""
        ),
        visual=(
            f'<div class="photo"><img src="{(PHOTOS / slide["photo"]).as_uri()}"></div>'
            # 写真だけだとアプリの画面が写らないので、ホームの「最新ステータス」を切り出して重ねる。
            # 切り出し位置は固定なので、最新ステータスが思い出フォトの上にあった頃（2.1.4）の画面を使う。
            f'<div class="ui"><img src="{(SRC / "home-status.png").as_uri()}"></div>'
            if slide.get("photo")
            else f'<div class="phone"><img src="{(SRC / slide["shot"]).as_uri()}"></div>'
        ),
        phone_top=(1260 if slide.get("photo") else 1190) if has_icon else 1060,
    )
    page = out / f"{slide['file']}.html"
    page.write_text(html, encoding="utf-8")
    subprocess.run(
        [
            CHROME,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            "--force-device-scale-factor=1",
            f"--window-size={W},{H}",
            "--virtual-time-budget=8000",
            "--allow-file-access-from-files",
            f"--screenshot={out / (slide['file'] + '.png')}",
            page.as_uri(),
        ],
        check=True,
        capture_output=True,
    )
    page.unlink()
    print("wrote", out / f"{slide['file']}.png")


if __name__ == "__main__":
    b = sys.argv[1:] == ["b"]
    out = ROOT / "out-b" if b else OUT
    out.mkdir(exist_ok=True)
    for s in SLIDES_B if b else SLIDES:
        render(s, out)
