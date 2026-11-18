import GoogleMobileAds
import SwiftUI
import UIKit

extension View {
    /// 画面の下にアダプティブバナー。広告が来るまでは場所をとらない。
    func withBanner(_ ads: AdsReady) -> some View {
        modifier(BannerArea(ads: ads))
    }
}

private struct BannerArea: ViewModifier {
    let ads: AdsReady
    @State private var bannerHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .contentMargins(.bottom, bannerHeight, for: .scrollContent)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if ads.stage == .ready {
                    GeometryReader { geo in
                        AdaptiveBanner(unit: ads.bannerUnit, width: geo.size.width) { h in
                            withAnimation(.easeOut(duration: 0.2)) { bannerHeight = h }
                        }
                    }
                    .frame(height: bannerHeight)
                    // iOS 26 の浮いたタブバーとのすき間を、下まで塗りつぶす。
                    .background { if bannerHeight > 0 { Hue.card.ignoresSafeArea(edges: .bottom) } }
                }
            }
    }
}

private struct AdaptiveBanner: UIViewRepresentable {
    let unit: String
    let width: CGFloat
    let onHeight: (CGFloat) -> Void

    func makeCoordinator() -> Listener { Listener(onHeight) }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView()
        banner.adUnitID = unit
        banner.delegate = context.coordinator
        return banner
    }

    func updateUIView(_ banner: GADBannerView, context: Context) {
        let listener = context.coordinator
        guard width > 0, listener.loadedWidth != width else { return }
        listener.loadedWidth = width
        if banner.rootViewController == nil {
            banner.rootViewController = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
        }
        banner.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        banner.load(GADRequest())
    }

    /// 枠の高さ0のまま SDK に渡すと、高さ0で頼みなおして失敗しつづけるので、広告の大きさで置く。
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: GADBannerView, context: Context) -> CGSize? {
        guard let w = proposal.width ?? (width > 0 ? width : nil), w > 0 else { return nil }
        return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(w).size
    }

    final class Listener: NSObject, GADBannerViewDelegate {
        var loadedWidth: CGFloat = 0
        private var shownOnce = false
        private let onHeight: (CGFloat) -> Void

        init(_ onHeight: @escaping (CGFloat) -> Void) { self.onHeight = onHeight }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            shownOnce = true
            onHeight(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: any Error) {
            // 一度出たあとは、更新に失敗しても前の広告を残す。
            if !shownOnce { onHeight(0) }
        }
    }
}
