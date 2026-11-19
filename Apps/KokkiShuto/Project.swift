import ProjectDescription

let marketingVersion = "1.0"
let buildNumber = "1"

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
                ]
            ),
            buildableFolders: ["KokkiShuto/Sources", "KokkiShuto/Resources"]
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
            testAction: .targets(["KokkiShutoTests"])
        ),
        // 審査用の画面収録（Release）。
        .scheme(
            name: "KokkiShutoTour",
            shared: true,
            buildAction: .buildAction(targets: ["KokkiShuto", "KokkiShutoUITests"]),
            testAction: .targets(["KokkiShutoUITests"], configuration: .release)
        ),
    ]
)
