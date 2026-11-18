// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(productTypes: [:])
#endif

// 下のバナー広告（AdMob）。同意画面の UMP も一緒に入る。
let package = Package(
    name: "MudaZero",
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.0.0"),
    ]
)
