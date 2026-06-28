import ProjectDescription

let project = Project(
    name: "PhotoCleaner",
    settings: .settings(
        base: [
            // 自動署名と開発チームを固定し、tuist generate で署名設定が消えないようにする。
            "DEVELOPMENT_TEAM": "8F626K46L8",
            "CODE_SIGN_STYLE": "Automatic",
        ]
    ),
    targets: [
        .target(
            name: "PhotoCleaner",
            destinations: .iOS,
            product: .app,
            bundleId: "tech.sesame.photocleaner",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    // 写真は完全オンデバイスで処理し、外部送信しない旨をユーザーに伝える。
                    "NSPhotoLibraryUsageDescription": "重複・類似した写真を端末内だけで検出し、削除候補として表示するために写真ライブラリにアクセスします。写真が端末外に送信されることはありません。",
                ]
            ),
            buildableFolders: [
                "PhotoCleaner/Sources",
                "PhotoCleaner/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "PhotoCleanerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "tech.sesame.photocleaner.tests",
            infoPlist: .default,
            buildableFolders: [
                "PhotoCleaner/Tests"
            ],
            dependencies: [.target(name: "PhotoCleaner")]
        ),
    ]
)
