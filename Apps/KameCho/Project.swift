import ProjectDescription

let marketingVersion = "1.0"
let buildNumber = "1"

/// AdMob の案内にある SKAdNetwork の ID。
let skNetworks = [
    "cstr6suwn9", "4fzdc2evr5", "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5",
    "ppxm28t8ap", "424m5254lk", "uw77j35x4d", "578prtvx9j", "4dzt52r2t5",
    "gta9lk7p23", "e5fvkxwrpn", "zq492l623r", "3qcr597p9d", "3rd42ekr43",
]

/// 単体テスト・審査用の録画は、同意画面・ATT・バナーなしで動かす。
let withoutAds: Arguments = .arguments(launchArguments: [.launchArgument(name: "-noAds", isEnabled: true)])

let project = Project(
    name: "KameCho",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
        ]
    ),
    targets: [
        .target(
            name: "KameCho",
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.kamecho",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": .dictionary([:]),
                    "CFBundleDisplayName": "カメ帳",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": .string(marketingVersion),
                    "CFBundleVersion": .string(buildNumber),
                    "ITSAppUsesNonExemptEncryption": false,
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    // TODO: AdMob に「カメ帳」を登録したら差しかえる（いまは Google のテスト用 ID）。
                    "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511",
                    "NSUserTrackingUsageDescription": "あなたに合った広告を出すために使います。許可しなくても、カメ帳はすべての機能を使えます。",
                    "SKAdNetworkItems": .array(skNetworks.map { .dictionary(["SKAdNetworkIdentifier": .string("\($0).skadnetwork")]) }),
                ]
            ),
            buildableFolders: ["KameCho/Sources", "KameCho/Resources"],
            dependencies: [.external(name: "GoogleMobileAds")]
        ),
        .target(
            name: "KameChoTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.kamecho.tests",
            infoPlist: .default,
            buildableFolders: ["KameCho/Tests"],
            dependencies: [.target(name: "KameCho")]
        ),
        .target(
            name: "KameChoUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "tech.sesame.kamecho.uitests",
            infoPlist: .default,
            buildableFolders: ["KameCho/UITests"],
            dependencies: [.target(name: "KameCho")]
        ),
    ],
    schemes: [
        .scheme(
            name: "KameCho",
            shared: true,
            buildAction: .buildAction(targets: ["KameCho"]),
            testAction: .targets(["KameChoTests"], arguments: withoutAds)
        ),
        // 審査に添える画面収録（Release で流す）。
        .scheme(
            name: "KameChoWalkthrough",
            shared: true,
            buildAction: .buildAction(targets: ["KameCho", "KameChoUITests"]),
            testAction: .targets(["KameChoUITests"], arguments: withoutAds, configuration: .release)
        ),
    ]
)
