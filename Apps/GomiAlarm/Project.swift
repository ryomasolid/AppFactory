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
    name: "GomiAlarm",
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
            name: "GomiAlarm",
            // ゴミ出しは iPhone で完結する用途なので iPhone 専用にし、iPad 用スクショ/レイアウト対応の工数を削る。
            destinations: [.iPhone],
            product: .app,
            bundleId: "tech.sesame.gomialarm",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "ゴミの日アラーム",
                    "CFBundleDevelopmentRegion": "ja",
                    "CFBundleShortVersionString": "1.0",
                    "CFBundleVersion": "1",
                    "ITSAppUsesNonExemptEncryption": false,
                    // TODO: AdMob で GomiAlarm 用のアプリを新規作成し、本番のアプリIDに差し替える。
                    "GADApplicationIdentifier": "ca-app-pub-6105029932689433~0000000000",
                    // 広告のトラッキング許可（ATT）ダイアログの説明文。
                    "NSUserTrackingUsageDescription": "あなたに関連性の高い広告を表示するために使用します。許可しなくてもアプリの機能はご利用いただけます。",
                    // 縦持ち固定（カレンダー/リストのレイアウトを1パターンに絞る）。
                    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                    "SKAdNetworkItems": .array(
                        skAdNetworkIDs.map { .dictionary(["SKAdNetworkIdentifier": .string($0)]) }
                    ),
                    // 具体日で登録した通知の窓（120日）が枯れる前に、バックグラウンドで組み直すため。
                    // 識別子は BackgroundRefresh.taskID と一致させること。
                    "BGTaskSchedulerPermittedIdentifiers": .array([.string("tech.sesame.gomialarm.refresh")]),
                    "UIBackgroundModes": .array([.string("fetch")]),
                ]
            ),
            buildableFolders: [
                "GomiAlarm/Sources",
                "GomiAlarm/Resources",
            ],
            dependencies: [
                // UserMessagingPlatform は GoogleMobileAds 経由で利用できる（transitive）。
                .external(name: "GoogleMobileAds"),
            ]
        ),
        .target(
            name: "GomiAlarmTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "tech.sesame.gomialarm.tests",
            infoPlist: .default,
            buildableFolders: [
                "GomiAlarm/Tests"
            ],
            dependencies: [.target(name: "GomiAlarm")]
        ),
    ],
    schemes: [
        .scheme(
            name: "GomiAlarm",
            shared: true,
            buildAction: .buildAction(targets: ["GomiAlarm"]),
            testAction: .targets(["GomiAlarmTests"]),
            // ローカルで課金フローをテストするための StoreKit 設定。
            runAction: .runAction(options: .options(storeKitConfigurationPath: "GomiAlarm.storekit"))
        ),
    ]
)
