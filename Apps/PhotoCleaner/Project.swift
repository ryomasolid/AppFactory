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
                    "CFBundleDisplayName": "PhotoCleaner",
                    // 写真は完全オンデバイスで処理し、外部送信しない旨をユーザーに伝える。
                    "NSPhotoLibraryUsageDescription": "重複・類似した写真を端末内だけで検出し、削除候補として表示するために写真ライブラリにアクセスします。写真が端末外に送信されることはありません。",
                    // AdMob アプリID（本番）。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~3939645937",
                    // 広告のトラッキング許可（ATT）ダイアログの説明文。
                    "NSUserTrackingUsageDescription": "あなたに関連性の高い広告を表示するために使用します。許可しなくてもアプリの機能はご利用いただけます。",
                    "SKAdNetworkItems": .array(
                        skAdNetworkIDs.map { .dictionary(["SKAdNetworkIdentifier": .string($0)]) }
                    ),
                ]
            ),
            buildableFolders: [
                "PhotoCleaner/Sources",
                "PhotoCleaner/Resources",
            ],
            dependencies: [
                // UserMessagingPlatform は GoogleMobileAds 経由で利用できる（transitive）。
                .external(name: "GoogleMobileAds"),
            ]
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
    ],
    schemes: [
        .scheme(
            name: "PhotoCleaner",
            shared: true,
            buildAction: .buildAction(targets: ["PhotoCleaner"]),
            testAction: .targets(["PhotoCleanerTests"]),
            // ローカルで課金フローをテストするための StoreKit 設定。
            runAction: .runAction(options: .options(storeKitConfigurationPath: "PhotoCleaner.storekit"))
        ),
    ]
)
