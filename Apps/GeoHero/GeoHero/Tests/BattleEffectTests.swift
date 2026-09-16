import Foundation
import Testing
@testable import GeoHero

/// 呪文・道具を使ったときに、画面の演出の合図が行に乗るか。
struct BattleEffectTests {

    /// レベルを上げて呪文をひととおり覚えた勇者。
    private func mage(level: Int = 8) -> Hero {
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(level).exp)
        hero.restoreFully()
        return hero
    }

    private func lines(_ command: BattleCommand, hero: Hero, enemy: EnemyKind = .cod, seed: UInt64 = 7) -> [BattleLine] {
        var rng = SeededRandomSource(seed: seed)
        var battle = Battle(hero: hero, enemy: Enemy(enemy))
        return battle.take(command, rng: &rng).lines
    }

    @Test func healingSpellCarriesHealEffect() {
        var hero = mage()
        hero.hp = 5
        let result = lines(.spell(.heal), hero: hero)
        let healEffects = result.compactMap { line -> Int? in
            if case let .heal(amount) = line.effect { return amount }
            return nil
        }
        #expect(healEffects.count == 1)
        #expect((healEffects.first ?? 0) > 0)
    }

    /// HP が満タンなら 0 しか回復しないので、粒と「+0」は出さない。
    @Test func fullHPHealHasNoEffect() {
        var hero = mage()
        hero.restoreFully()
        let result = lines(.spell(.heal), hero: hero)
        // メッセージは出すが、演出は出さない。
        let hasHealLine = result.contains { $0.text.contains("かいふく") }
        #expect(hasHealLine)
        let hasEffect = result.contains { if case .heal = $0.effect { return true } else { return false } }
        #expect(hasEffect == false)
    }

    @Test func attackSpellCarriesFlameEffect() {
        let result = lines(.spell(.fire), hero: mage())
        let flames = result.compactMap { line -> Bool? in
            if case let .flame(big) = line.effect { return big }
            return nil
        }
        #expect(flames == [false], "ファイアは小さい炎")
    }

    @Test func flameSpellIsBig() {
        let result = lines(.spell(.flame), hero: mage())
        let flames = result.compactMap { line -> Bool? in
            if case let .flame(big) = line.effect { return big }
            return nil
        }
        #expect(flames == [true], "フレイムは大きい炎")
    }

    /// 火の玉は「となえた！」の行で飛ばし、そのあとにダメージの行が来る。
    @Test func flameEffectComesBeforeDamage() {
        let result = lines(.spell(.fire), hero: mage())
        let flameIndex = result.firstIndex { if case .flame = $0.effect { return true } else { return false } }
        let damageIndex = result.firstIndex { $0.enemyDamage != nil }
        let flame = try! #require(flameIndex)
        let damage = try! #require(damageIndex)
        #expect(flame < damage)
    }

    @Test func herbCarriesHealEffect() {
        var hero = mage(level: 3)
        hero.hp = 5
        hero.receive(.herb)
        let result = lines(.item(.herb), hero: hero)
        let hasHeal = result.contains { if case .heal = $0.effect { return true } else { return false } }
        #expect(hasHeal)
    }

    @Test func plainAttackHasNoSpellEffect() {
        let result = lines(.attack, hero: mage())
        let hasEffect = result.contains { $0.effect != nil }
        #expect(hasEffect == false, "こうげきには呪文の演出を出さない")
    }

    /// MP が足りないときは呪文が不発なので、炎も出さない。
    @Test func failedSpellHasNoEffect() {
        var hero = mage()
        hero.mp = 0
        let result = lines(.spell(.flame), hero: hero)
        let hasEffect = result.contains { $0.effect != nil }
        #expect(hasEffect == false)
    }

    /// ボスのほのおは画面の火の粉の合図を持つ。
    @Test func bossBreathCarriesBreathEffect() {
        var found = false
        for seed in UInt64(1)...40 {
            let result = lines(.attack, hero: mage(level: 10), enemy: .guardian, seed: seed)
            if result.contains(where: { $0.effect == .breath }) {
                found = true
                break
            }
        }
        #expect(found, "ほのおの演出が 一度も 出ない")
    }
}

/// 起動引数で自動のコマンドを選べる（表示確認用）。
@MainActor
struct LaunchAutoCommandTests {

    @Test func mapsNamesToCommands() {
        #expect(Launch.autoCommand("attack") == .attack)
        #expect(Launch.autoCommand("fire") == .spell(.fire))
        #expect(Launch.autoCommand("highHeal") == .spell(.highHeal))
        #expect(Launch.autoCommand("herb") == .item(.herb))
    }

    @Test func unknownNameIsIgnored() {
        #expect(Launch.autoCommand(nil) == nil)
        #expect(Launch.autoCommand("なにこれ") == nil)
    }
}
