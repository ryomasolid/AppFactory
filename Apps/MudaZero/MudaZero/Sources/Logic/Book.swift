import Foundation

/// 計算用の1件（SwiftData から切りはなしてテストしやすく）。
struct Entry: Equatable {
    var day: Date
    var yen: Int
    var category: SpendType
    var isWant: Bool { category.isWant }
}

/// 1日の結果。
enum DayKind: Equatable {
    /// 1円も使わずにしめた。
    case zero
    /// 必要な出費だけでしめた。
    case clean(need: Int)
    /// ついつい使った。
    case slipped(want: Int, need: Int)
    /// まだしめていない（必要な出費だけ記録ずみのこともある）。
    case open(need: Int)

    var isWin: Bool {
        switch self {
        case .zero, .clean: true
        default: false
        }
    }
}

struct MonthSummary: Equatable {
    var zeroDays = 0
    var cleanDays = 0
    var slippedDays = 0
    var want = 0
    var need = 0
    /// ついつい の内訳（多い順）。
    var wantByCategory: [(category: SpendType, yen: Int)] = []

    var winDays: Int { zeroDays + cleanDays }

    static func == (a: MonthSummary, b: MonthSummary) -> Bool {
        a.zeroDays == b.zeroDays && a.cleanDays == b.cleanDays && a.slippedDays == b.slippedDays
            && a.want == b.want && a.need == b.need
            && a.wantByCategory.map(\.category) == b.wantByCategory.map(\.category)
            && a.wantByCategory.map(\.yen) == b.wantByCategory.map(\.yen)
    }
}

/// 今月の「ついつい」予算の進み具合。
struct Pace: Equatable {
    var spent: Int
    var budget: Int
    /// きょうをふくめた残りの日数。
    var daysLeft: Int

    var left: Int { budget - spent }
    var over: Bool { spent > budget }
    /// 残りの日、1日あたりいくらまで使えるか。
    var perDay: Int { daysLeft > 0 ? max(0, left) / daysLeft : 0 }
    var ratio: Double { budget > 0 ? min(1, Double(spent) / Double(budget)) : 0 }
}

/// 記録ぜんぶ。日ごとの結果・連続記録・浮いたお金を出す。
struct Book {
    let calendar: Calendar
    private var byDay: [Date: [Entry]] = [:]
    private var closed: Set<Date> = []

    init(entries: [Entry], closedDays: [Date], calendar: Calendar = .current) {
        self.calendar = calendar
        for e in entries {
            byDay[calendar.startOfDay(for: e.day), default: []].append(e)
        }
        closed = Set(closedDays.map { calendar.startOfDay(for: $0) })
    }

    func entries(on day: Date) -> [Entry] {
        byDay[calendar.startOfDay(for: day)] ?? []
    }

    func isClosed(_ day: Date) -> Bool {
        closed.contains(calendar.startOfDay(for: day))
    }

    func kind(on day: Date) -> DayKind {
        let es = entries(on: day)
        let want = es.filter(\.isWant).reduce(0) { $0 + $1.yen }
        let need = es.filter { !$0.isWant }.reduce(0) { $0 + $1.yen }
        if want > 0 { return .slipped(want: want, need: need) }
        guard isClosed(day) else { return .open(need: need) }
        return need == 0 ? .zero : .clean(need: need)
    }

    /// きょうまで何日つづけてムダゼロか。きょうがまだなら、きのうから数える。
    func streak(today: Date) -> Int {
        var day = calendar.startOfDay(for: today)
        if case .open = kind(on: day) { day = previous(day) }
        var n = 0
        while kind(on: day).isWin {
            n += 1
            day = previous(day)
        }
        return n
    }

    /// これまでで一番長くつづいた日数。
    func bestStreak(through today: Date) -> Int {
        let days = (Array(byDay.keys) + Array(closed)).filter { $0 <= calendar.startOfDay(for: today) }.sorted()
        guard let first = days.first else { return 0 }
        var best = 0, run = 0
        var day = first
        let end = calendar.startOfDay(for: today)
        while day <= end {
            if kind(on: day).isWin { run += 1; best = max(best, run) } else if day != end { run = 0 }
            day = next(day)
        }
        return best
    }

    /// がまんした分＝浮いたお金。ムダゼロの日は ふだんのムダ ぶん、ついつい の日は ふだんより少なかった分。
    func saved(from start: Date, through today: Date, usual: Int) -> Int {
        guard usual > 0 else { return 0 }
        var day = calendar.startOfDay(for: start)
        let end = calendar.startOfDay(for: today)
        var total = 0
        while day <= end {
            switch kind(on: day) {
            case .zero, .clean: total += usual
            case .slipped(let want, _): total += max(0, usual - want)
            case .open: break
            }
            day = next(day)
        }
        return total
    }

    func month(of anyDay: Date) -> MonthSummary {
        guard let range = calendar.range(of: .day, in: .month, for: anyDay),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: anyDay))
        else { return MonthSummary() }
        var s = MonthSummary()
        var byCategory: [SpendType: Int] = [:]
        for offset in 0..<range.count {
            let day = calendar.date(byAdding: .day, value: offset, to: first)!
            switch kind(on: day) {
            case .zero: s.zeroDays += 1
            case .clean: s.cleanDays += 1
            case .slipped: s.slippedDays += 1
            case .open: break
            }
            for e in entries(on: day) {
                if e.isWant {
                    s.want += e.yen
                    byCategory[e.category, default: 0] += e.yen
                } else {
                    s.need += e.yen
                }
            }
        }
        let pairs: [(category: SpendType, yen: Int)] = byCategory.map { (category: $0.key, yen: $0.value) }
        s.wantByCategory = pairs.sorted { a, b in
            if a.yen != b.yen { return a.yen > b.yen }
            return a.category.rawValue < b.category.rawValue
        }
        return s
    }

    func pace(budget: Int, today: Date) -> Pace {
        let spent = month(of: today).want
        let total = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        let dayOfMonth = calendar.component(.day, from: today)
        return Pace(spent: spent, budget: budget, daysLeft: total - dayOfMonth + 1)
    }

    private func previous(_ d: Date) -> Date { calendar.date(byAdding: .day, value: -1, to: d)! }
    private func next(_ d: Date) -> Date { calendar.date(byAdding: .day, value: 1, to: d)! }
}

/// 夜のお知らせの文面（7日ぶん）。
enum NightPlan {
    struct Night: Equatable {
        var day: Date
        var body: String
    }

    static func plan(book: Book, today: Date, days: Int = 7) -> [Night] {
        let cal = book.calendar
        let start = cal.startOfDay(for: today)
        var out: [Night] = []
        for i in 0..<days {
            let day = cal.date(byAdding: .day, value: i, to: start)!
            if i == 0 {
                guard case .open = book.kind(on: day) else { continue }
                let streak = book.streak(today: today)
                out.append(Night(day: day, body: streak > 0
                    ? "ムダゼロ\(streak)日つづいています。きょうの分もつけて、記録をのばしましょう。"
                    : "きょうはムダ遣いしませんでしたか？ 1タップでつけられます。"))
            } else {
                out.append(Night(day: day, body: "きょうのお金、どうでしたか？ ムダゼロなら1タップでしめましょう。"))
            }
        }
        return out
    }
}

extension Int {
    /// 1,280円
    var yen: String { formatted(.number.locale(Locale(identifier: "ja_JP"))) + "円" }
}
