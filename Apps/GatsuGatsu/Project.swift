import ProjectDescription

// AdMob の計測用 SKAdNetwork。https://developers.google.com/admob/ios/quick-start の一覧（2026-11-02 時点）。
// ATT を断った人の広告単価はこれで決まるので、省略せず全部入れる。
let skAdNetworks = [
    "cstr6suwn9", "4fzdc2evr5", "2fnua5tdw4", "ydx93a7ass", "p78axxw29g", "v72qych5uu", "ludvb6z3bs",
    "cp8zw746q7", "3sh42y64q3", "c6k4g5qg8m", "s39g8k73mm", "wg4vff78zm", "3qy4746246", "f38h382jlk",
    "hs6bdukanm", "mlmmfzh3r3", "v4nxqhlyqp", "wzmmz9fp6w", "su67r6k2v3", "yclnxrl5pm", "t38b2kh725",
    "7ug5zh24hu", "gta9lk7p23", "vutu7akeur", "y5ghdn5j9k", "v9wttpbfk9", "n38lu8286q", "47vhws6wlr",
    "kbd757ywx3", "9t245vhmpl", "a2p9lx4jpn", "22mmun2rn5", "44jx6755aq", "k674qkevps", "4468km3ulz",
    "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5", "ppxm28t8ap", "kbmxgpxpgc", "uw77j35x4d", "578prtvx9j",
    "4dzt52r2t5", "tl55sbb4fm", "c3frkrj4fj", "e5fvkxwrpn", "8c4e2ghe7u", "3rd42ekr43", "97r2b46745",
    "3qcr597p9d",
]

let project = Project(
    name: "GatsuGatsu",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        ],
        configurations: [
            // 開発中は Google のテスト用アプリID。本番の広告を自分で押してしまわないように。
            .debug(name: .debug, settings: ["GAD_APP_ID": "ca-app-pub-3940256099942544~1458002511"]),
            .release(name: .release, settings: ["GAD_APP_ID": "ca-app-pub-6105029932689433~8295009058"]),
        ]
    ),
    targets: [
        .target(
            name: "GatsuGatsu",
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.gatsugatsu",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": ["UIColorName": "Paper", "UIImageName": ""],
                "CFBundleDisplayName": "ガツガツグルメ",
                "CFBundleDevelopmentRegion": "ja",
                "CFBundleShortVersionString": "1.0",
                "CFBundleVersion": "2",
                "ITSAppUsesNonExemptEncryption": false,
                "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                "GADApplicationIdentifier": "$(GAD_APP_ID)",
                "NSUserTrackingUsageDescription": "お店やグルメなど、興味に近い広告を出すために使います。許可しなくても、すべての機能をそのまま使えます。",
                "SKAdNetworkItems": .array(skAdNetworks.map { .dictionary(["SKAdNetworkIdentifier": .string("\($0).skadnetwork")]) }),
            ]),
            buildableFolders: ["GatsuGatsu/Sources", "GatsuGatsu/Resources"],
            dependencies: [.external(name: "GoogleMobileAds")]
        ),
        .target(
            name: "GatsuGatsuTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.gatsugatsu.tests",
            infoPlist: .default,
            buildableFolders: ["GatsuGatsu/Tests"],
            dependencies: [.target(name: "GatsuGatsu")]
        ),
    ],
    schemes: [
        .scheme(
            name: "GatsuGatsu",
            shared: true,
            buildAction: .buildAction(targets: ["GatsuGatsu"]),
            testAction: .targets(["GatsuGatsuTests"])
        ),
    ]
)
