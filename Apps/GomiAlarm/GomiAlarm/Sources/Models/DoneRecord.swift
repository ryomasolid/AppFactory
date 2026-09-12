import Foundation
import SwiftData

/// 「出した」記録。ホームのストリーク表示と、当日カードのチェック状態に使う。
@Model
final class DoneRecord {
    var kindID: UUID = UUID()
    /// 収集日（時刻は 00:00 に丸めて保存する）。
    var date: Date = Date()

    init(kindID: UUID, date: Date, calendar: Calendar = .current) {
        self.kindID = kindID
        self.date = calendar.startOfDay(for: date)
    }
}
