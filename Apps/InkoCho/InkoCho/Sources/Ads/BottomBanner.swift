import GoogleMobileAds
import SwiftUI
import UIKit

extension View {
    /// 下にアダプティブバナー。届くまでは高さ0。
    func withBanner(_ ads: AdsReady) -> some View {
        modifier(BannerSlot(ads: ads))
    }
}

private struct BannerSlot: ViewModifier {
    let ads: AdsReady
    @State private var height: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .contentMargins(.bottom, height, for: .scrollContent)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if ads.step == .done {
                    GeometryReader { proxy in
                        BannerBox(unit: ads.unit, width: proxy.size.width) { h in
                            withAnimation(.easeInOut(duration: 0.2)) { height = h }
                        }
                    }
                    .frame(height: height)
                    // iOS 26 の浮いたタブバーのすき間に中身が見えないよう、下まで塗る。
                    .background { if height > 0 { Hue.card.ignoresSafeArea(edges: .bottom) } }
                }
            }
    }
}

private struct BannerBox: UIViewRepresentable {
    let unit: String
    let width: CGFloat
    let heightChanged: (CGFloat) -> Void

    func makeCoordinator() -> Watcher { Watcher(heightChanged) }

    func makeUIView(context: Context) -> GADBannerView {
        let view = GADBannerView()
        view.adUnitID = unit
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ view: GADBannerView, context: Context) {
        let c = context.coordinator
        guard width > 0, c.width != width else { return }
        c.width = width
        if view.rootViewController == nil {
            view.rootViewController = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
        }
        view.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        view.load(GADRequest())
    }

    /// 広告そのものの大きさで置く（枠の高さ0を渡すと SDK が高さ0で頼みなおして失敗しつづける）。
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: GADBannerView, context: Context) -> CGSize? {
        guard let w = proposal.width ?? (width > 0 ? width : nil), w > 0 else { return nil }
        return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(w).size
    }

    final class Watcher: NSObject, GADBannerViewDelegate {
        var width: CGFloat = 0
        private var gotOne = false
        private let heightChanged: (CGFloat) -> Void

        init(_ heightChanged: @escaping (CGFloat) -> Void) { self.heightChanged = heightChanged }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            gotOne = true
            heightChanged(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: any Error) {
            // 一度出たら、更新に失敗しても前の広告のまま。
            if !gotOne { heightChanged(0) }
        }
    }
}
