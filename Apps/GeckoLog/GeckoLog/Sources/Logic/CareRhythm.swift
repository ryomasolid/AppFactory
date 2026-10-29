import Foundation

/// 年齢の区切り。ハッチから 4か月未満をベビー、1歳未満をヤングとする（一般的な飼育書の目安）。
enum LifeStage: Equatable {
    case baby, juvenile, adult

    var label: String {
        switch self {
        case .baby: "ベビー"
        case .juvenile: "ヤング"
        case .adult: "アダルト"
        }
    }
}

/// ごはん・拒食・脱皮・体重の「次はいつ」「いつもと違う」を出す計算。
/// 画面や SwiftData に依存させず、日付の並びだけを受け取る（テストしやすいように）。
enum CareRhythm {
    static func stage(hatchedOn: Date?, now: Date, calendar: Calendar = .current) -> LifeStage {
        guard let hatchedOn else { return .adult }
        let months = calendar.dateComponents([.month], from: hatchedOn, to: now).month ?? 0
        if months < 4 { return .baby }
        if months < 12 { return .juvenile }
        return .adult
    }

    /// ベビーは毎日、ヤングは2日に1回、アダルトは週2回ほど。
    static func suggestedFeedInterval(for stage: LifeStage) -> Int {
        switch stage {
        case .baby: 1
        case .juvenile: 2
        case .adult: 4
        }
    }

    /// 記録がまだ少ないときの脱皮間隔の目安（日）。
    static func typicalShedInterval(for stage: LifeStage) -> Int {
        switch stage {
        case .baby: 10
        case .juvenile: 21
        case .adult: 35
        }
    }

    /// 次のごはんの日（その日の 0:00）。最後に与えた日（食べなかった日も含む）から間隔ぶん後。
    /// 一度も与えていなければ今日。
    static func nextFeedingDay(lastOffered: Date?, interval: Int, today: Date, calendar: Calendar = .current) -> Date {
        let todayStart = calendar.startOfDay(for: today)
        guard let lastOffered else { return todayStart }
        let base = calendar.startOfDay(for: lastOffered)
        return calendar.date(byAdding: .day, value: max(1, interval), to: base) ?? todayStart
    }

    /// 新しいほうから数えて、続けて食べなかった回数。
    static func refusalStreak(_ feedings: [(at: Date, accepted: Bool)]) -> Int {
        var streak = 0
        for feeding in feedings.sorted(by: { $0.at > $1.at }) {
            if feeding.accepted { break }
            streak += 1
        }
        return streak
    }

    /// 次の脱皮の予想日。直近3回ぶんの間隔の平均を使い、記録が1回だけなら年齢の目安を使う。
    static func nextShedDay(shedDates: [Date], stage: LifeStage, calendar: Calendar = .current) -> Date? {
        let days = shedDates.map { calendar.startOfDay(for: $0) }.sorted()
        guard let last = days.last else { return nil }
        let gaps = zip(days, days.dropFirst())
            .compactMap { calendar.dateComponents([.day], from: $0, to: $1).day }
            .filter { $0 > 0 }
            .suffix(3)
        let interval = gaps.isEmpty
            ? typicalShedInterval(for: stage)
            : Int((Double(gaps.reduce(0, +)) / Double(gaps.count)).rounded())
        return calendar.date(byAdding: .day, value: interval, to: last)
    }

    /// 最新の体重と、その約30日前の体重の差（%）。比べる記録がなければ nil。
    static func weightTrend(_ weighings: [(at: Date, grams: Double)], calendar: Calendar = .current) -> Double? {
        let sorted = weighings.sorted { $0.at < $1.at }
        guard let latest = sorted.last, sorted.count >= 2 else { return nil }
        guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: latest.at) else { return nil }
        let reference = sorted.last(where: { $0.at <= monthAgo }) ?? sorted.first!
        guard reference.grams > 0, reference.at < latest.at else { return nil }
        return (latest.grams - reference.grams) / reference.grams * 100
    }

    static func days(from: Date, to: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: from), to: calendar.startOfDay(for: to)).day ?? 0
    }
}

/// 1匹ぶんの「いまの様子」。一覧のカードと詳細画面で使う。
struct GeckoStatus {
    let stage: LifeStage
    let feedInterval: Int
    let nextFeeding: Date
    /// 次のごはんまでの日数。0 なら今日、負なら過ぎている。
    let daysUntilFeeding: Int
    let daysSinceAte: Int?
    let refusalStreak: Int
    let nextShed: Date?
    let daysUntilShed: Int?
    let latestGrams: Double?
    let monthlyWeightChange: Double?

    var isFeedingDue: Bool { daysUntilFeeding <= 0 }
    /// 2回以上続けて食べない、または2週間なにも食べていない。
    var needsAppetiteWatch: Bool { refusalStreak >= 2 || (daysSinceAte ?? 0) >= 14 }
    /// 1か月で 1割以上やせた。
    var isLosingWeight: Bool { (monthlyWeightChange ?? 0) <= -10 }
    /// 予想日の2日前から。
    var isShedNear: Bool { (daysUntilShed ?? .max) <= 2 }
}

extension Gecko {
    func status(now: Date = Date(), calendar: Calendar = .current) -> GeckoStatus {
        let stage = CareRhythm.stage(hatchedOn: hatchedOn, now: now, calendar: calendar)
        let interval = feedIntervalOverride > 0 ? feedIntervalOverride : CareRhythm.suggestedFeedInterval(for: stage)
        let all = allEntries
        let feedings = all.filter { $0.kind == .feeding }.map { (at: $0.occurredAt, accepted: $0.accepted) }
        let lastOffered = feedings.map(\.at).max()
        let lastAte = feedings.filter(\.accepted).map(\.at).max()
        let nextFeeding = CareRhythm.nextFeedingDay(lastOffered: lastOffered, interval: interval, today: now, calendar: calendar)
        let shedDates = all.filter { $0.kind == .shed }.map(\.occurredAt)
        let nextShed = CareRhythm.nextShedDay(shedDates: shedDates, stage: stage, calendar: calendar)
        let weighings = all.compactMap { entry in entry.kind == .weight ? entry.grams.map { (at: entry.occurredAt, grams: $0) } : nil }

        return GeckoStatus(
            stage: stage,
            feedInterval: interval,
            nextFeeding: nextFeeding,
            daysUntilFeeding: CareRhythm.days(from: now, to: nextFeeding, calendar: calendar),
            daysSinceAte: lastAte.map { CareRhythm.days(from: $0, to: now, calendar: calendar) },
            refusalStreak: CareRhythm.refusalStreak(feedings),
            nextShed: nextShed,
            daysUntilShed: nextShed.map { CareRhythm.days(from: now, to: $0, calendar: calendar) },
            latestGrams: weighings.max(by: { $0.at < $1.at })?.grams,
            monthlyWeightChange: CareRhythm.weightTrend(weighings, calendar: calendar)
        )
    }

    /// 「1歳3か月」のような年齢。ハッチ日がなければ nil。
    func ageText(now: Date = Date(), calendar: Calendar = .current) -> String? {
        guard let hatchedOn else { return nil }
        let parts = calendar.dateComponents([.year, .month], from: hatchedOn, to: now)
        let years = parts.year ?? 0, months = parts.month ?? 0
        if years == 0 && months == 0 {
            return "\(max(0, CareRhythm.days(from: hatchedOn, to: now, calendar: calendar)))日"
        }
        if years == 0 { return "\(months)か月" }
        return months == 0 ? "\(years)歳" : "\(years)歳\(months)か月"
    }
}
