import Foundation

/// 収集ルールから実際の収集日を列挙する純粋ロジック。
///
/// 日付の加減算を組み立てるより「1日ずつ進めて条件に合うか判定する」方が
/// 月末・うるう年・第5週・DST の取りこぼしが起きにくいので、意図的に総当たりで実装している。
/// 窓は最大でも数ヶ月なので性能上の問題はない。
enum ScheduleCalculator {

    /// 期間 [from, through]（両端を含む・日付単位）の収集日を昇順で返す。
    static func occurrences(
        of spec: RuleSpec,
        from: Date,
        through: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        guard spec.isValid else { return [] }
        let end = calendar.startOfDay(for: through)
        var day = calendar.startOfDay(for: from)
        guard day <= end else { return [] }

        var result: [Date] = []
        while day <= end {
            if matches(spec, on: day, calendar: calendar) { result.append(day) }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            // 夏時間などで時刻がずれても必ず日付境界に戻す。
            day = calendar.startOfDay(for: next)
        }
        return result
    }

    /// 複数ルール（1つの種類が持つすべてのルール）をまとめた収集日。重複は除く。
    static func occurrences(
        of specs: [RuleSpec],
        from: Date,
        through: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        var seen = Set<Date>()
        for spec in specs {
            for date in occurrences(of: spec, from: from, through: through, calendar: calendar) {
                seen.insert(date)
            }
        }
        return seen.sorted()
    }

    /// その日が収集日かどうか。
    static func matches(_ spec: RuleSpec, on date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        switch spec.frequency {
        case .weekly:
            return spec.weekdays.contains(Weekday.of(day, calendar: calendar))

        case .biweekly:
            guard spec.weekdays.contains(Weekday.of(day, calendar: calendar)),
                  let anchor = spec.anchorDate
            else { return false }
            return isEvenWeekApart(day, from: anchor, calendar: calendar)

        case .nthWeekday:
            guard spec.weekdays.contains(Weekday.of(day, calendar: calendar)) else { return false }
            return spec.nthWeeks.contains { $0.matches(day, calendar: calendar) }

        case .monthlyDay:
            guard let target = spec.dayOfMonth else { return false }
            let lastDay = calendar.range(of: .day, in: .month, for: day)?.count ?? 31
            // 「毎月31日」の2月など、その月に存在しない日は月末に丸める。
            return calendar.component(.day, from: day) == min(target, lastDay)

        case .once:
            guard let anchor = spec.anchorDate else { return false }
            return day == calendar.startOfDay(for: anchor)
        }
    }

    /// 基準日の週から見て偶数週ぶんだけ離れているか（隔週判定）。
    /// 週の開始日どうしの差で見るので、基準日と曜日が違っても正しく判定できる。
    private static func isEvenWeekApart(_ date: Date, from anchor: Date, calendar: Calendar) -> Bool {
        guard let anchorWeek = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start,
              let dateWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start,
              let days = calendar.dateComponents([.day], from: anchorWeek, to: dateWeek).day
        else { return false }
        return abs(days / 7) % 2 == 0
    }
}
