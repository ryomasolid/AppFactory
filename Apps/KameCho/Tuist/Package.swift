// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(productTypes: [:])
#endif

// 各画面の下に出すバナー（AdMob）。同意の画面（UMP）はこの依存についてくる。
let package = Package(
    name: "KameCho",
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.0.0"),
    ]
)
