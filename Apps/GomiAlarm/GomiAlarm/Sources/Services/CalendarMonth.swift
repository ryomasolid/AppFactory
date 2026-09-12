import Foundation

/// 月カレンダーの升目。日付の計算だけを担い、描画からは切り離してテストできるようにする。
struct CalendarMonth: Equatable, Sendable {
    /// その月の1日（00:00）。
    var firstDay: Date
    /// 週ごとの升目。前後の余白は nil。
    var weeks: [[Date?]]

    /// 指定した日を含む月を作る。
    static func make(containing date: Date, calendar: Calendar = .current) -> CalendarMonth {
        let start = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.year, .month], from: start)
        let firstDay = calendar.date(from: components) ?? start
        let dayCount = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 30

        // 週の開始曜日はカレンダー設定に従う（日曜始まり/月曜始まりの両方に対応）。
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: firstDay))
        }
        // 最終週を7つに揃える。
        while cells.count % 7 != 0 { cells.append(nil) }

        var weeks: [[Date?]] = []
        for index in stride(from: 0, to: cells.count, by: 7) {
            weeks.append(Array(cells[index..<index + 7]))
        }
        return CalendarMonth(firstDay: firstDay, weeks: weeks)
    }

    /// 前後の月へ移動する。
    func adding(months: Int, calendar: Calendar = .current) -> CalendarMonth {
        guard let moved = calendar.date(byAdding: .month, value: months, to: firstDay) else { return self }
        return CalendarMonth.make(containing: moved, calendar: calendar)
    }

    /// その月に含まれる日付（余白を除く）。
    var days: [Date] { weeks.flatMap { $0 }.compactMap { $0 } }

    /// 週の見出しに使う曜日の並び（カレンダー設定の週初めに合わせる）。
    static func weekdayOrder(calendar: Calendar = .current) -> [Weekday] {
        (0..<7).compactMap { offset in
            Weekday(rawValue: (calendar.firstWeekday - 1 + offset) % 7 + 1)
        }
    }
}
