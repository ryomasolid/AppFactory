import Foundation

/// 誕生日から「1歳2ヶ月」形式の年齢。ハムスターは寿命2〜3年なので月まで出す。
enum HamsterAge {
    static func text(birthDate: Date, at date: Date = Date(), calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: birthDate), to: calendar.startOfDay(for: date))
        let years = max(0, c.year ?? 0)
        let months = max(0, c.month ?? 0)
        switch (years, months) {
        case (0, 0): return String(localized: "0ヶ月")
        case (0, _): return String(localized: "\(months)ヶ月")
        case (_, 0): return String(localized: "\(years)歳")
        default: return String(localized: "\(years)歳\(months)ヶ月")
        }
    }
}

/// 消耗品の交換サイクルの進み具合。
struct ReminderStatus: Equatable {
    enum State: Equatable { case ok, soon, due }

    var daysPassed: Int
    var progress: Double
    var state: State
    /// 次に交換する日。一度も交換日を入れていなければ nil。
    var dueDate: Date?

    /// 8割を過ぎたら「もうすぐ」。旧版と同じ基準。
    static func evaluate(lastDate: Date?, cycleDays: Int, now: Date = Date(), calendar: Calendar = .current) -> ReminderStatus {
        let cycle = max(1, cycleDays)
        guard let lastDate else {
            return ReminderStatus(daysPassed: cycle, progress: 1, state: .due, dueDate: nil)
        }
        let start = calendar.startOfDay(for: lastDate)
        let days = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: now)).day ?? 0
        let state: State = days >= cycle ? .due : Double(days) >= Double(cycle) * 0.8 ? .soon : .ok
        return ReminderStatus(
            daysPassed: max(0, days),
            progress: min(max(Double(days) / Double(cycle), 0), 1),
            state: state,
            dueDate: calendar.date(byAdding: .day, value: cycle, to: start)
        )
    }
}

/// 体重グラフの点。
struct WeightPoint: Identifiable, Equatable {
    var date: Date
    var weight: Double
    var id: Date { date }
}

enum WeightRange: String, CaseIterable, Identifiable {
    case month, quarter, all
    var id: String { rawValue }

    var label: String {
        switch self {
        case .month: String(localized: "1ヶ月")
        case .quarter: String(localized: "3ヶ月")
        case .all: String(localized: "全期間")
        }
    }

    var days: Int? {
        switch self {
        case .month: 30
        case .quarter: 90
        case .all: nil
        }
    }
}

enum WeightSeries {
    /// 1日1点（同じ日に複数あれば、あとで作った記録を採る）で日付順。
    static func points(_ entries: [(date: Date, weight: Double?, createdAt: Date)], calendar: Calendar = .current) -> [WeightPoint] {
        var byDay: [Date: (weight: Double, createdAt: Date)] = [:]
        for entry in entries {
            guard let weight = entry.weight, weight > 0 else { continue }
            let day = calendar.startOfDay(for: entry.date)
            if let current = byDay[day], current.createdAt >= entry.createdAt { continue }
            byDay[day] = (weight, entry.createdAt)
        }
        return byDay.map { WeightPoint(date: $0.key, weight: $0.value.weight) }.sorted { $0.date < $1.date }
    }

    static func filter(_ points: [WeightPoint], range: WeightRange, now: Date = Date(), calendar: Calendar = .current) -> [WeightPoint] {
        guard let days = range.days,
              let from = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now)) else { return points }
        return points.filter { $0.date >= from }
    }

    /// 期間の最初から最新までの増減(g)。点が2つ未満なら nil。
    static func change(_ points: [WeightPoint]) -> Double? {
        guard points.count >= 2, let first = points.first, let last = points.last else { return nil }
        return ((last.weight - first.weight) * 10).rounded() / 10
    }

    /// グラフの縦軸。変化が小さくても線が平らに潰れないよう、少し余白を取る。
    static func yDomain(_ points: [WeightPoint]) -> ClosedRange<Double> {
        let weights = points.map(\.weight)
        guard let low = weights.min(), let high = weights.max() else { return 0...1 }
        let margin = max((high - low) * 0.2, 1)
        return (low - margin).rounded(.down)...(high + margin).rounded(.up)
    }
}

/// 体重の急な減り。
struct WeightDrop: Equatable {
    /// 比べた相手（直前7日間でいちばん重かった日）。
    var from: WeightPoint
    var to: WeightPoint
    /// 減った割合（0.1 = 1割）。
    var ratio: Double
}

/// ハムスターは体調を崩すと体重が落ちやすく、見た目では気づきにくい。急に減ったらホームで知らせる。
enum WeightAlert {
    /// 1割減ったら知らせる。
    static let dropRatio = 0.10
    /// 最新の体重と比べる期間。
    static let windowDays = 7
    /// 最新の記録がこれより古ければ、もう済んだ話として出さない。
    static let staleDays = 14

    /// 最新の体重が、その前7日間でいちばん重かった日より1割以上軽ければ返す。
    static func drop(in points: [WeightPoint], now: Date = Date(), calendar: Calendar = .current) -> WeightDrop? {
        guard let latest = points.last,
              let stale = calendar.date(byAdding: .day, value: -staleDays, to: calendar.startOfDay(for: now)),
              latest.date >= stale,
              let from = calendar.date(byAdding: .day, value: -windowDays, to: latest.date),
              let peak = points.dropLast().filter({ $0.date >= from }).max(by: { $0.weight < $1.weight })
        else { return nil }
        let ratio = (peak.weight - latest.weight) / peak.weight
        // 40g → 36g のようなちょうど1割を、浮動小数の誤差で取りこぼさない。
        return ratio >= dropRatio - 1e-9 ? WeightDrop(from: peak, to: latest, ratio: ratio) : nil
    }
}

/// App Store のレビュー依頼を出すか。
///
/// 記録が 3件・15件・50件 に届いた「アプリに慣れて気に入っていそうな」ときにだけ出す。
/// シェアカードを共有したあとと、記念日に記録したときにも出す（喜んでいそうなとき）。
/// iOS 側でも年3回までに絞られるが、しつこく見えないようアプリ側でも前回から60日あける。
enum ReviewPolicy {
    static let milestones = [3, 15, 50]
    static let minimumInterval: TimeInterval = 60 * 24 * 60 * 60

    static func shouldRequest(recordCount: Int, lastRequestedCount: Int?, lastRequestedAt: Date?, now: Date = Date()) -> Bool {
        let reached = milestones.filter { recordCount >= $0 }.count
        let reachedBefore = milestones.filter { (lastRequestedCount ?? 0) >= $0 }.count
        guard reached > reachedBefore else { return false }
        if let lastRequestedAt, now.timeIntervalSince(lastRequestedAt) < minimumInterval { return false }
        return true
    }

    /// 喜んでいそうなとき（シェアのあと・記念日の記録）に出すか。件数は問わず、前回からの間隔だけを見る。
    static func shouldRequestAtHappyMoment(lastRequestedAt: Date?, now: Date = Date()) -> Bool {
        guard let lastRequestedAt else { return true }
        return now.timeIntervalSince(lastRequestedAt) >= minimumInterval
    }
}
