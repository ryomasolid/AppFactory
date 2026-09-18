import ProjectDescription

// AdMob 広告計測用の SKAdNetwork 識別子。Google の公式リストに合わせて随時更新する。
// （不足しても計測範囲が狭まるだけで害はない。最新の完全なリストは AdMob のドキュメント参照）
let skAdNetworkIDs: [String] = [
    "cstr6suwn9.skadnetwork",
    "4fzdc2evr5.skadnetwork",
    "2u9pt9hc89.skadnetwork",
    "8s468mfl3y.skadnetwork",
    "klf5c3l5u5.skadnetwork",
    "ppxm28t8ap.skadnetwork",
    "424m5254lk.skadnetwork",
    "uw77j35x4d.skadnetwork",
    "578prtvx9j.skadnetwork",
    "4dzt52r2t5.skadnetwork",
    "gta9lk7p23.skadnetwork",
    "e5fvkxwrpn.skadnetwork",
    "zq492l623r.skadnetwork",
    "3qcr597p9d.skadnetwork",
    "3rd42ekr43.skadnetwork",
]

let project = Project(
    name: "TeikiCheck",
    settings: .settings(
        base: [
            // 自動署名と開発チームを固定し、tuist generate で署名設定が消えないようにする。
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            // SwiftUI 等の文字列を String Catalog へ自動抽出する。
            "SWIFT_EMIT_LOC_STRINGS": "YES",
        ]
    ),
    targets: [
        .target(
            name: "TeikiCheck",
            destinations: .iOS,
            product: .app,
            bundleId: "tech.sesame.teikicheck",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "定期チェック",
                    "CFBundleDevelopmentRegion": "ja",
                    // AdMob の app-ads.txt 検証に App Store のマーケティングURL が必須だが、
                    // 配信済み 1.0 ではメタデータを編集できないため 1.0.1 を出して設定する。
                    // （1.0 は審査リジェクト対応でビルド 2 まで使っている。）
                    "CFBundleShortVersionString": "1.0.1",
                    "CFBundleVersion": "3",
                    "ITSAppUsesNonExemptEncryption": false,
                    // AdMob アプリID（本番）。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~2706062104",
                    // 広告のトラッキング許可（ATT）ダイアログの説明文。
                    "NSUserTrackingUsageDescription": "あなたに関連性の高い広告を表示するために使用します。許可しなくてもアプリの機能はご利用いただけます。",
                    "SKAdNetworkItems": .array(
                        skAdNetworkIDs.map { .dictionary(["SKAdNetworkIdentifier": .string($0)]) }
                    ),
                ]
            ),
            buildableFolders: [
                "TeikiCheck/Sources",
                "TeikiCheck/Resources",
            ],
            dependencies: [
                // UserMessagingPlatform は GoogleMobileAds 経由で利用できる（transitive）。
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "TeikiCheckTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "tech.sesame.teikicheck.tests",
            infoPlist: .default,
            buildableFolders: [
                "TeikiCheck/Tests"
            ],
            dependencies: [.target(name: "TeikiCheck")]
        ),
    ],
    schemes: [
        .scheme(
            name: "TeikiCheck",
            shared: true,
            buildAction: .buildAction(targets: ["TeikiCheck"]),
            testAction: .targets(["TeikiCheckTests"]),
            // ローカルで課金フローをテストするための StoreKit 設定。
            runAction: .runAction(options: .options(storeKitConfigurationPath: "TeikiCheck.storekit"))
        ),
    ]
)
