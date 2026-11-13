// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(productTypes: [:])
#endif

// 2.0 は広告なし（旧 RN 版も広告IDが未設定で出ていなかった）。AdMob に登録したら Google Mobile Ads を足す。
let package = Package(
    name: "NemukeQuest",
    dependencies: []
)
