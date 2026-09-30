#!/usr/bin/env python3
"""App Store 用スクリーンショット（6.9インチ: 1320x2868）を生成する。

src/ にシミュレーターで撮った素のスクショを置き、
  python3 Store/screenshots/generate.py
を実行すると out/ に書き出す（Google Chrome のヘッドレスモードを使用）。
"""
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).parent
SRC = ROOT / "src"
OUT = ROOT / "out"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1320, 2868

SLIDES = [
    {
        "file": "01_home",
        "shot": "home.png",
        "eyebrow": "ハムスターの飼育記録アプリ",
        "title": "毎日のお世話を<br><mark>かんたん記録</mark>",
        "sub": "体重・ごはん・お掃除を<br>ワンタップで残せる",
        "bg": ("#FFF4E8", "#FFD9BF"),
        "chips": ["体重", "ごはん", "お掃除", "写真"],
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
        "file": "03_share",
        "shot": "share.png",
        "eyebrow": "シェアカード",
        "title": "うちの子の成長を<br><mark>SNSでシェア</mark>",
        "sub": "日付・体重入りのかわいい画像を<br>Instagram・X・LINEへ",
        "bg": ("#FFF1F0", "#FFC9C2"),
    },
    {
        "file": "04_reminder",
        "shot": "profile.png",
        "eyebrow": "通知でお知らせ",
        "title": "床材・フードの<br><mark>交換時期</mark>を忘れない",
        "sub": "消耗品の交換日を<br>プッシュ通知でリマインド",
        "bg": ("#F1F8EE", "#CDEBC4"),
    },
    {
        "file": "05_record",
        "shot": "record.png",
        "eyebrow": "登録した献立で時短",
        "title": "いつものごはんは<br><mark>1タップ入力</mark>",
        "sub": "献立テンプレート・お掃除項目を<br>自由にカスタマイズ",
        "bg": ("#EEF5FF", "#C9DEFF"),
    },
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
  <div class="phone"><img src="{shot}"></div>
</body></html>
"""


def render(slide: dict) -> None:
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
        sub=slide["sub"],
        chips=(
            '<div class="chips">' + "".join(f'<span class="chip">{c}</span>' for c in chips) + "</div>"
            if chips
            else ""
        ),
        shot=(SRC / slide["shot"]).as_uri(),
        phone_top=1300 if has_icon else 1060,
    )
    page = OUT / f"{slide['file']}.html"
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
            f"--screenshot={OUT / (slide['file'] + '.png')}",
            page.as_uri(),
        ],
        check=True,
        capture_output=True,
    )
    page.unlink()
    print("wrote", OUT / f"{slide['file']}.png")


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    for s in SLIDES:
        render(s)
