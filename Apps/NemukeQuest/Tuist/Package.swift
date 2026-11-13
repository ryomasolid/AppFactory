// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(productTypes: [:])
#endif

// 2.1 から 画面下の バナーと、見たい人だけのリワード広告（AdMob）を出す。同意フォーム（UMP）は Google Mobile Ads の依存として入る。
let package = Package(
    name: "NemukeQuest",
    dependencies: [
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            from: "11.0.0"
        ),
    ]
)
