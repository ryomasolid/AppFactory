import Foundation
import SwiftData

/// スクショ用の見本。起動引数 `-demo`（`-tab N` で最初のタブ）。
enum Demo {
    private static var args: [String] { ProcessInfo.processInfo.arguments }
    static var on: Bool { args.contains("-demo") }

    static var firstTab: Int {
        guard let i = args.firstIndex(of: "-tab"), args.indices.contains(i + 1) else { return 0 }
        return Int(args[i + 1]) ?? 0
    }

    @MainActor
    static func seed(_ context: ModelContext, now: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        func ago(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: today)! }

        let d = UserDefaults.standard
        d.set(true, forKey: Plan.startedKey)
        d.set(600, forKey: Plan.usualKey)
        d.set(10000, forKey: Plan.budgetKey)
        d.set("沖縄旅行", forKey: Plan.goalNameKey)
        d.set(60000, forKey: Plan.goalYenKey)
        d.set(ago(44).timeIntervalSinceReferenceDate, forKey: Plan.goalStartKey)

        // 45日前から。0=0円の日・n=必要だけ・w=ついつい
        let pattern: [String] = [
            "w", "0", "n", "n", "w", "0", "n", "w", "n", "0", "w", "n", "n", "0", "w",
            "n", "0", "w", "n", "n", "0", "n", "w", "n", "0", "n", "n", "w", "0", "n",
            "n", "0", "n", "w", "n", "0", "n", "n", "0", "n", "n", "0", "n", "0",
        ]
        let wants: [(SpendType, Int, String)] = [
            (.konbini, 380, "新作のアイス"), (.cafe, 520, "季節のラテ"), (.online, 2480, "セールのクッション"),
            (.sweets, 260, "チョコ"), (.eatOut, 1100, "ラーメン"), (.konbini, 450, "おにぎりとお菓子"), (.drinks, 3800, "同期と"),
        ]
        let needs: [(SpendType, Int, String)] = [
            (.groceries, 1840, "スーパー"), (.daily, 680, "洗剤"), (.transport, 420, ""), (.groceries, 2260, "まとめ買い"), (.medical, 1200, "歯医者"),
        ]
        for (i, mark) in pattern.enumerated() {
            let day = ago(pattern.count - i)
            switch mark {
            case "0":
                context.insert(DayMark(day: day))
            case "n":
                let n = needs[i % needs.count]
                context.insert(Spend(day: day, yen: n.1, category: n.0, memo: n.2))
                context.insert(DayMark(day: day))
            default:
                let w = wants[i % wants.count]
                context.insert(Spend(day: day, yen: w.1, category: w.0, memo: w.2))
            }
        }
        // きょうは食材だけ記録して、まだしめていない。
        context.insert(Spend(day: today, yen: 1280, category: .groceries, memo: "夕飯の材料"))
        try? context.save()
    }
}
