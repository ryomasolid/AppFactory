import Foundation

/// ガツログの1件。
struct Bite: Codable, Identifiable, Equatable {
    var id = UUID()
    var eatenAt: Date
    var name: String
    var place: String?
    var kcal: Double
    /// PFC は公式値から記録したときだけ入る。手入力ならカロリーだけ。
    var protein: Double?
    var fat: Double?
    var carbs: Double?
}

/// 記録の集計。画面やファイルの保存とは切り離してテストする。
struct BiteStats {
    struct DayTotal: Identifiable, Equatable {
        let day: Date
        let kcal: Double
        var id: Date { day }
    }

    struct Summary: Equatable {
        var kcal = 0.0
        var protein = 0.0
        var fat = 0.0
        var carbs = 0.0
        var count = 0
        /// カロリーを、茶碗のご飯に言い換えると何杯ぶんか。
        var riceBowls: Double { kcal / Portions.bowlKcal }
    }

    struct MonthReport: Equatable {
        let summary: Summary
        let activeDays: Int
        let biggestDay: DayTotal?
        let favoritePlace: String?
        var kcalPerActiveDay: Double { activeDays > 0 ? summary.kcal / Double(activeDays) : 0 }
    }

    let bites: [Bite]
    var calendar: Calendar = .current

    func summary(of bites: [Bite]) -> Summary {
        bites.reduce(into: Summary()) { sum, bite in
            sum.kcal += bite.kcal
            sum.protein += bite.protein ?? 0
            sum.fat += bite.fat ?? 0
            sum.carbs += bite.carbs ?? 0
            sum.count += 1
        }
    }

    func onDay(_ date: Date) -> [Bite] {
        bites.filter { calendar.isDate($0.eatenAt, inSameDayAs: date) }
    }

    /// 今日までの7日ぶん（古い順）。記録のない日は0で埋める。
    func lastWeek(until date: Date = .now) -> [DayTotal] {
        let today = calendar.startOfDay(for: date)
        return (0..<7).reversed().compactMap { back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { return nil }
            return DayTotal(day: day, kcal: summary(of: onDay(day)).kcal)
        }
    }

    func monthReport(containing date: Date = .now) -> MonthReport {
        let month = bites.filter { calendar.isDate($0.eatenAt, equalTo: date, toGranularity: .month) }
        let byDay = Dictionary(grouping: month) { calendar.startOfDay(for: $0.eatenAt) }
        let totals = byDay.map { DayTotal(day: $0.key, kcal: summary(of: $0.value).kcal) }
        let places = Dictionary(grouping: month.compactMap(\.place)) { $0 }
        return MonthReport(
            summary: summary(of: month),
            activeDays: byDay.count,
            biggestDay: totals.max { ($0.kcal, $1.day) < ($1.kcal, $0.day) },
            favoritePlace: places.max { ($0.value.count, $1.key) < ($1.value.count, $0.key) }?.key
        )
    }
}
