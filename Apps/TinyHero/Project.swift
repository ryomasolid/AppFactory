import ProjectDescription

let project = Project(
    name: "TinyHero",
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
            name: "TinyHero",
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.tinyhero",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "地理の勇者",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": "0.1",
                    "CFBundleVersion": "1",
                    "ITSAppUsesNonExemptEncryption": false,
                    // 十字キーの配置を1パターンに絞るため縦持ち固定。
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "UIStatusBarHidden": true,
                    "UIRequiresFullScreen": true,
                ]
            ),
            buildableFolders: [
                "TinyHero/Sources",
                "TinyHero/Resources",
            ]
        ),
        .target(
            name: "TinyHeroTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.tinyhero.tests",
            infoPlist: .default,
            buildableFolders: [
                "TinyHero/Tests"
            ],
            dependencies: [.target(name: "TinyHero")]
        ),
    ],
    schemes: [
        .scheme(
            name: "TinyHero",
            shared: true,
            buildAction: .buildAction(targets: ["TinyHero"]),
            testAction: .targets(["TinyHeroTests"])
        ),
    ]
)
