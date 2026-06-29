import GoogleMobileAds
import SwiftUI
import UIKit

/// AdMob バナー広告（無料ユーザー向け）。
/// 現在は Google のテスト用ユニットID。本番は自分の AdMob ユニットIDに差し替える。
struct BannerAdView: UIViewRepresentable {
    /// 開発中（DEBUG）は Google のテストユニット、リリースは本番ユニットを使う。
    /// （自分の実広告を誤クリックして無効トラフィック扱いになるのを防ぐ）
    static var defaultUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        return "ca-app-pub-6105029932689433/6374237580"
        #endif
    }
    var unitID: String = defaultUnitID

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = unitID
        banner.rootViewController = Self.rootViewController()
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    private static func rootViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.keyWindow?.rootViewController
    }
}
