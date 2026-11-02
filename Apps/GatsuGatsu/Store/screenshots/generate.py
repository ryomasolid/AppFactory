#!/usr/bin/env python3
"""App Store 用スクショ（6.9インチ 1320x2868）を作る。src/ の素のスクショに見出しを付け、Chrome のヘッドレスで書き出す。"""
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).parent
SRC, OUT = ROOT / "src", ROOT / "out"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1320, 2868

SLIDES = [
    ("01_quantity", "quantity.png", "#FFC53D", "大盛りって<br>何グラム？", "麺もご飯も、量を数字で換算"),
    ("02_report", "report.png", "#FFE7D1", "自分で食べた<br>店の記録", "写真と注文、支払った金額まで"),
    ("03_log", "log.png", "#FFC53D", "今月はご飯<br>何杯ぶん？", "公式値で記録するガツログ"),
    ("04_queue", "queue.png", "#FFE7D1", "行列の前で<br>入店時刻を計算", "入店の5分前に通知"),
    ("05_station", "station.png", "#FFC53D", "24駅の<br>がっつり飯ガイド", "東京・神奈川・埼玉・千葉"),
]

PAGE = """<!doctype html><html lang="ja"><head><meta charset="utf-8"><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{background:{bg};font-family:'Hiragino Sans','Hiragino Kaku Gothic ProN',sans-serif;color:#1C1917;position:relative}}
.copy{{position:absolute;top:130px;left:0;right:0;text-align:center}}
h1{{font-size:128px;font-weight:900;line-height:1.24;letter-spacing:.01em}}
p{{display:inline-block;margin-top:44px;font-size:52px;font-weight:800;background:#fff;border:7px solid #1C1917;border-radius:999px;padding:18px 48px;box-shadow:7px 7px 0 #1C1917}}
.phone{{position:absolute;top:720px;left:50%;transform:translateX(-50%);width:1040px;padding:20px;background:#1C1917;border-radius:136px;box-shadow:16px 16px 0 rgba(28,25,23,.9)}}
.phone img{{display:block;width:100%;border-radius:118px}}
</style></head><body><div class="copy"><h1>{title}</h1><p>{sub}</p></div>
<div class="phone"><img src="{shot}"></div></body></html>"""

OUT.mkdir(exist_ok=True)
for name, shot, bg, title, sub in SLIDES:
    page = OUT / f"{name}.html"
    page.write_text(PAGE.format(W=W, H=H, bg=bg, title=title, sub=sub, shot=(SRC / shot).as_uri()), encoding="utf-8")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    f"--window-size={W},{H}", "--allow-file-access-from-files",
                    f"--screenshot={OUT / (name + '.png')}", page.as_uri()], check=True, capture_output=True)
    page.unlink()
    print("wrote", name)
