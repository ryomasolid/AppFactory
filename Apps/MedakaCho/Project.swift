import ProjectDescription

let marketingVersion = "1.0"
let buildNumber = "1"

/// AdMob が案内している SKAdNetwork の ID。広告の効果計測に使う。
let adNetworks = [
    "cstr6suwn9", "4fzdc2evr5", "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5",
    "ppxm28t8ap", "424m5254lk", "uw77j35x4d", "578prtvx9j", "4dzt52r2t5",
    "gta9lk7p23", "e5fvkxwrpn", "zq492l623r", "3qcr597p9d", "3rd42ekr43",
]

/// テストと審査用の録画では 広告まわり（同意・ATT・バナー）を起こさない。
let quietLaunch: Arguments = .arguments(launchArguments: [.launchArgument(name: "-quiet", isEnabled: true)])

let project = Project(
    name: "MedakaCho",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
        ]
    ),
    targets: [
        .target(
            name: "MedakaCho",
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.medakacho",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": .dictionary([:]),
                    "CFBundleDisplayName": "めだか帳",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": .string(marketingVersion),
                    "CFBundleVersion": .string(buildNumber),
                    "ITSAppUsesNonExemptEncryption": false,
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    // AdMob「めだか帳」（2026-11-12 登録・ストア未掲載で作成）。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~7039306127",
                    "NSUserTrackingUsageDescription": "あなたの興味に近い広告を出すために使います。許可しなくても、めだか帳の機能はすべて使えます。",
                    "SKAdNetworkItems": .array(
                        adNetworks.map { .dictionary(["SKAdNetworkIdentifier": .string("\($0).skadnetwork")]) }
                    ),
                ]
            ),
            buildableFolders: [
                "MedakaCho/Sources",
                "MedakaCho/Resources",
            ],
            dependencies: [
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "MedakaChoTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.medakacho.tests",
            infoPlist: .default,
            buildableFolders: ["MedakaCho/Tests"],
            dependencies: [.target(name: "MedakaCho")]
        ),
        // 審査用の画面収録で、はじめての起動から同じ手順で操作するための UI テスト。
        .target(
            name: "MedakaChoUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "tech.sesame.medakacho.uitests",
            infoPlist: .default,
            buildableFolders: ["MedakaCho/UITests"],
            dependencies: [.target(name: "MedakaCho")]
        ),
    ],
    schemes: [
        .scheme(
            name: "MedakaCho",
            shared: true,
            buildAction: .buildAction(targets: ["MedakaCho"]),
            testAction: .targets(["MedakaChoTests"], arguments: quietLaunch)
        ),
        .scheme(
            name: "MedakaChoReviewTour",
            shared: true,
            buildAction: .buildAction(targets: ["MedakaCho", "MedakaChoUITests"]),
            testAction: .targets(["MedakaChoUITests"], arguments: quietLaunch, configuration: .release)
        ),
    ]
)
