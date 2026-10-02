// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [:]
    )
#endif

// 試作段階なので外部依存なし（広告・課金は公開を決めてから足す）。
let package = Package(
    name: "GeoHero",
    dependencies: []
)
