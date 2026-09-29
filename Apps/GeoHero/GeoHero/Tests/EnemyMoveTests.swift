import Foundation
import Testing
@testable import GeoHero

/// 敵は こうげき だけでなく、その土地に ちなんだ わざ（呪文・回復・強さを 上げる・つうこん）を 使う。
struct EnemyMoveTests {

    /// 勇者は 何もしない（持っていない 道具を 使おうとする）ので、敵の 行動だけが 見える。
    private let idle = BattleCommand.item(.hanabi)

    private func strongHero() -> Hero {
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(LevelTable.maxLevel).exp)
        hero.receive(.orcaSpear)
        hero.receive(.driftIceArmor)
        hero.restoreFully()
        return hero
    }

    /// 敵の 行動を `turns` ターンぶん 集める。
    private func enemyLines(_ enemies: [Enemy], seed: UInt64, turns: Int = 6) -> [BattleLine] {
        var rng = SeededRandomSource(seed: seed)
        var battle = Battle(hero: strongHero(), enemies: enemies)
        var lines: [BattleLine] = []
        for _ in 0..<turns where battle.end == nil {
            lines += battle.take(idle, rng: &rng).lines
        }
        return lines
    }

    /// ボス でない敵も ほぼ みな わざを もつ（こうげき だけ だと 単調）。
    @Test func mostFieldEnemiesHaveMoves() {
        let field = EnemyKind.allCases.filter { !$0.isBoss }
        let plain = field.filter(\.specialMoves.isEmpty)
        #expect(plain.isEmpty, "わざの ない敵: \(plain.map(\.stats.name))")
    }

    /// ボスは 強さを 上げる わざを もち、あとの ボスほど 手数が 多い。
    @Test func bossesRaiseTheirStrength() {
        let bosses = EnemyKind.allCases.filter(\.isBoss)
        for boss in bosses {
            let boosts = boss.specialMoves.filter { if case .boost = $0 { true } else { false } }
            #expect(!boosts.isEmpty, "\(boss.stats.name) が 強さを 上げない")
        }
        #expect(EnemyKind.guardian.specialMoves.count > EnemyKind.squidLord.specialMoves.count)
        // 守護神は こうげき・しゅび・すばやさ の みっつとも 上げる。
        let raised = Set(EnemyKind.guardian.specialMoves.compactMap { if case let .boost(b, _) = $0 { b } else { nil } })
        #expect(raised == Set(EnemyBoost.allCases))
    }

    /// 呪文は 守備力を 無視して 当たり、画面に 火の粉を 降らせる。
    @Test func fieldEnemyCastsMagic() {
        let found = (UInt64(1)...30).contains { seed in
            enemyLines([Enemy(.seagull)], seed: seed).contains { $0.text.contains("はねを とばした") && $0.effect == .breath }
        }
        #expect(found, "うみねこが 一度も わざを 使わない")
    }

    /// 呪文の ダメージは よろいで へらない。
    @Test func magicIgnoresArmor() {
        var low = FixedRandomSource(pick: .min)
        #expect(Battle.magicDamage(attack: 40, rng: &low) == 16)
        var high = FixedRandomSource(pick: .max)
        #expect(Battle.magicDamage(attack: 40, rng: &high) == 24)
    }

    /// 上げた 段の ぶんだけ 能力が 上がり、上限で 止まる。
    @Test func boostsRaiseStatsByStage() {
        var enemy = Enemy(.guardian)
        let base = EnemyKind.guardian.stats
        enemy.boosts = [.attack: 2, .defense: 1, .agility: 2]
        #expect(enemy.attack == base.attack * 6 / 4)
        #expect(enemy.defense == base.defense * 3 / 2)
        #expect(enemy.agility == base.agility * 2)
    }

    /// ボスは 戦いの なかで 強さを 上げてくる。上限（2段）より 上には 上げない。
    @Test func bossBoostsDuringBattleUpToTheCap() {
        var sawBoost = false
        for seed in UInt64(1)...20 {
            var rng = SeededRandomSource(seed: seed)
            var battle = Battle(hero: strongHero(), enemies: [Enemy(.guardian)])
            for _ in 0..<12 where battle.end == nil {
                let lines = battle.take(idle, rng: &rng).lines
                if lines.contains(where: { $0.text.hasSuffix("が あがった！") }) { sawBoost = true }
                for stage in battle.enemy.boosts.values { #expect(stage <= EnemyBoost.maxStage) }
            }
        }
        #expect(sawBoost, "守護神が 一度も 強さを 上げない")
    }

    /// 「ちしきの チャンス」に 正解すると、敵が 上げた 強さが もとに もどる。
    @Test func correctAnswerClearsBoosts() {
        let quiz = Quiz(question: "函館の 名物は？", choices: ["いかめし", "もみじまんじゅう", "ちんすこう"], answer: 0)
        var enemy = Enemy(.guardian)
        enemy.boosts = [.defense: 2, .attack: 1]
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(12).exp)
        var rng = SeededRandomSource(seed: 3)
        var battle = Battle(hero: hero, enemies: [enemy], quizzes: [quiz])
        let lines = battle.take(.quizAttack(answer: 0), rng: &rng).lines
        #expect(lines.contains { $0.text.contains("ちからが もとに もどった") })
    }

    /// まちがえても 強さは もどらない。
    @Test func wrongAnswerKeepsBoosts() {
        let quiz = Quiz(question: "函館の 名物は？", choices: ["いかめし", "もみじまんじゅう", "ちんすこう"], answer: 0)
        var enemy = Enemy(.guardian)
        enemy.boosts = [.defense: 2]
        var rng = SeededRandomSource(seed: 3)
        var battle = Battle(hero: strongHero(), enemies: [enemy], quizzes: [quiz])
        let lines = battle.take(.quizAttack(answer: 1), rng: &rng).lines
        #expect(!lines.contains { $0.text.contains("ちからが もとに もどった") })
        #expect(battle.enemy.stage(.defense) == 2)
    }

    /// ボス でない敵の 回復は 1戦に 1回まで（何度も 治されると 終わらない）。
    @Test func fieldHealerHealsOnlyOnce() {
        func heals(alreadyHealed: Bool) -> Int {
            (UInt64(1)...30).reduce(0) { total, seed in
                var enemy = Enemy(.kelpSlime)
                enemy.hp = 1
                enemy.hasHealed = alreadyHealed
                let lines = enemyLines([enemy], seed: seed, turns: 4)
                return total + lines.filter { $0.text.contains("きずが かいふくした") }.count
            }
        }
        #expect(heals(alreadyHealed: false) > 0, "弱っても 回復しない")
        #expect(heals(alreadyHealed: true) == 0, "2回目の 回復を している")
        // 1戦の なかでも 2回は 治さない。
        for seed in UInt64(1)...30 {
            var enemy = Enemy(.kelpSlime)
            enemy.hp = 1
            let lines = enemyLines([enemy], seed: seed, turns: 12)
            #expect(lines.filter { $0.text.contains("だしを すった") }.count <= 1)
        }
    }

    /// 元気な 敵は 回復の わざを 使わない（こうげきに まわす）。
    @Test func healthyEnemyDoesNotHeal() {
        for seed in UInt64(1)...30 {
            let lines = enemyLines([Enemy(.kelpSlime)], seed: seed, turns: 4)
            #expect(!lines.contains { $0.text.contains("だしを すった") })
        }
    }
}
