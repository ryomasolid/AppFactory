import Testing
@testable import GeoHero

/// 遭遇テーブルの組み方を守る。
/// 1つのエリアに強さの違いすぎる敵を混ぜると、同じ場所なのに歯ごたえがバラバラになる。
struct EncounterTests {

    /// 経験値を「その敵の強さ」の目安として使う（設計者が付けた値なので一番素直）。
    private func exps(_ kinds: [EnemyKind]) -> [Int] {
        kinds.map(\.stats.exp)
    }

    /// ほらあなの「地形ごとの表」と フィールドの「区域ごとの表」を ひとまとめに見る。
    private var allTables: [(MapID, String, [EnemyKind])] {
        MapID.allCases.flatMap { id -> [(MapID, String, [EnemyKind])] in
            let map = World.map(id)
            return map.encounters.map { (id, "\($0.key)", $0.value) }
                + map.encounterAreas.map { (id, $0.name, $0.enemies) }
        }
    }

    @Test func everyTableHasEnemies() {
        for (id, place, kinds) in allTables {
            #expect(kinds.isEmpty == false, "\(id) の \(place) に敵がいない")
        }
    }

    /// 同じエリアの中の強さのひらきは 2.5 倍まで。
    /// （以前は どうくつB1 が ヤミコウモリ(2) と ホネのへいし(22) で 5.5 倍あった）
    @Test func enemiesInOneAreaAreCloseInStrength() {
        for (id, place, kinds) in allTables {
            let values = exps(kinds)
            guard let low = values.min(), let high = values.max(), low > 0 else { continue }
            let spread = Double(high) / Double(low)
            #expect(spread <= 2.5, "\(id) の \(place) は強さのひらきが \(String(format: "%.1f", spread))倍: \(kinds.map(\.stats.name))")
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

        // 最初の2区域（函館のまわり・函館山のふもと）だけを見る。
        // 奥の区域には強い敵がいてよい（そのころには こちらも育っている）。
        for area in World.map(.field).encounterAreas.prefix(2) {
            for kind in area.enemies {
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

    /// 実際にたどる順番。フィールドの区域と ほらあなを 交互にたどる。
    private var route: [(String, [EnemyKind])] {
        func cave(_ id: MapID) -> [EnemyKind] { World.map(id).encounters[.caveFloor] ?? [] }
        func area(_ name: String) -> [EnemyKind] {
            World.map(.field).encounterAreas.first { $0.name == name }?.enemies ?? []
        }
        return [
            ("函館のまわり", area("函館のまわり")),
            ("函館山のふもと", area("函館山のふもと")),
            ("函館山の ほらあな", cave(.hakodateyama)),
            ("札幌へむかう道", area("札幌へむかう道")),
            ("藻岩山へむかう道", area("藻岩山へむかう道")),
            ("藻岩山B1", cave(.moiwa1)),
            ("藻岩山B2", cave(.moiwa2)),
            ("知床へむかう道", area("知床へむかう道")),
            ("羅臼岳へむかう道", area("羅臼岳へむかう道")),
            ("羅臼岳B1", cave(.rausudake1)),
            ("羅臼岳B2", cave(.rausudake2)),
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

    /// 場所ごとに 出る敵を変える。同じ敵が ふたつの場所に出ない。
    /// （以前は 7種を 11か所で使いまわしていて、どこへ行っても 同じ顔ぶれだった）
    @Test func everyPlaceHasItsOwnEnemies() {
        var seenAt: [EnemyKind: String] = [:]
        for (place, kinds) in route {
            for kind in kinds {
                if let other = seenAt[kind] {
                    Issue.record("\(kind.stats.name) が \(other) と \(place) の両方に出る")
                }
                seenAt[kind] = place
            }
        }
        #expect(Set(seenAt.keys).count == route.flatMap(\.1).count)
    }

    /// 場所ごとの、着いたころの レベル・装備。場所の順は `route` と同じ。
    /// 札幌へむかう道は 函館山のボス（銅の剣・革の鎧で LV3〜5）を倒したあとに来る。
    private let arrivals: [(level: Int, weapon: Item, armor: Item)] = [
        (1, .woodStick, .clothes), (2, .woodStick, .clothes), (3, .woodStick, .clothes),
        (4, .copperSword, .leatherArmor), (5, .copperSword, .leatherArmor), (6, .copperSword, .leatherArmor),
        (7, .copperSword, .leatherArmor), (8, .copperSword, .leatherArmor), (9, .copperSword, .leatherArmor),
        (10, .steelSword, .chainMail), (11, .steelSword, .chainMail),
    ]

    /// 同じ敵 `count` 体と こうげきだけで戦い、20戦のうち 勝った数を返す。
    private func wins(level: Int, weapon: Item, armor: Item, against kind: EnemyKind, count: Int) -> Int {
        var wins = 0
        for seed in UInt64(1)...20 {
            var rng = SeededRandomSource(seed: seed)
            var hero = Hero()
            _ = hero.gainExp(LevelTable.row(level).exp)
            hero.receive(weapon)
            hero.receive(armor)
            hero.restoreFully()
            var battle = Battle(hero: hero, enemies: EnemyGroup.numbered(Array(repeating: kind, count: count)))
            var end: BattleEnd?
            for _ in 0..<60 where end == nil {
                end = battle.take(.attack, rng: &rng).end
            }
            if end == .won(exp: kind.stats.exp * count, gold: kind.stats.gold * count) { wins += 1 }
        }
        return wins
    }

    /// 場所ごとに、着いたころの レベル・装備なら 同じ敵 3体に 回復なしで勝てる。
    @Test func everyPlaceIsBeatableOnArrival() {
        #expect(arrivals.count == route.count)
        for ((place, kinds), arrival) in zip(route, arrivals) {
            for kind in kinds {
                let won = wins(level: arrival.level, weapon: arrival.weapon, armor: arrival.armor, against: kind, count: 3)
                #expect(won == 20, "\(place) LV\(arrival.level) で \(kind.stats.name)×3 に \(20 - won)/20 回 負ける")
            }
        }
    }

    /// 2レベル足りないまま先へ行くと、楽には勝てない。
    /// 1体なら勝てるが、ひと振りでは倒せず、3体に囲まれると たいてい負ける。
    /// （札幌の敵を LV2 で楽に倒せていたのを直したときの見張り。函館の3か所は となりどうしなので見ない）
    @Test func underleveledHeroCannotBreezeThrough() {
        var strongest = FixedRandomSource(pick: .max)
        for index in 3..<route.count {
            let (place, kinds) = route[index]
            let level = arrivals[index].level - 2
            let (weapon, armor) = (arrivals[index - 2].weapon, arrivals[index - 2].armor)
            var hero = Hero()
            _ = hero.gainExp(LevelTable.row(level).exp)
            hero.receive(weapon)
            for kind in kinds {
                let hit = Battle.damage(attack: hero.attack, defense: kind.stats.defense, rng: &strongest)
                #expect(hit < kind.stats.maxHP, "\(place) の \(kind.stats.name) を LV\(level) で ひと振りで倒せる")
                let won = wins(level: level, weapon: weapon, armor: armor, against: kind, count: 3)
                #expect(won <= 10, "\(place) の \(kind.stats.name)×3 に LV\(level) で \(won)/20 回 勝ててしまう")
                let alone = wins(level: level, weapon: weapon, armor: armor, against: kind, count: 1)
                #expect(alone >= 15, "\(place) の \(kind.stats.name) 1体に LV\(level) で \(20 - alone)/20 回 負ける")
            }
        }
    }

    /// どの敵にも 自分の絵がある（絵の名前を 敵の名前とそろえてあるので、足し忘れると ポテトーになる）。
    @Test func everyEnemyHasItsOwnSprite() {
        for kind in EnemyKind.allCases {
            #expect(SpriteID(enemy: kind).rawValue == kind.rawValue, "\(kind.stats.name) の絵がない")
        }
    }

    /// 道を歩いていて 区域が 弱いほうへ戻らない。
    /// 海でへだてられた土地は まわり道になるので、目印までの直線距離だけだと
    /// 手前の道に 先の区域が食いこむことがある（実際に一度やった）。
    @Test func walkingTheRouteNeverGetsEasier() throws {
        let field = World.map(.field)
        let order = field.encounterAreas.map(\.name)
        func landing(_ id: MapID) throws -> Point {
            let entrance = try #require(field.warps.first { $0.value.to == id })
            return entrance.key + Point(x: 0, y: 1)
        }
        let legs: [(MapID, MapID)] = [
            (.hakodate, .hakodateyama), (.hakodateyama, .sapporo),
            (.sapporo, .moiwa1), (.moiwa1, .rausu), (.rausu, .rausudake1),
        ]
        for (from, to) in legs {
            let path = try #require(walk(field, from: try landing(from), to: try landing(to)),
                                    "\(from) から \(to) へ歩いて行けない")
            var highest = 0
            for point in path {
                let area = try #require(field.area(at: point))
                let rank = try #require(order.firstIndex(of: area.name))
                #expect(rank >= highest,
                        "\(from)→\(to) の (\(point.x), \(point.y)) で \(area.name) に 弱くなる")
                highest = max(highest, rank)
            }
        }
    }

    /// 2点を結ぶ道すじ（歩けるマスだけ）。
    private func walk(_ map: GameMap, from: Point, to: Point) -> [Point]? {
        var came: [Point: Point] = [:]
        var seen: Set<Point> = [from]
        var queue = [from]
        var head = 0
        while head < queue.count {
            let point = queue[head]; head += 1
            if point == to {
                var path = [to]
                while let previous = came[path[0]] { path.insert(previous, at: 0) }
                return path
            }
            for direction in Direction.allCases {
                let next = point + direction.delta
                guard map.tile(at: next).isPassable, seen.insert(next).inserted else { continue }
                came[next] = point
                queue.append(next)
            }
        }
        return nil
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

    /// 道の上でも敵は出る。道だけ安全だと 街から街まで無傷で歩けてしまう。
    @Test func roadsAreNotASafeCorridor() {
        let field = World.map(.field)
        var roads = 0
        for y in 0..<field.height {
            for x in 0..<field.width where [.road, .bridge].contains(field.tile(at: Point(x: x, y: y))) {
                let point = Point(x: x, y: y)
                roads += 1
                let table = field.encounterTable(at: point) ?? []
                #expect(!table.isEmpty, "みち (\(x), \(y)) で敵が出ない")
            }
        }
        #expect(roads > 0, "フィールドに みちがない")
    }

    /// 奥へ行くほど手ごわくなる。ほらあなの入口で出る敵の経験値で見る。
    @Test func theJourneyGetsHarder() throws {
        let field = World.map(.field)
        func toughness(_ id: MapID) throws -> Int {
            let entrance = try #require(field.warps.first { $0.value.to == id })
            let table = try #require(field.encounterTable(at: entrance.key + Point(x: 0, y: 1)))
            return table.map(\.stats.exp).max() ?? 0
        }
        let first = try toughness(.hakodateyama)
        let last = try toughness(.rausudake1)
        #expect(last > first, "羅臼岳のまわり(\(last)) が 函館山のまわり(\(first)) より楽になっている")
    }
}

/// 街ごとの ちがい。旅が進むほど 宿代は高く、品ぞろえは強くなる。
struct TownTests {
    private let route: [MapID] = [.hakodate, .sapporo, .rausu]

    /// 奥の街ほど 宿代が高い。
    @Test func innGetsMoreExpensiveAlongTheRoute() throws {
        for level in [1, 6, 12] {
            var previous = 0
            for id in route {
                let town = try #require(id.townInfo)
                let price = town.innBase + level * town.innPerLevel
                #expect(price > previous, "LV\(level) の \(id) は ひとばん \(price)G で 手前の街より安い")
                previous = price
            }
        }
    }

    /// 道具屋は 進むほど強い品を置く。薬草は どこでも買える。
    @Test func shopStockGrowsStronger() throws {
        var previousWeapon = 0
        var previousArmor = 0
        for id in route {
            let town = try #require(id.townInfo)
            #expect(town.stock.contains(.herb), "\(id) の道具屋に 薬草がない")
            var weapon = 0
            var armor = 0
            for item in town.stock {
                switch item.kind {
                case .weapon(let power): weapon = max(weapon, power)
                case .armor(let power): armor = max(armor, power)
                case .consumable: break
                }
            }
            #expect(weapon >= previousWeapon, "\(id) の ぶきが 手前の街より弱い")
            #expect(armor >= previousArmor, "\(id) の よろいが 手前の街より弱い")
            previousWeapon = weapon
            previousArmor = armor
        }
        #expect(previousWeapon > 0 && previousArmor > 0, "さいごの街に そうびが置かれていない")
    }

    /// まだ早い装備は 手前の街に置かない（最初の街で鋼の剣が買えると 旅にならない）。
    @Test func earlyTownsDoNotSellLateGear() throws {
        let hakodate = try #require(MapID.hakodate.townInfo)
        #expect(!hakodate.stock.contains(.steelSword), "函館で はがねの剣が買える")
        #expect(!hakodate.stock.contains(.chainMail), "函館で くさりかたびらが買える")
        // もう用のない装備も、さいはての町には置かない。
        let rausu = try #require(MapID.rausu.townInfo)
        #expect(!rausu.stock.contains(.copperSword), "羅臼で まだ どうの剣を売っている")
    }

    /// 街ごとに にぎわいと 家の数を変える。
    @Test func townsDifferInCrowdAndBuildings() {
        let people = route.map { World.map($0).npcs.count }
        #expect(Set(people).count == people.count, "どの街も 人の数が同じ: \(people)")
        #expect(people[1] > people[0], "札幌が いちばん にぎやかであってほしい: \(people)")
        #expect(people[2] < people[0], "羅臼は さいはての町なので 人が少ないほうがいい: \(people)")

        let roofs = route.map { id -> Int in
            let map = World.map(id)
            var count = 0
            for y in 0..<map.height {
                for x in 0..<map.width {
                    switch map.tile(at: Point(x: x, y: y)) {
                    case .innRoof, .shopRoof, .house: count += 1
                    default: break
                    }
                }
            }
            return count
        }
        #expect(roofs[1] > roofs[0], "札幌に 家が多くない: \(roofs)")
    }

    /// どの街にも 宿屋と道具屋の入口がある。
    @Test func everyTownHasAnInnAndAShop() {
        for id in route {
            let warps = World.map(id).warps.values
            #expect(warps.contains { $0.to == .innInside }, "\(id) に 宿屋がない")
            #expect(warps.contains { $0.to == .shopInside }, "\(id) に 道具屋がない")
        }
    }

    /// おかねが足りない品も 道具屋で選べて、あと いくら足りないかが分かる。
    /// 買えない品を選べなくしていたころは、どれだけ強くなるかを見ることもできなかった。
    @MainActor @Test func shortfallTellsHowMuchIsMissing() {
        let game = GameState()
        game.newGame()
        game.hero.gold = 50
        #expect(game.shortfall(for: .herb) == 0, "8G の薬草が 50G で買えない")
        #expect(game.shortfall(for: .copperSword) == 50, "100G の どうの剣に あと 50G のはず")
        game.hero.gold = 100
        #expect(game.shortfall(for: .copperSword) == 0)
    }
}
