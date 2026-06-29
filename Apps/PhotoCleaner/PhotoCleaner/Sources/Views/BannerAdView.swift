import GoogleMobileAds
import SwiftUI
import UIKit

/// AdMob バナー広告（無料ユーザー向け）。
/// 現在は Google のテスト用ユニットID。本番は自分の AdMob ユニットIDに差し替える。
struct BannerAdView: UIViewRepresentable {
    static let testUnitID = "ca-app-pub-3940256099942544/2934735716"
    var unitID: String = testUnitID

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
