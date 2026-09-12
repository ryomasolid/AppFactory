import Foundation

/// テスト用の固定カレンダー。端末のタイムゾーン・週初めに依存して落ちないよう明示する。
/// （隔週判定は「週の開始日」を基準にするため firstWeekday の固定が重要）
let jst: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
    calendar.locale = Locale(identifier: "ja_JP")
    calendar.firstWeekday = 1
    return calendar
}()

/// 日付リテラル。
func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    jst.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
}

/// 日時リテラル。
func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    jst.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? .distantPast
}
