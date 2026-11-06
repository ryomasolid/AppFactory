#!/usr/bin/env python3
"""全国の駅一覧（stations-japan.json）を作る。

元データ: 国土数値情報（鉄道データ）N02 の N02-XX_Station.geojson（CC BY 4.0・国土交通省）。
https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-N02-2025.html

    python3 -I Scripts/export_stations.py <N02-25_Station.geojson> 2025

会社ごとに分かれている同じ駅は、同じ名前で 1.2km 以内のものを 1 駅にまとめる。
アプリには 駅名・緯度・経度・路線（短い表記）だけを入れる。
"""
import json
import math
import re
import sys
import unicodedata
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "GatsuGatsu/Resources/Content/stations-japan.json"
MERGE_KM = 1.2

JR = {"北海道旅客鉄道", "東日本旅客鉄道", "東海旅客鉄道", "西日本旅客鉄道", "四国旅客鉄道", "九州旅客鉄道"}
SHORT = {
    "東京地下鉄": "東京メトロ", "東京都": "都営", "大阪市高速電気軌道": "Osaka Metro",
    "名古屋市": "名古屋市営", "札幌市": "札幌市営", "横浜市": "横浜市営", "京都市": "京都市営",
    "神戸市": "神戸市営", "福岡市": "福岡市地下鉄", "仙台市": "仙台市地下鉄",
    "熊本市": "熊本市電", "鹿児島市": "鹿児島市電", "函館市": "函館市電",
    "東急電鉄": "東急", "京王電鉄": "京王", "小田急電鉄": "小田急", "近畿日本鉄道": "近鉄",
    "名古屋鉄道": "名鉄", "京浜急行電鉄": "京急", "京成電鉄": "京成", "東武鉄道": "東武",
    "西武鉄道": "西武", "阪急電鉄": "阪急", "阪神電気鉄道": "阪神", "京阪電気鉄道": "京阪",
    "南海電気鉄道": "南海", "西日本鉄道": "西鉄", "相模鉄道": "相鉄",
}


def clean_line(line: str) -> str:
    """「4号線丸ノ内線」「1号線(御堂筋線)」→「丸ノ内線」「御堂筋線」。番号だけの路線はそのまま。"""
    m = re.match(r"^\d+号線\(?(.+?)\)?(分岐線)?$", line)
    return m.group(1) if m else line


def label(operator: str, line: str) -> str:
    line = clean_line(line)
    if operator in JR:
        return line if line.endswith("新幹線") else f"JR{line}"
    short = SHORT.get(operator, operator)
    if line.startswith(short) or line == operator:
        return line
    return f"{short}{line}"


def center(geometry) -> tuple[float, float]:
    points = geometry["coordinates"]
    if geometry["type"] == "MultiLineString":
        points = [p for part in points for p in part]
    lon = sum(p[0] for p in points) / len(points)
    lat = sum(p[1] for p in points) / len(points)
    return lat, lon


def km(a, b) -> float:
    lat = math.radians((a[0] + b[0]) / 2)
    dy = (a[0] - b[0]) * 111.0
    dx = (a[1] - b[1]) * 111.0 * math.cos(lat)
    return math.hypot(dx, dy)


def main() -> None:
    source, year = Path(sys.argv[1]), sys.argv[2]
    features = json.loads(source.read_text(encoding="utf-8"))["features"]

    by_name: dict[str, list] = {}
    for f in features:
        p = f["properties"]
        name = unicodedata.normalize("NFKC", p["N02_005"]).strip()
        operator = unicodedata.normalize("NFKC", p["N02_004"]).strip()
        by_name.setdefault(name, []).append((center(f["geometry"]), label(operator, p["N02_003"])))

    stations = []
    for name, records in by_name.items():
        # 同じ名前の記録を、近いもの同士でつなぐ（単連結）。
        groups: list[list] = []
        for record in records:
            near = [g for g in groups if any(km(record[0], r[0]) <= MERGE_KM for r in g)]
            merged = [record]
            for g in near:
                merged += g
                groups.remove(g)
            groups.append(merged)
        for g in groups:
            lat = sum(r[0][0] for r in g) / len(g)
            lon = sum(r[0][1] for r in g) / len(g)
            lines = list(dict.fromkeys(r[1] for r in g))
            stations.append([name, round(lat, 5), round(lon, 5), lines])

    stations.sort(key=lambda s: (s[0], -s[1]))
    OUT.write_text(json.dumps({
        "source": f"国土数値情報（鉄道データ）{year}年度版　国土交通省",
        "license": "CC BY 4.0",
        "stations": stations,
    }, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"{len(stations)} 駅 → {OUT}（{OUT.stat().st_size // 1024} KB）")


if __name__ == "__main__":
    main()
