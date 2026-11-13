import ProjectDescription

// ストアの公開版は 1.2（React Native 版「dont snack」）。Swift 版は 2.0 から。
let marketingVersion = "2.0"
let buildNumber = "1"

/// AdMob が案内している SKAdNetwork の ID。広告の効果計測に使う。
let adNetworks = [
    "cstr6suwn9", "4fzdc2evr5", "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5",
    "ppxm28t8ap", "424m5254lk", "uw77j35x4d", "578prtvx9j", "4dzt52r2t5",
    "gta9lk7p23", "e5fvkxwrpn", "zq492l623r", "3qcr597p9d", "3rd42ekr43",
]

/// テストでは 広告まわり（同意・ATT・バナー）を起こさない。
let quietLaunch: Arguments = .arguments(launchArguments: [.launchArgument(name: "-quiet", isEnabled: true)])

let project = Project(
    name: "KanshokuStop",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
        ]
    ),
    targets: [
        .target(
            name: "KanshokuStop",
            // 旧 RN 版が iPad 対応（supportsTablet）で出ていたので、アップデートも iPad を外せない。
            destinations: [.iPhone, .iPad],
            product: .app,
            // 既存アプリ（旧 React Native 版）のアップデートとして出すため、旧版のバンドルIDをそのまま使う。
            // 変えると別アプリ扱いになり、ユーザー・レビュー・端末内の記録が引き継げない。
            bundleId: "com.ryomasolid.dontsnack2",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": .dictionary([:]),
                    "CFBundleDisplayName": "間食ストップ",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": .string(marketingVersion),
                    "CFBundleVersion": .string(buildNumber),
                    "ITSAppUsesNonExemptEncryption": false,
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "UISupportedInterfaceOrientations~ipad": .array([.string("UIInterfaceOrientationPortrait")]),
                    // iPad でも縦向き固定にするため、Split View には出さない。
                    "UIRequiresFullScreen": true,
                    // AdMob「Don't snack」（旧 RN 版から使っている ryomasolid の AdMob。app-ads.txt は don-t-snack.web.app）。
                    "GADApplicationIdentifier": "ca-app-pub-3362493734697220~2379722807",
                    "NSUserTrackingUsageDescription": "あなたの興味に近い広告を出すために使います。許可しなくても、間食ストップの機能はすべて使えます。",
                    "SKAdNetworkItems": .array(
                        adNetworks.map { .dictionary(["SKAdNetworkIdentifier": .string("\($0).skadnetwork")]) }
                    ),
                ]
            ),
            buildableFolders: [
                "KanshokuStop/Sources",
                "KanshokuStop/Resources",
            ],
            dependencies: [
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "KanshokuStopTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.ryomasolid.dontsnack2.tests",
            infoPlist: .default,
            buildableFolders: ["KanshokuStop/Tests"],
            dependencies: [.target(name: "KanshokuStop")]
        ),
    ],
    schemes: [
        .scheme(
            name: "KanshokuStop",
            shared: true,
            buildAction: .buildAction(targets: ["KanshokuStop"]),
            testAction: .targets(["KanshokuStopTests"], arguments: quietLaunch)
        ),
    ]
)
