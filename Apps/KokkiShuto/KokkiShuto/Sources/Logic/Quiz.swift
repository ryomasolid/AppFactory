import Foundation

/// 覚えるもの。国旗と首都の2つ（国名はどちらにも出てくる）。
enum Topic: String, Codable, CaseIterable {
    case flag, capital

    var label: String { self == .flag ? "国旗" : "首都" }
}

/// 出題の向き。どれも4択。
enum Mode: String, CaseIterable, Identifiable, Codable {
    case flagToName, nameToFlag, nameToCapital, capitalToName

    var id: String { rawValue }
    var topic: Topic { (self == .flagToName || self == .nameToFlag) ? .flag : .capital }

    var title: String {
        switch self {
        case .flagToName: "国旗 → 国名"
        case .nameToFlag: "国名 → 国旗"
        case .nameToCapital: "国名 → 首都"
        case .capitalToName: "首都 → 国名"
        }
    }

    var question: String {
        switch self {
        case .flagToName: "この国旗の国は？"
        case .nameToFlag: "この国の国旗は？"
        case .nameToCapital: "この国の首都は？"
        case .capitalToName: "ここが首都の国は？"
        }
    }

    var symbol: String {
        switch self {
        case .flagToName: "flag"
        case .nameToFlag: "square.grid.2x2"
        case .nameToCapital: "building.columns"
        case .capitalToName: "mappin.and.ellipse"
        }
    }
}

struct Question: Identifiable, Equatable {
    let id = UUID()
    let mode: Mode
    let answer: Country
    let choices: [Country]

    /// 問題文の大きな表示（国旗・国名・首都のどれか）。
    var prompt: String {
        switch mode {
        case .flagToName: answer.flag
        case .nameToFlag, .nameToCapital: answer.name
        case .capitalToName: answer.capital
        }
    }

    func label(of choice: Country) -> String {
        switch mode {
        case .flagToName, .capitalToName: choice.name
        case .nameToFlag: choice.flag
        case .nameToCapital: choice.capital
        }
    }
}

enum QuizMaker {
    /// 出題する国を選ぶ。まだ覚えていない国・まちがえた国を先に、覚えた国もときどき混ぜる。
    static func pick(
        from pool: [Country], count: Int, topic: Topic, progress: Learned,
        using rng: inout some RandomNumberGenerator
    ) -> [Country] {
        let scored = pool.map { country -> (Country, Double) in
            let mark = progress.mark(country.code, topic)
            var score = Double(min(mark.streak, Learned.masteredStreak)) + Double.random(in: 0..<1.6, using: &rng)
            if mark.misses > 0 && !mark.mastered { score -= 0.5 }
            return (country, score)
        }
        return scored.sorted { $0.1 < $1.1 }.prefix(count).map(\.0)
    }

    /// 1問ぶん。まちがいの3つは、なるべく同じ地域から（見分けがいるように）。
    static func question(
        for answer: Country, mode: Mode, all: [Country] = Country.all,
        using rng: inout some RandomNumberGenerator
    ) -> Question {
        var taken: Set<String> = [answer.code]
        var labels: Set<String> = [label(answer, mode)]
        var wrong: [Country] = []

        func ok(_ c: Country) -> Bool {
            guard !taken.contains(c.code), !labels.contains(label(c, mode)) else { return false }
            if mode.topic == .flag {
                let codes = taken.union([c.code])
                if Country.lookalikes.contains(where: { $0.isSubset(of: codes) }) { return false }
            }
            return true
        }
        func add(from list: [Country], upTo limit: Int) {
            for c in list.shuffled(using: &rng) where wrong.count < limit && ok(c) {
                wrong.append(c)
                taken.insert(c.code)
                labels.insert(label(c, mode))
            }
        }

        add(from: all.filter { $0.region == answer.region }, upTo: 2)
        add(from: all, upTo: 3)

        var choices = wrong + [answer]
        choices.shuffle(using: &rng)
        return Question(mode: mode, answer: answer, choices: choices)
    }

    static func round(
        modes: [Mode], countries: [Country], using rng: inout some RandomNumberGenerator
    ) -> [Question] {
        countries.map { c in
            let mode = modes.randomElement(using: &rng) ?? .flagToName
            return question(for: c, mode: mode, using: &rng)
        }
    }

    private static func label(_ c: Country, _ mode: Mode) -> String {
        switch mode {
        case .flagToName, .capitalToName: c.name
        case .nameToFlag: c.code
        case .nameToCapital: c.capital
        }
    }
}
