import Foundation

/// 体重の見守り。小鳥は具合の悪さを隠すので、毎日のグラムの減りがいちばん早いサインになる。
/// 直前7日のふだんの体重（平均）と、いちばん新しい体重をくらべる。
enum GramWatch {
    enum Level: Equatable {
        case steady
        /// 5%以上へった。
        case dipping(percent: Int)
        /// 10%以上へった（すぐ病院へ）。
        case falling(percent: Int)
        /// 10%以上ふえた（発情・太りすぎ・お腹の卵など）。
        case rising(percent: Int)
    }

    struct Reading: Equatable {
        var latest: Double
        var latestDay: Date
        var usual: Double?
        var level: Level
        /// 3回つづけて減っている。
        var slidingDown: Bool
    }

    static let dipLine = -0.05
    static let fallLine = -0.10
    static let riseLine = 0.10

    static func read(_ points: [(day: Date, grams: Double)], calendar: Calendar = .current) -> Reading? {
        let list = points.filter { $0.grams > 0 }.sorted { $0.day < $1.day }
        guard let last = list.last else { return nil }
        let lastDay = calendar.startOfDay(for: last.day)
        let from = calendar.date(byAdding: .day, value: -7, to: lastDay)!
        let before = list.dropLast().filter { (from..<lastDay).contains(calendar.startOfDay(for: $0.day)) }
        let usual = before.isEmpty ? nil : before.map(\.grams).reduce(0, +) / Double(before.count)

        var level = Level.steady
        if let usual {
            let ratio = (last.grams - usual) / usual
            let percent = Int((abs(ratio) * 100).rounded())
            if ratio <= fallLine { level = .falling(percent: percent) }
            else if ratio <= dipLine { level = .dipping(percent: percent) }
            else if ratio >= riseLine { level = .rising(percent: percent) }
        }
        let tail = list.suffix(4).map(\.grams)
        let sliding = tail.count == 4 && zip(tail, tail.dropFirst()).allSatisfy { $1 < $0 }
        return Reading(latest: last.grams, latestDay: lastDay, usual: usual.map { ($0 * 10).rounded() / 10 }, level: level, slidingDown: sliding)
    }

    static func text(_ grams: Double) -> String {
        grams.formatted(.number.precision(.fractionLength(1))) + "g"
    }
}
