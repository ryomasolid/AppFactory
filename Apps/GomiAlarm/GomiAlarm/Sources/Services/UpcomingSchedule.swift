import Foundation

/// ホームやカレンダーに出す「1日ぶんの収集予定」。
struct CollectionDay: Equatable, Sendable, Identifiable {
    var date: Date
    /// その日に出す種類。並び順は渡された種類の並び（sortOrder）をそのまま保つ。
    var kindIDs: [UUID]

    var id: Date { date }
}

/// 収集予定を日付ごとにまとめる。
///
/// 通知と同じ `ScheduleCalculator` / 祝日設定を使うのが要点。
/// 画面に出ている予定と実際に鳴る通知が食い違うと、アプリ全体が信用されなくなる。
enum UpcomingSchedule {

    /// 期間 [from, through]（両端を含む）の収集日を昇順で返す。収集の無い日は含めない。
    static func days(
        for kinds: [KindPlan],
        from: Date,
        through: Date,
        settings: NotificationSettings = .default,
        calendar: Calendar = .current,
        holidays: Set<Date>? = nil
    ) -> [CollectionDay] {
        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: through)
        guard start <= end else { return [] }

        let skipped: Set<Date> = settings.skipHolidays
            ? (holidays ?? HolidayCalendar.holidays(from: start, through: end, calendar: calendar))
            : []

        var byDate: [Date: [UUID]] = [:]
        for kind in kinds {
            let dates = ScheduleCalculator.occurrences(
                of: kind.specs, from: start, through: end, calendar: calendar
            )
            for date in dates where !skipped.contains(date) {
                byDate[date, default: []].append(kind.id)
            }
        }
        return byDate.keys.sorted().map { CollectionDay(date: $0, kindIDs: byDate[$0] ?? []) }
    }
}
