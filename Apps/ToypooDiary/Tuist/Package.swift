// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(productTypes: [:])
#endif

// 画面下のバナー（AdMob）。同意フォーム（UMP）は Google Mobile Ads といっしょに入る。
let package = Package(
    name: "ToypooDiary",
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.0.0"),
    ]
)
