#!/usr/bin/env python3
"""アプリのアイコン（1024x1024 PNG・透明なし）を ゲームのデータから作る。

北海道のかたちは Maps.swift のフィールド、勇者は CharacterArt.swift、
色は PixelArt.swift の Palette から読む。手で描いた絵を置かないので、
地図や配色を変えたら 作り直すだけで アイコンも合う。

    python3 Tools/make_app_icon.py

外部ライブラリは使わない（zlib だけで PNG を書く）。
"""
import re
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "TinyHero/Sources/Game"
OUT = ROOT / "TinyHero/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

GRID = 64          # アイコンを 64x64 の「大きなドット」で組む
CELL = 16          # 1ドット = 16px → 1024px
ISLAND_W, ISLAND_H = 62, 36
ISLAND_X, ISLAND_Y = 1, 19
HERO_SCALE = 2     # 16x16 の勇者を 32x32 に
HERO_Y = 10        # 足もとが島の上に来る高さ


def palette():
    text = (SRC / "PixelArt.swift").read_text()
    block = re.search(r"static let colors: \[Character: \(r: UInt8, g: UInt8, b: UInt8\)\] = \[(.*?)\n    \]",
                      text, re.S).group(1)
    found = {}
    for key, r, g, b in re.findall(r'"(.)": \((\d+), (\d+), (\d+)\)', block):
        found[key] = (int(r), int(g), int(b))
    return found


def sprite(name, path):
    text = (SRC / path).read_text()
    block = re.search(rf"\.{name}: \[\n(.*?)\n        \]", text, re.S).group(1)
    return [line.strip().strip(",").strip('"') for line in block.split("\n")]


def field_rows():
    text = (SRC / "Maps.swift").read_text()
    block = re.search(r"static let field = GameMap\(.*?rows: \[\n(.*?)\n        \],", text, re.S).group(1)
    return [line.strip().strip(",").strip('"') for line in block.split("\n")]


def write_png(path, pixels, width, height):
    """RGB（アルファなし）で書き出す。App Store のアイコンは透明を許さない。"""
    raw = b"".join(b"\x00" + bytes(pixels[y]) for y in range(height))

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    path.write_bytes(png)


def main():
    colors = palette()
    # 海は濃い青。勇者の服が青なので、同じ青だと 溶けて見えなくなる。
    sea, foam = colors["B"], colors["b"]
    land, edge, leaf = colors["g"], colors["G"], colors["l"]

    grid = [[sea for _ in range(GRID)] for _ in range(GRID)]

    # 海。ゲームの水タイルに合わせて 白波を まばらに置く。
    for y in range(GRID):
        for x in range(GRID):
            if (x * 5 + y * 3) % 37 == 0:
                grid[y][x] = foam

    # 北海道。フィールドの陸／海だけを引きのばして使う。
    rows = field_rows()
    src_w, src_h = len(rows[0]), len(rows)
    is_land = [[False] * GRID for _ in range(GRID)]
    for y in range(ISLAND_H):
        for x in range(ISLAND_W):
            if rows[y * src_h // ISLAND_H][x * src_w // ISLAND_W] != "~":
                is_land[ISLAND_Y + y][ISLAND_X + x] = True
    for y in range(GRID):
        for x in range(GRID):
            if not is_land[y][x]:
                continue
            # 海に接するマスは濃い緑で ふちどる（小さくしたとき 輪郭が残る）。
            coast = any(not (0 <= x + dx < GRID and 0 <= y + dy < GRID and is_land[y + dy][x + dx])
                        for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)))
            grid[y][x] = edge if coast else (leaf if (x * 7 + y * 11) % 17 == 0 else land)

    # 勇者。島の上に立たせる。
    hero = sprite("hero1", "CharacterArt.swift")
    size = len(hero) * HERO_SCALE
    left = (GRID - size) // 2
    filled = {}
    for y, line in enumerate(hero):
        for x, ch in enumerate(line):
            if ch == "." or ch not in colors:
                continue
            for dy in range(HERO_SCALE):
                for dx in range(HERO_SCALE):
                    filled[(left + x * HERO_SCALE + dx, HERO_Y + y * HERO_SCALE + dy)] = colors[ch]
    # 海にも島にも負けないよう、黒でふちどる（服の青が海と同系色のため）。
    outline = colors["k"]
    for (px, py) in list(filled):
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                spot = (px + dx, py + dy)
                if spot not in filled and 0 <= spot[0] < GRID and 0 <= spot[1] < GRID:
                    grid[spot[1]][spot[0]] = outline
    for (px, py), color in filled.items():
        if 0 <= px < GRID and 0 <= py < GRID:
            grid[py][px] = color

    # 1024px へ引きのばす（にじませない）。
    width = height = GRID * CELL
    pixels = []
    for y in range(height):
        row = bytearray()
        for x in range(width):
            row += bytes(grid[y // CELL][x // CELL])
        pixels.append(row)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    write_png(OUT, pixels, width, height)
    print(f"かきだした: {OUT.relative_to(ROOT)} ({width}x{height})")


if __name__ == "__main__":
    sys.exit(main())
