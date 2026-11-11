import GoogleMobileAds
import SwiftUI
import UIKit

extension View {
    /// 画面の下（タブバーのすぐ上）にバナーの棚を置く。中身は棚の上で止まる。
    func bannerShelf(_ gate: AdGate) -> some View {
        modifier(BannerShelfModifier(gate: gate))
    }
}

private struct BannerShelfModifier: ViewModifier {
    let gate: AdGate
    @State private var shelfHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            // NavigationStack の中の List や ScrollView には safeAreaInset の高さが伝わらず、
            // 一番下までスクロールしても最後の行が棚の裏に隠れる。棚の高さぶんの余白を中身に足す。
            .contentMargins(.bottom, shelfHeight, for: .scrollContent)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BannerShelf(gate: gate, height: $shelfHeight)
            }
    }
}

/// バナーを載せる棚。門（`AdGate`）が開くまでは何も置かず、広告が届いてはじめて高さを持つ。
/// 届かなかったときは高さ0のまま（砂色の画面に灰色の空き枠を残さない）。
struct BannerShelf: View {
    let gate: AdGate
    @Binding var height: CGFloat

    /// Google のテスト用ユニット（アダプティブバナー）。Debug と TestFlight ではこちらを使う。
    private static let sampleUnit = "ca-app-pub-3940256099942544/2435281174"
    /// AdMob の「GeckoLog Banner」（2026-11-12 作成）。
    private static let liveUnit = "ca-app-pub-6105029932689433/1723485985"

    private var unit: String {
        #if DEBUG
        Self.sampleUnit
        #else
        gate.sandboxed ? Self.sampleUnit : Self.liveUnit
        #endif
    }

    var body: some View {
        if gate.door == .open {
            GeometryReader { proxy in
                BannerBox(unit: unit, width: proxy.size.width) { newHeight in
                    withAnimation(.easeInOut(duration: 0.25)) { height = newHeight }
                }
            }
            .frame(height: height)
            // iOS 26 のタブバーは中身の上に浮くので、棚の下（タブバーの裏）まで塗って
            // 棚とタブバーのすきまから中身が透けないようにする。
            .background {
                if height > 0 { Terrarium.card.ignoresSafeArea(edges: .bottom) }
            }
        }
    }
}

/// GADBannerView を載せる箱。幅が決まったとき（変わったとき）にだけ読み込み直す。
private struct BannerBox: UIViewRepresentable {
    let unit: String
    let width: CGFloat
    let onHeight: (CGFloat) -> Void

    func makeCoordinator() -> Keeper { Keeper(onHeight: onHeight) }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView()
        banner.adUnitID = unit
        banner.delegate = context.coordinator
        return banner
    }

    func updateUIView(_ banner: GADBannerView, context: Context) {
        let keeper = context.coordinator
        guard width > 0, width != keeper.loadedWidth else { return }
        keeper.loadedWidth = width
        banner.rootViewController = banner.window?.rootViewController ?? Self.anyRoot()
        banner.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        banner.load(GADRequest())
    }

    /// GADBannerView の intrinsicContentSize は頼んだ広告の倍になることがあり、そのままだと棚からはみ出す。
    /// 棚の幅と、その幅のアダプティブバナーの高さに固定する。棚の高さ（届く前は0）には合わせない。
    /// 高さ0を返すと SDK が (幅, 0) で頼み直して失敗し続け、棚が二度と開かなくなる。
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: GADBannerView, context: Context) -> CGSize? {
        let width = proposal.width ?? width
        guard width > 0 else { return nil }
        return CGSize(width: width, height: GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width).size.height)
    }

    private static func anyRoot() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
    }

    final class Keeper: NSObject, GADBannerViewDelegate {
        var loadedWidth: CGFloat = 0
        /// 一度でも広告が届いたか。届いたあとの自動更新が失敗しても前の広告は見えたままなので、棚は畳まない。
        private var received = false
        let onHeight: (CGFloat) -> Void

        init(onHeight: @escaping (CGFloat) -> Void) { self.onHeight = onHeight }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            received = true
            onHeight(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: any Error) {
            if !received { onHeight(0) }
        }
    }
}
