import GoogleMobileAds
import SwiftUI
import UIKit

extension View {
    /// 中身の下（タブバーのすぐ上）に広告の帯を差し込む。中身は帯の上で止まる。
    func adStrip(_ permission: AdPermission) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) { AdStrip(permission: permission) }
    }
}

/// タブバーの上に置く広告の帯。
///
/// `AdPermission` が `.ready` になるまでは何も置かず、広告が届いてはじめて高さを持つ。
/// 届かなかったときは高さ0のまま（クリーム地に灰色の空き枠を残さない）。
struct AdStrip: View {
    let permission: AdPermission
    @State private var bannerHeight: CGFloat = 0

    #if DEBUG
    private let unitID = "ca-app-pub-3940256099942544/2934735716"  // Google のテスト用ユニット
    #else
    private let unitID = "ca-app-pub-6105029932689433/4525015975"
    #endif

    var body: some View {
        if permission.phase == .ready {
            GeometryReader { proxy in
                BannerHost(unitID: unitID, width: proxy.size.width) { height in
                    withAnimation(.easeInOut(duration: 0.25)) { bannerHeight = height }
                }
            }
            .frame(height: bannerHeight)
            // iOS 26 のタブバーは中身の上に浮くので、帯の下（タブバーの裏）も塗りつぶして
            // 広告とタブバーのすきまに中身が透けて見えないようにする。
            .background {
                if bannerHeight > 0 { Theme.card.ignoresSafeArea(edges: .bottom) }
            }
        }
    }
}

/// GADBannerView を載せる UIView。幅が決まったとき（変わったとき）にだけ読み込み直す。
private struct BannerHost: UIViewRepresentable {
    let unitID: String
    let width: CGFloat
    let onHeight: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onHeight: onHeight) }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView()
        banner.adUnitID = unitID
        banner.delegate = context.coordinator
        return banner
    }

    func updateUIView(_ banner: GADBannerView, context: Context) {
        let coordinator = context.coordinator
        guard width > 0, width != coordinator.requestedWidth else { return }
        coordinator.requestedWidth = width
        banner.rootViewController = banner.window?.rootViewController ?? Self.fallbackRoot()
        banner.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        banner.load(GADRequest())
    }

    private static func fallbackRoot() -> UIViewController? {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
    }

    final class Coordinator: NSObject, GADBannerViewDelegate {
        var requestedWidth: CGFloat = 0
        let onHeight: (CGFloat) -> Void

        init(onHeight: @escaping (CGFloat) -> Void) { self.onHeight = onHeight }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            onHeight(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: any Error) {
            onHeight(0)
        }
    }
}
