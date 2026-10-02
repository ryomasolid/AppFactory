import Testing
@testable import GeoHero2

/// 戦いの 手ごたえ。敵の 強さは `Balance` の 式で 決まるので、ここで 場所ごとに たしかめる。
struct BalanceTests {

    /// 同じ敵 `count` 体と 20戦して、勝った数と 勝ったときに のこった HP の割合（平均）を返す。
    /// `healing` なら HP が 4割を 切ったら 回復の呪文・りんご（3つ）で なおす。ほかは こうげき だけ。
    static func fights(_ arrival: Balance.Arrival, against kind: EnemyKind, count: Int,
                       healing: Bool = false) -> (wins: Int, hpLeft: Double) {
        var wins = 0
        var hpLeft = 0.0
        for seed in UInt64(1)...20 {
            var rng = SeededRandomSource(seed: seed)
            var hero = Balance.hero(arrival)
            hero.inventory[.apple] = healing ? 3 : 0
            hero.restoreFully()
            var battle = Battle(hero: hero, enemies: EnemyGroup.numbered(Array(repeating: kind, count: count)))
            var end: BattleEnd?
            var lastHP = 0
            for _ in 0..<60 where end == nil {
                let me = battle.hero
                var command = BattleCommand.attack
                if healing, me.hp < me.maxHP * 2 / 5 {
                    if let heal = [Spell.fullHeal, .highHeal, .heal].first(where: { me.spells.contains($0) && me.mp >= $0.mpCost }) {
                        command = .spell(heal)
                    } else if me.herbCount > 0 {
                        command = .item(.apple)
                    }
                }
                let result = battle.take(command, rng: &rng)
                end = result.end
                if let won = result.lines.first(where: { $0.text == "たたかいに かった！" }) { lastHP = won.hero?.hp ?? 0 }
            }
            if case .won = end {
                wins += 1
                hpLeft += Double(lastHP) / Double(battle.hero.maxHP)
            }
        }
        return (wins, wins > 0 ? hpLeft / Double(wins) : 0)
    }

    /// 着いたころの レベル・装備なら 同じ敵 3体に 回復しながら 勝てる。
    /// ただし 楽ではない：ひと振りでは 倒せず、回復なしだと HP が 半分より 多く へる。
    @Test func everyPlaceIsBeatableOnArrival() {
        var strongest = FixedRandomSource(pick: .max)
        for (index, place) in Balance.places.enumerated() {
            let hero = Balance.hero(place.arrival)
            for kind in place.enemies {
                let hit = Battle.damage(attack: hero.attack, defense: kind.stats.defense, rng: &strongest)
                #expect(hit < kind.stats.maxHP, "\(place.name) の \(kind.name) を ひと振りで 倒せる")
                let healed = Self.fights(place.arrival, against: kind, count: 3, healing: true)
                #expect(healed.wins >= 19, "\(place.name) LV\(place.arrival.level) で \(kind.name)×3 に 回復しても \(20 - healed.wins)/20 回 負ける")
                let bare = Self.fights(place.arrival, against: kind, count: 3)
                #expect(bare.wins >= 12, "\(place.name) LV\(place.arrival.level) で \(kind.name)×3 に 回復なしだと \(20 - bare.wins)/20 回 負ける")
                #expect(index == 0 || bare.hpLeft <= 0.6, "\(place.name) の \(kind.name)×3 が 楽すぎる（HP \(Int(bare.hpLeft * 100))% のこる）")
            }
        }
    }

    /// 2レベル 足りず 装備も 前の ままだと、3体には まず 勝てない（1体なら 回復しながら 勝てる）。
    @Test func underleveledHeroCannotBreezeThrough() {
        for index in 3..<Balance.places.count {
            let place = Balance.places[index]
            let earlier = Balance.places[index - 2].arrival
            let weak = Balance.Arrival(level: place.arrival.level - 2, weapon: earlier.weapon, armor: earlier.armor)
            for kind in place.enemies {
                let won = Self.fights(weak, against: kind, count: 3).wins
                #expect(won <= 13, "\(place.name) の \(kind.name)×3 に LV\(weak.level) で \(won)/20 回 勝ててしまう")
                let alone = Self.fights(weak, against: kind, count: 1, healing: true).wins
                #expect(alone >= 15, "\(place.name) の \(kind.name) 1体に LV\(weak.level) で \(20 - alone)/20 回 負ける")
            }
        }
    }

