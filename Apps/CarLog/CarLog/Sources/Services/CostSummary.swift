import Foundation

/// カテゴリ別の合計。
struct CategoryTotal: Identifiable, Equatable, Sendable {
    var category: ExpenseCategory
    var amount: Int
    var id: String { category.rawValue }
}

/// 月ごとの合計（棒グラフ用）。
struct MonthlyTotal: Identifiable, Equatable, Sendable {
    /// その月の1日。
    var month: Date
    var amount: Int
    var id: Date { month }
}

/// 期間内のコスト内訳。
struct CostBreakdown: Equatable, Sendable {
    /// 金額の降順。0円のカテゴリは含まない。
    var categories: [CategoryTotal]
    var total: Int
    /// 期間内に走った距離(km)。記録が1件以下だと 0。
    var distance: Double
    /// 期間が何か月ぶんか（1未満にはならない）。
    var months: Int
    /// 1kmあたりのコスト(円)。走行距離が取れないときは nil。
    var costPerKilometer: Double?
    /// 月平均(円)。
    var monthlyAverage: Int

    var isEmpty: Bool { total == 0 }
}

/// 集計の対象期間。
enum CostPeriod: String, CaseIterable, Identifiable, Sendable {
    case month
    case year
    case all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .month: String(localized: "今月")
        case .year: String(localized: "今年")
        case .all: String(localized: "全期間")
        }
    }

    /// 対象期間。`.all` は最古の記録から今日まで（記録が無ければ今日1日）。
    func interval(
        now: Date = Date(), earliest: Date? = nil, calendar: Calendar = .current
    ) -> DateInterval {
        let end = calendar.startOfDay(for: now)
        switch self {
        case .month:
            let start = calendar.date(
                from: calendar.dateComponents([.year, .month], from: now)
            ) ?? end
            return DateInterval(start: start, end: end)
        case .year:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? end
            return DateInterval(start: start, end: end)
        case .all:
            let start = calendar.startOfDay(for: earliest ?? end)
            return DateInterval(start: min(start, end), end: end)
        }
    }
}

/// 給油と費用をまとめて集計する。
///
/// ガソリン代は `ExpenseRecord` には持たず、給油記録から `.fuel` カテゴリとして合成する。
enum CostSummary {
    static func breakdown(
        fuel: [FuelEntry],
        expenses: [ExpenseEntry],
        in interval: DateInterval,
        calendar: Calendar = .current
    ) -> CostBreakdown {
        let fuelInRange = fuel.filter { contains(interval, $0.date, calendar: calendar) }
        let expensesInRange = expenses.filter { contains(interval, $0.date, calendar: calendar) }

        var totals: [ExpenseCategory: Int] = [:]
        let fuelTotal = FuelEconomy.totalSpent(for: fuelInRange)
        if fuelTotal > 0 { totals[.fuel] = fuelTotal }
        for expense in expensesInRange {
            totals[expense.category, default: 0] += expense.amount
        }

        let categories = totals
            .map { CategoryTotal(category: $0.key, amount: $0.value) }
            // 金額が同じときはカテゴリ順で安定させる（並びがちらつかないように）。
            .sorted { $0.amount == $1.amount ? $0.category.rawValue < $1.category.rawValue : $0.amount > $1.amount }

        let total = totals.values.reduce(0, +)
        let odometers = fuelInRange.map(\.odometer)
        let distance: Double = {
            guard let min = odometers.min(), let max = odometers.max(), max > min else { return 0 }
            return max - min
        }()
        let months = monthCount(in: interval, calendar: calendar)

        return CostBreakdown(
            categories: categories,
            total: total,
            distance: distance,
            months: months,
            costPerKilometer: distance > 0 ? Double(total) / distance : nil,
            monthlyAverage: Int((Double(total) / Double(months)).rounded())
        )
    }

    /// 月別の合計。記録の無い月も 0 で埋める（グラフの横軸が飛ばないように）。
    static func monthlyTotals(
        fuel: [FuelEntry],
        expenses: [ExpenseEntry],
        in interval: DateInterval,
        calendar: Calendar = .current
    ) -> [MonthlyTotal] {
        var totals: [Date: Int] = [:]

        func add(_ amount: Int, on date: Date) {
            guard contains(interval, date, calendar: calendar) else { return }
            guard let month = startOfMonth(date, calendar: calendar) else { return }
            totals[month, default: 0] += amount
        }

        for record in fuel { add(record.totalPrice, on: record.date) }
        for expense in expenses { add(expense.amount, on: expense.date) }

        guard var cursor = startOfMonth(interval.start, calendar: calendar),
              let last = startOfMonth(interval.end, calendar: calendar)
        else { return [] }

        var result: [MonthlyTotal] = []
        while cursor <= last {
            result.append(MonthlyTotal(month: cursor, amount: totals[cursor] ?? 0))
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    /// 期間が何か月ぶんか。月をまたがない短い期間でも 1 を返す（0除算を避ける）。
    static func monthCount(in interval: DateInterval, calendar: Calendar = .current) -> Int {
        guard let start = startOfMonth(interval.start, calendar: calendar),
              let end = startOfMonth(interval.end, calendar: calendar),
              let months = calendar.dateComponents([.month], from: start, to: end).month
        else { return 1 }
        return max(1, months + 1)
    }

    /// 日単位で期間に含まれるか。時刻の有無で境界日が落ちないよう、日の始まりで比べる。
    private static func contains(
        _ interval: DateInterval, _ date: Date, calendar: Calendar
    ) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: interval.start)
            && day <= calendar.startOfDay(for: interval.end)
    }

    private static func startOfMonth(_ date: Date, calendar: Calendar) -> Date? {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))
    }
}
