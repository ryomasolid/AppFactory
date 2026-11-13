import ProjectDescription

// ストアの公開版は 1.2（React Native 版「Nemuke Quest」）。Swift 版は 2.0 から。
let marketingVersion = "2.0"
let buildNumber = "1"

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
                ]
            ),
            buildableFolders: [
                "NemukeQuest/Sources",
                "NemukeQuest/Resources",
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
    ],
    schemes: [
        .scheme(
            name: "NemukeQuest",
            shared: true,
            buildAction: .buildAction(targets: ["NemukeQuest"]),
            testAction: .targets(["NemukeQuestTests"])
        ),
    ]
)
