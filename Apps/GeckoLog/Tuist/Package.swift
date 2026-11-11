// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(productTypes: [:])
#endif

// 1.1 から バナー広告（AdMob）を載せる。UserMessagingPlatform は GoogleMobileAds に付いてくる。
let package = Package(
    name: "GeckoLog",
    dependencies: [
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            from: "11.0.0"
        ),
    ]
)
