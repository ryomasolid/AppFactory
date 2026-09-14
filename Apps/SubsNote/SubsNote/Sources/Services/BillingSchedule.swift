import Foundation

/// サブスクの状態。
enum BillingState: String, Sendable {
    /// 無料体験中（今日 ≤ 体験最終日）。
    case trial
    case active
    case cancelled

    var label: String {
        switch self {
        case .trial: String(localized: "無料体験中")
        case .active: String(localized: "契約中")
        case .cancelled: String(localized: "解約済み")
        }
    }
}

/// 支払日と金額の計算に使う値。SwiftData のモデルを値に写してから渡す（純粋関数としてテストするため）。
struct BillingPlan: Equatable, Sendable {
    var price: Int
    var cycle: BillingCycle
    var interval: Int = 1
    /// 支払日の起点。無料体験があるときは体験最終日の翌日。
    var anchorDate: Date
    var trialEndDate: Date?
    var isCancelled: Bool = false
    var cancelledAt: Date?
}

/// 支払日の計算。
enum BillingSchedule {
    /// 起点から数えて n 回目（0 = 起点）の支払日。
    ///
    /// **必ず起点から足す**。前回の支払日に足していくと 1/31 → 2/28 → 3/28 と日がずれていく。
    /// 起点から足せば 1/31 → 2/28 → 3/31 → 4/30、閏日 2/29 の年払いは平年だけ 2/28 になる。
    static func billingDate(_ n: Int, of plan: BillingPlan, calendar: Calendar = .current) -> Date? {
        let anchor = calendar.startOfDay(for: plan.anchorDate)
        let steps = max(1, plan.interval) * n
        switch plan.cycle {
        case .week: return calendar.date(byAdding: .day, value: 7 * steps, to: anchor)
        case .month: return calendar.date(byAdding: .month, value: steps, to: anchor)
        case .year: return calendar.date(byAdding: .year, value: steps, to: anchor)
        }
    }

    /// `date` の日以降で最初に来る支払日が何回目か（その日が支払日ならその回）。
    static func firstIndex(onOrAfter date: Date, plan: BillingPlan, calendar: Calendar = .current) -> Int {
        let day = calendar.startOfDay(for: date)
        let anchor = calendar.startOfDay(for: plan.anchorDate)
        guard anchor < day else { return 0 }

        // 起点からの経過でおおよその回数を出し、少し手前から数え直す（何年分も1回ずつ足さない）。
        let elapsed: Int
        switch plan.cycle {
        case .week: elapsed = (calendar.dateComponents([.day], from: anchor, to: day).day ?? 0) / 7
        case .month: elapsed = calendar.dateComponents([.month], from: anchor, to: day).month ?? 0
        case .year: elapsed = calendar.dateComponents([.year], from: anchor, to: day).year ?? 0
        }
        var n = max(0, elapsed / max(1, plan.interval) - 1)
        while let billing = billingDate(n, of: plan, calendar: calendar), billing < day {
            n += 1
        }
        return n
    }

    /// 次回の支払日（今日が支払日なら今日）。解約済みは nil。
    ///
    /// 無料体験中は起点が体験最終日の翌日なので、自然にその日が返る。
    static func nextBillingDate(onOrAfter date: Date, plan: BillingPlan, calendar: Calendar = .current) -> Date? {
        guard !plan.isCancelled else { return nil }
        return billingDate(firstIndex(onOrAfter: date, plan: plan, calendar: calendar), of: plan, calendar: calendar)
    }

    /// `start` の日から `end` の日まで（両端を含む）に来る支払日。解約済みは空。
    static func billingDates(
        from start: Date, through end: Date, plan: BillingPlan, calendar: Calendar = .current, limit: Int = 400
    ) -> [Date] {
        guard !plan.isCancelled else { return [] }
        let last = calendar.startOfDay(for: end)
        var n = firstIndex(onOrAfter: start, plan: plan, calendar: calendar)
        var dates: [Date] = []
        while dates.count < limit, let billing = billingDate(n, of: plan, calendar: calendar), billing <= last {
            dates.append(billing)
            n += 1
        }
        return dates
    }

    /// `date` の日以降の支払日を count 回ぶん。
    static func upcoming(_ count: Int, from date: Date, plan: BillingPlan, calendar: Calendar = .current) -> [Date] {
        guard !plan.isCancelled else { return [] }
        let first = firstIndex(onOrAfter: date, plan: plan, calendar: calendar)
        return (first..<(first + count)).compactMap { billingDate($0, of: plan, calendar: calendar) }
    }

    static func state(of plan: BillingPlan, today: Date, calendar: Calendar = .current) -> BillingState {
        if plan.isCancelled { return .cancelled }
        if let trialEnd = plan.trialEndDate,
           calendar.startOfDay(for: today) <= calendar.startOfDay(for: trialEnd) {
            return .trial
        }
        return .active
    }

    /// 起点から今日（解約済みは解約日）までに来た支払日の回数。「これまでの支払い（概算）」に使う。
    static func paidCount(plan: BillingPlan, today: Date, calendar: Calendar = .current) -> Int {
        let end = calendar.startOfDay(for: plan.isCancelled ? (plan.cancelledAt ?? today) : today)
        guard calendar.startOfDay(for: plan.anchorDate) <= end,
              let nextDay = calendar.date(byAdding: .day, value: 1, to: end)
        else { return 0 }
        // 翌日以降で最初の回 = 今日までに来た回数。
        return firstIndex(onOrAfter: nextDay, plan: plan, calendar: calendar)
    }

    /// 無料体験の最終日から、初回の支払日（翌日）を出す。
    static func firstBillingDate(afterTrialEnd trialEnd: Date, calendar: Calendar = .current) -> Date {
        let lastDay = calendar.startOfDay(for: trialEnd)
        return calendar.date(byAdding: .day, value: 1, to: lastDay) ?? lastDay
    }
}
