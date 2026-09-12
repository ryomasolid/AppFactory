import Foundation
import SwiftData

/// 起動引数（スクリーンショット撮影・デモ用）。
/// すべてローカルの起動引数で制御し、通常のユーザー利用時には一切影響しない。
enum Launch {
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    /// 広告バナーを非表示（スクショ撮影用）。
    static var hideAds: Bool { args.contains("-hideAds") }
    /// デモ用のゴミの種類を投入する。
    static var isDemo: Bool { args.contains("-demo") }
    /// 起動時にペイウォールを表示（既存アプリと引数名を揃える）。
    static var showPaywall: Bool { args.contains("-showPaywall") }
    /// オンボーディングを強制表示（スクショ撮影用）。
    static var forceOnboarding: Bool { args.contains("-forceOnboarding") }
    /// 周期エディタを起動直後に表示（スクショ撮影・レイアウト確認用）。
    static var showRuleEditor: Bool { args.contains("-showRuleEditor") }
    /// 種類の編集画面を起動直後に表示（スクショ撮影・レイアウト確認用）。
    static var showKindEditor: Bool { args.contains("-showKindEditor") }

    /// オンボーディングの開始ページ（"templates" / "notifications"）。スクショ撮影用。
    static var onboardingStep: String? {
        guard let i = args.firstIndex(of: "-onboardingStep"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// 起動時に選択するタブ（"schedule" / "calendar" / "settings"）。
    static var startTab: String? {
        guard let i = args.firstIndex(of: "-startTab"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// デモ用のゴミの種類。ASO のスクショ構成に合わせた4種類。
    ///
    /// 燃えるゴミの曜日は **実行日の曜日に合わせる**。
    /// ホームの主役は「今日出すゴミ」の大カードなので、いつ撮っても必ず埋まるようにしておく。
    static func demoKinds(calendar: Calendar = .current) -> [GarbageKind] {
        let today = calendar.startOfDay(for: Date())
        // 隔週の基準日は「今週」にして、デモが常に近い日付で成立するようにする。
        let thisWeek = today
        let todayWeekday = Weekday.of(today, calendar: calendar)
        let laterWeekday = Weekday.of(
            calendar.date(byAdding: .day, value: 3, to: today) ?? today, calendar: calendar
        )
        return [
            GarbageKind(
                name: String(localized: "燃えるゴミ"), colorHex: "#E8543F", symbolName: "flame.fill",
                note: String(localized: "45Lまで"), sortOrder: 0,
                rules: [CollectionRule(spec: RuleSpec(
                    frequency: .weekly, weekdays: [todayWeekday, laterWeekday]
                ))]
            ),
            GarbageKind(
                name: String(localized: "資源ごみ"), colorHex: "#2F7DD1", symbolName: "arrow.3.trianglepath",
                note: String(localized: "新聞は紐でしばる"), sortOrder: 1,
                rules: [CollectionRule(spec: RuleSpec(
                    frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth]
                ))]
            ),
            GarbageKind(
                name: String(localized: "プラスチック"), colorHex: "#E0A21B", symbolName: "takeoutbag.and.cup.and.straw.fill",
                note: String(localized: "キャップは外す"), sortOrder: 2,
                rules: [CollectionRule(spec: RuleSpec(frequency: .weekly, weekdays: [.friday]))]
            ),
            GarbageKind(
                name: String(localized: "缶・瓶"), colorHex: "#3E9B6B", symbolName: "cylinder.split.1x2.fill",
                note: "", sortOrder: 3,
                rules: [CollectionRule(spec: RuleSpec(
                    frequency: .biweekly, weekdays: [.tuesday], anchorDate: thisWeek
                ))]
            ),
        ]
    }

    /// 種類編集のデモ内容（`-showKindEditor` 用）。
    static var demoDraft: KindDraft {
        var draft = KindDraft()
        draft.name = String(localized: "資源ごみ")
        draft.colorHex = KindPalette.colors[3]
        draft.symbolName = KindPalette.symbols[1]
        draft.note = String(localized: "新聞は紐でしばる")
        draft.specs = [
            RuleSpec(frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth])
        ]
        return draft
    }

    /// 種類が未登録のときだけデモデータを投入する。
    @MainActor
    static func seedIfNeeded(_ context: ModelContext, calendar: Calendar = .current) {
        let count = (try? context.fetchCount(FetchDescriptor<GarbageKind>())) ?? 0
        guard count == 0 else { return }
        let kinds = demoKinds(calendar: calendar)
        for kind in kinds { context.insert(kind) }
        seedDoneRecords(for: kinds, into: context, calendar: calendar)
        try? context.save()
    }

    /// デモ用の「出した」記録。ホームのストリーク表示を確認・撮影できるように、
    /// 直近の収集日8回ぶんを「出した」状態にする。
    @MainActor
    private static func seedDoneRecords(
        for kinds: [GarbageKind], into context: ModelContext, calendar: Calendar
    ) {
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -60, to: today),
              let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        else { return }

        let past = UpcomingSchedule.days(
            for: kinds.map(KindPlan.init), from: start, through: yesterday, calendar: calendar
        )
        // 連続扱いにするため、直近から途切れなく埋める（その日の種類は全部出した状態にする）。
        for day in past.suffix(8) {
            for kindID in day.kindIDs {
                context.insert(DoneRecord(kindID: kindID, date: day.date, calendar: calendar))
            }
        }
    }
}
