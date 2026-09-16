import Foundation
import Testing
@testable import TinyHero

/// ドット絵の書き間違い（行の長さ違い・未定義の色）を捕まえる。
struct SpriteTests {

    @Test func everySpriteIs16x16WithKnownColors() {
        for id in SpriteID.allCases {
            let rows = SpriteID.art[id] ?? []
            #expect(rows.count == 16, "\(id) の行数が \(rows.count)")
            for (y, row) in rows.enumerated() {
                #expect(row.count == 16, "\(id) の \(y) 行目が \(row.count) 文字")
                for char in row where char != "." {
                    #expect(Palette.colors[char] != nil, "\(id) に未定義の色 \(char)")
                }
            }
        }
    }
}

struct HeroSpriteTests {

    @Test func rightFacingIsMirrorOfLeft() {
        #expect(SpriteID.art[.heroRight1] == CharacterArt.mirrored(CharacterArt.heroLeft1))
        #expect(SpriteID.art[.heroRight2] == CharacterArt.mirrored(CharacterArt.heroLeft2))
    }

    @Test func eachDirectionHasItsOwnTwoFrames() {
        var seen: Set<SpriteID> = []
        for direction in Direction.allCases {
            let first = SpriteID.hero(facing: direction, step: 0)
            let second = SpriteID.hero(facing: direction, step: 1)
            #expect(first != second)
            #expect(SpriteID.hero(facing: direction, step: 2) == first)
            seen.insert(first)
            seen.insert(second)
        }
        #expect(seen.count == 8)
        // 下向きの1コマ目はタイトルなどで使う従来の絵のまま。
        #expect(SpriteID.hero(facing: .down, step: 0) == .hero1)
    }
}

struct MapTests {

    @Test func mapsAreRectangular() {
        for id in MapID.allCases {
            let map = World.map(id)
            #expect(map.height > 0)
            for row in map.tiles {
                #expect(row.count == map.width, "\(id) の行の幅がそろっていない")
            }
        }
    }

    @Test func warpsLandOnWalkableNonWarpTiles() {
        for id in MapID.allCases {
            let map = World.map(id)
            for (from, warp) in map.warps {
                #expect(map.contains(from))
                let destination = World.map(warp.to)
                #expect(destination.isWalkable(warp.at), "\(id)→\(warp.to) の到着点に入れない")
                #expect(destination.warps[warp.at] == nil, "\(id)→\(warp.to) の到着点がワープ床")
            }
        }
    }

    @Test func startIsWalkable() {
        #expect(World.map(World.startMap).isWalkable(World.startPoint))
        #expect(World.map(World.revivePoint.map).isWalkable(World.revivePoint.point))
    }

    @Test func bossAndChestsAreReachableFromStart() {
        let reached = reachable()
        let cave2 = World.cave2
        let boss = try! #require(cave2.boss)
        let nextToBoss = Direction.allCases.contains { reached.contains(Place(map: .cave2, point: boss + $0.delta)) }
        #expect(nextToBoss, "ボスの隣まで歩けない")

        for id in MapID.allCases {
            for chest in World.map(id).chests {
                let nextToChest = Direction.allCases.contains { reached.contains(Place(map: id, point: chest.position + $0.delta)) }
                #expect(nextToChest, "宝箱 \(chest.id) の隣まで歩けない")
            }
        }
    }

    /// 宿屋と道具屋の主人は、村から歩いて行けるカウンターの前から話しかけられる。
    @Test func keepersAreReachableAcrossCounter() {
        let reached = reachable()
        for id in [MapID.innInside, .shopInside] {
            let map = World.map(id)
            let keepers = map.npcs.filter { $0.role == .innkeeper || $0.role == .shopkeeper }
            #expect(keepers.count == 1, "\(id) に主人がいない")
            for keeper in keepers {
                let talkable = Direction.allCases.contains { direction in
                    let counter = keeper.position + Point(x: -direction.delta.x, y: -direction.delta.y)
                    let standing = counter + Point(x: -direction.delta.x, y: -direction.delta.y)
                    return map.tile(at: counter) == .counter && reached.contains(Place(map: id, point: standing))
                }
                #expect(talkable, "\(id) の主人にカウンター越しに話しかけられない")
            }
        }
        // 村の外に主人は立っていない。
        #expect(!World.village.npcs.contains { $0.role == .innkeeper || $0.role == .shopkeeper })
    }

