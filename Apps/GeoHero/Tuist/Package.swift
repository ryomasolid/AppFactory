// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [:]
    )
#endif

// 1.3 から 見たい人だけが見る広告（リワード広告）のために AdMob を入れる。
let package = Package(
    name: "GeoHero",
    dependencies: [
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            from: "12.0.0"
        ),
    ]
)
