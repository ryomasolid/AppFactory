import GoogleMobileAds
import SwiftUI
import UIKit

extension View {
    /// 画面の下にバナーを置く。広告が届くまでは高さ0で、場所をとらない。
    func bannerBelow(_ gate: AdGate) -> some View {
        modifier(BannerBelow(gate: gate))
    }
}

private struct BannerBelow: ViewModifier {
    let gate: AdGate
    @State private var shown: CGFloat = 0

    func body(content: Content) -> some View {
        content
            // スクロールのいちばん下がバナーの裏に入らないように。
            .contentMargins(.bottom, shown, for: .scrollContent)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if gate.state == .open {
                    GeometryReader { geo in
                        AdaptiveBanner(unitID: gate.bannerID, width: geo.size.width) { height in
                            withAnimation(.easeOut(duration: 0.25)) { shown = height }
                        }
                    }
                    .frame(height: shown)
                    .background {
                        // iOS 26 の浮いたタブバーのすき間から中身が透けないように塗る。
                        if shown > 0 { Tone.card.ignoresSafeArea(edges: .bottom) }
                    }
                }
            }
    }
}

private struct AdaptiveBanner: UIViewRepresentable {
    let unitID: String
    let width: CGFloat
    let onHeight: (CGFloat) -> Void

    func makeCoordinator() -> Relay { Relay(onHeight: onHeight) }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView()
        banner.adUnitID = unitID
        banner.delegate = context.coordinator
        return banner
    }

    func updateUIView(_ banner: GADBannerView, context: Context) {
        guard width > 0, width != context.coordinator.loadedWidth else { return }
        context.coordinator.loadedWidth = width
        banner.rootViewController = banner.window?.rootViewController
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.keyWindow?.rootViewController
        banner.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        banner.load(GADRequest())
    }

    /// 枠の高さ（届く前は0）ではなく、広告そのものの大きさを返す。
    /// 0 を渡すと SDK が高さ0で頼みなおして、ずっと失敗する。
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: GADBannerView, context: Context) -> CGSize? {
        let w = proposal.width ?? width
        return w > 0 ? GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(w).size : nil
    }

    final class Relay: NSObject, GADBannerViewDelegate {
        var loadedWidth: CGFloat = 0
        private var everShown = false
        private let onHeight: (CGFloat) -> Void

        init(onHeight: @escaping (CGFloat) -> Void) { self.onHeight = onHeight }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            everShown = true
            onHeight(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: any Error) {
            // 一度出たあとの更新の失敗では閉じない（前の広告のまま）。
            if !everShown { onHeight(0) }
        }
    }
}
