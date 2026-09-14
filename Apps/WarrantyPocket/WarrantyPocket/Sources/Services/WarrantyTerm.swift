import Foundation

/// 保証の種類。メーカー保証と、量販店などの延長保証は期限も窓口も違うので別々に持つ。
enum WarrantyKind: String, CaseIterable, Sendable {
    case manufacturer
    case extended

    var label: String {
        switch self {
        case .manufacturer: String(localized: "メーカー保証")
        case .extended: String(localized: "延長保証")
        }
    }
}

/// 保証期間1つ。
struct WarrantyPeriod: Equatable, Sendable {
    var kind: WarrantyKind
    var months: Int
    /// 起算日（購入日の0時）。
    var startDate: Date
    /// 保証が有効な最後の日（その日の終わりまで有効）。
    var lastDay: Date
}

enum WarrantyState: Equatable, Sendable {
    /// 保証中（最終日まで31日以上）。
    case active
    /// まもなく終了（最終日まで30日以内・当日を含む）。
    case soon
    /// 終了。
    case expired
    /// 保証が設定されていない。
    case none
}

struct WarrantyStatus: Equatable, Sendable {
    var state: WarrantyState
    var lastDay: Date?
    /// 今日から最終日までの日数。最終日当日は 0、終了後は負。
    var remainingDays: Int?

    static let none = WarrantyStatus(state: .none, lastDay: nil, remainingDays: nil)

    /// まだ保証が使えるか。
    var isCovered: Bool { state == .active || state == .soon }
}

/// 保証期限の計算。
///
/// 「お買い上げ日から1年間」は**購入日を含めて1年**なので、最終日 = 購入日 + 12か月 − 1日。
enum WarrantyTerm {
    /// この日数以内になったら「まもなく終了」。
    static let soonDays = 30

    /// 最終日。月末の購入は `Calendar` が月末に丸める挙動に揃える（1/31 + 1か月 = 2/28 → 最終日 2/27）。
    static func lastDay(purchaseDate: Date, months: Int, calendar: Calendar = .current) -> Date? {
        guard months > 0 else { return nil }
        let start = calendar.startOfDay(for: purchaseDate)
        guard let end = calendar.date(byAdding: .month, value: months, to: start) else { return nil }
        return calendar.date(byAdding: .day, value: -1, to: end)
    }

    /// 商品が持つ保証期間（メーカー保証 → 延長保証の順）。
    static func periods(
        purchaseDate: Date, warrantyMonths: Int?, extendedMonths: Int?, calendar: Calendar = .current
    ) -> [WarrantyPeriod] {
        let start = calendar.startOfDay(for: purchaseDate)
        let pairs: [(WarrantyKind, Int?)] = [(.manufacturer, warrantyMonths), (.extended, extendedMonths)]
        return pairs.compactMap { kind, months in
            guard let months, let last = lastDay(purchaseDate: start, months: months, calendar: calendar) else {
                return nil
            }
            return WarrantyPeriod(kind: kind, months: months, startDate: start, lastDay: last)
        }
    }

    static func status(of period: WarrantyPeriod?, now: Date = Date(), calendar: Calendar = .current) -> WarrantyStatus {
        guard let period else { return .none }
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: today, to: period.lastDay).day ?? 0
        let state: WarrantyState = days < 0 ? .expired : (days <= soonDays ? .soon : .active)
        return WarrantyStatus(state: state, lastDay: period.lastDay, remainingDays: days)
    }

    /// 商品全体の状態。まだ使える保証のうち最終日が遅いほう。
    /// すべて終わっていれば最後に終わったもの。延長保証がある商品は、メーカー保証が切れても保証中のまま。
    static func overall(_ periods: [WarrantyPeriod], now: Date = Date(), calendar: Calendar = .current) -> WarrantyStatus {
        let statuses = periods.map { status(of: $0, now: now, calendar: calendar) }
        let latest: (WarrantyStatus, WarrantyStatus) -> Bool = {
            ($0.remainingDays ?? .min) < ($1.remainingDays ?? .min)
        }
        if let covered = statuses.filter(\.isCovered).max(by: latest) { return covered }
        return statuses.max(by: latest) ?? .none
    }

    /// 経過した割合（0...1）。進捗バーに使う。
    static func elapsedFraction(of period: WarrantyPeriod, now: Date = Date(), calendar: Calendar = .current) -> Double {
        let total = (calendar.dateComponents([.day], from: period.startDate, to: period.lastDay).day ?? 0) + 1
        let elapsed = calendar.dateComponents([.day], from: period.startDate, to: calendar.startOfDay(for: now)).day ?? 0
        guard total > 0 else { return 1 }
        return min(1, max(0, Double(elapsed) / Double(total)))
    }
}
