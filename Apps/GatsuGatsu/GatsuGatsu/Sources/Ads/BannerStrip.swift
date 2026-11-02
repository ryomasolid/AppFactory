import GoogleMobileAds
import SwiftUI

extension View {
    /// 画面の下（タブバーのすぐ上）に帯状のバナーを置く。NavigationStack の外側に付ける。
    func bannerStrip(path: String? = nil) -> some View {
        modifier(BannerStripModifier(path: path))
    }
}

/// iOS 26 の浮いたタブバーに広告が重なると、AdMob に「広告の前面に重なるコンテンツ」として
/// 配信を制限される（はむはむ日記で実際に起きた）。必ず各タブの中で safeAreaInset にして、
/// TabView の外に並べたり TabView 自体に付けたりしない。
private struct BannerStripModifier: ViewModifier {
    let path: String?
    @Environment(AdDirector.self) private var ads
    @State private var height: CGFloat = 0
    @State private var keyboardIsUp = false

    /// キーボードのすぐ上に広告が来ると押しまちがえるので、入力中は引っ込める。
    private var visible: Bool { ads.showsAds && !keyboardIsUp }

    func body(content: Content) -> some View {
        content
            .contentMargins(.bottom, visible ? height : 0, for: .scrollContent)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if visible, let unit = ads.unitID(.banner) {
                    GeometryReader { proxy in
                        BannerHost(unit: unit, width: proxy.size.width, path: path) { received in
                            withAnimation(.easeOut(duration: 0.2)) { height = received }
                        }
                    }
                    .frame(height: height)
                    // 浮いたタブバーとのすきまに中身が透けないように塗る。
                    .background { if height > 0 { Color.card.ignoresSafeArea(edges: .bottom) } }
                }
            }
            // 帯を本当に外したときだけ高さを戻す（次は新しいバナーが届いて開く）。
            // onDisappear では戻さない。全画面広告やタブ切り替えでも呼ばれ、同じバナーのまま高さ0で固まる。
            .onChange(of: visible) { _, nowVisible in
                if !nowVisible { height = 0 }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in keyboardIsUp = true }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardIsUp = false }
    }
}

private struct BannerHost: UIViewRepresentable {
    let unit: String
    let width: CGFloat
    let path: String?
    let onHeight: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(path: path, onHeight: onHeight) }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = unit
        banner.delegate = context.coordinator
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        guard width > 0, width != context.coordinator.requestedWidth else { return }
        context.coordinator.requestedWidth = width
        banner.rootViewController = AdDirector.topController()
        banner.adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
        banner.load(AdDirector.request(path: path))
    }

    /// バナー自身が報告する大きさは実際より大きいことがあるので、頼んだ広告の大きさにそろえる。
    /// 帯の高さ（届く前は0）を渡すと SDK が高さ0で頼み直して失敗し続けるので、必ず広告の高さを返す。
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BannerView, context: Context) -> CGSize? {
        let w = proposal.width ?? width
        guard w > 0 else { return nil }
        return currentOrientationAnchoredAdaptiveBanner(width: w).size
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var requestedWidth: CGFloat = 0
        private var received = false
        private let path: String?
        private let onHeight: (CGFloat) -> Void

        init(path: String?, onHeight: @escaping (CGFloat) -> Void) {
            self.path = path
            self.onHeight = onHeight
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            received = true
            onHeight(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            // 一度届いたあとの更新の失敗では、前の広告が出たままなので畳まない。
            guard !received else { return }
            onHeight(0)
            // 一度も届かないと SDK の自動更新が始まらない。少し待って頼み直す。
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak bannerView, path] in
                guard let bannerView, bannerView.window != nil else { return }
                bannerView.load(AdDirector.request(path: path))
            }
        }
    }
}
