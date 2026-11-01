import GoogleMobileAds
import SwiftUI
import UIKit

/// 画面の上に出す バナー広告。下には 十字キーと コマンドが あって 押しまちがえやすいので、上に置く。
///
/// 広告が届く前や 届かないときも 高さは 変えない（遊んでいる途中で 地図や 敵の絵が ずれないように）。
/// 空いているあいだは ただの黒い帯になる。
struct TopBannerAd: View {
    #if DEBUG
    // Google の テスト用 ユニット。開発中に 本番の広告を 押してしまわないように。
    private static let unitID = "ca-app-pub-3940256099942544/2435281174"
    #else
    private static let unitID = "ca-app-pub-6105029932689433/8549325778"
    #endif

    @State private var width: CGFloat = 0

    var body: some View {
        Color.black
            .frame(height: width > 0 ? BannerHost.size(width: width).height : 50)
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .overlay {
                if width > 0 {
                    BannerHost(unitID: Self.unitID, width: width)
                }
            }
    }
}

/// BannerView を載せる。幅が決まったとき（変わったとき）にだけ 読み込みなおす。
private struct BannerHost: UIViewRepresentable {
    let unitID: String
    let width: CGFloat

    static func size(width: CGFloat) -> CGSize {
        currentOrientationAnchoredAdaptiveBanner(width: width).size
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = unitID
        banner.delegate = context.coordinator
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        let coordinator = context.coordinator
        guard width > 0, width != coordinator.requestedWidth else { return }
        coordinator.requestedWidth = width
        banner.rootViewController = banner.window?.rootViewController ?? Self.fallbackRoot()
        banner.adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
        banner.load(Request())
    }

    /// BannerView 自身の大きさは 頼んだ広告より 大きくなることがあるので、帯の大きさに そろえる。
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BannerView, context: Context) -> CGSize? {
        Self.size(width: proposal.width ?? width)
    }

    private static func fallbackRoot() -> UIViewController? {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.rootViewController
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var requestedWidth: CGFloat = 0

        /// 一度も届かないと 自動更新が 始まらないので、しばらくして もう一度 ためす（電波がない・在庫がない）。
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak bannerView] in
                guard let bannerView, bannerView.window != nil, bannerView.responseInfo == nil else { return }
                bannerView.load(Request())
            }
        }
    }
}
