import Foundation

/// 見直しの判定。「先月何回使ったか」から1回あたりの値段を出し、やめる候補を選ぶ。
///
/// 使った回数は自己申告（アプリは他のアプリの利用状況を読めないし、読まない）。
/// 目安は「1回あたり ¥500」＝映画館や雑誌1冊の値段。これを超えると単品で払ったほうが安いことが多い。
enum UsageReview {
    /// これ以上なら割高とみなす1回あたりの額（円）。
    static let pricyPerUse = 500
    /// 回数を記入してからこの日数が過ぎたら、もう一度つけ直してもらう。
    static let staleAfterDays = 30

    enum Verdict: Equatable, Sendable {
        /// まだ回数をつけていない。
        case unrated
        /// 先月は0回。
        case unused
        /// 1回あたりが高い。
        case pricy(perUse: Int)
        /// 元が取れている。
        case worth(perUse: Int)

        /// やめる候補か。
        var isCandidate: Bool {
            switch self {
            case .unused, .pricy: true
            case .unrated, .worth: false
            }
        }
    }

    /// 1回あたりの額（月あたりの額 ÷ 回数、四捨五入）。0回は nil。
    static func perUse(monthly: Int, uses: Int) -> Int? {
        guard uses > 0 else { return nil }
        return (2 * max(0, monthly) + uses) / (2 * uses)
    }

    static func verdict(monthly: Int, uses: Int?) -> Verdict {
        guard let uses else { return .unrated }
        guard let perUse = perUse(monthly: monthly, uses: uses) else { return .unused }
        return perUse >= pricyPerUse ? .pricy(perUse: perUse) : .worth(perUse: perUse)
    }

    /// やめる候補をすべてやめたときに浮く年額。
    static func yearlySaving(_ items: [(plan: BillingPlan, uses: Int?)]) -> Int {
        let candidates = items.filter { verdict(monthly: CostSummary.monthly($0.plan), uses: $0.uses).isCandidate }
        return CostSummary.totals(candidates.map(\.plan)).yearly
    }

    /// 回数が古くなっていて、つけ直したほうがよいか（未記入は含めない）。
    static func isStale(checkedAt: Date?, today: Date, calendar: Calendar = .current) -> Bool {
        guard let checkedAt else { return false }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: checkedAt), to: calendar.startOfDay(for: today)).day ?? 0
        return days >= staleAfterDays
    }
}
