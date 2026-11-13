import GoogleMobileAds
import SwiftUI
import UIKit

extension View {
    /// 画面の下に広告の帯を敷く。広告が届くまでは場所を取らない。
    func adStrip(_ consent: AdConsent) -> some View {
        modifier(AdStripSlot(consent: consent))
    }
}

private struct AdStripSlot: ViewModifier {
    let consent: AdConsent
    @State private var bannerHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            // List / ScrollView の最後の行が帯に隠れないよう、帯の高さだけ下に余白を足す。
            .contentMargins(.bottom, bannerHeight, for: .scrollContent)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if consent.phase == .ready {
                    AdStrip(unitID: consent.unitID, height: $bannerHeight)
                }
            }
    }
}

extension AdConsent {
    /// Google のサンプル用（アダプティブバナー）。
    static let testUnit = "ca-app-pub-3940256099942544/2435281174"
    /// AdMob「NemukeQuest Banner」（2026-11-13 作成）。
    static let bannerUnit = "ca-app-pub-6105029932689433/5308732532"

    var unitID: String {
        #if DEBUG
        Self.testUnit
        #else
        isSandbox ? Self.testUnit : Self.bannerUnit
        #endif
    }
}

private struct AdStrip: View {
    let unitID: String
    @Binding var height: CGFloat

    var body: some View {
        GeometryReader { geo in
            BannerHost(unitID: unitID, width: geo.size.width) { newHeight in
                withAnimation(.easeOut(duration: 0.2)) { height = newHeight }
            }
        }
        .frame(height: height)
        // iOS 26 の浮いたタブバーとの間から中身が透けないよう、帯の下まで地の色で塗る。
        .background {
            if height > 0 { Palette.background.ignoresSafeArea(edges: .bottom) }
        }
    }
}

private struct BannerHost: UIViewRepresentable {
    let unitID: String
    let width: CGFloat
    let reportHeight: (CGFloat) -> Void

    func makeCoordinator() -> Listener { Listener(reportHeight: reportHeight) }

    func makeUIView(context: Context) -> GADBannerView {
        let view = GADBannerView()
        view.adUnitID = unitID
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ view: GADBannerView, context: Context) {
        // 幅が決まった（変わった）ときだけ頼み直す。
        guard width > 0, context.coordinator.requestedWidth != width else { return }
        context.coordinator.requestedWidth = width
        view.rootViewController = view.window?.rootViewController
            ?? UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.windows.first?.rootViewController }.first
        view.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        view.load(GADRequest())
    }

    /// 広告のサイズに固定する。帯の高さ（届く前は0）に合わせると SDK が高さ0で頼み直して失敗し続ける。
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: GADBannerView, context: Context) -> CGSize? {
        let w = proposal.width ?? width
        guard w > 0 else { return nil }
        return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(w).size
    }

    final class Listener: NSObject, GADBannerViewDelegate {
        var requestedWidth: CGFloat = 0
        private var hasShown = false
        let reportHeight: (CGFloat) -> Void

        init(reportHeight: @escaping (CGFloat) -> Void) { self.reportHeight = reportHeight }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            hasShown = true
            reportHeight(bannerView.adSize.size.height)
        }

        /// 一度出たあとの更新の失敗では帯を畳まない（前の広告が見えたまま）。
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: any Error) {
            if !hasShown { reportHeight(0) }
        }
    }
}
