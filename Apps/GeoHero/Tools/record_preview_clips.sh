#!/bin/bash
# App プレビュー動画の 素材を シミュレータで 録る。いま 起動している シミュレータに、Debug ビルドの アプリを 入れて 撮る。
#
#     Tools/record_preview_clips.sh <出力フォルダ>
#
# できた 動画を `swift Tools/make_preview.swift` が つなぐ。
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:?出力フォルダ}
APP_ID=tech.sesame.geohero
APP=DerivedData/Build/Products/Debug-iphonesimulator/GeoHero.app
mkdir -p "$OUT"

# 名前 録る秒数 起動引数...
clip() {
  local name=$1 seconds=$2; shift 2
  xcrun simctl terminate booted "$APP_ID" 2>/dev/null || true
  # セーブが 残っていると タイトルに「つづきから」が 出るので、毎回 入れなおす。
  xcrun simctl uninstall booted "$APP_ID" 2>/dev/null || true
  xcrun simctl install booted "$APP"
  xcrun simctl io booted recordVideo --codec=h264 --force "$OUT/$name.mp4" 2>/dev/null &
  local recorder=$!
  sleep 1
  xcrun simctl launch booted "$APP_ID" "$@" >/dev/null
  sleep "$seconds"
  kill -INT "$recorder"
  wait "$recorder" 2>/dev/null || true
  echo "  $OUT/$name.mp4"
}

clip 1_title 5
clip 2_field 7 -startMap field -startX 47 -startY 29 -startLevel 5 -autoWalk left,left,left,left,left,up,up,up,up,up,up
clip 3_town 7 -startMap hakodate -startX 16 -startY 22 -autoWalk up,up,up,up,up,up,right,right,right,right,up,up,up,up,up
clip 4_quiz 10 -startBattle sakuraSpirit,matsumaeZuke,kitamaeShip -startLevel 5 -autoQuiz YES
clip 5_boss 12 -startBattle tengu -startLevel 10 -autoAttack YES
