import Testing
@testable import GeoHero

/// ストーリーどおりに 進んだときの レベルの 見つもり。
/// 道のりの歩数から 戦いの数を 見つもり、その場所の敵の 経験値を つみあげる（寄り道・レベル上げは しない）。
enum StoryPace {
    /// 戦いと 戦いの あいだの 平均の歩数（戦いの あとは しばらく 出ない＋1歩ごとの くじ）。
    static let stepsPerBattle = Double(GameState.safeSteps + GameState.encounterDenominator)
    /// 1回の戦いの 平均の 敵の数（1〜3体）。
    static let enemiesPerBattle = Double(EnemyGroup.sizeRange.lowerBound + EnemyGroup.sizeRange.upperBound) / 2

    enum Leg {
        /// フィールドを 目印から 目印へ 歩く。
        case field(MapID, from: MapID, to: MapID)
        /// ほらあなを 入口から ボスまで 歩いて もどる（階では 下り階段まで）。
        case cave(MapID)
        /// ボスを たおす。
        case boss(EnemyKind)
        /// その場所に 着いた（`EncounterTests` の 旅の順の 名前）。
        case arrive(String)
    }

    /// 物語の すじみち。
    static let legs: [Leg] = [
        .arrive("函館のまわり"), .arrive("函館山のふもと"),
        .field(.hakodateArea, from: .hakodate, to: .hakodateyama),
        .arrive("函館山の ほらあな"), .cave(.hakodateyama), .boss(.squidLord),
        .field(.hakodateArea, from: .hakodateyama, to: .hakodate),
        .arrive("松前へむかう道"), .field(.hakodateArea, from: .hakodate, to: .matsumae),
        .arrive("大沼のまわり"), .field(.hakodateArea, from: .matsumae, to: .onuma),
        .field(.hakodateArea, from: .onuma, to: .komagatake),
        .arrive("駒ヶ岳の ほらあな"), .cave(.komagatake), .boss(.komaLord),
        .field(.hakodateArea, from: .komagatake, to: .sapporoArea),
        .arrive("札幌のまわり"), .field(.sapporoArea, from: .hakodateArea, to: .sapporo),
        .arrive("小樽へむかう道"), .field(.sapporoArea, from: .sapporo, to: .otaru),
        .field(.sapporoArea, from: .otaru, to: .tenguyama),
        .arrive("天狗山の ほらあな"), .cave(.tenguyama), .boss(.tengu),
        .field(.sapporoArea, from: .tenguyama, to: .otaru),
        .field(.sapporoArea, from: .otaru, to: .moiwa1),
        .arrive("藻岩山の ほらあな"), .cave(.moiwa1), .cave(.moiwa2), .boss(.bearLord),
        .field(.sapporoArea, from: .moiwa1, to: .shiretokoArea),
        .arrive("中標津のまわり"), .field(.shiretokoArea, from: .sapporoArea, to: .rausu),
        .arrive("ウトロへむかう道"), .field(.shiretokoArea, from: .rausu, to: .utoro),
        .field(.shiretokoArea, from: .utoro, to: .shiretokoMisaki),
        .arrive("知床岬の ほらあな"), .cave(.shiretokoMisaki), .boss(.todoLord),
        .field(.shiretokoArea, from: .shiretokoMisaki, to: .rausu),
        .field(.shiretokoArea, from: .rausu, to: .rausudake1),
        .arrive("羅臼岳の ほらあな"), .cave(.rausudake1), .cave(.rausudake2),
    ]

    /// ボスに いどむ レベル（`BossBalanceTests` の表）。足りなければ ボスの前で レベルを 上げる。
    static let bossLevels: [EnemyKind: Int] = [
        .squidLord: 4, .komaLord: 7, .tengu: 10, .bearLord: 11, .todoLord: 14, .guardian: 15,
    ]
    /// 場所ごとに 敵を 合わせた レベル（`EncounterTests` の 着いたころの表と 同じ）。
    static let designLevels = [1, 2, 3, 4, 5, 6, 8, 8, 9, 10, 11, 12, 13, 14]
    /// 近道だけでなく 宝箱や 看板を さがして 歩くぶん。
    static let wander = 1.3

    /// 場所ごとの 着いたときの 経験値。
    static func arrivalExp() -> [(String, Int)] { walk().map { ($0.name, $0.exp) } }

    /// 場所ごとの 着いたときの 経験値と、ためた ゴールド（買いものは しない）。
    static func walk() -> [(name: String, exp: Int, gold: Int)] {
        var exp = 0.0
        var gold = Double(Hero().gold)
        var arrivals: [(name: String, exp: Int, gold: Int)] = []
        var lastGoldPerExp = 1.0
        for leg in legs {
            switch leg {
            case let .arrive(name):
                arrivals.append((name, Int(exp), Int(gold)))
            case let .boss(kind):
                // 勝てる レベルまで 上げてから いどむ。
                if let level = bossLevels[kind] {
                    let needed = Double(LevelTable.row(level).exp)
                    // レベル上げの あいだにも ゴールドは たまる（その場所の 敵の 経験値と ゴールドの 割合で）。
                    if needed > exp { gold += (needed - exp) * lastGoldPerExp }
                    exp = max(exp, needed)
                }
                exp += Double(kind.stats.exp)
                gold += Double(kind.stats.gold)
            case let .field(id, from, to):
                let map = World.map(id)
                guard let path = path(on: map, from: landing(map, to: from), to: landing(map, to: to)) else { continue }
                for point in path {
                    let table = map.encounterTable(at: point) ?? []
                    exp += expPerStep(table) * wander
                    gold += goldPerStep(table) * wander
                    if !table.isEmpty { lastGoldPerExp = goldPerStep(table) / expPerStep(table) }
                }
            case let .cave(id):
                let map = World.map(id)
                let arrival = MapID.allCases.flatMap { World.map($0).warps.values }.first { $0.to == id }!.at
                // 下り階段か ボスの となりまで。行って もどるので 2倍。
                let goal = map.boss ?? map.warps.first { World.map($0.value.to).id != id && $0.value.to.isCave }!.key
                let steps = distance(on: map, from: arrival, toNeighbourOf: goal) ?? 0
                let table = map.encounters[.caveFloor] ?? []
                exp += Double(steps * 2) * expPerStep(table) * wander
                gold += Double(steps * 2) * goldPerStep(table) * wander
                if !table.isEmpty { lastGoldPerExp = goldPerStep(table) / expPerStep(table) }
            }
        }
        return arrivals
    }

