import ProjectDescription

let marketingVersion = "1.0.1"
let buildNumber = "2"

/// SKAdNetwork（AdMob が案内しているもの）。広告の効果を測るのに使う。
let skanIDs = [
    "cstr6suwn9", "4fzdc2evr5", "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5",
    "ppxm28t8ap", "424m5254lk", "uw77j35x4d", "578prtvx9j", "4dzt52r2t5",
    "gta9lk7p23", "e5fvkxwrpn", "zq492l623r", "3qcr597p9d", "3rd42ekr43",
]

/// 単体テスト・審査用の録画では 同意フォーム・ATT・バナーを出さない。
let calmLaunch: Arguments = .arguments(launchArguments: [.launchArgument(name: "-calm", isEnabled: true)])

let project = Project(
    name: "ToypooDiary",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "",
        ]
    ),
    targets: [
        .target(
            name: "ToypooDiary",
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.toypoodiary",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": .dictionary([:]),
                    "CFBundleDisplayName": "といぷー日記",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": .string(marketingVersion),
                    "CFBundleVersion": .string(buildNumber),
                    "ITSAppUsesNonExemptEncryption": false,
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "NSCameraUsageDescription": "わんちゃんの写真を撮って、日記やトリミングの記録に残すために使います。写真はこの端末の中にだけ保存します。",
                    // AdMob「といぷー日記」（2026-11-16 登録・ストア未掲載で作成）。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~9897311863",
                    "NSUserTrackingUsageDescription": "興味に合った広告を出すために使います。許可しなくても、といぷー日記はすべての機能を使えます。",
                    "SKAdNetworkItems": .array(
                        skanIDs.map { .dictionary(["SKAdNetworkIdentifier": .string("\($0).skadnetwork")]) }
                    ),
                ]
            ),
            buildableFolders: [
                "ToypooDiary/Sources",
                "ToypooDiary/Resources",
            ],
            dependencies: [
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "ToypooDiaryTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.toypoodiary.tests",
            infoPlist: .default,
            buildableFolders: ["ToypooDiary/Tests"],
            dependencies: [.target(name: "ToypooDiary")]
        ),
        // 審査用の画面収録で、はじめての起動から同じ順に操作する。
        .target(
            name: "ToypooDiaryUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "tech.sesame.toypoodiary.uitests",
            infoPlist: .default,
            buildableFolders: ["ToypooDiary/UITests"],
            dependencies: [.target(name: "ToypooDiary")]
        ),
    ],
    schemes: [
        .scheme(
            name: "ToypooDiary",
            shared: true,
            buildAction: .buildAction(targets: ["ToypooDiary"]),
            testAction: .targets(["ToypooDiaryTests"], arguments: calmLaunch)
        ),
        .scheme(
            name: "ToypooDiaryWalkthrough",
            shared: true,
            buildAction: .buildAction(targets: ["ToypooDiary", "ToypooDiaryUITests"]),
            testAction: .targets(["ToypooDiaryUITests"], arguments: calmLaunch, configuration: .release)
        ),
    ]
)
