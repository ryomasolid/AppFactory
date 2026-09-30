import GoogleMobileAds
import SwiftUI
import UIKit

/// タブの下に置く無料版のバナー。
///
/// 読み込めるまでは高さ0で、広告が届いてから出す（届かない地域や通信のないときに空白の帯を残さない）。
/// バナーは自分を載せた ViewController を rootViewController にするので、シーンを探し回らない。
struct FooterAd: View {
    @State private var height: CGFloat = 0

    #if DEBUG
    private static let unitID = "ca-app-pub-3940256099942544/2934735716"  // Google のテスト用
    #else
    private static let unitID = "ca-app-pub-6105029932689433/9095945673"
    #endif

    var body: some View {
        GeometryReader { proxy in
            Holder(unitID: Self.unitID, width: proxy.size.width) { loadedHeight in
                withAnimation(.easeOut(duration: 0.2)) { height = loadedHeight }
            }
        }
        .frame(height: height)
        .clipped()
    }

    private struct Holder: UIViewControllerRepresentable {
        let unitID: String
        let width: CGFloat
        let onHeight: (CGFloat) -> Void

        func makeUIViewController(context: Context) -> Controller {
            Controller(unitID: unitID, onHeight: onHeight)
        }

        func updateUIViewController(_ controller: Controller, context: Context) {
            controller.load(width: width)
        }
    }

    final class Controller: UIViewController, GADBannerViewDelegate {
        private let banner = GADBannerView()
        private let onHeight: (CGFloat) -> Void
        private var loadedWidth: CGFloat = 0

        init(unitID: String, onHeight: @escaping (CGFloat) -> Void) {
            self.onHeight = onHeight
            super.init(nibName: nil, bundle: nil)
            banner.adUnitID = unitID
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override func viewDidLoad() {
            super.viewDidLoad()
            banner.delegate = self
            banner.rootViewController = self
            banner.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(banner)
            NSLayoutConstraint.activate([
                banner.topAnchor.constraint(equalTo: view.topAnchor),
                banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ])
        }

        /// 幅が決まってから（変わったときだけ）読み込む。
        func load(width: CGFloat) {
            guard width > 0, width != loadedWidth else { return }
            loadedWidth = width
            banner.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
            banner.load(GADRequest())
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            onHeight(bannerView.adSize.size.height)
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            onHeight(0)
        }
    }
}