    /// ボスは いどむ レベル・装備で、ときどき 出る ちしきに 正解しながら 回復して 戦えば 勝てる。
    static func bossFights(_ kind: EnemyKind) -> (wins: Int, turns: Int) {
        let plan = Balance.bosses[kind]!
        let place = Balance.places[plan.place - 1]
        let quizzes = QuizBank.byTown.values.first ?? []
        var wins = 0
        var turns = 0
        for seed in UInt64(1)...20 {
            var rng = SeededRandomSource(seed: seed)
            var hero = Balance.hero(Balance.Arrival(level: plan.level, weapon: place.arrival.weapon, armor: place.arrival.armor))
            hero.inventory[.apple] = 5
            hero.restoreFully()
            var battle = Battle(hero: hero, enemies: [Enemy(kind)], quizzes: quizzes)
            var end: BattleEnd?
            for _ in 0..<80 where end == nil {
                let me = battle.hero
                let command: BattleCommand
                if me.hp < me.maxHP * 2 / 5, let heal = [Spell.fullHeal, .highHeal, .heal].first(where: { me.spells.contains($0) && me.mp >= $0.mpCost }) {
                    command = .spell(heal)
                } else if me.hp < me.maxHP * 2 / 5, me.herbCount > 0 {
                    command = .item(.apple)
                } else if let quiz = battle.nextQuiz, rng.chance(battle.quizChanceDenominator) {
                    command = .quizAttack(answer: quiz.answer)
                } else {
                    command = .attack
                }
                end = battle.take(command, target: 0, rng: &rng).end
                turns += 1
            }
            if case .won = end { wins += 1 }
        }
        return (wins, turns / 20)
    }

    @Test(arguments: EnemyKind.allCases.filter(\.isBoss))
    func bossesAreBeatableButTough(kind: EnemyKind) {
        let (wins, turns) = Self.bossFights(kind)
        #expect(wins >= 14, "\(kind.name) に \(wins)/20 回しか 勝てない")
        #expect(wins <= 19 || turns >= 8, "\(kind.name) が かんたんすぎる（平均 \(turns) ターン）")
        #expect(turns >= 6, "\(kind.name) が 平均 \(turns) ターンで おわる")
    }

    /// 旅の 先ほど 敵は 強く、もらえる 経験値も ふえる（場所ごとの 平均で 見る）。
    @Test func enemiesGrowAlongTheRoute() {
        var last = (hp: 0.0, exp: 0.0)
        for place in Balance.places {
            let hp = Double(place.enemies.map(\.stats.maxHP).reduce(0, +)) / 3
            let exp = Double(place.enemies.map(\.stats.exp).reduce(0, +)) / 3
            #expect(hp >= last.hp * 0.85, "\(place.name) の 敵が 前より 弱い")
            #expect(exp >= last.exp, "\(place.name) の 経験値が 前より すくない")
            last = (hp, exp)
        }
    }

    /// どの 敵も どこかに 出る（ボス以外）。
    @Test func everyEnemyAppears() {
        let tables = World.all.values.flatMap { map in
            map.encounterAreas.flatMap(\.enemies) + map.encounters.values.flatMap { $0 }
        }
        for kind in EnemyKind.allCases where !kind.isBoss {
            #expect(tables.contains(kind), "\(kind.name) が どこにも 出ない")
        }
    }

    /// 戦いの メッセージに 名前が おさまる。
    @Test func enemyNamesAreShort() {
        for kind in EnemyKind.allCases {
            #expect(kind.name.count <= 9, "\(kind.name) が 長い")
        }
    }
}
