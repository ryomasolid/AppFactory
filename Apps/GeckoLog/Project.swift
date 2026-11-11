import ProjectDescription

// 1.0 は広告も課金も載せなかった（外部 SDK ゼロ）。1.1 からタブの上にバナー広告（AdMob）を置く。
let marketingVersion = "1.1"
let buildNumber = "2"

// AdMob の広告計測に使う SKAdNetwork の識別子（Google の公式リスト）。足りなくても計測の範囲が狭まるだけ。
let skAdNetworkIDs: [String] = [
    "cstr6suwn9.skadnetwork",
    "4fzdc2evr5.skadnetwork",
    "2u9pt9hc89.skadnetwork",
    "8s468mfl3y.skadnetwork",
    "klf5c3l5u5.skadnetwork",
    "ppxm28t8ap.skadnetwork",
    "424m5254lk.skadnetwork",
    "uw77j35x4d.skadnetwork",
    "578prtvx9j.skadnetwork",
    "4dzt52r2t5.skadnetwork",
    "gta9lk7p23.skadnetwork",
    "e5fvkxwrpn.skadnetwork",
    "zq492l623r.skadnetwork",
    "3qcr597p9d.skadnetwork",
    "3rd42ekr43.skadnetwork",
]

// 単体テストと審査用の録画では広告の同意・ATT を出さない。
let noAdsArguments: Arguments = .arguments(launchArguments: [.launchArgument(name: "-noAds", isEnabled: true)])

let project = Project(
    name: "GeckoLog",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
        ]
    ),
    targets: [
        .target(
            name: "GeckoLog",
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.geckolog",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": .dictionary([:]),
                    "CFBundleDisplayName": "げこログ",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": .string(marketingVersion),
                    "CFBundleVersion": .string(buildNumber),
                    "ITSAppUsesNonExemptEncryption": false,
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    // AdMob のアプリ ID（pub-6105029932689433 に 2026-11-12 登録）。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~9601976006",
                    // トラッキング許可（ATT）のダイアログに出す説明。
                    "NSUserTrackingUsageDescription": "広告をあなたに合った内容にするために使います。許可しなくても、げこログのすべての機能を使えます。",
                    "SKAdNetworkItems": .array(
                        skAdNetworkIDs.map { .dictionary(["SKAdNetworkIdentifier": .string($0)]) }
                    ),
                ]
            ),
            buildableFolders: [
                "GeckoLog/Sources",
                "GeckoLog/Resources",
            ],
            dependencies: [
                // UserMessagingPlatform（同意フォーム）は GoogleMobileAds に付いてくる。
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "GeckoLogTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.geckolog.tests",
            infoPlist: .default,
            buildableFolders: ["GeckoLog/Tests"],
            dependencies: [.target(name: "GeckoLog")]
        ),
        // 審査用の画面収録で、新規インストールからの流れを毎回同じ手順で操作する。
        .target(
            name: "GeckoLogUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "tech.sesame.geckolog.uitests",
            infoPlist: .default,
            buildableFolders: ["GeckoLog/UITests"],
            dependencies: [.target(name: "GeckoLog")]
        ),
    ],
    schemes: [
        .scheme(
            name: "GeckoLog",
            shared: true,
            buildAction: .buildAction(targets: ["GeckoLog"]),
            testAction: .targets(["GeckoLogTests"], arguments: noAdsArguments)
        ),
        .scheme(
            name: "GeckoLogReviewWalkthrough",
            shared: true,
            buildAction: .buildAction(targets: ["GeckoLog", "GeckoLogUITests"]),
            testAction: .targets(["GeckoLogUITests"], arguments: noAdsArguments, configuration: .release)
        ),
    ]
)
