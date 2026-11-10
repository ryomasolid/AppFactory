import ProjectDescription

// AdMob の 広告計測（SKAdNetwork）。Google の リストの 主なもの。
let skAdNetworks = [
    "cstr6suwn9", "4fzdc2evr5", "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5", "ppxm28t8ap",
    "424m5254lk", "uw77j35x4d", "578prtvx9j", "4dzt52r2t5", "gta9lk7p23", "e5fvkxwrpn",
    "zq492l623r", "3qcr597p9d", "3rd42ekr43",
]

let project = Project(
    name: "GeoHero",
    settings: .settings(
        base: [
            // 自動署名と開発チームを固定し、tuist generate で署名設定が消えないようにする。
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        ],
        configurations: [
            // 開発中は Google の テスト用アプリIDで 本番の広告を 出さない。
            .debug(name: .debug, settings: ["GAD_APP_ID": "ca-app-pub-3940256099942544~1458002511"]),
            .release(name: .release, settings: ["GAD_APP_ID": "ca-app-pub-6105029932689433~3935848258"]),
        ]
    ),
    targets: [
        .target(
            name: "GeoHero",
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.geohero",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "地理の勇者",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": "2.0",
                    "CFBundleVersion": "14",
                    "GADApplicationIdentifier": "$(GAD_APP_ID)",
                    "SKAdNetworkItems": .array(skAdNetworks.map { .dictionary(["SKAdNetworkIdentifier": .string("\($0).skadnetwork")]) }),
                    "ITSAppUsesNonExemptEncryption": false,
                    // 十字キーの配置を1パターンに絞るため縦持ち固定。
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "UIStatusBarHidden": true,
                    "UIRequiresFullScreen": true,
                    // App Store の アプリ内イベントから 開く（geohero://stamp-rally など）。
                    "CFBundleURLTypes": .array([.dictionary([
                        "CFBundleURLName": .string("tech.sesame.geohero"),
                        "CFBundleURLSchemes": .array([.string("geohero")]),
                    ])]),
                ]
            ),
            buildableFolders: [
                "GeoHero/Sources",
                "GeoHero/Resources",
            ],
            dependencies: [.external(name: "GoogleMobileAds")]
        ),
        .target(
            name: "GeoHeroTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.geohero.tests",
            infoPlist: .default,
            buildableFolders: [
                "GeoHero/Tests"
            ],
            dependencies: [.target(name: "GeoHero")]
        ),
    ],
    schemes: [
        .scheme(
            name: "GeoHero",
            shared: true,
            buildAction: .buildAction(targets: ["GeoHero"]),
            testAction: .targets(["GeoHeroTests"])
        ),
    ]
)