    private static func goldPerStep(_ table: [EnemyKind]) -> Double {
        guard !table.isEmpty else { return 0 }
        let mean = Double(table.map(\.stats.gold).reduce(0, +)) / Double(table.count)
        return mean * enemiesPerBattle / stepsPerBattle
    }

    private static func expPerStep(_ table: [EnemyKind]) -> Double {
        guard !table.isEmpty else { return 0 }
        let mean = Double(table.map(\.stats.exp).reduce(0, +)) / Double(table.count)
        return mean * enemiesPerBattle / stepsPerBattle
    }

    /// 目印（街・ほらあな・空港）の 入口の 下の マス。
    private static func landing(_ map: GameMap, to id: MapID) -> Point {
        map.warps.first { $0.value.to == id }!.key + Point(x: 0, y: 1)
    }

    private static func path(on map: GameMap, from: Point, to: Point) -> [Point]? {
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
                guard map.tile(at: next).isPassable, map.warps[next] == nil || next == to,
                      seen.insert(next).inserted else { continue }
                came[next] = point
                queue.append(next)
            }
        }
        return nil
    }

    private static func distance(on map: GameMap, from: Point, toNeighbourOf target: Point) -> Int? {
        var seen: Set<Point> = [from]
        var queue = [(from, 0)]
        var head = 0
        while head < queue.count {
            let (point, steps) = queue[head]; head += 1
            if Direction.allCases.contains(where: { point + $0.delta == target }) { return steps }
            for direction in Direction.allCases {
                let next = point + direction.delta
                guard map.isWalkable(next), map.warps[next] == nil, seen.insert(next).inserted else { continue }
                queue.append((next, steps + 1))
            }
        }
        return nil
    }

    static func level(forExp exp: Int) -> Int {
        (1...LevelTable.maxLevel).last { LevelTable.row($0).exp <= exp } ?? 1
    }
}

struct StoryPaceTests {
    /// ストーリーどおりに 進むと、場所ごとに 敵を 合わせた レベル（`EncounterTests` の 着いたころの表）で 着く。
    /// ずれると、レベルを 上げすぎて 敵が 弱く 感じたり、足りなくて レベル上げを しいられたりする。
    /// 函館の はじめの 3か所は 歩く道が みじかいので、まわりを 歩いて 上げる 前提で 見ない。
    @Test func storyReachesEachPlaceAtItsLevel() {
        let arrivals = StoryPace.arrivalExp()
        for (index, (name, exp)) in arrivals.enumerated() where index >= 3 {
            let expected = StoryPace.designLevels[index]
            let reached = StoryPace.level(forExp: exp)
            print("PACE \(name) exp \(exp) LV \(reached) / \(expected) gold \(StoryPace.walk()[index].gold)")
            #expect(reached == expected, "\(name) に LV\(reached) で 着く（敵は LV\(expected) に 合わせてある）")
        }
    }

    /// ストーリーどおりに 進めば、その場所に 合わせた 装備が だいたい 買える（のこりは 宝箱や お礼で）。
    @Test func standardGearIsAffordable() {
        let walk = StoryPace.walk()
        let checkpoints: [(String, [Item])] = [
            ("松前へむかう道", [.copperSword, .leatherArmor]),
            ("藻岩山の ほらあな", [.copperSword, .leatherArmor, .steelSword, .chainMail]),
        ]
        for (name, gear) in checkpoints {
            let gold = walk.first { $0.name == name }?.gold ?? 0
            let cost = gear.map(\.price).reduce(0, +)
            #expect(Double(gold) >= Double(cost) * 0.75, "\(name) に 着くまでに \(gold)G しか たまらない（装備は \(cost)G）")
        }
    }

    /// 宝箱も お礼も ぜんぶ あつめても、店の 装備を ぜんぶは 買えない（お金が あまらない）。
    @Test func moneyDoesNotPileUp() {
        let story = StoryPace.walk().last?.gold ?? 0
        let chests = MapID.allCases.flatMap { World.map($0).chests }.reduce(0) { total, chest in
            if case let .gold(amount) = chest.reward { return total + amount }
            return total
        }
        let rewards = Resident.allCases.map(\.totalGold).reduce(0, +)
        let gear = Item.allCases.filter { $0.kind != .consumable }.map(\.price).reduce(0, +)
        let earned = story + chests + rewards
        print("MONEY story \(story) chests \(chests) rewards \(rewards) = \(earned) / gear \(gear)")
        #expect(earned < gear, "ぜんぶで \(earned)G たまり、装備（\(gear)G）を ぜんぶ 買えてしまう")
    }
}
