import Testing
@testable import TinyHero

/// 敵は1〜3体で出てくる。3体に囲まれても回復なしで勝ちきれること。
struct GroupBattleTests {

    @Test func groupsAreOneToThree() {
        var rng = SeededRandomSource(seed: 5)
        var sizes: Set<Int> = []
        for _ in 0..<400 {
            let group = EnemyGroup.random(from: [.potato, .kelpSlime], rng: &rng)
            sizes.insert(group.count)
        }
        #expect(sizes == [1, 2, 3], "出てくる数が 1〜3 になっていない: \(sizes.sorted())")
    }

    @Test func duplicatesGetLetters() {
        let group = EnemyGroup.numbered([.potato, .potato, .kelpSlime])
        #expect(group[0].name == "ポテトーA")
        #expect(group[1].name == "ポテトーB")
        #expect(group[2].name == "こんぶスライム")
        #expect(Set(group.map(\.id)).count == 3, "id が かぶっている")
    }

    @Test func encounterTextCountsThem() {
        #expect(EnemyGroup.encounterText(EnemyGroup.numbered([.potato, .potato]))
                == "ポテトー 2ひきが あらわれた！")
        #expect(EnemyGroup.encounterText(EnemyGroup.numbered([.snowman]))
                == "ゆきおとこが あらわれた！")
    }

    /// 経験値とゴールドは たおした敵ぶんを合計する。
    @Test func rewardsAddUpAcrossTheGroup() {
        var rng = SeededRandomSource(seed: 3)
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(6).exp)
        hero.receive(.steelSword)
        var battle = Battle(hero: hero, enemies: EnemyGroup.numbered([.potato, .potato, .potato]))
        var end: BattleEnd?
        for _ in 0..<20 where end == nil {
            end = battle.take(.attack, rng: &rng).end
        }
        let one = EnemyKind.potato.stats
        #expect(end == .won(exp: one.exp * 3, gold: one.gold * 3))
    }

    /// たおした敵は もう殴ってこない（3体ぶんの攻撃が続かない）。
    @Test func defeatedEnemiesStopAttacking() {
        var rng = SeededRandomSource(seed: 9)
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(8).exp)
        hero.receive(.steelSword)
        var battle = Battle(hero: hero, enemies: EnemyGroup.numbered([.potato, .potato, .potato]))
        _ = battle.take(.attack, rng: &rng)
        #expect(battle.living.count < 3, "1ターンで 1体も 倒せていない")
    }

    /// そのエリアに入りたてのレベルなら、3体でも回復なしで勝てる。
    @Test func threeEnemiesAreBeatableWithoutHealing() {
        // エリアと、そこに着くころのレベル・装備。
        let cases: [(String, EnemyKind, Int, Item, Item)] = [
            ("くさち", .kelpSlime, 1, .woodStick, .clothes),
            ("もり", .fox, 3, .woodStick, .clothes),
            ("おか", .cod, 5, .copperSword, .leatherArmor),
            ("ほらあなB1", .snowman, 7, .copperSword, .leatherArmor),
            ("ほらあなB2", .iceGolem, 9, .steelSword, .chainMail),
        ]
        for (zone, kind, level, weapon, armor) in cases {
            var losses = 0
            for seed in UInt64(1)...20 {
                var rng = SeededRandomSource(seed: seed)
                var hero = Hero()
                _ = hero.gainExp(LevelTable.row(level).exp)
                hero.receive(weapon)
                hero.receive(armor)
                hero.restoreFully()

                var battle = Battle(hero: hero, enemies: EnemyGroup.numbered([kind, kind, kind]))
                var end: BattleEnd?
                for _ in 0..<60 where end == nil {
                    end = battle.take(.attack, rng: &rng).end
                }
                if end != .won(exp: kind.stats.exp * 3, gold: kind.stats.gold * 3) { losses += 1 }
            }
            #expect(losses == 0, "\(zone) LV\(level) で \(kind.stats.name)×3 に \(losses)/20 回 負ける")
        }
    }

    /// ボスは1体で出てくる（群れない）。
    @Test func bossComesAlone() {
        let battle = Battle(hero: Hero(), enemies: EnemyGroup.numbered([.guardian]))
        #expect(battle.enemies.count == 1)
        #expect(battle.isBoss)
    }
}
