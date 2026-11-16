#!/usr/bin/env python3
"""といぷー日記の App Store 用スクショを作る。

src/ にシミュレーター（iPhone 17 Pro）で撮った素の画面を置いて
  python3 Store/screenshots/generate.py
を実行すると、out/（6.9インチ 1320x2868）と out-6.3/（1206x2622）に書き出す。
素の画面は `-sample -demoPhotos <photos の絶対パス>` ＋ 各画面の引数で撮る（Docs/Design.md）。
"""
import pathlib
import subprocess
import tempfile

HERE = pathlib.Path(__file__).parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SIZES = {"out": (1320, 2868), "out-6.3": (1206, 2622)}

PAGES = [
    ("01_diary", "diary.png", "トイプードル専用の日記", "うちの子の毎日を<br><em>写真で日記に</em>", "きぶん・散歩・ごはん・歯みがきを<br>タップで記録", "#FFF1E4", "#F7D3B5"),
    ("02_trim", "trim.png", "トリミング手帳", "次のトリミングが<br><em>ひと目でわかる</em>", "前回のカットからの日数と<br>毛の伸びをお知らせ", "#FDF0EE", "#F4C9C6"),
    ("03_health", "health.png", "けんこう管理", "体重と予防の予定を<br><em>まとめてチェック</em>", "ワクチン・フィラリア・ノミダニの<br>次の日がすぐわかる", "#F1F6EE", "#CFE4C6"),
    ("04_detail", "detail.png", "思い出アルバム", "かわいい瞬間を<br><em>ずっと残せる</em>", "写真つきの日記を<br>SNSにシェアもできる", "#FFF5E6", "#F5DCA9"),
    ("05_family", "settings.png", "多頭飼いもOK", "お知らせで<br><em>うっかり忘れ</em>を防ぐ", "予防・トリミングの日は朝に<br>日記は夜にそっとおさそい", "#EEF2FA", "#CBD7EE"),
]


def page_html(w, h, shot, eyebrow, title, sub, top, bottom, icon):
    s = w / 1320
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
html,body{{margin:0;width:{w}px;height:{h}px;overflow:hidden;font-family:'Hiragino Maru Gothic ProN','Hiragino Sans',sans-serif}}
body{{background:linear-gradient(170deg,{top} 0%,{bottom} 100%);color:#5B3A26;text-align:center;position:relative}}
.eyebrow{{display:inline-flex;align-items:center;gap:{18*s}px;margin-top:{150*s}px;font-size:{50*s}px;font-weight:700;color:#8B5A3C;
  background:rgba(255,255,255,.75);padding:{16*s}px {40*s}px;border-radius:{60*s}px}}
.eyebrow img{{width:{64*s}px;height:{64*s}px;border-radius:{15*s}px}}
h1{{font-size:{112*s}px;line-height:1.28;margin:{48*s}px 0 0;font-weight:800;letter-spacing:{2*s}px}}
h1 em{{font-style:normal;color:#C8606E}}
p{{font-size:{50*s}px;line-height:1.55;margin:{36*s}px 0 0;color:#7A5B48;font-weight:600}}
.phone{{position:absolute;left:50%;bottom:{-260*s}px;transform:translateX(-50%);width:{940*s}px;border-radius:{120*s}px;
  border:{22*s}px solid #2B211D;box-shadow:0 {40*s}px {90*s}px rgba(91,58,38,.28);overflow:hidden;background:#000}}
.phone img{{display:block;width:100%}}
.paw{{position:absolute;opacity:.10;font-size:{150*s}px}}
</style></head><body>
<div class="paw" style="left:{60*s}px;top:{620*s}px;transform:rotate(-20deg)">🐾</div>
<div class="paw" style="right:{70*s}px;top:{180*s}px;transform:rotate(18deg)">🐾</div>
<div class="eyebrow"><img src="{icon}">{eyebrow}</div>
<h1>{title}</h1>
<p>{sub}</p>
<div class="phone"><img src="{shot}"></div>
</body></html>"""


def main():
    icon = (HERE.parent.parent / "ToypooDiary/Resources/Assets.xcassets/AppIcon.appiconset/icon.png").resolve().as_uri()
    for folder, (w, h) in SIZES.items():
        out = HERE / folder
        out.mkdir(exist_ok=True)
        for name, shot, eyebrow, title, sub, top, bottom in PAGES:
            html = page_html(w, h, (HERE / "src" / shot).resolve().as_uri(), eyebrow, title, sub, top, bottom, icon)
            with tempfile.TemporaryDirectory() as tmp:
                page = pathlib.Path(tmp) / "page.html"
                page.write_text(html, encoding="utf-8")
                png = pathlib.Path(tmp) / "shot.png"
                subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                                f"--window-size={w},{h}", f"--screenshot={png}", page.as_uri()],
                               check=True, capture_output=True)
                # 透過なしにする（JPEG を経由して PNG に戻す）。
                jpg = pathlib.Path(tmp) / "shot.jpg"
                subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "95", str(png), "--out", str(jpg)], check=True, capture_output=True)
                subprocess.run(["sips", "-s", "format", "png", str(jpg), "--out", str(out / f"{name}.png")], check=True, capture_output=True)
            print(out / f"{name}.png")


if __name__ == "__main__":
    main()
