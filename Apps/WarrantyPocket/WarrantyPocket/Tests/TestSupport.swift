import Foundation
@testable import WarrantyPocket

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

/// 通知計画の入力リテラル。
func input(
    name: String = "エアコン",
    purchased: Date,
    warranty: Int? = 12,
    extended: Int? = nil,
    provider: String = "",
    archived: Bool = false
) -> ItemNotificationInput {
    ItemNotificationInput(
        id: UUID(), name: name, purchaseDate: purchased, warrantyMonths: warranty,
        extendedMonths: extended, extendedProvider: provider, isArchived: archived
    )
}
