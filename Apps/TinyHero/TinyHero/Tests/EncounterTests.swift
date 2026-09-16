import Testing
@testable import TinyHero

/// 遭遇テーブルの組み方を守る。
/// 1つのエリアに強さの違いすぎる敵を混ぜると、同じ場所なのに歯ごたえがバラバラになる。
struct EncounterTests {

    /// 経験値を「その敵の強さ」の目安として使う（設計者が付けた値なので一番素直）。
    private func exps(_ kinds: [EnemyKind]) -> [Int] {
        kinds.map(\.stats.exp)
    }

    private var allTables: [(MapID, Tile, [EnemyKind])] {
        MapID.allCases.flatMap { id in
            World.map(id).encounters.map { (id, $0.key, $0.value) }
        }
    }

    @Test func everyTableHasEnemies() {
        for (id, tile, kinds) in allTables {
            #expect(kinds.isEmpty == false, "\(id) の \(tile) に敵がいない")
        }
    }

    /// 同じエリアの中の強さのひらきは 2.5 倍まで。
    /// （以前は どうくつB1 が ヤミコウモリ(2) と ホネのへいし(22) で 5.5 倍あった）
    @Test func enemiesInOneAreaAreCloseInStrength() {
        for (id, tile, kinds) in allTables {
            let values = exps(kinds)
            guard let low = values.min(), let high = values.max(), low > 0 else { continue }
            let spread = Double(high) / Double(low)
            #expect(spread <= 2.5, "\(id) の \(tile) は強さのひらきが \(String(format: "%.1f", spread))倍: \(kinds.map(\.stats.name))")
        }
    }

    /// ボス以外の敵は、どこかで必ず出る（使われない敵を作らない）。
    @Test func everyEnemyAppearsSomewhere() {
        let used = Set(allTables.flatMap(\.2))
        for kind in EnemyKind.allCases where !kind.isBoss {
            #expect(used.contains(kind), "\(kind.stats.name) がどこにも出ない")
        }
    }

    /// 最初のフィールドの敵は、迷いこんだ低レベルの勇者を2発で倒さない。
    /// （きたきつね・タラこぞうが LV1〜3 を2発で倒していたのを直したときの見張り）
    @Test func firstFieldEnemiesCannotTwoShotTheHero() {
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(3).exp)
        hero.restoreFully()
        var worstCase = FixedRandomSource(pick: .max)

        for kinds in World.map(.field).encounters.values {
            for kind in kinds {
                let damage = Battle.damage(attack: kind.stats.attack, defense: hero.defense, rng: &worstCase)
                let hits = Int((Double(hero.maxHP) / Double(max(1, damage))).rounded(.up))
                #expect(hits >= 3, "\(kind.stats.name) は LV3 の勇者を \(hits) 発で倒してしまう")
            }
        }
    }

    /// フィールドの宝箱は 海ぎわ（端っこ）に置く。歩きまわった ごほうびにするため。
    @Test func fieldChestsSitOnTheCoast() {
        let field = World.map(.field)
        #expect(field.chests.count >= 3, "フィールドに宝箱が \(field.chests.count) 個しかない")

        for chest in field.chests {
            let nearSea = (-2...2).contains { dx in
                (-2...2).contains { dy in
                    field.tile(at: Point(x: chest.position.x + dx, y: chest.position.y + dy)) == .water
                }
            }
            #expect(nearSea, "宝箱 \(chest.id) が 海から はなれている（端っこでない）")
        }
    }

    /// 宝箱の中身は ばらばらにする（同じものばかりにしない）。
    @Test func fieldChestsHoldDifferentThings() {
        let rewards = World.map(.field).chests.map(\.reward)
        #expect(Set(rewards.map { "\($0)" }).count == rewards.count, "同じ中身の宝箱がある")
    }

    /// ボスは遭遇テーブルに混ぜない（話しかけて始まる戦闘なので）。
    @Test func bossNeverAppearsRandomly() {
        let used = Set(allTables.flatMap(\.2))
        #expect(used.contains(.guardian) == false)
    }

    /// 実際にたどる順番。函館 → 函館山 → もり → 藻岩山 → おか → 羅臼岳。
    private var route: [(String, [EnemyKind])] {
        func table(_ id: MapID, _ tile: Tile) -> [EnemyKind] {
            World.map(id).encounters[tile] ?? []
        }
        return [
            ("くさち", table(.field, .grass)),
            ("函館山", table(.hakodateyama, .caveFloor)),
            ("もり", table(.field, .forest)),
            ("藻岩山B1", table(.moiwa1, .caveFloor)),
            ("藻岩山B2", table(.moiwa2, .caveFloor)),
            ("おか", table(.field, .hills)),
            ("羅臼岳B1", table(.rausudake1, .caveFloor)),
            ("羅臼岳B2", table(.rausudake2, .caveFloor)),
        ]
    }

    /// 進むほど強くなる（弱いほうへ戻らない）。同じ強さが続くのは許す。
    @Test func areasGetHarderAlongTheRoute() {
        let ladder = route
        for (index, step) in ladder.enumerated() where index > 0 {
            let previous = ladder[index - 1]
            #expect((exps(step.1).max() ?? 0) >= (exps(previous.1).max() ?? 0),
                    "\(step.0) が \(previous.0) より弱くなっている")
            #expect((exps(step.1).min() ?? 0) >= (exps(previous.1).min() ?? 0),
                    "\(step.0) に \(previous.0) より弱い敵がいる")
        }
        // 最後は いちばん強い。
        #expect((exps(ladder.last!.1).max() ?? 0) > (exps(ladder.first!.1).max() ?? 0))
    }

    /// となりの場所とは 少なくとも1種 重ねて、地続きにする。
    @Test func neighbouringAreasOverlap() {
        let ladder = route
        for index in 1..<ladder.count {
            let shared = Set(ladder[index].1).intersection(Set(ladder[index - 1].1))
            #expect(shared.isEmpty == false,
                    "\(ladder[index].0) と \(ladder[index - 1].0) に 共通の敵がいない")
        }
    }

    /// ほらあなは3つ、それぞれに ボスがいる（街→ほらあな→ボス を3回くりかえす）。
    @Test func thereAreThreeBosses() {
        let bosses = MapID.allCases.compactMap { World.map($0).bossKind }
        #expect(Set(bosses) == [.squidLord, .bearLord, .guardian], "ボスが 3体そろっていない: \(bosses)")
        #expect(bosses.count == 3, "ボスのいるマップが \(bosses.count) つ")
    }

    /// 前のボスを倒すまで つぎの ほらあなに入れない。
    @Test func cavesOpenInOrder() {
        let warps = World.map(.field).warps.values
        let gated = warps.compactMap(\.requires)
        #expect(Set(gated) == [.squidLord, .bearLord], "ほらあなの関所が そろっていない: \(gated)")
        // 最初の ほらあな（函館山）には いつでも入れる。
        let first = warps.first { $0.to == .hakodateyama }
        #expect(first?.requires == nil, "はじめの ほらあなに 関所がある")
    }

}
