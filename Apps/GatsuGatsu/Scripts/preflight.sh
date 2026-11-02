#!/bin/zsh
# App Store へ出す前の確認。テスト用の広告IDのまま提出するのを止める。
set -u
cd "$(dirname "$0")/.."
fail=0
if grep -E '\.release\(.*GAD_APP_ID.*ca-app-pub-3940256099942544' Project.swift >/dev/null; then
  echo "NG: Project.swift の Release がテスト用アプリIDのままです"; fail=1
fi
if grep -E 'static let production: \[Kind: String\] = \[:\]' GatsuGatsu/Sources/Ads/AdUnits.swift >/dev/null; then
  echo "NG: AdUnits.production が空です（このまま出すと広告が一切出ません）"; fail=1
fi
curl -sf https://ryomasolid.github.io/privacy-gatsugatsu.html >/dev/null || { echo "NG: プライバシーポリシーが未公開です"; fail=1; }
curl -sf https://ryomasolid.github.io/support-gatsugatsu.html >/dev/null || { echo "NG: サポートページが未公開です"; fail=1; }
[ $fail -eq 0 ] && echo "OK: 提出前の確認を通過しました"
exit $fail
