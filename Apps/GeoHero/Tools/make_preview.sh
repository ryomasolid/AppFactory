#!/bin/bash
# App プレビュー動画を 作る（録る → つなぐ）。いま 起動している シミュレータを 使う。
#
#     Tools/make_preview.sh
#
# できたものは Docs/Store/preview/geohero_preview_886x1920.mp4。
set -euo pipefail
cd "$(dirname "$0")/.."
TMP=$(mktemp -d)
OUT=Docs/Store/preview
mkdir -p "$OUT"

xcodebuild build -workspace GeoHero.xcworkspace -scheme GeoHero \
  -destination 'platform=iOS Simulator,id='"$(xcrun simctl list devices booted -j | python3 -c 'import json,sys; print([d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["state"]=="Booted"][0])')" \
  -derivedDataPath DerivedData -quiet
echo "録画中:"
Tools/record_preview_clips.sh "$TMP/clips"
swiftc -O -o "$TMP/make_preview" Tools/make_preview.swift \
  GeoHero/Sources/Audio/Synth.swift GeoHero/Sources/Audio/Scores.swift GeoHero/Sources/Audio/Sound.swift
echo "つないでいる:"
"$TMP/make_preview" "$TMP/clips" "$OUT/geohero_preview_886x1920.mp4"
rm -rf "$TMP"