    private struct Place: Hashable {
        let map: MapID
        let point: Point
    }

    /// 村の開始地点から歩いて行ける場所（ワープを含む）。
    private func reachable() -> Set<Place> {
        var seen: Set<Place> = [Place(map: World.startMap, point: World.startPoint)]
        var queue = Array(seen)
        while let place = queue.popLast() {
            let map = World.map(place.map)
            for direction in Direction.allCases {
                let next = place.point + direction.delta
                guard map.isWalkable(next) else { continue }
                var arrived = Place(map: place.map, point: next)
                if let warp = map.warps[next] {
                    arrived = Place(map: warp.to, point: warp.at)
                }
                if seen.insert(arrived).inserted {
                    queue.append(arrived)
                }
            }
        }
        return seen
    }
}

struct HeroTests {

    @Test func levelsUpAndLearnsSpells() {
        var hero = Hero()
        #expect(hero.spells.isEmpty)
        let messages = hero.gainExp(LevelTable.row(4).exp)
        #expect(hero.level == 4)
        #expect(hero.spells == [.heal, .fire])
        #expect(messages.contains("ヒールを おぼえた！"))
        #expect(messages.contains("ファイアを おぼえた！"))
    }

    /// レベルアップしたら HP・MP は全快する（差分を足すだけだった頃からの変更）。
    @Test func levelUpRefillsHPAndMP() {
        var hero = Hero()
        hero.hp = 5
        hero.mp = 0
        _ = hero.gainExp(LevelTable.row(2).exp)
        #expect(hero.hp == LevelTable.row(2).maxHP)
        #expect(hero.mp == LevelTable.row(2).maxMP)
    }

    @Test func levelStopsAtMax() {
        var hero = Hero()
        _ = hero.gainExp(1_000_000)
        #expect(hero.level == LevelTable.maxLevel)
    }

    @Test func equipmentAddsPower() {
        var hero = Hero()
        let base = hero.base.attack
        hero.receive(.steelSword)
        #expect(hero.weapon == .steelSword)
        #expect(hero.attack == base + 16)
        hero.receive(.herb)
        #expect(hero.herbCount == 3)
        // #expect の中で mutating は呼べないので、結果を先に受け取る。
        let usedHerb = hero.consume(.herb)
        let usedSword = hero.consume(.steelSword)
        #expect(usedHerb)
        #expect(!usedSword)
    }
}

struct BattleTests {

    @Test func damageRange() {
        var low = FixedRandomSource(pick: .min)
        var high = FixedRandomSource(pick: .max)
        #expect(Battle.damage(attack: 20, defense: 8, rng: &low) == 12)
        #expect(Battle.damage(attack: 20, defense: 8, rng: &high) == 16)
        // 攻撃が守備に届かなければ 0〜1。
        #expect(Battle.damage(attack: 5, defense: 30, rng: &high) == 1)
        #expect(Battle.damage(attack: 5, defense: 30, rng: &low) == 0)
    }

