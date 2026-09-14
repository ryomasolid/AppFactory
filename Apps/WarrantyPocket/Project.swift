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
    name: "WarrantyPocket",
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
            name: "WarrantyPocket",
            // 保証書をその場で撮って登録する用途なので iPhone 専用。iPad 対応の工数とスクショ枚数を削る。
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.warrantypocket",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "保証書ポケット",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": "1.0",
                    "CFBundleVersion": "1",
                    "ITSAppUsesNonExemptEncryption": false,
                    // AdMob の本番アプリID（保証書ポケット）。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~3449310861",
                    // 書類スキャン（VisionKit）で使う。写真の取り込みは PhotosPicker なので写真ライブラリの許可は不要。
                    "NSCameraUsageDescription": "保証書やレシートを撮影して登録するために使用します。",
                    // 広告のトラッキング許可（ATT）ダイアログの説明文。
                    "NSUserTrackingUsageDescription": "あなたに関連性の高い広告を表示するために使用します。許可しなくてもアプリの機能はご利用いただけます。",
                    // 縦持ち固定（入力フォームと写真のレイアウトを1パターンに絞る）。
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "SKAdNetworkItems": .array(
                        skAdNetworkIDs.map { .dictionary(["SKAdNetworkIdentifier": .string($0)]) }
                    ),
                ]
            ),
            buildableFolders: [
                "WarrantyPocket/Sources",
                "WarrantyPocket/Resources",
            ],
            dependencies: [
                // UserMessagingPlatform は GoogleMobileAds 経由で利用できる（transitive）。
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "WarrantyPocketTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.warrantypocket.tests",
            infoPlist: .default,
            buildableFolders: [
                "WarrantyPocket/Tests"
            ],
            dependencies: [.target(name: "WarrantyPocket")]
        ),
    ],
    schemes: [
        .scheme(
            name: "WarrantyPocket",
            shared: true,
            buildAction: .buildAction(targets: ["WarrantyPocket"]),
            testAction: .targets(["WarrantyPocketTests"]),
            // ローカルで課金フローをテストするための StoreKit 設定。
            runAction: .runAction(options: .options(storeKitConfigurationPath: "WarrantyPocket.storekit"))
        ),
    ]
)
