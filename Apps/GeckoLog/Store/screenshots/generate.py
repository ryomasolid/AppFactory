#!/usr/bin/env python3
"""App Store 用スクショ（6.9インチ 1320x2868）を作る。src/ の素のスクショに見出しを付け、Chrome のヘッドレスで書き出す。
src/ は iPhone 17 Pro Max シミュレータで `-showcase -tab N`／`-showcase -openGecko` を付けて起動し、
`simctl status_bar override --time 9:41 --batteryState discharging` のうえ `simctl io screenshot` で撮る。"""
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).parent
SRC, OUT = ROOT / "src", ROOT / "out"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1320, 2868

# アプリの色（Terrarium）に合わせる。苔の緑の背景は白い文字、砂色の背景は黒い文字。
MOSS, SAND, AMBER = "#4F7A35", "#F3EEDF", "#E5A823"
SLIDES = [
    ("01_cage", "cage.png", MOSS, "今日ごはんの子が<br>ひと目でわかる", "多頭飼いでも まとめて1回で記録"),
    ("02_gecko", "gecko.png", SAND, "拒食や体重の減りに<br>すぐ気づける", "次のごはん・次の脱皮も自動で予想"),
    ("03_eggs", "eggs.png", MOSS, "温度から<br>孵化予定日がわかる", "オス・メスの傾向の目安も"),
    ("04_journal", "journal.png", SAND, "ごはん・脱皮・体重<br>ぜんぶ1か所に", "エサの種類やダスティングも残せる"),
    ("05_prefs", "prefs.png", MOSS, "ごはんの日を<br>1日1通でお知らせ", "広告なし・記録は iPhone の中だけ"),
]

PAGE = """<!doctype html><html lang="ja"><head><meta charset="utf-8"><style>
*{{margin:0;padding:0;box-sizing:border-box}}
html,body{{width:{W}px;height:{H}px;overflow:hidden}}
body{{background:{bg};font-family:'Hiragino Maru Gothic ProN','Hiragino Sans',sans-serif;color:{fg};position:relative}}
.copy{{position:absolute;top:150px;left:0;right:0;text-align:center}}
h1{{font-size:112px;font-weight:800;line-height:1.28}}
p{{margin-top:44px;font-size:50px;font-weight:700;color:{sub}}}
.dot{{display:inline-block;width:22px;height:22px;border-radius:50%;background:{AMBER};margin:0 18px 8px;vertical-align:middle}}
.phone{{position:absolute;top:740px;left:50%;transform:translateX(-50%);width:1040px;padding:18px;background:#26261F;border-radius:136px;box-shadow:0 40px 80px rgba(0,0,0,.22)}}
.phone img{{display:block;width:100%;border-radius:120px}}
</style></head><body><div class="copy"><h1>{title}</h1><p><span class="dot"></span>{text}<span class="dot"></span></p></div>
<div class="phone"><img src="{shot}"></div></body></html>"""

OUT.mkdir(exist_ok=True)
for name, shot, bg, title, text in SLIDES:
    page = OUT / f"{name}.html"
    dark = bg == MOSS
    page.write_text(PAGE.format(W=W, H=H, bg=bg, fg="#FFFFFF" if dark else "#26261F",
                                sub="#E8F0DF" if dark else MOSS, AMBER=AMBER,
                                title=title, text=text, shot=(SRC / shot).as_uri()), encoding="utf-8")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                    f"--window-size={W},{H}", "--allow-file-access-from-files",
                    f"--screenshot={OUT / (name + '.png')}", page.as_uri()], check=True, capture_output=True)
    page.unlink()
    # ASC のバージョンページの枠（Dynamic Island 搭載 iPhone・中型）は 6.3インチ 1206x2622 を受け付ける。
    OUT63 = ROOT / "out-6.3"
    OUT63.mkdir(exist_ok=True)
    subprocess.run(["sips", "-z", "2622", "1206", str(OUT / (name + ".png")), "--out", str(OUT63 / (name + ".png"))],
                   check=True, capture_output=True)
    print("wrote", name)
