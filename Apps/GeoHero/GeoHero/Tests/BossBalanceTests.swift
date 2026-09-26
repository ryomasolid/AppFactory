import Testing
@testable import GeoHero

/// ボスは 着くころの レベル・装備で、「ちしき」で まもりを やぶり、回復しながら戦えば 勝てる。
/// 駒ヶ岳のぬし・天狗を 足して 旅が のびたので、藻岩山・羅臼岳の ボスも 着くころのレベルに合わせた。
struct BossBalanceTests {

    /// ボスと、倒しに行くころの レベル・装備・問題の土地。
    private let bosses: [(EnemyKind, Int, Item, Item, QuizRegion)] = [
        (.squidLord, 5, .copperSword, .leatherArmor, .hakodate),
        (.komaLord, 7, .copperSword, .leatherArmor, .onuma),
        (.tengu, 10, .copperSword, .leatherArmor, .otaru),
        (.bearLord, 11, .steelSword, .chainMail, .sapporo),
        (.todoLord, 14, .steelSword, .chainMail, .utoro),
        (.guardian, 15, .steelSword, .chainMail, .rausu),
    ]

    /// まもりが のこっていれば 問題に答え、HPが へったら 回復し、それ以外は こうげき。薬草は 5つ。
    private func wins(_ kind: EnemyKind, level: Int, weapon: Item, armor: Item, region: QuizRegion) -> Int {
        var wins = 0
        for seed in UInt64(1)...20 {
            var rng = SeededRandomSource(seed: seed)
            var hero = Hero()
            _ = hero.gainExp(LevelTable.row(level).exp)
            hero.receive(weapon)
            hero.receive(armor)
            for _ in 0..<5 { hero.receive(.herb) }
            hero.restoreFully()
            var battle = Battle(hero: hero, enemies: [Enemy(kind)], quizzes: region.quizzes)
            var end: BattleEnd?
            for _ in 0..<80 where end == nil {
                let me = battle.hero
                let command: BattleCommand
                if me.hp < me.maxHP * 2 / 5, let heal = [Spell.highHeal, .heal].first(where: { me.spells.contains($0) && me.mp >= $0.mpCost }) {
                    command = .spell(heal)
                } else if me.hp < me.maxHP * 2 / 5, me.inventory[.herb, default: 0] > 0 {
                    command = .item(.herb)
                } else if battle.veil > 0, let quiz = battle.nextQuiz {
                    command = .quiz(answer: quiz.answer)
                } else {
                    command = .attack
                }
                end = battle.take(command, target: 0, rng: &rng).end
            }
            if case .won = end { wins += 1 }
        }
        return wins
    }

    @Test func bossesAreBeatableWhenPrepared() {
        for (kind, level, weapon, armor, region) in bosses {
            let won = wins(kind, level: level, weapon: weapon, armor: armor, region: region)
            #expect(won >= 18, "\(kind.stats.name) に LV\(level) で \(won)/20 回しか 勝てない")
        }
    }
}
