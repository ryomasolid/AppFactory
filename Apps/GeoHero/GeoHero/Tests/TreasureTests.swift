import Foundation
import Testing
@testable import GeoHero

/// 宝箱からは お金や ハスカップ だけでなく、その土地の 名産や めずらしい 道具が 出る。
struct TreasureTests {

    private var allRewards: [ChestReward] {
        MapID.allCases.flatMap { World.map($0).chests.map(\.reward) }
    }

    /// 宝箱の 中身は いろいろ（同じものばかりに しない）。
    @Test func chestsHoldManyKindsOfThings() {
        let items = Set(allRewards.compactMap { if case let .item(item) = $0 { item } else { nil } })
        #expect(items.count >= 12, "宝箱から 出る道具が \(items.count) 種類しかない")
        let golds = allRewards.filter { if case .gold = $0 { true } else { false } }.count
        #expect(golds * 2 < allRewards.count, "宝箱の 半分以上が お金")
    }

    /// 宝箱でしか 手に入らない 道具は、どれも どこかの 宝箱に 入っている。店には 並ばない。
    @Test func everyTreasureItemIsSomewhere() {
        for item in Item.allCases where item.isTreasure {
            #expect(allRewards.contains(.item(item)), "\(item.name) が どの宝箱にも ない")
        }
        let stock = Set(MapID.allCases.compactMap(\.townInfo).flatMap(\.stock))
        #expect(stock.allSatisfy { !$0.isTreasure }, "宝箱の 道具が 店に 並んでいる")
    }

    /// 花火は 敵みんなに 当たる。
    @Test func fireworksHitEveryEnemy() {
        var hero = Hero()
        hero.receive(.hanabi)
        var rng = SeededRandomSource(seed: 1)
        var battle = Battle(hero: hero, enemies: EnemyGroup.numbered([.cornSoldier, .cornSoldier, .cornSoldier]))
        let lines = battle.take(.item(.hanabi), rng: &rng).lines
        let hitIDs = Set(lines.compactMap(\.enemyID))
        #expect(hitIDs.count == 3)
        #expect(battle.hero.inventory[.hanabi] == nil)
    }

    /// クマよけの鈴で かならず にげられる。ボスからは にげられない。
    @Test func bearBellEscapesButNotFromBosses() {
        for seed in UInt64(1)...10 {
            // 先に きつねに たおされない 強さにする。
            var hero = Hero()
            _ = hero.gainExp(LevelTable.row(8).exp)
            hero.receive(.bearBell)
            var rng = SeededRandomSource(seed: seed)
            var battle = Battle(hero: hero, enemies: EnemyGroup.numbered([.fox, .fox]))
            #expect(battle.take(.item(.bearBell), rng: &rng).end == .fled)

            var bossHero = Hero()
            bossHero.receive(.bearBell)
            var bossBattle = Battle(hero: bossHero, enemies: [Enemy(.squidLord)])
            #expect(bossBattle.take(.item(.bearBell), rng: &rng).end != .fled)
        }
    }

    /// 名産を 食べると 能力が ずっと 上がる。戦いの「どうぐ」には 並ばない。
    @Test func specialtiesRaiseStatsForGood() {
        var hero = Hero()
        let attack = hero.attack, defense = hero.defense, agility = hero.agility, maxHP = hero.maxHP
        var rng = SeededRandomSource(seed: 1)
        for item in [Item.walnut, .soybean, .hakka, .melon] {
            hero.receive(item)
            #expect(hero.canUse(item))
            #expect(!hero.battleItems.contains { $0.item == item })
            _ = hero.consume(item)
            _ = hero.apply(item.effect!, rng: &rng)
        }
        #expect(hero.attack == attack + 2)
        #expect(hero.defense == defense + 2)
        #expect(hero.agility == agility + 2)
        #expect(hero.maxHP == maxHP + 10)
        // レベルが 上がっても 上がった ぶんは 残る。
        _ = hero.gainExp(LevelTable.row(2).exp)
        #expect(hero.attack == LevelTable.row(2).attack + Item.woodStick.power + 2)
    }

    /// 上がった 能力は セーブに 残る。前の セーブ（上がった ぶんが ない）も 読める。
    @Test func growthSurvivesSaveAndOldSavesLoad() throws {
        var hero = Hero()
        hero.grow(.attack, by: 2)
        let data = try JSONEncoder().encode(hero)
        #expect(try JSONDecoder().decode(Hero.self, from: data) == hero)

        var json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["growth"] = nil
        let old = try JSONSerialization.data(withJSONObject: json)
        let loaded = try JSONDecoder().decode(Hero.self, from: old)
        #expect(loaded.growth.isEmpty)
        #expect(loaded.level == hero.level)
    }

    /// フィールドで 名産を 食べると 上がった 能力を 知らせる。
    @MainActor @Test func eatingInTheFieldTellsTheGain() {
        let game = GameState()
        game.waitsForTap = false
        game.newGame()
        game.say([])
        game.hero.receive(.walnut)
        let before = game.hero.attack
        game.useInField(.walnut)
        #expect(game.hero.attack == before + 2)
        #expect(game.currentPage?.contains("こうげきが 2 あがった！") == true)
    }
}
