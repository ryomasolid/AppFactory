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
    name: "HamuhamuDiary",
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
            name: "HamuhamuDiary",
            // 旧 React Native 版（App移管前の ryomasolid 時代）も iPhone 専用。
            destinations: [.iPhone],
            product: .app,
            // 既存アプリのアップデートとして出すため、旧版のバンドルIDをそのまま使う。
            // 変えると別アプリ扱いになり、ユーザー・レビュー・端末内の日記が引き継げない。
            bundleId: "com.ryomasolid.hamuhamudiary",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "Background",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "はむ日記",
                    "CFBundleDevelopmentRegion": "ja",
                    // ストアの公開版が 1.3（React Native 版）なので、Swift 版は 2.0 から。
                    "CFBundleShortVersionString": "2.0",
                    "CFBundleVersion": "1",
                    "ITSAppUsesNonExemptEncryption": false,
                    // AdMob のアプリID。TODO: 自分の AdMob アカウントでアプリを登録したら差し替える
                    // （現在は移管前の旧アカウントのもの。`BannerAdView` のユニットIDも同様）。
                    "GADApplicationIdentifier": "ca-app-pub-3362493734697220~7622911129",
                    // 広告のトラッキング許可（ATT）ダイアログの説明文。
                    "NSUserTrackingUsageDescription": "あなたに関連性の高い広告を表示するために使用します。許可しなくてもアプリの機能はご利用いただけます。",
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "SKAdNetworkItems": .array(
                        skAdNetworkIDs.map { .dictionary(["SKAdNetworkIdentifier": .string($0)]) }
                    ),
                ]
            ),
            buildableFolders: [
                "HamuhamuDiary/Sources",
                "HamuhamuDiary/Resources",
            ],
            dependencies: [
                // UserMessagingPlatform は GoogleMobileAds 経由で利用できる（transitive）。
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "HamuhamuDiaryTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.ryomasolid.hamuhamudiary.tests",
            infoPlist: .default,
            buildableFolders: [
                "HamuhamuDiary/Tests"
            ],
            dependencies: [.target(name: "HamuhamuDiary")]
        ),
    ],
    schemes: [
        .scheme(
            name: "HamuhamuDiary",
            shared: true,
            buildAction: .buildAction(targets: ["HamuhamuDiary"]),
            testAction: .targets(["HamuhamuDiaryTests"])
        ),
    ]
)
