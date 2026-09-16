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

    /// エリアを進むほど強くなる（弱いほうへ戻らない）。
    @Test func areasGetHarderInOrder() {
        let ladder: [(String, [EnemyKind])] = [
            ("くさち", World.map(.field).encounters[.grass] ?? []),
            ("もり", World.map(.field).encounters[.forest] ?? []),
            ("おか", World.map(.field).encounters[.hills] ?? []),
            ("どうくつB1", World.map(.cave1).encounters[.caveFloor] ?? []),
            ("どうくつB2", World.map(.cave2).encounters[.caveFloor] ?? []),
        ]
        for (index, step) in ladder.enumerated() where index > 0 {
            let previous = ladder[index - 1]
            let previousTop = exps(previous.1).max() ?? 0
            let currentTop = exps(step.1).max() ?? 0
            let currentLow = exps(step.1).min() ?? 0
            #expect(currentTop > previousTop, "\(step.0) が \(previous.0) より強くなっていない")
            // となりのエリアより下には戻らない（弱すぎる敵を混ぜない）。
            let previousLow = exps(previous.1).min() ?? 0
            #expect(currentLow >= previousLow, "\(step.0) に \(previous.0) より弱い敵がいる")
        }
    }

    /// となりのエリアとは1種だけ重ねて、地続きにする。
    @Test func neighbouringAreasOverlapByOne() {
        let ladder: [[EnemyKind]] = [
            World.map(.field).encounters[.grass] ?? [],
            World.map(.field).encounters[.forest] ?? [],
            World.map(.field).encounters[.hills] ?? [],
            World.map(.cave1).encounters[.caveFloor] ?? [],
            World.map(.cave2).encounters[.caveFloor] ?? [],
        ]
        for index in 1..<ladder.count {
            let shared = Set(ladder[index]).intersection(Set(ladder[index - 1]))
            #expect(shared.count == 1, "\(index) 番目のエリアの重なりが \(shared.count) 種")
        }
    }
}
