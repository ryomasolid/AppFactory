#!/bin/bash
# 審査用スクリーンショット（6.5インチ・1242x2688・透過なしJPEG）を撮り直す。
#
#     Tools/make_screenshots.sh
#
# 6.9インチ(iPhone 16 Pro Max など)は App Store Connect に弾かれるので、
# 6.5インチの iPhone 11 Pro Max でしか撮らない。
set -euo pipefail
cd "$(dirname "$0")/.."

APP_ID=tech.sesame.geohero
DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-11-Pro-Max
OUT=Docs/Store/screenshots
TMP=$(mktemp -d)

mise exec -- tuist generate --no-open >/dev/null
xcodebuild build -workspace GeoHero.xcworkspace -scheme GeoHero \
  -destination 'platform=iOS Simulator,name=iPhone 11 Pro Max' \
  -derivedDataPath DerivedData >/dev/null
APP=$(find DerivedData/Build/Products -name GeoHero.app -path '*iphonesimulator*' | head -1)

DEV=$(xcrun simctl list devices -j | python3 -c "
import json,sys
for rt, ds in json.load(sys.stdin)['devices'].items():
    for d in ds:
        if d['name'] == 'iPhone 11 Pro Max':
            print(d['udid']); raise SystemExit
")
if [ -z "$DEV" ]; then DEV=$(xcrun simctl create "iPhone 11 Pro Max" "$DEVICE_TYPE"); fi
xcrun simctl boot "$DEV" 2>/dev/null || true
sleep 5
# セーブが残っていると タイトルに「つづきから」が出るので 消してから入れる。
xcrun simctl uninstall "$DEV" "$APP_ID" 2>/dev/null || true
xcrun simctl install "$DEV" "$APP"

shot() {
  local name=$1 wait=$2; shift 2
  xcrun simctl terminate "$DEV" "$APP_ID" 2>/dev/null || true
  xcrun simctl launch "$DEV" "$APP_ID" "$@" >/dev/null
  sleep "$wait"
  xcrun simctl io "$DEV" screenshot "$TMP/$name.png" >/dev/null
  sips -s format jpeg -s formatOptions 92 "$TMP/$name.png" --out "$OUT/65_$name.jpg" >/dev/null
  echo "  $OUT/65_$name.jpg"
}

mkdir -p "$OUT"
echo "撮影中:"
shot 1_title  4
shot 2_field  4 -startMap field -startX 16 -startY 35 -startLevel 5
shot 3_battle 5 -startBattle potato,kelpSlime,scallop -startLevel 5
shot 4_boss   5 -startBattle guardian -startLevel 12
shot 5_shop   4 -startMap sapporo -startX 7 -startY 11 -startLevel 8 -startOverlay shop -shopConfirm steelSword
rm -rf "$TMP"
