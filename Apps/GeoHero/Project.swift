import ProjectDescription

let project = Project(
    name: "GeoHero",
    settings: .settings(
        base: [
            // 自動署名と開発チームを固定し、tuist generate で署名設定が消えないようにする。
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
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
                    "CFBundleShortVersionString": "1.2",
                    "CFBundleVersion": "7",
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
            ]
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
