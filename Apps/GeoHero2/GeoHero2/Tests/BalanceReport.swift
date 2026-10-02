import Testing
@testable import GeoHero2

/// 調整用の 一覧（ふだんは 見ない）。`REPORT` を grep する。
struct BalanceReport {
    @Test(.disabled("調整するときだけ 動かす")) func report() {
        for (index, place) in Balance.places.enumerated() {
            let hero = Balance.hero(place.arrival)
            for kind in place.enemies {
                let s = kind.stats
                let healed = BalanceTests.fights(place.arrival, against: kind, count: 3, healing: true)
                let bare = BalanceTests.fights(place.arrival, against: kind, count: 3)
                let earlier = Balance.places[max(0, index - 2)].arrival
                let weak = Balance.Arrival(level: max(1, place.arrival.level - 2), weapon: earlier.weapon, armor: earlier.armor)
                let under = BalanceTests.fights(weak, against: kind, count: 3).wins
                let alone = BalanceTests.fights(weak, against: kind, count: 1, healing: true).wins
                print("REPORT \(index + 1) \(place.name) \(kind.name) hp\(s.maxHP) at\(s.attack) df\(s.defense) ag\(s.agility) ex\(s.exp) | hero at\(hero.attack) df\(hero.defense) hp\(hero.maxHP) ag\(hero.agility) | heal \(healed.wins) bare \(bare.wins) left \(Int(bare.hpLeft * 100))% | under \(under) alone \(alone)")
            }
        }
        for kind in EnemyKind.allCases where kind.isBoss {
            let s = kind.stats
            let (wins, turns) = BalanceTests.bossFights(kind)
            print("REPORT BOSS \(kind.name) hp\(s.maxHP) at\(s.attack) df\(s.defense) ag\(s.agility) ex\(s.exp) | wins \(wins) turns \(turns)")
        }
    }
}
