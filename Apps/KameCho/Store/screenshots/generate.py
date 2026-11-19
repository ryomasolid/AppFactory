#!/usr/bin/env python3
"""カメ帳の App Store 用スクショ。

src/ の画面（iPhone 17 Pro・`-sample -tab N`、冬眠は `-sampleWinter`、リクガメは `-pickSecond`）に
見出しと端末の枠を付けて、out/（6.9インチ 1320x2868）と out-6.3/（1206x2622）に書き出す。
  python3 Store/screenshots/generate.py
"""
import pathlib
import subprocess
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
ICON = HERE.parent.parent / "KameCho/Resources/Assets.xcassets/AppIcon.appiconset/icon.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SIZES = {"out": (1320, 2868), "out-6.3": (1206, 2622)}

PAGES = [
    # (書き出し名, 素材, 札, 見出し, 説明, 背景の上, 背景の下)
    ("01_today", "today", "ミズガメ・リクガメの飼育帳", "ごはん・水換えを<br><b>もう迷わない</b>", "種類と年齢から世話の予定を自動で<br>水温が外れたらすぐ気づける", "#EAF3E2", "#BFDDB3"),
    ("02_growth", "growth", "成長の記録", "甲長と体重の<br><b>のびがグラフに</b>", "前回からの差と1年でのびた長さ<br>冬眠していた期間もわかる", "#F6F0DF", "#E6D3A6"),
    ("03_winter", "winter", "冬眠の見守り", "冬眠中の<br><b>体重の減り</b>を見張る", "始めた日の体重とくらべて<br>ひと月あたりの減りを表示", "#E3EEF3", "#B5D2DE"),
    ("04_gear", "gear", "器具の交換時期", "UVBライトの<br><b>替えどき</b>を逃さない", "紫外線は光っていても弱くなる<br>ヒーター・ろ材もまとめて管理", "#FBF1DC", "#F2D29A"),
    ("05_land", "land", "リクガメにも", "温浴・床材の交換も<br><b>1匹ずつ</b>記録", "何匹いても切りかえかんたん<br>記録は iPhone の中だけ・無料", "#EEF1E4", "#CBD7AE"),
]


def page(w, h, shot, tag, title, lead, top, bottom):
    u = w / 1320
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
*{{box-sizing:border-box}}
html,body{{margin:0;width:{w}px;height:{h}px;overflow:hidden}}
body{{background:linear-gradient(180deg,{top},{bottom});font-family:'Hiragino Sans','Hiragino Kaku Gothic ProN',sans-serif;color:#2F3A2C;text-align:center;position:relative}}
.tag{{margin:{140*u}px auto 0;display:inline-flex;align-items:center;gap:{16*u}px;font-size:{48*u}px;font-weight:700;color:#4F8A5B;
  background:#FFFDF8;border-radius:{50*u}px;padding:{14*u}px {38*u}px {14*u}px {16*u}px;box-shadow:0 {6*u}px {20*u}px rgba(79,138,91,.18)}}
.tag img{{width:{68*u}px;height:{68*u}px;border-radius:{16*u}px}}
h1{{margin:{50*u}px 0 0;font-size:{108*u}px;line-height:1.3;font-weight:800}}
h1 b{{color:#4F8A5B}}
p{{margin:{34*u}px 0 0;font-size:{48*u}px;line-height:1.6;color:#55604F;font-weight:600}}
.phone{{position:absolute;left:50%;transform:translateX(-50%);bottom:{-250*u}px;width:{930*u}px;padding:{20*u}px;background:#26302A;border-radius:{130*u}px;
  box-shadow:0 {36*u}px {80*u}px rgba(47,58,44,.28)}}
.phone img{{display:block;width:100%;border-radius:{110*u}px}}
.leaf{{position:absolute;font-size:{120*u}px;opacity:.13}}
</style></head><body>
<div class="leaf" style="left:{70*u}px;top:{660*u}px;transform:rotate(-20deg)">🍃</div>
<div class="leaf" style="right:{80*u}px;top:{240*u}px;transform:rotate(25deg)">🐢</div>
<div class="tag"><img src="{ICON.as_uri()}">{tag}</div>
<h1>{title}</h1>
<p>{lead}</p>
<div class="phone"><img src="{shot}"></div>
</body></html>"""


def shoot(markup, w, h, dest):
    with tempfile.TemporaryDirectory() as tmp:
        d = pathlib.Path(tmp)
        (d / "page.html").write_text(markup, encoding="utf-8")
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                        f"--window-size={w},{h}", f"--screenshot={d / 'page.png'}", (d / "page.html").as_uri()], check=True, capture_output=True)
        # ASC は透過を受けつけないので、JPEG を通してアルファを落とす。
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "95", str(d / "page.png"), "--out", str(d / "page.jpg")], check=True, capture_output=True)
        subprocess.run(["sips", "-s", "format", "png", str(d / "page.jpg"), "--out", str(dest)], check=True, capture_output=True)


for folder, (w, h) in SIZES.items():
    (HERE / folder).mkdir(exist_ok=True)
    for name, src, tag, title, lead, top, bottom in PAGES:
        shoot(page(w, h, (HERE / "src" / f"{src}.png").as_uri(), tag, title, lead, top, bottom), w, h, HERE / folder / f"{name}.png")
        print(folder, name)
