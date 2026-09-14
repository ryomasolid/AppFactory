import Foundation
@testable import CarLog

/// テスト用の固定カレンダー。端末のタイムゾーンに依存して落ちないよう明示する。
let jst: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
    calendar.locale = Locale(identifier: "ja_JP")
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

/// 給油記録リテラル。
func fuel(
    _ date: Date, odometer: Double, liters: Double, price: Int = 0, full: Bool = true
) -> FuelEntry {
    FuelEntry(id: UUID(), date: date, odometer: odometer, liters: liters, totalPrice: price, isFullTank: full)
}

/// メンテ項目リテラル。
func plan(
    months: Int? = nil,
    distance: Double? = nil,
    lastDate: Date? = nil,
    lastOdometer: Double? = nil,
    notifyDaysBefore: Int = 7,
    hour: Int = 9,
    minute: Int = 0,
    enabled: Bool = true,
    title: String = "オイル交換"
) -> MaintenancePlan {
    MaintenancePlan(
        id: UUID(), title: title, symbolName: "drop.fill",
        intervalMonths: months, intervalDistance: distance,
        lastDoneDate: lastDate, lastDoneOdometer: lastOdometer,
        notifyDaysBefore: notifyDaysBefore, notifyHour: hour, notifyMinute: minute,
        isEnabled: enabled
    )
}
