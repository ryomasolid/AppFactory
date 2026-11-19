#!/usr/bin/env python3
"""国旗と首都の App Store 用スクショ。

src/ の素の画面（Shots-KS = iPhone 17 Pro・`-demo` に `-quiz <Mode>` / `-answered` / `-tab 1`）に見出しと枠を付けて、
out/（6.9インチ 1320x2868）と out-6.3/（1206x2622）に書き出す。
  python3 Store/screenshots/generate.py
"""
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
ICON = ROOT.parent.parent / "KokkiShuto/Resources/Assets.xcassets/AppIcon.appiconset/icon.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TARGETS = [("out", 1320, 2868), ("out-6.3", 1206, 2622)]

SHOTS = [
    # (書き出し名, 素の画面, 小見出し, 見出し, 説明, 上の色, 下の色)
    ("01_flag", "flag", "国旗 → 国名", "国旗と首都を<br><b>4択</b>で覚える", "197か国・国名と首都と国旗だけ<br>1回10問、すきま時間にサクッと", "#E6EEFB", "#BCD0F2"),
    ("02_answered", "flagAnswered", "まちがえても大丈夫", "まちがえた国が<br><b>また出る</b>", "答えのあとに正解と首都を確認<br>覚えていない国から先に出題", "#FCEDEA", "#F4CBC2"),
    ("03_capital", "capital", "国名 → 首都", "まぎらわしい首都も<br><b>ちゃんと覚える</b>", "まちがいの選択肢は同じ地域から<br>なんとなく、では当たらない", "#F1EAFB", "#D9C6F2"),
    ("04_nameflag", "nameFlag", "国名 → 国旗", "にている国旗を<br><b>見分ける</b>", "出し方は4つ ＋ まぜる<br>にがてな国だけの出題も", "#E7F3FB", "#BFDDF2"),
    ("05_home", "home", "覚えた数がふえる", "3回つづけて正解で<br><b>覚えた！</b>", "国旗・首都それぞれ 197か国中いくつ<br>地域をしぼって出題もできる", "#FFF6DC", "#F7E1A2"),
    ("06_dex", "dex", "ずかん", "世界の国を<br><b>いつでも調べる</b>", "地域でしぼる・国名や首都でさがす<br>広告なし・登録なし・無料", "#EEF0F4", "#D3D9E3"),
]


def html(w, h, shot, kicker, title, lead, top, bottom):
    k = w / 1320
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
*{{box-sizing:border-box}}
html,body{{margin:0;width:{w}px;height:{h}px;overflow:hidden}}
body{{background:linear-gradient(180deg,{top},{bottom});font-family:'Hiragino Sans','Hiragino Kaku Gothic ProN',sans-serif;color:#16213A;text-align:center;position:relative}}
.kicker{{margin:{140*k}px auto 0;display:inline-flex;align-items:center;gap:{16*k}px;font-size:{48*k}px;font-weight:700;color:#1E4A9E;
  background:#fff;border-radius:{50*k}px;padding:{14*k}px {38*k}px {14*k}px {16*k}px;box-shadow:0 {6*k}px {20*k}px rgba(30,74,158,.15)}}
.kicker img{{width:{68*k}px;height:{68*k}px;border-radius:{16*k}px}}
h1{{margin:{50*k}px 0 0;font-size:{110*k}px;line-height:1.3;font-weight:800}}
h1 b{{color:#1E4A9E}}
p{{margin:{34*k}px 0 0;font-size:{48*k}px;line-height:1.6;color:#4A5670;font-weight:600}}
.device{{position:absolute;left:50%;transform:translateX(-50%);bottom:{-250*k}px;width:{930*k}px;padding:{20*k}px;background:#16213A;border-radius:{130*k}px;
  box-shadow:0 {36*k}px {80*k}px rgba(22,33,58,.25)}}
.device img{{display:block;width:100%;border-radius:{110*k}px}}
.coin{{position:absolute;width:{150*k}px;height:{150*k}px;border-radius:50%;background:#7B4FD6;opacity:.16}}
</style></head><body>
<div class="coin" style="left:{60*k}px;top:{640*k}px"></div>
<div class="coin" style="right:{70*k}px;top:{230*k}px;width:{100*k}px;height:{100*k}px"></div>
<div class="kicker"><img src="{ICON.as_uri()}">{kicker}</div>
<h1>{title}</h1>
<p>{lead}</p>
<div class="device"><img src="{shot}"></div>
</body></html>"""


def render(page_html, w, h, dest):
    with tempfile.TemporaryDirectory() as tmp:
        t = pathlib.Path(tmp)
        (t / "p.html").write_text(page_html, encoding="utf-8")
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                        f"--window-size={w},{h}", f"--screenshot={t / 'p.png'}", (t / "p.html").as_uri()], check=True, capture_output=True)
        # 透過なしの JPEG にする（App Store Connect は透過を受けつけない）。
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "95", str(t / "p.png"), "--out", str(dest)], check=True, capture_output=True)


for folder, w, h in TARGETS:
    (ROOT / folder).mkdir(exist_ok=True)
    for name, src, kicker, title, lead, top, bottom in SHOTS:
        render(html(w, h, (ROOT / "src" / f"{src}.png").as_uri(), kicker, title, lead, top, bottom), w, h, ROOT / folder / f"{name}.jpg")
        print(folder, name)
