import Foundation

/// 円の分数。
///
/// 月払い・年払い・週払いを「月あたり」にそろえると端数が出る。1件ずつ丸めて足すと数十円ずれるので、
/// 分数のまま足してから最後に1回だけ丸める。金額は 0 以上を前提にする。
struct YenFraction: Equatable, Sendable {
    private(set) var numerator: Int
    private(set) var denominator: Int

    init(_ numerator: Int, _ denominator: Int = 1) {
        let divisor = Self.gcd(abs(numerator), max(1, denominator))
        self.numerator = numerator / max(1, divisor)
        self.denominator = max(1, denominator) / max(1, divisor)
    }

    static let zero = YenFraction(0)

    static func + (lhs: YenFraction, rhs: YenFraction) -> YenFraction {
        // 分母は周期の間隔（1〜12）程度なので、最小公倍数でそろえれば桁あふれしない。
        let common = lhs.denominator / gcd(lhs.denominator, rhs.denominator) * rhs.denominator
        return YenFraction(
            lhs.numerator * (common / lhs.denominator) + rhs.numerator * (common / rhs.denominator),
            common
        )
    }

    /// divisor で割って四捨五入した円。
    func rounded(dividedBy divisor: Int = 1) -> Int {
        let scaled = denominator * max(1, divisor)
        return (2 * numerator + scaled) / (2 * scaled)
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var (x, y) = (a, b)
        while y != 0 { (x, y) = (y, x % y) }
        return max(1, x)
    }
}

struct CostTotals: Equatable, Sendable {
    var monthly: Int
    var yearly: Int
    var daily: Int
}

/// 内訳の1行。
struct BreakdownEntry<Key: Hashable>: Hashable {
    var key: Key
    var monthly: Int
    var count: Int
}

/// 金額の換算と集計。
enum CostSummary {
    /// 1件の年あたり（分数）。週払いは52回、月払いは12回、年払いは1回を、間隔で割る。
    static func yearly(_ plan: BillingPlan) -> YenFraction {
        YenFraction(max(0, plan.price) * plan.cycle.timesPerYear, max(1, plan.interval))
    }

    static func monthly(_ plan: BillingPlan) -> Int {
        yearly(plan).rounded(dividedBy: 12)
    }

    /// 渡したものをすべて足した月・年・1日あたり。
    static func totals(_ plans: [BillingPlan]) -> CostTotals {
        let sum = plans.reduce(YenFraction.zero) { $0 + yearly($1) }
        return CostTotals(monthly: sum.rounded(dividedBy: 12), yearly: sum.rounded(), daily: sum.rounded(dividedBy: 365))
    }

    /// 契約中の合計。**無料体験中と解約済みは含めない**。
    static func activeTotals(_ plans: [BillingPlan], today: Date, calendar: Calendar = .current) -> CostTotals {
        totals(plans.filter { BillingSchedule.state(of: $0, today: today, calendar: calendar) == .active })
    }

    /// 無料体験中のものが本契約になると増える月あたり（「体験が終わると 月 +¥1,490」）。
    static func trialMonthlyAddition(_ plans: [BillingPlan], today: Date, calendar: Calendar = .current) -> Int {
        let trials = plans.filter { BillingSchedule.state(of: $0, today: today, calendar: calendar) == .trial }
        return trials.isEmpty ? 0 : totals(trials).monthly
    }

    /// 期間内（両端の日を含む）に来る支払いの**実額**の合計。解約済みは除き、体験後の初回の支払いは含める。
    static func payments(_ plans: [BillingPlan], from start: Date, through end: Date, calendar: Calendar = .current) -> Int {
        plans.reduce(0) { total, plan in
            total + BillingSchedule.billingDates(from: start, through: end, plan: plan, calendar: calendar).count * plan.price
        }
    }

    /// その日を含む月の1日と末日。
    static func monthRange(containing date: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        guard let interval = calendar.dateInterval(of: .month, for: date),
              let end = calendar.date(byAdding: .day, value: -1, to: interval.end)
        else {
            let day = calendar.startOfDay(for: date)
            return (day, day)
        }
        return (calendar.startOfDay(for: interval.start), calendar.startOfDay(for: end))
    }

    /// その月の支払い（1日〜末日）。カレンダーの月合計と一致させる。
    static func paymentsInMonth(_ plans: [BillingPlan], containing date: Date, calendar: Calendar = .current) -> Int {
        let range = monthRange(containing: date, calendar: calendar)
        return payments(plans, from: range.start, through: range.end, calendar: calendar)
    }

    /// 今月の残りの支払い（今日〜末日）。
    static func remainingInMonth(_ plans: [BillingPlan], today: Date, calendar: Calendar = .current) -> Int {
        payments(plans, from: today, through: monthRange(containing: today, calendar: calendar).end, calendar: calendar)
    }

    /// 解約で浮いた年額（解約済みの年あたりの合計）。
    static func yearlySaved(_ plans: [BillingPlan]) -> Int {
        totals(plans.filter(\.isCancelled)).yearly
    }

    /// キーごとの月あたり。金額の大きい順（同額は先に出てきた順）。
    static func breakdown<Key: Hashable>(_ items: [(key: Key, plan: BillingPlan)]) -> [BreakdownEntry<Key>] {
        var order: [Key] = []
        var sums: [Key: YenFraction] = [:]
        var counts: [Key: Int] = [:]
        for item in items {
            if sums[item.key] == nil { order.append(item.key) }
            sums[item.key, default: .zero] = sums[item.key, default: .zero] + yearly(item.plan)
            counts[item.key, default: 0] += 1
        }
        let entries = order.enumerated().map { index, key in
            (index, BreakdownEntry(key: key, monthly: (sums[key] ?? .zero).rounded(dividedBy: 12), count: counts[key] ?? 0))
        }
        return entries
            .sorted { $0.1.monthly == $1.1.monthly ? $0.0 < $1.0 : $0.1.monthly > $1.1.monthly }
            .map(\.1)
    }
}
