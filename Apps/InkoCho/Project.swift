import ProjectDescription

let marketingVersion = "1.0.1"
let buildNumber = "2"

/// AdMob が案内している SKAdNetwork。
let networkIDs = [
    "cstr6suwn9", "4fzdc2evr5", "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5",
    "ppxm28t8ap", "424m5254lk", "uw77j35x4d", "578prtvx9j", "4dzt52r2t5",
    "gta9lk7p23", "e5fvkxwrpn", "zq492l623r", "3qcr597p9d", "3rd42ekr43",
]

/// テストと審査用の録画では、広告の同意・ATT・バナーを出さない。
let noAds: Arguments = .arguments(launchArguments: [.launchArgument(name: "-noAds", isEnabled: true)])

let project = Project(
    name: "InkoCho",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
        ]
    ),
    targets: [
        .target(
            name: "InkoCho",
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.inkocho",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": .dictionary([:]),
                    "CFBundleDisplayName": "インコ帳",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": .string(marketingVersion),
                    "CFBundleVersion": .string(buildNumber),
                    "ITSAppUsesNonExemptEncryption": false,
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "NSCameraUsageDescription": "インコの写真を撮って、きょうの記録に残すために使います。写真はこの端末の中にだけ保存します。",
                    // AdMob「インコ帳」（2026-11-17 登録・ストア未掲載で作成）。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~5697232465",
                    "NSUserTrackingUsageDescription": "興味に合った広告を出すために使います。許可しなくても、インコ帳はすべての機能を使えます。",
                    "SKAdNetworkItems": .array(networkIDs.map { .dictionary(["SKAdNetworkIdentifier": .string($0 + ".skadnetwork")]) }),
                ]
            ),
            buildableFolders: ["InkoCho/Sources", "InkoCho/Resources"],
            dependencies: [.external(name: "GoogleMobileAds")]
        ),
        .target(
            name: "InkoChoTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.inkocho.tests",
            infoPlist: .default,
            buildableFolders: ["InkoCho/Tests"],
            dependencies: [.target(name: "InkoCho")]
        ),
        .target(
            name: "InkoChoUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "tech.sesame.inkocho.uitests",
            infoPlist: .default,
            buildableFolders: ["InkoCho/UITests"],
            dependencies: [.target(name: "InkoCho")]
        ),
    ],
    schemes: [
        .scheme(
            name: "InkoCho",
            shared: true,
            buildAction: .buildAction(targets: ["InkoCho"]),
            testAction: .targets(["InkoChoTests"], arguments: noAds)
        ),
        // 審査用の画面収録（Release）。
        .scheme(
            name: "InkoChoTour",
            shared: true,
            buildAction: .buildAction(targets: ["InkoCho", "InkoChoUITests"]),
            testAction: .targets(["InkoChoUITests"], arguments: noAds, configuration: .release)
        ),
    ]
)
