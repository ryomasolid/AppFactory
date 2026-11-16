import Foundation

/// お知らせの中身を組む（通知の登録は `Reminders`）。
/// 朝は「予防の日・トリミングの目安日」、夜は「まだ日記を書いていない日」。1日にそれぞれ1通まで。
enum DailyNudge {
    static let daysAhead = 7

    struct DueThing: Equatable {
        var dog: String
        var what: String
        var day: Date
    }

    struct Morning: Equatable {
        var day: Date
        var lines: [String]
    }

    /// 過ぎている予防は今日の朝にまとめる。トリミングは目安の日だけ。
    static func mornings(prevention: [DueThing], trims: [DueThing], today now: Date, calendar: Calendar = .current) -> [Morning] {
        let today = calendar.startOfDay(for: now)
        return (0..<daysAhead).compactMap { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: today)!
            let care = prevention.filter {
                let d = calendar.startOfDay(for: $0.day)
                return offset == 0 ? d <= day : d == day
            }
            let cut = trims.filter { calendar.startOfDay(for: $0.day) == day }
            let lines = care.map { "\($0.dog)：\($0.what)の日です" } + cut.map { "\($0.dog)：そろそろトリミングの時期です" }
            return lines.isEmpty ? nil : Morning(day: day, lines: lines)
        }
    }

    static func body(_ morning: Morning) -> String {
        morning.lines.count > 3
            ? (morning.lines.prefix(3) + ["ほか\(morning.lines.count - 3)件"]).joined(separator: "\n")
            : morning.lines.joined(separator: "\n")
    }

    /// 夜のお知らせを出す日。今日すでに書いていれば今日はとばす。
    static func eveningDays(writtenToday: Bool, today now: Date, calendar: Calendar = .current) -> [Date] {
        let today = calendar.startOfDay(for: now)
        let first = writtenToday ? 1 : 0
        return (first..<daysAhead).map { calendar.date(byAdding: .day, value: $0, to: today)! }
    }
}
