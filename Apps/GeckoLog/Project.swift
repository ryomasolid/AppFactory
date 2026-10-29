import ProjectDescription

// 1.0 は広告も課金も載せない（外部 SDK ゼロ）。収益化は承認後のバージョンで考える。
let marketingVersion = "1.0"
let buildNumber = "1"

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
                ]
            ),
            buildableFolders: [
                "GeckoLog/Sources",
                "GeckoLog/Resources",
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
    ],
    schemes: [
        .scheme(
            name: "GeckoLog",
            shared: true,
            buildAction: .buildAction(targets: ["GeckoLog"]),
            testAction: .targets(["GeckoLogTests"])
        ),
    ]
)
