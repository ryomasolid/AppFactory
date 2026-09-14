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
    name: "CarLog",
    settings: .settings(
        base: [
            // 自動署名と開発チームを固定し、tuist generate で署名設定が消えないようにする。
            "DEVELOPMENT_TEAM": "ZP3T7MAT5U",
            "CODE_SIGN_STYLE": "Automatic",
            // SwiftUI 等の文字列を String Catalog へ自動抽出する。
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            // これが無いと SwiftUI の Color.accentColor がアセットの色ではなくシステム既定(青)になる。
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        ]
    ),
    targets: [
        .target(
            name: "CarLog",
            // 給油のたびに片手で入力する用途なので iPhone 専用。iPad 対応の工数とスクショ枚数を削る。
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.carlog",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "カーログ",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": "1.0",
                    "CFBundleVersion": "1",
                    "ITSAppUsesNonExemptEncryption": false,
                    // AdMob の本番アプリID（カーログ）。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~4880977884",
                    // 広告のトラッキング許可（ATT）ダイアログの説明文。
                    "NSUserTrackingUsageDescription": "あなたに関連性の高い広告を表示するために使用します。許可しなくてもアプリの機能はご利用いただけます。",
                    // 縦持ち固定（入力フォームとグラフのレイアウトを1パターンに絞る）。
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "SKAdNetworkItems": .array(
                        skAdNetworkIDs.map { .dictionary(["SKAdNetworkIdentifier": .string($0)]) }
                    ),
                ]
            ),
            buildableFolders: [
                "CarLog/Sources",
                "CarLog/Resources",
            ],
            dependencies: [
                // UserMessagingPlatform は GoogleMobileAds 経由で利用できる（transitive）。
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "CarLogTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.carlog.tests",
            infoPlist: .default,
            buildableFolders: [
                "CarLog/Tests"
            ],
            dependencies: [.target(name: "CarLog")]
        ),
    ],
    schemes: [
        .scheme(
            name: "CarLog",
            shared: true,
            buildAction: .buildAction(targets: ["CarLog"]),
            testAction: .targets(["CarLogTests"]),
            // ローカルで課金フローをテストするための StoreKit 設定。
            runAction: .runAction(options: .options(storeKitConfigurationPath: "CarLog.storekit"))
        ),
    ]
)
