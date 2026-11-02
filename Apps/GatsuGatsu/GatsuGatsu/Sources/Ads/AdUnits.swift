import Foundation

/// 広告ユニットIDの置き場所。
enum AdUnits {
    enum Kind: CaseIterable {
        case banner, native, interstitial, rewarded, appOpen
    }

    /// 本番のユニットID（AdMob のアプリ「ガツガツグルメ」）。
    /// 5つそろっていないと App Store 版は広告を出さない。テスト広告を本番へ出してしまうより安全なので。
    static let production: [Kind: String] = [
        .banner: "ca-app-pub-6105029932689433/8399397947",
        .native: "ca-app-pub-6105029932689433/9524330245",
        .interstitial: "ca-app-pub-6105029932689433/7086316276",
        .rewarded: "ca-app-pub-6105029932689433/5773234609",
        .appOpen: "ca-app-pub-6105029932689433/6964569335",
    ]

    /// Google が公開しているテスト用ユニット。
    static let test: [Kind: String] = [
        .banner: "ca-app-pub-3940256099942544/2435281174",
        .native: "ca-app-pub-3940256099942544/3986624511",
        .interstitial: "ca-app-pub-3940256099942544/4411468910",
        .rewarded: "ca-app-pub-3940256099942544/1712485313",
        .appOpen: "ca-app-pub-3940256099942544/5575463023",
    ]
}
