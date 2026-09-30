import Foundation
@testable import HamuhamuDiary

/// テスト用の固定カレンダー。端末のタイムゾーンに依存して落ちないよう明示する。
let jst: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
    calendar.locale = Locale(identifier: "ja_JP")
    return calendar
}()

/// 日付リテラル（端末のカレンダーで。DayFormat の既定と合わせる）。
func day(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar = .current) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
}

/// 日時リテラル（JST）。
func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    jst.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? .distantPast
}

/// 旧版の記録 JSON 1件。
func legacyRecordJSON(
    id: String, date: String, weight: String = "null", photo: String = "null", updatedAt: String = "2026-06-01T12:00:00.000Z"
) -> String {
    """
    {"id":"\(id)","date":"\(date)","weight":\(weight),"food":"ペレット 4g","cleaningTaskIds":["partial"],\
    "memo":"元気","photoUri":\(photo),"createdAt":"2026-06-01T11:00:00.000Z","updatedAt":"\(updatedAt)"}
    """
}

func record(_ date: String, updatedAt: String = "2026-06-01T12:00:00.000Z", photoData: String? = nil) -> RecordDTO {
    RecordDTO(
        id: "record-\(date)", date: date, weight: 40, food: "", cleaningTaskIds: [], memo: "",
        photoUri: nil, createdAt: updatedAt, updatedAt: updatedAt, photoData: photoData
    )
}
