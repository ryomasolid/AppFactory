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
    name: "SubsNote",
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
            name: "SubsNote",
            // 手元で登録・確認するアプリなので iPhone 専用。iPad 対応の工数とスクショ枚数を削る。
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.subsnote",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "サブスク帳",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": "1.0",
                    "CFBundleVersion": "1",
                    "ITSAppUsesNonExemptEncryption": false,
                    // TODO: AdMob にアプリを作成したら本番のアプリIDに差し替える（今は Google のテスト用アプリID）。
                    "GADApplicationIdentifier": "ca-app-pub-3940256099942544~1458002511",
                    // 広告のトラッキング許可（ATT）ダイアログの説明文。
                    "NSUserTrackingUsageDescription": "あなたに関連性の高い広告を表示するために使用します。許可しなくてもアプリの機能はご利用いただけます。",
                    // 縦持ち固定（一覧とカレンダーのレイアウトを1パターンに絞る）。
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "SKAdNetworkItems": .array(
                        skAdNetworkIDs.map { .dictionary(["SKAdNetworkIdentifier": .string($0)]) }
                    ),
                    // 月払いが多いと予約（60件）が2か月弱で尽きるので、バックグラウンドで組み直す。
                    // 識別子は BackgroundRefresh.taskID と一致させること。
                    "BGTaskSchedulerPermittedIdentifiers": .array([.string("tech.sesame.subsnote.refresh")]),
                    "UIBackgroundModes": .array([.string("fetch")]),
                ]
            ),
            buildableFolders: [
                "SubsNote/Sources",
                "SubsNote/Resources",
            ],
            dependencies: [
                // UserMessagingPlatform は GoogleMobileAds 経由で利用できる（transitive）。
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "SubsNoteTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.subsnote.tests",
            infoPlist: .default,
            buildableFolders: [
                "SubsNote/Tests"
            ],
            dependencies: [.target(name: "SubsNote")]
        ),
    ],
    schemes: [
        .scheme(
            name: "SubsNote",
            shared: true,
            buildAction: .buildAction(targets: ["SubsNote"]),
            testAction: .targets(["SubsNoteTests"]),
            // ローカルで課金フローをテストするための StoreKit 設定。
            runAction: .runAction(options: .options(storeKitConfigurationPath: "SubsNote.storekit"))
        ),
    ]
)
