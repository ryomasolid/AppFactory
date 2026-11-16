import Foundation

/// 朝のお知らせの中身。毎朝「体重をはかろう」と、その日が目安のおせわを1通にまとめる。
enum MorningPlan {
    static let days = 7

    struct Morning: Equatable {
        var day: Date
        var body: String
    }

    /// - Parameters:
    ///   - weighedToday: 今日すでにはかっていれば、今日のぶんは出さない。
    ///   - chores: (鳥の名前, おせわ, 目安の日)。過ぎているものは今日にまとめる。
    static func plan(birdNames: [String], weighedToday: Bool, chores: [(bird: String, kind: ChoreKind, due: Date)], today now: Date, calendar: Calendar = .current) -> [Morning] {
        let today = calendar.startOfDay(for: now)
        let who = birdNames.isEmpty ? "インコ" : birdNames.prefix(2).joined(separator: "・") + (birdNames.count > 2 ? "たち" : "")
        return (0..<days).compactMap { offset -> Morning? in
            let day = calendar.date(byAdding: .day, value: offset, to: today)!
            var lines: [String] = []
            if !(offset == 0 && weighedToday) { lines.append("\(who)の体重をはかろう") }
            let todays = chores.filter {
                let d = calendar.startOfDay(for: $0.due)
                return offset == 0 ? d <= day : d == day
            }
            let kinds = Array(Set(todays.map(\.kind))).sorted { $0.rawValue < $1.rawValue }
            if !kinds.isEmpty { lines.append("おせわ：" + kinds.map(\.label).joined(separator: "・")) }
            return lines.isEmpty ? nil : Morning(day: day, body: lines.joined(separator: "\n"))
        }
    }
}
