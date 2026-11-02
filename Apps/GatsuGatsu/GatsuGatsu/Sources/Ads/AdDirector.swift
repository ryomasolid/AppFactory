import AppTrackingTransparency
import GoogleMobileAds
import Observation
import StoreKit
import UIKit
import UserMessagingPlatform

/// 広告全体の司令塔。同意の確認、全画面広告の読み込みと表示、リワードのほうびを受け持つ。
/// バナーと記事内広告は、`showsAds` を見て自分で出す（BannerStrip / SponsoredCard）。
@MainActor
@Observable
final class AdDirector: NSObject {
    enum Phase: Equatable {
        case idle, asking
        /// 広告を出せる。
        case ready
        /// 同意が得られない・本番IDが未設定・撮影用などで広告を出さない。
        case off
    }

    /// リワード広告で受け取れるもの。どちらも、見たい人だけが自分で押したときに流す。
    enum Reward: Equatable {
        case adFree
        case monthReport

        static let adFreeDuration: TimeInterval = 2 * 60 * 60
        static let monthReportDuration: TimeInterval = 24 * 60 * 60
    }

    private(set) var phase: Phase = UserDefaults.standard.bool(forKey: "hideAds") ? .off : .idle
    private(set) var rewardedReady = false
    private(set) var adFreeUntil: Date
    private(set) var monthReportUntil: Date
    /// EU など、あとから同意を変更する導線が必要な地域か。
    private(set) var needsPrivacyOptions = false

    private var units: [AdUnits.Kind: String] = [:]
    private var pacing: AdPacing
    private var interstitial: InterstitialAd?
    private var appOpen: (ad: AppOpenAd, loadedAt: Date)?
    private var rewarded: RewardedAd?
    private var isLoadingInterstitial = false
    private var isLoadingAppOpen = false
    private var isLoadingRewarded = false
    private var rewardRetryDelay: TimeInterval = 30
    private var presenting: Presenting?
    private var rewardContinuation: CheckedContinuation<Bool, Never>?
    private var rewardEarned = false
    private var wentToBackgroundAt: Date?
    private var expiryTask: Task<Void, Never>?
    @ObservationIgnored private let defaults: UserDefaults

