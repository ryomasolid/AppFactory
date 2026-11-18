import Foundation
import Testing
@testable import KokkiShuto

struct CountryTests {
    @Test func count() {
        #expect(Country.all.count == 197)
    }

    @Test func uniqueCodesNamesCapitals() {
        #expect(Set(Country.all.map(\.code)).count == Country.all.count)
        #expect(Set(Country.all.map(\.name)).count == Country.all.count)
        #expect(Set(Country.all.map(\.capital)).count == Country.all.count)
    }

    @Test func flagEmoji() {
        #expect(Country.find("JP")?.flag == "🇯🇵")
        for c in Country.all {
            #expect(c.flag.unicodeScalars.count == 2)
        }
    }

    @Test func everyRegionHasEnough() {
        for r in Region.allCases {
            #expect(Country.all.filter { $0.region == r }.count >= 4)
        }
    }
}

struct QuizMakerTests {
    @Test func fourDistinctChoicesWithAnswer() {
        var rng = SystemRandomNumberGenerator()
        for mode in Mode.allCases {
            for c in Country.all {
                let q = QuizMaker.question(for: c, mode: mode, using: &rng)
                #expect(q.choices.count == 4)
                #expect(q.choices.contains { $0 == c })
                #expect(Set(q.choices.map { q.label(of: $0) }).count == 4)
            }
        }
    }

    @Test func lookalikeFlagsNeverTogether() {
        var rng = SystemRandomNumberGenerator()
        let chad = Country.find("TD")!
        for _ in 0..<300 {
            let q = QuizMaker.question(for: chad, mode: .nameToFlag, using: &rng)
            #expect(!q.choices.contains { $0.code == "RO" })
        }
    }

    @Test func pickPrefersUnmastered() {
        let p = Learned(defaults: nil)
        let pool = Array(Country.all.prefix(20))
        for c in pool.prefix(10) {
            for _ in 0..<3 { p.record(c.code, .flag, correct: true) }
        }
        var rng = SystemRandomNumberGenerator()
        let picked = QuizMaker.pick(from: pool, count: 10, topic: .flag, progress: p, using: &rng)
        let fresh = picked.filter { !p.mark($0.code, .flag).mastered }.count
        #expect(fresh >= 8)
    }
}

struct ProgressTests {
    @Test func streakAndWeak() {
        let p = Learned(defaults: nil)
        p.record("FR", .capital, correct: true)
        p.record("FR", .capital, correct: false)
        #expect(p.mark("FR", .capital).streak == 0)
        #expect(p.weak(.capital).map(\.code) == ["FR"])
        for _ in 0..<3 { p.record("FR", .capital, correct: true) }
        #expect(p.mark("FR", .capital).mastered)
        #expect(p.weak(.capital).isEmpty)
        #expect(p.masteredCount(.capital) == 1)
        #expect(p.masteredCount(.flag) == 0)
    }
}
