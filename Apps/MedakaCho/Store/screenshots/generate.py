#!/usr/bin/env python3
"""App Store 用スクショを作る。src/ の素のスクショ（iPhone 17 Pro Max・1320x2868）に見出しを付け、Chrome のヘッドレスで書き出す。
src/ は `simctl status_bar <udid> override --time 9:41` のうえ、`-sample -tab N` ／ `-sample -openVessel` で起動して `simctl io screenshot` で撮る。
ASC の iPhone 枠（Dynamic Island 搭載・中型）は 6.3インチ 1206x2622 なので、out-6.3/ に縮めたものも作る。"""
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).parent
SRC, OUT, OUT63 = ROOT / "src", ROOT / "out", ROOT / "out-6.3"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1320, 2868

# アプリの配色（Palette）に合わせる。水の青緑は白い文字、水面の淡色は濃い文字。
DEEP, PALE, KOI = "#1F6F78", "#E8F3F1", "#E0612F"
SLIDES = [
    ("01_vessels", "vessels.png", DEEP, "鉢ごとに<br>水換えの時期がわかる", "睡蓮鉢・発泡・水槽をまとめて管理"),
    ("02_vessel", "vessel.png", PALE, "水温から<br>えさの量の目安も", "えさ・水換え・足し水はワンタップ"),
    ("03_eggs", "eggs.png", DEEP, "採った卵の<br>孵化日がわかる", "水温×日数＝250 で自動計算"),
    ("04_breeds", "breeds.png", PALE, "品種ごとの数と<br>孵化率をまとめて", "楊貴妃・幹之・オーロラ…"),
    ("05_settings", "settings.png", DEEP, "水換えの日は<br>朝に1通でお知らせ", "記録は iPhone の中だけ・CSV 書き出し"),
]

PAGE = """<!doctype html><html lang="ja"><head><meta charset="utf-8"><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{background:{bg};font-family:'Hiragino Maru Gothic ProN','Hiragino Sans',sans-serif;color:{fg};position:relative}}
.copy{{position:absolute;top:150px;left:0;right:0;text-align:center}}
h1{{font-size:110px;font-weight:800;line-height:1.28}}
p{{margin-top:44px;font-size:50px;font-weight:700;color:{sub}}}
.fish{{display:inline-block;width:46px;height:20px;border-radius:50%;background:{KOI};margin:0 18px 10px;vertical-align:middle}}
.phone{{position:absolute;top:740px;left:50%;transform:translateX(-50%);width:1040px;padding:18px;background:#13292C;border-radius:136px;box-shadow:0 40px 80px rgba(0,0,0,.22)}}
.phone img{{display:block;width:100%;border-radius:120px}}
</style></head><body><div class="copy"><h1>{title}</h1><p><span class="fish"></span>{text}<span class="fish"></span></p></div>
<div class="phone"><img src="{shot}"></div></body></html>"""

OUT.mkdir(exist_ok=True)
OUT63.mkdir(exist_ok=True)
for name, shot, bg, title, text in SLIDES:
    page = OUT / f"{name}.html"
    dark = bg == DEEP
    page.write_text(PAGE.format(W=W, H=H, bg=bg, fg="#FFFFFF" if dark else "#13292C",
                                sub="#CDEBE8" if dark else DEEP, KOI=KOI,
                                title=title, text=text, shot=(SRC / shot).as_uri()), encoding="utf-8")
    png = OUT / f"{name}.png"
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    f"--window-size={W},{H}", "--allow-file-access-from-files", f"--screenshot={png}", page.as_uri()],
                   check=True, capture_output=True)
    page.unlink()
    # 透過なしの JPEG を経由して、ASC に弾かれないようにする。
    jpg = OUT63 / f"{name}.jpg"
    subprocess.run(["sips", "-z", "2622", "1206", "-s", "format", "jpeg", "-s", "formatOptions", "92", str(png), "--out", str(jpg)],
                   check=True, capture_output=True)
    print("wrote", name)