    @Test func cannotFleeFromBoss() {
        var rng = SeededRandomSource(seed: 1)
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(LevelTable.maxLevel).exp)
        hero.restoreFully()
        for _ in 0..<20 {
            var battle = Battle(hero: hero, enemy: Enemy(.guardian))
            let result = battle.take(.run, rng: &rng)
            #expect(result.end != .fled)
        }
    }

    @Test func winningGivesGoldAndExp() {
        var rng = SeededRandomSource(seed: 7)
        var hero = Hero()
        hero.receive(.steelSword)
        var battle = Battle(hero: hero, enemy: Enemy(.potato))
        var end: BattleEnd?
        for _ in 0..<10 where end == nil {
            end = battle.take(.attack, rng: &rng).end
        }
        #expect(end == .won(exp: 2, gold: 3))
        #expect(battle.hero.gold == hero.gold + 3)
        #expect(battle.hero.exp == 2)
    }

    @Test func weakHeroLosesToBoss() {
        var rng = SeededRandomSource(seed: 3)
        var battle = Battle(hero: Hero(), enemy: Enemy(.guardian))
        var end: BattleEnd?
        for _ in 0..<20 where end == nil {
            end = battle.take(.attack, rng: &rng).end
        }
        #expect(end == .lost)
        #expect(battle.hero.hp == 0)
    }

    /// 行動の区切りで枠を空け、結果は別ページ、HP の表示はその行に合わせる。
    @Test func linesArePacedByActionAndCarryHeroState() {
        var rng = SeededRandomSource(seed: 7)
        var hero = Hero()
        // レベル1だとゴブリンに一撃で倒されて結果のページが出ないので、勝てる強さにする。
        _ = hero.gainExp(LevelTable.row(5).exp)
        hero.receive(.steelSword)
        var battle = Battle(hero: hero, enemy: Enemy(.cod))
        var lines: [BattleLine] = []
        for _ in 0..<10 where battle.end == nil {
            lines += battle.take(.attack, rng: &rng).lines
        }
        for line in lines where line.text.hasSuffix("の こうげき！") {
            #expect(line.pause == .beat, "\(line.text)")
        }
        let reward = try? #require(lines.first { $0.text.hasPrefix("けいけんち") })
        #expect(reward?.pause == .page)
        if let damaged = lines.first(where: { $0.cue == .damage }) {
            #expect((damaged.hero?.hp ?? hero.maxHP) < hero.maxHP)
        }
        let stats = EnemyKind.cod.stats
        #expect(battle.end == .won(exp: stats.exp, gold: stats.gold))
        #expect(lines.allSatisfy { $0.hero != nil })
    }

    /// 勇者が受けたダメージは、その行の前後の HP の差と一致する。
    @Test func damageTakenLinesCarryHeroDamage() {
        var rng = SeededRandomSource(seed: 21)
        var battle = Battle(hero: Hero(), enemy: Enemy(.fox))
        var hpBefore = battle.hero.hp
        var checked = 0
        for _ in 0..<10 where battle.end == nil {
            for line in battle.take(.attack, rng: &rng).lines {
                if let damage = line.heroDamage {
                    #expect(line.cue == .damage)
                    // HP は0で止まるので、減る量は「受けたダメージ」と「残っていたHP」の小さいほう。
                    #expect(hpBefore - (line.hero?.hp ?? hpBefore) == min(damage, hpBefore))
                    checked += 1
                }
                hpBefore = line.hero?.hp ?? hpBefore
            }
        }
        #expect(checked > 0)
    }

    @Test func spellNeedsMP() {
        var rng = SeededRandomSource(seed: 5)
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(2).exp)
        hero.mp = 0
        var battle = Battle(hero: hero, enemy: Enemy(.kelpSlime))
        let result = battle.take(.spell(.heal), rng: &rng)
        #expect(result.messages.contains("MPが たりない！"))
        #expect(battle.hero.mp == 0)
    }
}

struct SaveTests {

    @Test func roundTrip() throws {
        let defaults = try #require(UserDefaults(suiteName: "tinyhero.tests.\(UUID().uuidString)"))
        var hero = Hero()
        _ = hero.gainExp(120)
        hero.receive(.chainMail)
        let save = SaveData(hero: hero, map: .cave1, position: Point(x: 3, y: 4), openedChests: ["cave1-0"])
        SaveStore.save(save, to: defaults)
        #expect(SaveStore.load(from: defaults) == save)
        SaveStore.delete(from: defaults)
        #expect(SaveStore.load(from: defaults) == nil)
    }
}
