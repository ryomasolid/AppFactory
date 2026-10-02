#!/usr/bin/env python3
"""アプリのアイコン（1024x1024 PNG・透明なし）を ゲームのデータから作る。

東北の まつりの 夜空（ちょうちんの 列）に 勇者と 大きな「2」。
勇者は CharacterArt.swift、色は PixelArt.swift の Palette から読む。

    python3 Tools/make_app_icon.py

外部ライブラリは使わない（zlib だけで PNG を書く）。
"""
import re
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "GeoHero2/Sources/Game"
OUT = ROOT / "GeoHero2/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

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


# 「2」の ドット文字（5×7）。
TWO = [
    ".###.",
    "#...#",
    "....#",
    "...#.",
    "..#..",
    ".#...",
    "#####",
]


def main():
    colors = palette()
    grid = [[colors["k"] for _ in range(GRID)] for _ in range(GRID)]

    # 夜空：上は 濃い紫、下へ いくほど まつりの あかりで 赤く。
    for y in range(GRID):
        color = colors["P"] if y < 22 else (colors["R"] if y < 44 else colors["r"])
        for x in range(GRID):
            grid[y][x] = color
    # 星。
    for y in range(22):
        for x in range(GRID):
            if (x * 7 + y * 13) % 41 == 0:
                grid[y][x] = colors["w"]

    # ちょうちんの 列（竿燈・ねぶたの あかり）。
    for y in range(6, 8):
        for x in range(GRID):
            grid[y][x] = colors["N"]
    for cx in range(3, GRID, 8):
        for y in range(8, 14):
            for x in range(cx - 2, cx + 3):
                edge = y in (8, 13) or x in (cx - 2, cx + 2)
                grid[y][x] = colors["r"] if edge else colors["y"]

    # 地面（田んぼの 緑）。
    for y in range(52, GRID):
        for x in range(GRID):
            grid[y][x] = colors["G"] if (x + y) % 5 else colors["g"]

    # 勇者。
    hero = sprite("hero1", "CharacterArt.swift")
    size = len(hero) * HERO_SCALE
    left = 8
    top = 52 - size
    filled = {}
    for y, line in enumerate(hero):
        for x, ch in enumerate(line):
            if ch == "." or ch not in colors:
                continue
            for dy in range(HERO_SCALE):
                for dx in range(HERO_SCALE):
                    filled[(left + x * HERO_SCALE + dx, top + y * HERO_SCALE + dy)] = colors[ch]
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

    # 大きな「2」（4倍・黒い ふち）。
    scale = 4
    ox, oy = 40, 20
    two = set()
    for y, line in enumerate(TWO):
        for x, ch in enumerate(line):
            if ch == "#":
                for dy in range(scale):
                    for dx in range(scale):
                        two.add((ox + x * scale + dx, oy + y * scale + dy))
    for (px, py) in two:
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                spot = (px + dx, py + dy)
                if spot not in two:
                    grid[spot[1]][spot[0]] = outline
    for (px, py) in two:
        grid[py][px] = colors["y"]

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
