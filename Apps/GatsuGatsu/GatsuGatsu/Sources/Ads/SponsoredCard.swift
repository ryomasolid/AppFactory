import GoogleMobileAds
import Observation
import SwiftUI

/// 記事内・一覧内のネイティブ広告の受け取り口。同じ枠は開き直しても同じ広告を使い回し、古くなったら取り替える。
@MainActor
@Observable
final class SponsoredCardBroker: NSObject {
    private struct Entry {
        let ad: NativeAd
        let loadedAt: Date
    }

    /// 枠ごとに持つ広告の上限。古いものから捨てる。
    private static let maxStored = 12
    /// これより古い広告は、枠を開き直したときに取り替える（Google の目安は1時間で無効）。
    private static let maxAge: TimeInterval = 30 * 60

    private var entries: [String: Entry] = [:]
    @ObservationIgnored private var loaders: [ObjectIdentifier: (loader: AdLoader, slot: String)] = [:]
    @ObservationIgnored private var inFlight: Set<String> = []

    func ad(for slot: String) -> NativeAd? { entries[slot]?.ad }

    func fetch(slot: String, path: String?, unit: String) {
        if let entry = entries[slot], Date.now.timeIntervalSince(entry.loadedAt) < Self.maxAge { return }
        guard !inFlight.contains(slot) else { return }
        inFlight.insert(slot)
        let loader = AdLoader(adUnitID: unit, rootViewController: AdDirector.topController(), adTypes: [.native], options: nil)
        loader.delegate = self
        loaders[ObjectIdentifier(loader)] = (loader, slot)
        loader.load(AdDirector.request(path: path))
    }

    private func store(_ ad: NativeAd, slot: String) {
        entries[slot] = Entry(ad: ad, loadedAt: .now)
        guard entries.count > Self.maxStored else { return }
        let oldest = entries.filter { $0.key != slot }.min { $0.value.loadedAt < $1.value.loadedAt }
        if let oldest { entries[oldest.key] = nil }
    }

    private func finish(_ loader: AdLoader) -> String? {
        guard let slot = loaders.removeValue(forKey: ObjectIdentifier(loader))?.slot else { return nil }
        inFlight.remove(slot)
        return slot
    }
}

extension SponsoredCardBroker: NativeAdLoaderDelegate {
    nonisolated func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        MainActor.assumeIsolated {
            if let slot = finish(adLoader) { store(nativeAd, slot: slot) }
        }
    }

    nonisolated func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        // 届かなかった枠は何も出さない（空の枠を残さない）。
        MainActor.assumeIsolated { _ = finish(adLoader) }
    }
}

/// 一覧や記事に混ぜる広告カード。届くまでは高さを持たない。
struct SponsoredCard: View {
    let slot: String
    var path: String? = nil
    @Environment(AdDirector.self) private var ads
    @Environment(SponsoredCardBroker.self) private var broker
    @State private var width: CGFloat = 0

    var body: some View {
        Group {
            if ads.showsAds, let ad = broker.ad(for: slot), width > 0 {
                SponsoredCardHost(ad: ad)
                    .frame(height: SponsoredCardView.height(forWidth: width))
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay { RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.35), lineWidth: 1) }
            } else {
                Color.clear.frame(height: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .onAppear(perform: fetch)
        .onChange(of: ads.showsAds) { fetch() }
    }

    private func fetch() {
        guard ads.showsAds, let unit = ads.unitID(.native) else { return }
        broker.fetch(slot: slot, path: path, unit: unit)
    }
}

private struct SponsoredCardHost: UIViewRepresentable {
    let ad: NativeAd

    func makeUIView(context: Context) -> SponsoredCardView { SponsoredCardView() }

    func updateUIView(_ view: SponsoredCardView, context: Context) {
        if view.nativeAd !== ad { view.fill(with: ad) }
    }
}

/// ネイティブ広告の中身。「広告」の表示、メディア、見出し、ボタンを必ず同じ並びで出す。
final class SponsoredCardView: NativeAdView {
    private static let padding: CGFloat = 12
    private static let textBlockHeight: CGFloat = 18 + 8 + 8 + 44 + 4 + 36 + 8 + 40

    /// 高さを先に決めておくと、広告が届いたときに本文のレイアウトが一度で決まる。
    static func height(forWidth width: CGFloat) -> CGFloat {
        let inner = max(width - padding * 2, 120)
        return padding * 2 + textBlockHeight + inner * 9 / 16
    }

    private let badge = UILabel()
    private let advertiser = UILabel()
    private let media = MediaView()
    private let icon = UIImageView()
    private let headline = UILabel()
    private let bodyText = UILabel()
    private let action = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(named: "Card")

        badge.text = " 広告 "
        badge.font = .systemFont(ofSize: 11, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = .systemGray
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true

        advertiser.font = .systemFont(ofSize: 12)
        advertiser.textColor = .secondaryLabel
        icon.layer.cornerRadius = 8
        icon.clipsToBounds = true
        media.contentMode = .scaleAspectFit
        media.clipsToBounds = true
        headline.font = .systemFont(ofSize: 15, weight: .bold)
        headline.numberOfLines = 2
        bodyText.font = .systemFont(ofSize: 13)
        bodyText.textColor = .secondaryLabel
        bodyText.numberOfLines = 2

        action.font = .systemFont(ofSize: 15, weight: .bold)
        action.textColor = .white
        action.textAlignment = .center
        action.backgroundColor = .tintColor
        action.layer.cornerRadius = 10
        action.clipsToBounds = true

        for view in [badge, advertiser, media, icon, headline, bodyText, action] as [UIView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        let pad = Self.padding
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: topAnchor, constant: pad),
            badge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
            badge.heightAnchor.constraint(equalToConstant: 18),
            advertiser.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            advertiser.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 6),
            // 右上は AdChoices のアイコンが乗るので空ける。
            advertiser.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -36),

            media.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 8),
            media.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
            media.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),
            media.heightAnchor.constraint(equalTo: media.widthAnchor, multiplier: 9.0 / 16.0),

            icon.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 8),
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
            icon.widthAnchor.constraint(equalToConstant: 44),
            icon.heightAnchor.constraint(equalToConstant: 44),
            headline.topAnchor.constraint(equalTo: icon.topAnchor),
            headline.heightAnchor.constraint(equalToConstant: 44),
            headline.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            headline.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),

            bodyText.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 4),
            bodyText.heightAnchor.constraint(equalToConstant: 36),
            bodyText.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
            bodyText.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),

            action.topAnchor.constraint(equalTo: bodyText.bottomAnchor, constant: 8),
            action.heightAnchor.constraint(equalToConstant: 40),
            action.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
            action.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),
        ])
        headlineView = headline
        bodyView = bodyText
        mediaView = media
        iconView = icon
        advertiserView = advertiser
        callToActionView = action
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func fill(with ad: NativeAd) {
        headline.text = ad.headline
        bodyText.text = ad.body
        advertiser.text = ad.advertiser
        icon.image = ad.icon?.image
        icon.isHidden = ad.icon == nil
        media.mediaContent = ad.mediaContent
        action.text = ad.callToAction
        action.isHidden = ad.callToAction == nil
        // タップは NativeAdView が受ける。子の UILabel は反応させない。
        action.isUserInteractionEnabled = false
        // 最後に入れる。これで SDK が各部品を広告として認識する。
        nativeAd = ad
    }
}
