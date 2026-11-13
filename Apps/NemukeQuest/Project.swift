import ProjectDescription

// ストアの公開版は 1.2（React Native 版「Nemuke Quest」）。Swift 版は 2.0 から。
let marketingVersion = "2.0"
let buildNumber = "2"

/// AdMob が案内している SKAdNetwork の ID。広告の効果計測に使う。
let adNetworks = [
    "cstr6suwn9", "4fzdc2evr5", "2u9pt9hc89", "8s468mfl3y", "klf5c3l5u5",
    "ppxm28t8ap", "424m5254lk", "uw77j35x4d", "578prtvx9j", "4dzt52r2t5",
    "gta9lk7p23", "e5fvkxwrpn", "zq492l623r", "3qcr597p9d", "3rd42ekr43",
]

/// テストでは 広告まわり（同意・ATT・バナー）を起こさない。
let quietLaunch: Arguments = .arguments(launchArguments: [.launchArgument(name: "-quiet", isEnabled: true)])

let project = Project(
    name: "NemukeQuest",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
        ]
    ),
    targets: [
        .target(
            name: "NemukeQuest",
            // 旧 RN 版が iPad 対応（supportsTablet）で出ていたので、アップデートも iPad を外せない。
            destinations: [.iPhone, .iPad],
            product: .app,
            // 既存アプリ（旧 React Native 版）のアップデートとして出すため、旧版のバンドルIDをそのまま使う。
            // 変えると別アプリ扱いになり、ユーザー・レビュー・端末内のレベルや連続記録が引き継げない。
            bundleId: "com.ryomasolid.nemukequest",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": .dictionary(["UIColorName": "LaunchBackground"]),
                    "CFBundleDisplayName": "ねむけクエスト",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": .string(marketingVersion),
                    "CFBundleVersion": .string(buildNumber),
                    "ITSAppUsesNonExemptEncryption": false,
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "UISupportedInterfaceOrientations~ipad": .array([.string("UIInterfaceOrientationPortrait")]),
                    // iPad でも縦向き固定にするため、Split View には出さない。
                    "UIRequiresFullScreen": true,
                    "UIUserInterfaceStyle": "Dark",
                    // AdMob「Nemuke Quest」（2026-11-13 登録・App Store にリンク）。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~1148840721",
                    "NSUserTrackingUsageDescription": "あなたの興味に近い広告を出すために使います。許可しなくても、ねむけクエストはすべて遊べます。",
                    "SKAdNetworkItems": .array(
                        adNetworks.map { .dictionary(["SKAdNetworkIdentifier": .string("\($0).skadnetwork")]) }
                    ),
                ]
            ),
            buildableFolders: [
                "NemukeQuest/Sources",
                "NemukeQuest/Resources",
            ],
            dependencies: [
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "NemukeQuestTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.ryomasolid.nemukequest.tests",
            infoPlist: .default,
            buildableFolders: ["NemukeQuest/Tests"],
            dependencies: [.target(name: "NemukeQuest")]
        ),
        // リワード広告がひと回り動くかを確かめる UI テスト（広告を本当に読み込むので、ふだんのテストとは分ける）。
        .target(
            name: "NemukeQuestUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "com.ryomasolid.nemukequest.uitests",
            infoPlist: .default,
            buildableFolders: ["NemukeQuest/UITests"],
            dependencies: [.target(name: "NemukeQuest")]
        ),
    ],
    schemes: [
        .scheme(
            name: "NemukeQuest",
            shared: true,
            buildAction: .buildAction(targets: ["NemukeQuest"]),
            testAction: .targets(["NemukeQuestTests"], arguments: quietLaunch)
        ),
        .scheme(
            name: "NemukeQuestRewardedTour",
            shared: true,
            buildAction: .buildAction(targets: ["NemukeQuest", "NemukeQuestUITests"]),
            testAction: .targets(["NemukeQuestUITests"])
        ),
    ]
)
