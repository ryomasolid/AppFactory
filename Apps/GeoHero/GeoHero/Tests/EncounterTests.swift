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
        for area in World.map(.hakodateArea).encounterAreas.prefix(2) {
            for kind in area.enemies {
                let damage = Battle.damage(attack: kind.stats.attack, defense: hero.defense, rng: &worstCase)
                let hits = Int((Double(hero.maxHP) / Double(max(1, damage))).rounded(.up))
                #expect(hits >= 3, "\(kind.stats.name) は LV3 の勇者を \(hits) 発で倒してしまう")
            }
        }
    }

    /// フィールドの宝箱は 海ぎわ（端っこ）に置く。歩きまわった ごほうびにするため。
    @Test func fieldChestsSitOnTheCoast() {
        let field = World.map(.hakodateArea)
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
        let rewards = World.map(.hakodateArea).chests.map(\.reward)
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
            Region.allCases.flatMap { World.map($0.field).encounterAreas }.first { $0.name == name }?.enemies ?? []
        }
        return [
            ("函館のまわり", area("函館のまわり")),
            ("函館山のふもと", area("函館山のふもと")),
            ("函館山の ほらあな", cave(.hakodateyama)),
            ("松前へむかう道", area("松前へむかう道")),
            ("大沼のまわり", area("大沼のまわり")),
            ("駒ヶ岳の ほらあな", cave(.komagatake)),
            ("札幌のまわり", area("札幌のまわり")),
            ("小樽へむかう道", area("小樽へむかう道")),
            ("天狗山の ほらあな", cave(.tenguyama)),
            ("藻岩山の ほらあな", cave(.moiwa2)),
            ("中標津のまわり", area("中標津のまわり")),
            ("ウトロへむかう道", area("ウトロへむかう道")),
            ("知床岬の ほらあな", cave(.shiretokoMisaki)),
            ("羅臼岳の ほらあな", cave(.rausudake2)),
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
    /// ストーリーどおりに 進んだときの レベル（`StoryPaceTests`）に そろえてある。
    /// 札幌は 駒ヶ岳のぬしの 経験値で LV8 に なって 着くので、小樽へむかう道と 同じ LV8。
    /// 松前へむかう道は 函館山のボス（銅の剣・革の鎧で LV3〜5）を倒したあとに来る。
    /// 鋼の剣と 鎖帷子は 札幌・小樽で そろえ、藻岩山から 使う。
    private let arrivals: [(level: Int, weapon: Item, armor: Item)] = [
        (1, .woodStick, .clothes), (2, .woodStick, .clothes), (3, .woodStick, .clothes),
        (4, .copperSword, .leatherArmor), (5, .copperSword, .leatherArmor), (6, .copperSword, .leatherArmor),
        (8, .copperSword, .leatherArmor), (8, .copperSword, .leatherArmor), (9, .copperSword, .leatherArmor),
        (10, .steelSword, .chainMail), (11, .steelSword, .chainMail), (12, .steelSword, .chainMail),
        (13, .steelSword, .chainMail), (14, .steelSword, .chainMail),
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
        let legs: [(MapID, MapID, MapID)] = [
            (.hakodateArea, .hakodate, .hakodateyama), (.hakodateArea, .hakodate, .matsumae),
            (.hakodateArea, .matsumae, .onuma), (.hakodateArea, .hakodate, .onuma),
            (.sapporoArea, .sapporo, .moiwa1), (.sapporoArea, .sapporo, .otaru),
            (.sapporoArea, .otaru, .tenguyama), (.sapporoArea, .moiwa1, .jozankei),
            (.shiretokoArea, .rausu, .rausudake1), (.shiretokoArea, .nakashibetsu, .rausu),
            (.shiretokoArea, .nakashibetsu, .utoro), (.shiretokoArea, .utoro, .shiretokoMisaki),
        ]
        for (fieldID, from, to) in legs {
            let field = World.map(fieldID)
            let order = field.encounterAreas.map(\.name)
            func landing(_ id: MapID) throws -> Point {
                let entrance = try #require(field.warps.first { $0.value.to == id })
                return entrance.key + Point(x: 0, y: 1)
            }
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

    /// ボスのいる ほらあなは6つ（函館山・駒ヶ岳・天狗山・藻岩山・知床岬・羅臼岳）。
    @Test func thereAreSixBosses() {
        let bosses = MapID.allCases.compactMap { World.map($0).bossKind }
        #expect(Set(bosses) == [.squidLord, .komaLord, .tengu, .bearLord, .todoLord, .guardian], "ボスが そろっていない: \(bosses)")
        #expect(bosses.count == 6, "ボスのいるマップが \(bosses.count) つ")
    }

    /// 函館エリアの ほらあなは 物語で ひらく。函館山は 奉行の てがた、駒ヶ岳は 殿様の おふだ。
    /// となりの地方へは 空港から きっぷで とぶ。
    @Test func gatesFollowTheStory() {
        let warps = World.map(.hakodateArea).warps.values
        #expect(warps.first { $0.to == .hakodateyama }?.needs == .hakodateyamaPass)
        #expect(warps.first { $0.to == .komagatake }?.needs == .fireCharm)
        #expect(warps.first { $0.to == .sapporoArea }?.needs == .ticketToSapporo)
        let sapporo = World.map(.sapporoArea).warps.values
        // 藻岩山は 小樽の オルゴールで ヒグマの こどもたちを しずめてから。天狗山は いつでも。
        #expect(sapporo.first { $0.to == .moiwa1 }?.needs == .musicBox)
        #expect(sapporo.first { $0.to == .tenguyama }?.needs == nil)
        #expect(sapporo.first { $0.to == .hakodateArea }?.needs == .ticketToSapporo, "函館へ もどれない")
        #expect(sapporo.first { $0.to == .shiretokoArea }?.needs == .ticketToShiretoko)
        #expect(World.map(.shiretokoArea).warps.values.first { $0.to == .sapporoArea }?.needs == .ticketToShiretoko)
        // 羅臼岳は カムイの はねで ふぶきを はらってから。知床岬は いつでも。
        let shiretoko = World.map(.shiretokoArea).warps.values
        #expect(shiretoko.first { $0.to == .rausudake1 }?.needs == .kamuiFeather)
        #expect(shiretoko.first { $0.to == .shiretokoMisaki }?.needs == nil)
        // きっぷは ボスを倒すと もらえる。
        #expect(StoryFlag.ticketToSapporo.impliedBy == .komaLord)
        #expect(StoryFlag.ticketToShiretoko.impliedBy == .bearLord)
    }

    /// 道の上でも敵は出る。道だけ安全だと 街から街まで無傷で歩けてしまう。
    @Test(arguments: Region.allCases)
    func roadsAreNotASafeCorridor(region: Region) {
        let field = World.map(region.field)
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
        func toughness(_ fieldID: MapID, _ id: MapID) throws -> Int {
            let field = World.map(fieldID)
            let entrance = try #require(field.warps.first { $0.value.to == id })
            let table = try #require(field.encounterTable(at: entrance.key + Point(x: 0, y: 1)))
            return table.map(\.stats.exp).max() ?? 0
        }
        let steps = [
            try toughness(.hakodateArea, .hakodateyama), try toughness(.hakodateArea, .komagatake),
            try toughness(.sapporoArea, .tenguyama), try toughness(.shiretokoArea, .shiretokoMisaki),
        ]
        #expect(steps == steps.sorted() && Set(steps).count == steps.count, "ほらあなの前が 奥ほど 手ごわくない: \(steps)")
    }
}

/// 街ごとの ちがい。旅が進むほど 宿代は高く、品ぞろえは強くなる。
struct TownTests {
    private let route: [MapID] = [.hakodate, .matsumae, .onuma, .sapporo, .otaru, .jozankei, .nakashibetsu, .utoro, .rausu]

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
    /// 函館は 歩きまわって 話を聞く街（物語の はじまり）なので いちばん広く、人も多い。
    @Test func townsDifferInCrowdAndBuildings() {
        let people = route.map { World.map($0).npcs.count }
        #expect(people[0] == people.max(), "函館が いちばん にぎやかで ないと: \(people)")
        // 小さな 町（定山渓・中標津）は 大きな街（札幌）より 人が少ない。
        let count = Dictionary(uniqueKeysWithValues: zip(route, people))
        #expect(count[.jozankei]! < count[.sapporo]! && count[.nakashibetsu]! < count[.sapporo]!, "\(people)")

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
        #expect(roofs[3] > roofs.last!, "札幌より 羅臼に 家が多い: \(roofs)")
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
