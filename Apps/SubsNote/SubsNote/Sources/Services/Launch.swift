import Foundation
import SwiftData

/// 起動引数（スクリーンショット撮影・デモ用）。
/// すべてローカルの起動引数で制御し、通常のユーザー利用時には一切影響しない。
enum Launch {
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    /// 広告バナーと同意/ATT フローを止める（スクショ撮影用）。
    static var hideAds: Bool { args.contains("-hideAds") }
    /// デモのサブスクを投入する。
    static var isDemo: Bool { args.contains("-demo") }
    /// 起動時にペイウォールを表示（既存アプリと引数名を揃える）。
    static var showPaywall: Bool { args.contains("-showPaywall") }
    /// オンボーディングを強制表示（スクショ撮影用）。
    static var forceOnboarding: Bool { args.contains("-forceOnboarding") }
    /// 追加のプリセット選択画面を開く。
    static var showPresetPicker: Bool { args.contains("-showPresetPicker") }
    /// デモの動画サービス（`demoDetailName`）の詳細を開く。
    static var showDetail: Bool { args.contains("-showDetail") }
    /// カテゴリ別・支払い方法別の内訳を開く（Pro の購入状態に関係なく開く）。
    static var showBreakdown: Bool { args.contains("-showBreakdown") }

    /// オンボーディングの開始ページ（"1"〜"3"、または "trial" / "notifications"）。
    static var onboardingStep: String? { value(after: "-onboardingStep") }
    /// 起動時に選択するタブ（"calendar" / "settings"）。
    static var startTab: String? { value(after: "-startTab") }
    /// 「今日」を固定する（yyyy-MM-dd）。スクショの日付・残り日数を毎回同じにする。
    static var fixedToday: Date? { value(after: "-fixedToday").flatMap { parseDay($0) } }

    static let demoDetailName = "動画プラス"

    private static func value(after flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// "2026-09-14" → その日の正午（日付の境目で揺れないように）。
    static func parseDay(_ text: String, calendar: Calendar = .current) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }

    // MARK: - デモデータ

    /// サービス名は架空にする（スクショに他社の商標を載せない）。
    private struct DemoSubscription {
        var name: String
        var category: SubCategory
        var price: Int
        var cycle: BillingCycle = .month
        /// 次の支払日まで何日か。
        var daysUntilNext: Int = 0
        /// 無料体験の残り日数（体験中のとき）。
        var trialDaysLeft: Int?
        /// 何日前に解約したか（解約済みのとき）。
        var cancelledDaysAgo: Int?
        var payment: PaymentMethod
        var paymentNote: String = ""
    }

    /// いつ撮っても「次の支払い」が近い順に並ぶよう、支払日は今日から逆算する。
    private static let demoSubscriptions: [DemoSubscription] = [
        DemoSubscription(name: "動画プラス", category: .video, price: 1590, daysUntilNext: 3, payment: .creditCard, paymentNote: "サンプルカード"),
        DemoSubscription(name: "シネマパス", category: .video, price: 990, trialDaysLeft: 2, payment: .appStore),
        DemoSubscription(name: "ミュージックワン", category: .music, price: 1080, daysUntilNext: 6, payment: .appStore),
        DemoSubscription(name: "AIアシスタント Pro", category: .ai, price: 3000, daysUntilNext: 10, payment: .creditCard, paymentNote: "サンプルカード"),
        DemoSubscription(name: "フィットネスジム", category: .fitness, price: 3278, daysUntilNext: 17, payment: .bank),
        DemoSubscription(name: "デジタル新聞", category: .reading, price: 1980, daysUntilNext: 21, payment: .creditCard, paymentNote: "サンプルカード"),
        DemoSubscription(name: "アニメ見放題", category: .video, price: 550, daysUntilNext: 26, payment: .carrier),
        DemoSubscription(name: "クラウドボックス", category: .cloud, price: 5400, cycle: .year, daysUntilNext: 48, payment: .appStore),
        DemoSubscription(name: "マンガ読み放題", category: .reading, price: 980, cancelledDaysAgo: 40, payment: .appStore),
    ]

    /// サブスクが未登録のときだけデモデータを投入する。
    @MainActor
    static func seedIfNeeded(_ context: ModelContext, calendar: Calendar = .current) {
        let count = (try? context.fetchCount(FetchDescriptor<Subscription>())) ?? 0
        guard count == 0 else { return }

        let today = calendar.startOfDay(for: AppClock.now)
        for (index, demo) in demoSubscriptions.enumerated() {
            let subscription = Subscription(
                name: demo.name,
                category: demo.category,
                price: demo.price,
                cycle: demo.cycle,
                paymentMethod: demo.payment,
                paymentNote: demo.paymentNote,
                cancelNote: demo.payment.cancelGuide,
                createdAt: Date().addingTimeInterval(TimeInterval(index))
            )
            if let daysLeft = demo.trialDaysLeft {
                let trialEnd = calendar.date(byAdding: .day, value: daysLeft, to: today) ?? today
                subscription.trialEndDate = trialEnd
                subscription.anchorDate = BillingSchedule.firstBillingDate(afterTrialEnd: trialEnd, calendar: calendar)
            } else if let daysAgo = demo.cancelledDaysAgo {
                subscription.anchorDate = calendar.date(byAdding: .month, value: -8, to: today) ?? today
                subscription.isCancelled = true
                subscription.cancelledAt = calendar.date(byAdding: .day, value: -daysAgo, to: today)
            } else {
                let next = calendar.date(byAdding: .day, value: demo.daysUntilNext, to: today) ?? today
                // 何回か払ってきた体にする（詳細の「これまでの支払い」を出すため）。
                let component: Calendar.Component = demo.cycle == .year ? .year : .month
                subscription.anchorDate = calendar.date(byAdding: component, value: demo.cycle == .year ? -1 : -5, to: next) ?? next
            }
            context.insert(subscription)
        }
        try? context.save()
    }
}