    private enum Presenting { case interstitial, appOpen, rewarded }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        adFreeUntil = defaults.object(forKey: "ads.adFreeUntil") as? Date ?? .distantPast
        monthReportUntil = defaults.object(forKey: "ads.monthReportUntil") as? Date ?? .distantPast
        if let data = defaults.data(forKey: "ads.pacing"), let saved = try? JSONDecoder().decode(AdPacing.self, from: data) {
            pacing = saved
        } else {
            pacing = AdPacing()
        }
        super.init()
        pacing.noteLaunch()
        savePacing()
        scheduleExpiry()
    }

    // MARK: - 状態

    var isAdFree: Bool { adFreeUntil > .now }
    /// バナー・記事内広告・全画面広告を出してよいか。リワードだけは広告オフ中も流せる。
    var showsAds: Bool { phase == .ready && !isAdFree }
    /// 月のまとめが開いているか。広告を出せない状態なら見られなくしない（行き止まりを作らない）。
    var monthReportOpen: Bool { phase == .off || monthReportUntil > .now }

    func unitID(_ kind: AdUnits.Kind) -> String? { units[kind] }

    /// 記事の内容に合った広告が出やすいよう、サイトの同じ記事の URL と話題を添える。
    static func request(path: String? = nil) -> Request {
        let request = Request()
        request.keywords = ["グルメ", "ラーメン", "外食", "デカ盛り", "食べ放題"]
        if let path { request.contentURL = "https://gatsugatsu-gurume.com\(path)" }
        return request
    }

    // MARK: - 起動

    /// 同意の確認 → トラッキング許可 → SDK の起動。最初の画面を描いたあとに1度だけ呼ぶ。
    func begin() async {
        guard phase == .idle else { return }
        phase = .asking

        guard let resolved = await resolveUnits() else {
            phase = .off
            return
        }
        units = resolved

        let consent = ConsentInformation.shared
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false
        do {
            try await consent.requestConsentInfoUpdate(with: parameters)
            if !Self.skipsConsentPrompts {
                try await ConsentForm.loadAndPresentIfRequired(from: Self.topController())
            }
        } catch {
            // 通信できないときなど。前回の同意が残っていれば広告は出せる。
        }
        needsPrivacyOptions = consent.privacyOptionsRequirementStatus == .required
        guard consent.canRequestAds || Self.skipsConsentPrompts else {
            phase = .off
            return
        }

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined, !Self.skipsConsentPrompts {
            // 画面の切り替わりと重なると ATT が出ないことがある。
            try? await Task.sleep(for: .milliseconds(700))
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }

        await MobileAds.shared.start()
        phase = .ready
        loadInterstitialIfNeeded()
        loadAppOpenIfNeeded()
        loadRewardedIfNeeded()
    }

    /// どのユニットを使うか。開発中と TestFlight はテスト広告。App Store 版は本番IDがなければ広告なし。
    private func resolveUnits() async -> [AdUnits.Kind: String]? {
        #if DEBUG || targetEnvironment(simulator)
        return AdUnits.test
        #else
        if case .verified(let transaction)? = try? await AppTransaction.shared, transaction.environment == .sandbox {
            return AdUnits.test
        }
        return AdUnits.production.count == AdUnits.Kind.allCases.count ? AdUnits.production : nil
        #endif
    }

    /// 同意の内容を変更する画面を開く（設定から）。
    func presentPrivacyOptions() async {
        try? await ConsentForm.presentPrivacyOptionsForm(from: Self.topController())
    }

    // MARK: - インタースティシャル

    /// 記事やツールを読み終えて、一覧へ戻ったときに呼ぶ。
    func pageFinished() {
        pacing.notePageFinished()
        savePacing()
        let paced = Self.pacingDisabled || pacing.allowsInterstitial()
        guard showsAds, paced, let ad = interstitial, presenting == nil else {
            loadInterstitialIfNeeded()
            return
        }
        // 戻るアニメーションが終わってから出す（押しまちがいを防ぐ）。
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard let controller = Self.idleController(), self.presenting == nil else { return }
            self.interstitial = nil
            self.presenting = .interstitial
            self.pacing.noteInterstitialShown()
            self.savePacing()
            ad.present(from: controller)
        }
    }

    private func loadInterstitialIfNeeded() {
        guard showsAds, interstitial == nil, !isLoadingInterstitial, let id = units[.interstitial] else { return }
        isLoadingInterstitial = true
        Task {
            defer { isLoadingInterstitial = false }
            guard let ad = try? await InterstitialAd.load(with: id, request: Self.request()) else { return }
            ad.fullScreenContentDelegate = self
            interstitial = ad
        }
    }

    // MARK: - アプリ起動広告

    func sceneWentToBackground() {
        wentToBackgroundAt = .now
        loadAppOpenIfNeeded()
    }

    /// バックグラウンドから戻ったとき。しばらく離れていたときだけ、読み込み済みの広告を出す。
    func sceneCameBack() {
        guard let leftAt = wentToBackgroundAt else { return }
        wentToBackgroundAt = nil
        let paced = Self.pacingDisabled || pacing.allowsAppOpen(awayFor: Date.now.timeIntervalSince(leftAt))
        guard showsAds, paced, presenting == nil, let stored = appOpen,
              Date.now.timeIntervalSince(stored.loadedAt) < 4 * 60 * 60,   // 4時間を過ぎた広告は無効になる
              let controller = Self.idleController() else {
            loadInterstitialIfNeeded()
            return
        }
        appOpen = nil
        presenting = .appOpen
        pacing.noteAppOpenShown()
        savePacing()
        stored.ad.present(from: controller)
    }

    private func loadAppOpenIfNeeded() {
        let stale = appOpen.map { Date.now.timeIntervalSince($0.loadedAt) >= 4 * 60 * 60 } ?? true
        guard showsAds, stale, !isLoadingAppOpen, let id = units[.appOpen] else { return }
        isLoadingAppOpen = true
        Task {
            defer { isLoadingAppOpen = false }
            guard let ad = try? await AppOpenAd.load(with: id, request: Self.request()) else { return }
            ad.fullScreenContentDelegate = self
            appOpen = (ad, .now)
        }
    }

    // MARK: - リワード

    /// 広告を最後まで見たら、ほうびを渡して true を返す。
    @discardableResult
    func watch(for reward: Reward) async -> Bool {
        guard let ad = rewarded, let controller = Self.topController(), presenting == nil else { return false }
        rewarded = nil
        rewardedReady = false
        presenting = .rewarded
        rewardEarned = false
        let earned = await withCheckedContinuation { continuation in
            rewardContinuation = continuation
            ad.present(from: controller) { [weak self] in
                self?.rewardEarned = true
            }
        }
        if earned { grant(reward) }
        return earned
    }

    private func grant(_ reward: Reward) {
        switch reward {
        case .adFree:
            adFreeUntil = .now.addingTimeInterval(Reward.adFreeDuration)
            defaults.set(adFreeUntil, forKey: "ads.adFreeUntil")
            scheduleExpiry()
        case .monthReport:
            monthReportUntil = .now.addingTimeInterval(Reward.monthReportDuration)
            defaults.set(monthReportUntil, forKey: "ads.monthReportUntil")
        }
    }

    /// 広告オフの時間が切れた瞬間に、バナーなどが戻るようにする。
    private func scheduleExpiry() {
        expiryTask?.cancel()
        let until = adFreeUntil
        guard until > .now else { return }
        expiryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(until.timeIntervalSinceNow + 1))
            guard !Task.isCancelled, let self else { return }
            self.adFreeUntil = .distantPast
            self.loadInterstitialIfNeeded()
            self.loadAppOpenIfNeeded()
        }
    }

    private func loadRewardedIfNeeded() {
        guard phase == .ready, rewarded == nil, !isLoadingRewarded, let id = units[.rewarded] else { return }
        isLoadingRewarded = true
        Task {
            defer { isLoadingRewarded = false }
            do {
                let ad = try await RewardedAd.load(with: id, request: Self.request())
                ad.fullScreenContentDelegate = self
                rewarded = ad
                rewardedReady = true
                rewardRetryDelay = 30
            } catch {
                // 在庫がない・電波がない。間隔を広げながら試し直す。
                let delay = rewardRetryDelay
                rewardRetryDelay = min(delay * 2, 600)
                Task {
                    try? await Task.sleep(for: .seconds(delay))
                    self.loadRewardedIfNeeded()
                }
            }
        }
    }

    // MARK: - 共通

    private func savePacing() {
        if let data = try? JSONEncoder().encode(pacing) { defaults.set(data, forKey: "ads.pacing") }
    }

    private func finishPresentation() {
        let finished = presenting
        presenting = nil
        if finished == .rewarded {
            pacing.noteFullScreen()
            savePacing()
            rewardContinuation?.resume(returning: rewardEarned)
            rewardContinuation = nil
        }
        loadInterstitialIfNeeded()
        loadAppOpenIfNeeded()
        loadRewardedIfNeeded()
    }

    /// 動作確認用。-adPaceOff を付けて起動すると、回数と間隔の制限を外す。
    private static var pacingDisabled: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "adPaceOff")
        #else
        false
        #endif
    }

    /// 動作確認用。-skipATT を付けて起動すると、同意と ATT のダイアログを出さない。
    private static var skipsConsentPrompts: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "skipATT")
        #else
        false
        #endif
    }

    static func topController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    /// シートなどを開いていないときだけ返す。使っている途中に全画面広告を割り込ませない。
    private static func idleController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let root = scene?.keyWindow?.rootViewController, root.presentedViewController == nil else { return nil }
        return root
    }
}

extension AdDirector: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in finishPresentation() }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in finishPresentation() }
    }
}
