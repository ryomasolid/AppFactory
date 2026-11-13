#!/usr/bin/env python3
"""App Store 用スクショを作る。src/ の素のスクショ（iPhone 17 Pro Max・1320x2868）に見出しを付け、Chrome のヘッドレスで書き出す。
src/ は `simctl status_bar <udid> override --time 9:41` のうえ、ほかのアプリを終了してから `-sample -tab N`（ほか下の SLIDES の引数）で起動し、
`simctl io screenshot` で撮る。iPad（iPad Pro 13・2064x2752）は見出しなしの素のまま JPEG にする。
ASC には out/ の JPEG（透過なし）を入れる：iPhone 6.9インチ・iPad 13インチ。"""
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).parent
SRC, OUT = ROOT / "src", ROOT / "out"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1320, 2868

# アプリの配色（Palette）に合わせる。若草色は白い文字、生成りは濃い文字。
LEAF = ("#2FA864", "#FFFFFF", "#E2F7EA", "#2E2A24")
PAPER = ("#FBF6EE", "#2E2A24", "#E07A2E", "#2E2A24")
CRUST = ("#E07A2E", "#FFFFFF", "#FFE9D6", "#2E2A24")
SLIDES = [
    ("01_today", "today.png", LEAF, "間食したかを<br>1日1タップで記録", "ログインなし・すぐ使える"),
    ("02_calendar", "calendar.png", PAPER, "我慢できた日は緑<br>ひと月がひと目で", "体重とメモも日ごとに残せる"),
    ("03_streak", "today-dark.png", CRUST, "連続記録で<br>おやつ我慢が続く", "いまの記録と最長記録を表示"),
]
IPAD = ["ipad-today.png", "ipad-calendar.png"]

PAGE = """<!doctype html><html lang="ja"><head><meta charset="utf-8"><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{background:{bg};font-family:'Hiragino Maru Gothic ProN','Hiragino Sans',sans-serif;color:{fg};position:relative}}
.copy{{position:absolute;top:150px;left:0;right:0;text-align:center}}
h1{{font-size:108px;font-weight:800;line-height:1.28}}
p{{margin-top:44px;font-size:50px;font-weight:700;color:{sub}}}
.phone{{position:absolute;top:740px;left:50%;transform:translateX(-50%);width:1040px;padding:18px;background:{frame};border-radius:136px;box-shadow:0 40px 80px rgba(0,0,0,.25)}}
.phone img{{display:block;width:100%;border-radius:120px}}
</style></head><body><div class="copy"><h1>{title}</h1><p>{text}</p></div>
<div class="phone"><img src="{shot}"></div></body></html>"""

OUT.mkdir(exist_ok=True)
for name, shot, (bg, fg, sub, frame), title, text in SLIDES:
    page = OUT / f"{name}.html"
    page.write_text(PAGE.format(W=W, H=H, bg=bg, fg=fg, sub=sub, frame=frame,
                                title=title, text=text, shot=(SRC / shot).as_uri()), encoding="utf-8")
    png = OUT / f"{name}.png"
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    f"--window-size={W},{H}", "--allow-file-access-from-files", f"--screenshot={png}", page.as_uri()],
                   check=True, capture_output=True)
    page.unlink()
    # 透過なしの JPEG にして、ASC に弾かれないようにする。
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "92", str(png), "--out", str(OUT / f"{name}.jpg")],
                   check=True, capture_output=True)
    png.unlink()
    print("wrote", name)

for shot in IPAD:
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "92", str(SRC / shot),
                    "--out", str(OUT / shot.replace(".png", ".jpg"))], check=True, capture_output=True)
    print("wrote", shot)
