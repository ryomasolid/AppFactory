import Foundation
import Observation

/// 国ごと・覚えるものごとの記録。続けて3回正解で「覚えた」。まちがえると0にもどる。
struct Mark: Codable, Equatable {
    var streak = 0
    var corrects = 0
    var misses = 0

    var mastered: Bool { streak >= Learned.masteredStreak }
    var seen: Bool { corrects + misses > 0 }
}

@Observable
final class Learned {
    static let masteredStreak = 3

    private(set) var marks: [String: Mark] = [:]
    private let defaults: UserDefaults?
    private static let key = "progress.v1"

    /// defaults が nil なら保存しない（見本・テスト用）。
    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
        if let data = defaults?.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([String: Mark].self, from: data) {
            marks = saved
        }
    }

    func mark(_ code: String, _ topic: Topic) -> Mark {
        marks[Self.slot(code, topic)] ?? Mark()
    }

    func record(_ code: String, _ topic: Topic, correct: Bool) {
        var m = mark(code, topic)
        if correct {
            m.streak += 1
            m.corrects += 1
        } else {
            m.streak = 0
            m.misses += 1
        }
        marks[Self.slot(code, topic)] = m
        save()
    }

    func masteredCount(_ topic: Topic, in countries: [Country] = Country.all) -> Int {
        countries.filter { mark($0.code, topic).mastered }.count
    }

    /// まちがえたことがあって、まだ覚えていない国。
    func weak(_ topic: Topic, in countries: [Country] = Country.all) -> [Country] {
        countries.filter {
            let m = mark($0.code, topic)
            return m.misses > 0 && !m.mastered
        }
    }

    func reset() {
        marks = [:]
        save()
    }

    /// 見本用：記録をまとめて入れる。
    func load(_ marks: [String: Mark]) {
        self.marks = marks
    }

    static func slot(_ code: String, _ topic: Topic) -> String { "\(code).\(topic.rawValue)" }

    private func save() {
        guard let defaults, let data = try? JSONEncoder().encode(marks) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
