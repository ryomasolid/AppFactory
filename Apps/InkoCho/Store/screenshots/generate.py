#!/usr/bin/env python3
"""インコ帳の App Store 用スクショ。

src/ の素の画面（iPhone 17 Pro・`-demo -tab N`）に見出しと枠を付けて、
out/（6.9インチ 1320x2868）と out-6.3/（1206x2622）に書き出す。
  python3 Store/screenshots/generate.py
"""
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
ICON = ROOT.parent.parent / "InkoCho/Resources/Assets.xcassets/AppIcon.appiconset/icon.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TARGETS = [("out", 1320, 2868), ("out-6.3", 1206, 2622)]

SHOTS = [
    # (書き出し名, 素の画面, 小見出し, 見出し, 説明, 上の色, 下の色)
    ("01_today", "today", "セキセイインコの見守り帳", "小さな変化に<br><b>早く気づける</b>", "毎朝の体重を「ふだん」とくらべて<br>ふくらみ・フン・室温もいっしょに", "#E4F3FC", "#B6DDF5"),
    ("02_weight", "weight", "体重グラフ", "グラム単位で<br><b>体重の変化</b>が見える", "7日平均の「ふだん」の線つき<br>減りが続くとお知らせ", "#EAF7E8", "#C3E6BC"),
    ("03_words", "words", "ことば帳", "おぼえた言葉を<br><b>日付つきで</b>残す", "はじめて聞いた日の思い出も<br>鳴きまねもまとめて", "#FFF7DD", "#F8E3A0"),
    ("04_chores", "chores", "おせわの目安", "大掃除・爪切りを<br><b>うっかり忘れない</b>", "前回と次の目安がひと目でわかる<br>朝のお知らせで1通にまとめて", "#FDECEF", "#F6C8D1"),
    ("05_birds", "settings", "多頭飼いもOK", "何羽いても<br><b>1羽ずつ</b>記録", "記録は iPhone の中だけ<br>アカウント登録なし・無料", "#EEF0FB", "#CCD3F2"),
]


def html(w, h, shot, kicker, title, lead, top, bottom):
    k = w / 1320
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
*{{box-sizing:border-box}}
html,body{{margin:0;width:{w}px;height:{h}px;overflow:hidden}}
body{{background:linear-gradient(180deg,{top},{bottom});font-family:'Hiragino Sans','Hiragino Kaku Gothic ProN',sans-serif;color:#23384D;text-align:center;position:relative}}
.kicker{{margin:{140*k}px auto 0;display:inline-flex;align-items:center;gap:{16*k}px;font-size:{48*k}px;font-weight:700;color:#2F8FD8;
  background:#fff;border-radius:{50*k}px;padding:{14*k}px {38*k}px {14*k}px {16*k}px;box-shadow:0 {6*k}px {20*k}px rgba(47,143,216,.15)}}
.kicker img{{width:{68*k}px;height:{68*k}px;border-radius:{16*k}px}}
h1{{margin:{50*k}px 0 0;font-size:{110*k}px;line-height:1.3;font-weight:800}}
h1 b{{color:#2F8FD8}}
p{{margin:{34*k}px 0 0;font-size:{48*k}px;line-height:1.6;color:#4E6377;font-weight:600}}
.device{{position:absolute;left:50%;transform:translateX(-50%);bottom:{-250*k}px;width:{930*k}px;padding:{20*k}px;background:#1E2A36;border-radius:{130*k}px;
  box-shadow:0 {36*k}px {80*k}px rgba(35,56,77,.25)}}
.device img{{display:block;width:100%;border-radius:{110*k}px}}
.feather{{position:absolute;font-size:{120*k}px;opacity:.14}}
</style></head><body>
<div class="feather" style="left:{70*k}px;top:{660*k}px;transform:rotate(-25deg)">🪶</div>
<div class="feather" style="right:{80*k}px;top:{240*k}px;transform:rotate(20deg)">🪶</div>
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
        # アルファなしにする（App Store Connect は透過を受けつけない）。
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "95", str(t / "p.png"), "--out", str(t / "p.jpg")], check=True, capture_output=True)
        subprocess.run(["sips", "-s", "format", "png", str(t / "p.jpg"), "--out", str(dest)], check=True, capture_output=True)


for folder, w, h in TARGETS:
    (ROOT / folder).mkdir(exist_ok=True)
    for name, src, kicker, title, lead, top, bottom in SHOTS:
        render(html(w, h, (ROOT / "src" / f"{src}.png").as_uri(), kicker, title, lead, top, bottom), w, h, ROOT / folder / f"{name}.png")
        print(folder, name)
