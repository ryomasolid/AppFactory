#!/usr/bin/env python3
"""App Store 用スクショ（6.9インチ 1320x2868）を作る。src/ の素のスクショに見出しを付け、Chrome のヘッドレスで書き出す。
6.3インチ（1206x2622）は out-6.3/ に縮小して書き出す。src/ は UI テスト StoreShots（iPhone 17 Pro Max・-hideAds -demoLog）で撮る。"""
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).parent
SRC, OUT = ROOT / "src", ROOT / "out"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1320, 2868

# 1.1 の新デザイン（白基調＋朱色）に合わせた見た目。朱色の背景は白い文字、薄い背景は黒い文字。
ACCENT, SOFT = "#D9480F", "#FFEEE5"
SLIDES = [
    ("01_home", "home.png", ACCENT, "どの駅で<br>がっつり食べる？", "全国9,000駅から大盛りの店を探す"),
    ("02_search", "search.png", SOFT, "全国の駅を<br>駅名ですぐ検索", "同じ名前の駅は路線で見分けられる"),
    ("03_station", "japan.png", ACCENT, "駅のまわりの<br>デカ盛りを地図で", "大盛り無料・食べ放題・二郎系など"),
    ("04_quantity", "quantity.png", SOFT, "大盛りって<br>何グラム？", "麺もご飯も、量を数字で換算"),
    ("05_report", "report.png", ACCENT, "自分で食べた<br>店の記録", "写真と注文、量と味まで"),
    ("06_log", "log.png", SOFT, "今日はご飯<br>何杯ぶん？", "チェーンの公式値で記録するガツログ"),
]

PAGE = """<!doctype html><html lang="ja"><head><meta charset="utf-8"><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{background:{bg};font-family:'Hiragino Sans','Hiragino Kaku Gothic ProN',sans-serif;color:{fg};position:relative}}
.copy{{position:absolute;top:140px;left:0;right:0;text-align:center}}
h1{{font-size:120px;font-weight:800;line-height:1.25;letter-spacing:.01em}}
p{{display:inline-block;margin-top:48px;font-size:48px;font-weight:700;color:{pillFg};background:{pillBg};border-radius:999px;padding:20px 52px}}
.phone{{position:absolute;top:720px;left:50%;transform:translateX(-50%);width:1040px;padding:18px;background:#1A1A1A;border-radius:136px;box-shadow:0 40px 80px rgba(0,0,0,.25)}}
.phone img{{display:block;width:100%;border-radius:120px}}
</style></head><body><div class="copy"><h1>{title}</h1><p>{sub}</p></div>
<div class="phone"><img src="{shot}"></div></body></html>"""

OUT.mkdir(exist_ok=True)
for name, shot, bg, title, sub in SLIDES:
    page = OUT / f"{name}.html"
    dark = bg == ACCENT
    page.write_text(PAGE.format(W=W, H=H, bg=bg, fg="#FFFFFF" if dark else "#1A1A1A",
                                pillBg="#FFFFFF" if dark else ACCENT, pillFg=ACCENT if dark else "#FFFFFF",
                                title=title, sub=sub, shot=(SRC / shot).as_uri()), encoding="utf-8")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    f"--window-size={W},{H}", "--allow-file-access-from-files",
                    f"--screenshot={OUT / (name + '.png')}", page.as_uri()], check=True, capture_output=True)
    page.unlink()
    print("wrote", name)
    OUT63 = ROOT / "out-6.3"
    OUT63.mkdir(exist_ok=True)
    subprocess.run(["sips", "-z", "2622", "1206", str(OUT / (name + ".png")), "--out", str(OUT63 / (name + ".png"))], check=True, capture_output=True)
