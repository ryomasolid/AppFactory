import GoogleMobileAds
import SwiftUI
import UIKit

extension View {
    /// 画面の下にバナーを足す。広告が来るまでは場所をとらない。
    func adStrip(_ gate: AdGate) -> some View {
        modifier(AdStripModifier(gate: gate))
    }
}

private struct AdStripModifier: ViewModifier {
    let gate: AdGate
    @State private var bannerHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .contentMargins(.bottom, bannerHeight, for: .scrollContent)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if gate.phase == .ready {
                    GeometryReader { geo in
                        AdBannerView(unitID: gate.unitID, width: geo.size.width) { h in
                            withAnimation(.easeOut(duration: 0.25)) { bannerHeight = h }
                        }
                    }
                    .frame(height: bannerHeight)
                    .background {
                        // iOS 26 の浮いたタブバーとのすき間を埋める。
                        if bannerHeight > 0 { Palette.paper.ignoresSafeArea(edges: .bottom) }
                    }
                }
            }
    }
}

private struct AdBannerView: UIViewRepresentable {
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
        guard width > 0, context.coordinator.loadedWidth != width else { return }
        context.coordinator.loadedWidth = width
        if banner.rootViewController == nil {
            banner.rootViewController = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController
        }
        banner.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        banner.load(GADRequest())
    }

    /// バナー自身の大きさを返す（0 を渡すと SDK が高さ 0 で読みなおして失敗をくり返す）。
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: GADBannerView, context: Context) -> CGSize? {
        let w = proposal.width ?? width
        guard w > 0 else { return nil }
        return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(w).size
    }

    final class Coordinator: NSObject, GADBannerViewDelegate {
        var loadedWidth: CGFloat = 0
        private var shown = false
        private let onHeight: (CGFloat) -> Void

        init(onHeight: @escaping (CGFloat) -> Void) { self.onHeight = onHeight }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            shown = true
            onHeight(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: any Error) {
            // いちど出たあとは、更新に失敗しても前の広告を残す。
            if !shown { onHeight(0) }
        }
    }
}
