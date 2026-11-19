import Foundation

/// 世話の間隔の目安（日）。子ガメ（1歳まで）はこまめに。0 は「目安なし（したときに付けるだけ）」。
enum Rhythm {
    static func days(_ kind: CareKind, habitat: Habitat, young: Bool) -> Int {
        switch (kind, habitat) {
        case (.feed, .water): young ? 1 : 2
        case (.feed, .land): 1
        case (.water, .water): young ? 2 : 3
        case (.soak, .land): young ? 2 : 4
        case (.bedding, .land): 30
        default: 0
        }
    }

    static func isYoung(ageBase: Date, now: Date, calendar: Calendar = .current) -> Bool {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: ageBase), to: calendar.startOfDay(for: now)).day ?? 0
        return days < 365
    }

    /// 上書きがあればそれを、なければ目安。
    static func interval(_ kind: CareKind, turtle: Turtle, now: Date = Date()) -> Int {
        let custom: Int? = switch kind {
        case .feed: turtle.feedEvery
        case .water, .bedding: turtle.tidyEvery
        case .soak: turtle.soakEvery
        case .sun: nil
        }
        if let custom { return max(0, custom) }
        return days(kind, habitat: turtle.species.habitat, young: isYoung(ageBase: turtle.ageBase, now: now))
    }
}

/// きょうやること。
struct Due: Equatable, Identifiable {
    enum Task: Hashable {
        case care(CareKind)
        case measure
    }

    let task: Task
    let last: Date?
    let next: Date
    /// 何日すぎているか（きょうが期日なら 0、まだなら負）。
    let late: Int

    var id: Task { task }
    var isDue: Bool { late >= 0 }
}

enum DueList {
    /// 計測の間隔。冬眠中は体重の減りを見るので短く。
    static func measureEvery(resting: Bool) -> Int { resting ? 7 : 14 }

    /// 冬眠中は、ごはん・温浴などの世話は止めて、体重だけを見る。
    static func make(
        intervals: [CareKind: Int],
        lastCare: [CareKind: Date],
        lastMeasure: Date?,
        resting: Bool,
        now: Date,
        calendar: Calendar = .current
    ) -> [Due] {
        let today = calendar.startOfDay(for: now)
        func item(_ task: Due.Task, last: Date?, every: Int) -> Due {
            guard let last else { return Due(task: task, last: nil, next: today, late: 0) }
            let lastDay = calendar.startOfDay(for: last)
            let next = calendar.date(byAdding: .day, value: every, to: lastDay) ?? today
            let late = calendar.dateComponents([.day], from: next, to: today).day ?? 0
            return Due(task: task, last: last, next: next, late: late)
        }

        var list: [Due] = []
        if !resting {
            for kind in CareKind.allCases {
                guard let every = intervals[kind], every > 0 else { continue }
                list.append(item(.care(kind), last: lastCare[kind], every: every))
            }
        }
        list.append(item(.measure, last: lastMeasure, every: measureEvery(resting: resting)))
        return list.sorted { $0.next == $1.next ? order($0.task) < order($1.task) : $0.next < $1.next }
    }

    private static func order(_ task: Due.Task) -> Int {
        switch task {
        case .care(let kind): CareKind.allCases.firstIndex(of: kind) ?? 0
        case .measure: 99
        }
    }

    static func make(for turtle: Turtle, now: Date = Date(), calendar: Calendar = .current) -> [Due] {
        var intervals: [CareKind: Int] = [:]
        var last: [CareKind: Date] = [:]
        for kind in CareKind.kinds(for: turtle.species.habitat) {
            intervals[kind] = Rhythm.interval(kind, turtle: turtle, now: now)
        }
        for care in turtle.cares ?? [] where (last[care.kind] ?? .distantPast) < care.at {
            last[care.kind] = care.at
        }
        let lastMeasure = (turtle.measures ?? []).map(\.on).max()
        return make(intervals: intervals, lastCare: last, lastMeasure: lastMeasure, resting: turtle.currentRest != nil, now: now, calendar: calendar)
    }
}
