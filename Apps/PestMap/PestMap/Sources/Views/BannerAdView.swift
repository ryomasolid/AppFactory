import GoogleMobileAds
import SwiftUI
import UIKit

/// AdMob アダプティブ・アンカー・バナー（画面幅に最適化）。
/// 開発中（DEBUG）は Google のテストユニット、リリースは本番ユニットを使う。
struct BannerAdView: View {
    private static var unitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        return "ca-app-pub-6105029932689433/3834301789"
        #endif
    }

    private var adSize: GADAdSize {
        GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(UIScreen.main.bounds.width)
    }

    var body: some View {
        Representable(adSize: adSize, unitID: Self.unitID)
            .frame(height: adSize.size.height)
    }

    private struct Representable: UIViewRepresentable {
        let adSize: GADAdSize
        let unitID: String

        func makeUIView(context: Context) -> GADBannerView {
            let banner = GADBannerView(adSize: adSize)
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
}
