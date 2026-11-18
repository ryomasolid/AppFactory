#!/usr/bin/env python3
"""ムダゼロの App Store 用スクショ。

src/ の素の画面（iPhone 17 Pro・`-demo` に `-tab N` / `-demoClosed` / `-hello`）に見出しと枠を付けて、
out/（6.9インチ 1320x2868）と out-6.3/（1206x2622）に書き出す。
  python3 Store/screenshots/generate.py
"""
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
ICON = ROOT.parent.parent / "MudaZero/Resources/Assets.xcassets/AppIcon.appiconset/icon.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TARGETS = [("out", 1320, 2868), ("out-6.3", 1206, 2622)]

SHOTS = [
    # (書き出し名, 素の画面, 小見出し, 見出し, 説明, 上の色, 下の色)
    ("01_close", "closed", "ノーマネーデー記録", "ムダ遣いゼロの日を<br><b>1タップ</b>で記録", "使わなかった日は、夜にしめるだけ<br>0円の日・ムダゼロの連続日数も", "#E3F6EE", "#B5E6D2"),
    ("02_budget", "today", "今月のムダ予算", "あと<b>1日いくら</b>まで<br>使えるかわかる", "ついつい の出費だけを予算から引く<br>浮いたお金は旅行やほしいものへ", "#FFF6DC", "#F7E1A2"),
    ("03_calendar", "calendar", "節約カレンダー", "がんばった日が<br><b>色でたまる</b>", "0円の日は金・ムダゼロは緑<br>ついつい の内訳で使いすぎも見える", "#E7F3FB", "#BFDDF2"),
    ("04_start", "hello", "家計簿が続かない人へ", "全部つけなくて<br><b>大丈夫</b>", "「ついつい」と「必要」を分けるだけ<br>はじめの設定は2タップ", "#FCEDEA", "#F4CBC2"),
    ("05_settings", "settings", "夜のお知らせ", "つけ忘れない<br><b>やさしい通知</b>", "しめていない日だけ1日1回<br>記録は iPhone の中だけ・無料", "#EEF0F4", "#D3D9E3"),
]


def html(w, h, shot, kicker, title, lead, top, bottom):
    k = w / 1320
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
*{{box-sizing:border-box}}
html,body{{margin:0;width:{w}px;height:{h}px;overflow:hidden}}
body{{background:linear-gradient(180deg,{top},{bottom});font-family:'Hiragino Sans','Hiragino Kaku Gothic ProN',sans-serif;color:#1E2B25;text-align:center;position:relative}}
.kicker{{margin:{140*k}px auto 0;display:inline-flex;align-items:center;gap:{16*k}px;font-size:{48*k}px;font-weight:700;color:#1F9E78;
  background:#fff;border-radius:{50*k}px;padding:{14*k}px {38*k}px {14*k}px {16*k}px;box-shadow:0 {6*k}px {20*k}px rgba(31,158,120,.15)}}
.kicker img{{width:{68*k}px;height:{68*k}px;border-radius:{16*k}px}}
h1{{margin:{50*k}px 0 0;font-size:{110*k}px;line-height:1.3;font-weight:800}}
h1 b{{color:#1F9E78}}
p{{margin:{34*k}px 0 0;font-size:{48*k}px;line-height:1.6;color:#4C5C54;font-weight:600}}
.device{{position:absolute;left:50%;transform:translateX(-50%);bottom:{-250*k}px;width:{930*k}px;padding:{20*k}px;background:#1E2B25;border-radius:{130*k}px;
  box-shadow:0 {36*k}px {80*k}px rgba(30,43,37,.25)}}
.device img{{display:block;width:100%;border-radius:{110*k}px}}
.coin{{position:absolute;width:{150*k}px;height:{150*k}px;border-radius:50%;background:#E0A82E;opacity:.16}}
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
