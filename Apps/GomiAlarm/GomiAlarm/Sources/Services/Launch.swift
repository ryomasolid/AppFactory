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

    /// 起動時に選択するタブ（"schedule" / "calendar" / "settings"）。
    static var startTab: String? {
        guard let i = args.firstIndex(of: "-startTab"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// デモ用のゴミの種類。ASO のスクショ構成に合わせた4種類。
    static func demoKinds(calendar: Calendar = .current) -> [GarbageKind] {
        // 隔週の基準日は「今週」にして、デモが常に近い日付で成立するようにする。
        let thisWeek = calendar.startOfDay(for: Date())
        return [
            GarbageKind(
                name: String(localized: "燃えるゴミ"), colorHex: "#E8543F", symbolName: "flame.fill",
                note: String(localized: "45Lまで"), sortOrder: 0,
                rules: [CollectionRule(spec: RuleSpec(frequency: .weekly, weekdays: [.monday, .thursday]))]
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

    /// 種類が未登録のときだけデモデータを投入する。
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<GarbageKind>())) ?? 0
        guard count == 0 else { return }
        for kind in demoKinds() { context.insert(kind) }
        try? context.save()
    }
}
