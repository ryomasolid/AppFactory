import ProjectDescription

let project = Project(
    name: "PestMap",
    settings: .settings(
        base: [
            // 自動署名と開発チームを固定し、tuist generate で署名設定が消えないようにする。
            "DEVELOPMENT_TEAM": "8F626K46L8",
            "CODE_SIGN_STYLE": "Automatic",
        ]
    ),
    targets: [
        .target(
            name: "PestMap",
            destinations: .iOS,
            product: .app,
            bundleId: "tech.sesame.pestmap",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    // 間取り図を撮影して取り込むためにカメラを使う。
                    "NSCameraUsageDescription": "間取り図を撮影して取り込むためにカメラを使用します。",
                ]
            ),
            buildableFolders: [
                "PestMap/Sources",
                "PestMap/Resources",
            ],
            dependencies: []
        ),
    ]
)
