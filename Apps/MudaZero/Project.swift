import ProjectDescription

let marketingVersion = "1.0"
let buildNumber = "1"

/// AdMob が案内している SKAdNetwork。
let networkIDs = [
    "cstr6suwn9", "4fzdc2evr5", "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5",
    "ppxm28t8ap", "424m5254lk", "uw77j35x4d", "578prtvx9j", "4dzt52r2t5",
    "gta9lk7p23", "e5fvkxwrpn", "zq492l623r", "3qcr597p9d", "3rd42ekr43",
]

/// テストと審査用の録画では、広告の同意・ATT・バナーを出さない。
let quiet: Arguments = .arguments(launchArguments: [.launchArgument(name: "-noAds", isEnabled: true)])

let project = Project(
    name: "MudaZero",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
        ]
    ),
    targets: [
        .target(
            name: "MudaZero",
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.mudazero",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": .dictionary([:]),
                    "CFBundleDisplayName": "ムダゼロ",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": .string(marketingVersion),
                    "CFBundleVersion": .string(buildNumber),
                    "ITSAppUsesNonExemptEncryption": false,
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    // TODO: AdMob に「ムダゼロ」を登録したら本物のアプリ ID にする（いまは Google のサンプル）。
                    "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511",
                    "NSUserTrackingUsageDescription": "興味に合った広告を出すために使います。許可しなくても、ムダゼロはすべての機能を使えます。",
                    "SKAdNetworkItems": .array(networkIDs.map { .dictionary(["SKAdNetworkIdentifier": .string($0 + ".skadnetwork")]) }),
                ]
            ),
            buildableFolders: ["MudaZero/Sources", "MudaZero/Resources"],
            dependencies: [.external(name: "GoogleMobileAds")]
        ),
        .target(
            name: "MudaZeroTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.mudazero.tests",
            infoPlist: .default,
            buildableFolders: ["MudaZero/Tests"],
            dependencies: [.target(name: "MudaZero")]
        ),
        .target(
            name: "MudaZeroUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "tech.sesame.mudazero.uitests",
            infoPlist: .default,
            buildableFolders: ["MudaZero/UITests"],
            dependencies: [.target(name: "MudaZero")]
        ),
    ],
    schemes: [
        .scheme(
            name: "MudaZero",
            shared: true,
            buildAction: .buildAction(targets: ["MudaZero"]),
            testAction: .targets(["MudaZeroTests"], arguments: quiet)
        ),
        // 審査用の画面収録（Release）。
        .scheme(
            name: "MudaZeroTour",
            shared: true,
            buildAction: .buildAction(targets: ["MudaZero", "MudaZeroUITests"]),
            testAction: .targets(["MudaZeroUITests"], arguments: quiet, configuration: .release)
        ),
    ]
)
