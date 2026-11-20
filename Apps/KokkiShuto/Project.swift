import ProjectDescription

let marketingVersion = "1.0.1"
let buildNumber = "2"

/// AdMob の案内にある SKAdNetwork の ID。
let skNetworks = [
    "cstr6suwn9", "4fzdc2evr5", "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5",
    "ppxm28t8ap", "424m5254lk", "uw77j35x4d", "578prtvx9j", "4dzt52r2t5",
    "gta9lk7p23", "e5fvkxwrpn", "zq492l623r", "3qcr597p9d", "3rd42ekr43",
]

/// 単体テスト・審査用の録画は、バナーなしで動かす。
let withoutAds: Arguments = .arguments(launchArguments: [.launchArgument(name: "-noAds", isEnabled: true)])

let project = Project(
    name: "KokkiShuto",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
        ]
    ),
    targets: [
        .target(
            name: "KokkiShuto",
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.kokkishuto",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": .dictionary([:]),
                    "CFBundleDisplayName": "国旗と首都",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": .string(marketingVersion),
                    "CFBundleVersion": .string(buildNumber),
                    "ITSAppUsesNonExemptEncryption": false,
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    // AdMob「国旗と首都」（2026-11-20 登録・App Store に紐づけ済み）。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~7450487203",
                    "SKAdNetworkItems": .array(skNetworks.map { .dictionary(["SKAdNetworkIdentifier": .string("\($0).skadnetwork")]) }),
                ]
            ),
            buildableFolders: ["KokkiShuto/Sources", "KokkiShuto/Resources"],
            dependencies: [.external(name: "GoogleMobileAds")]
        ),
        .target(
            name: "KokkiShutoTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.kokkishuto.tests",
            infoPlist: .default,
            buildableFolders: ["KokkiShuto/Tests"],
            dependencies: [.target(name: "KokkiShuto")]
        ),
        .target(
            name: "KokkiShutoUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "tech.sesame.kokkishuto.uitests",
            infoPlist: .default,
            buildableFolders: ["KokkiShuto/UITests"],
            dependencies: [.target(name: "KokkiShuto")]
        ),
    ],
    schemes: [
        .scheme(
            name: "KokkiShuto",
            shared: true,
            buildAction: .buildAction(targets: ["KokkiShuto"]),
            testAction: .targets(["KokkiShutoTests"], arguments: withoutAds)
        ),
        // 審査用の画面収録（Release）。
        .scheme(
            name: "KokkiShutoTour",
            shared: true,
            buildAction: .buildAction(targets: ["KokkiShuto", "KokkiShutoUITests"]),
            testAction: .targets(["KokkiShutoUITests"], arguments: withoutAds, configuration: .release)
        ),
    ]
)
