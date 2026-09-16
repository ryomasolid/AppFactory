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

    /// 勇者が先手を取れる確率。`Battle` の決め方（勇者は 0…すばやさ×2、敵は 0…すばやさ）と同じ。
    private func firstStrikeChance(heroAgility: Int, enemyAgility: Int) -> Double {
        let heroFaces = heroAgility * 2 + 1
        let enemyFaces = enemyAgility + 1
        var wins = 0
        for hero in 0..<heroFaces where true {
            for enemy in 0..<enemyFaces where hero >= enemy { wins += 1 }
        }
        return Double(wins) / Double(heroFaces * enemyFaces)
    }

    /// 最初のフィールドでは、勇者がたいてい先手を取れる。
    /// （ホタテキッドが すばやさ9 のままで、LV1 では先手が五分だった）
    @Test func heroUsuallyStrikesFirstOnTheField() {
        // 地形と、そこを歩くころのレベル。
        let zones: [(Tile, Int)] = [(.grass, 1), (.forest, 3), (.hills, 5)]
        for (tile, level) in zones {
            let heroAgility = LevelTable.row(level).agility
            for kind in World.map(.field).encounters[tile] ?? [] {
                let chance = firstStrikeChance(heroAgility: heroAgility, enemyAgility: kind.stats.agility)
                #expect(chance >= 0.65,
                        "LV\(level) で \(kind.stats.name) に 先手を取れるのが \(Int(chance * 100))% しかない")
            }
        }
    }

    /// すばやさは 題材の順になっている（こんぶ < ポテトー < ホタテ < タラ < きつね）。
    @Test func agilityFollowsWhatTheyAre() {
        let order: [EnemyKind] = [.kelpSlime, .potato, .scallop, .cod, .fox]
        let values = order.map(\.stats.agility)
        #expect(values == values.sorted(), "すばやさの順が ちぐはぐ: \(values)")
    }

    /// ボスは1体で出てくる（群れない）。
    @Test func bossComesAlone() {
        let battle = Battle(hero: Hero(), enemies: EnemyGroup.numbered([.guardian]))
        #expect(battle.enemies.count == 1)
        #expect(battle.isBoss)
    }
}
