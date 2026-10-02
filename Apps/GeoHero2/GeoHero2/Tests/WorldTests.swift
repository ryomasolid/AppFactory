import Testing
@testable import GeoHero2

/// 地図の つながり。どこへでも 歩いて 行けて、ワープの 着地が 床の 上に ある。
struct WorldTests {

    /// その地図で 歩いて とどく マス（ワープの マスには 入れるが その先へは ぬけない）。
    static func reachable(_ map: GameMap, from start: Point) -> Set<Point> {
        var seen: Set<Point> = [start]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let point = queue[head]; head += 1
            if point != start, map.warps[point] != nil || map.tile(at: point) == .station { continue }
            for direction in Direction.allCases {
                let next = point + direction.delta
                guard map.contains(next), map.isWalkable(next, bossRemains: true, progress: nil),
                      seen.insert(next).inserted else { continue }
                queue.append(next)
            }
        }
        return seen
    }

    /// 話しかけたり 開けたり できる（となりの マスに 立てる。カウンター越しも 見る）。
    static func canReach(_ target: Point, in seen: Set<Point>, map: GameMap) -> Bool {
        Direction.allCases.contains { direction in
            let next = target + direction.delta
            if seen.contains(next) { return true }
            return map.tile(at: next) == .counter && seen.contains(next + direction.delta)
        }
    }

    @Test func everyMapExists() {
        for id in MapID.allCases {
            #expect(World.all[id] != nil, "\(id) の 地図が ない")
        }
    }

    @Test func everyWarpLandsOnFloor() {
        for map in World.all.values where map.id != .innInside && map.id != .shopInside {
            for (point, warp) in map.warps {
                let target = World.map(warp.to)
                #expect(World.all[warp.to] != nil, "\(map.id) の \(point) の 行き先 \(warp.to) が ない")
                let floor = target.contains(warp.at) && target.tile(at: warp.at).isPassable
                #expect(floor,
                        "\(map.id) \(point) → \(warp.to) \(warp.at) が 床でない（\(target.tile(at: warp.at))）")
                #expect(target.warps[warp.at] == nil, "\(map.id) \(point) → \(warp.to) \(warp.at) が また ワープの 上")
                let empty = target.npc(at: warp.at) == nil && target.chest(at: warp.at) == nil
                #expect(empty,
                        "\(map.id) → \(warp.to) \(warp.at) に 人か 宝箱が いる")
            }
        }
    }

    /// 地図の 行は ぜんぶ 同じ 長さ。
    @Test func rowsAreRectangular() {
        for map in World.all.values {
            #expect(Set(map.tiles.map(\.count)).count == 1, "\(map.id) の 行の 長さが ばらばら")
        }
    }

    /// 地図に 入ったら、その地図の ワープ・人・宝箱・看板・ボス・駅 すべてに 歩いて とどく。
    @Test func everythingIsReachable() {
        for map in World.all.values where map.id != .innInside && map.id != .shopInside {
            // 入ってくる 着地点から 歩く。
            let entries = World.all.values.flatMap { other in other.warps.values.filter { $0.to == map.id }.map(\.at) }
            var seen: Set<Point> = []
            for entry in entries { seen.formUnion(Self.reachable(map, from: entry)) }
            if map.kind == .field, let station = map.station {
                seen.formUnion(Self.reachable(map, from: station + Point(x: 0, y: 1)))
            }
            #expect(!entries.isEmpty || map.kind == .field, "\(map.id) へ 入る ワープが ない")
            for point in map.warps.keys {
                let ok = Self.canReach(point, in: seen, map: map)
                #expect(ok, "\(map.id) の ワープ \(point) に とどかない")
            }
            for npc in map.npcs {
                let ok = Self.canReach(npc.position, in: seen, map: map)
                #expect(ok, "\(map.id) の 人 \(npc.position) に 話せない")
            }
            for chest in map.chests {
                let ok = Self.canReach(chest.position, in: seen, map: map)
                #expect(ok, "\(map.id) の 宝箱 \(chest.position) に とどかない")
            }
            for point in map.plaques.keys {
                #expect(map.tile(at: point) == .signpost, "\(map.id) \(point) の 看板が 看板の マスに ない")
                let ok = Self.canReach(point, in: seen, map: map)
                #expect(ok, "\(map.id) の 看板 \(point) に とどかない")
            }
            if let boss = map.boss {
                let ok = Self.canReach(boss, in: seen, map: map)
                #expect(ok, "\(map.id) の ボスに とどかない")
            }
            if let station = map.station {
                let ok = Self.canReach(station, in: seen, map: map)
                #expect(ok, "\(map.id) の 駅に とどかない")
            }
        }
    }

    /// 県ごとに フィールド・駅・街3つ・ボス2体（山形は 守護神まで）が そろっている。
    @Test(arguments: Region.allCases)
    func everyRegionIsComplete(region: Region) {
        let field = World.map(region.field)
        #expect(field.kind == .field && field.region == region)
        #expect(field.station != nil, "\(region) に 駅が ない")
        let towns = MapID.allCases.filter { $0.isTown && $0.region == region }
        #expect(towns.count == 3, "\(region) の 街が \(towns.count)")
        let bosses = World.all.values.filter { $0.region == region }.compactMap(\.bossKind)
        #expect(bosses.contains(region.subBoss) && bosses.contains(region.lord), "\(region) の ボスが そろっていない")
        #expect(World.stampTotal(in: region) >= 7, "\(region) の 名所の 看板が \(World.stampTotal(in: region))")
    }

    /// 家の 出口は 入ってきた 街へ もどる。
    @Test func housesReturnToTheirTown() {
        for map in World.all.values where map.id.isHouse {
            let exits = map.warps.values
            #expect(exits.count == 1, "\(map.id) の 出口が \(exits.count)")
            let entry = World.all.values.first { $0.warps.values.contains { $0.to == map.id } }
            #expect(entry?.id == exits.first?.to, "\(map.id) の 出口が 入口の 街と ちがう")
        }
    }

    /// ほらあなの「だっしゅつ」は フィールドの 入口の 前へ。
    @Test func escapeLeadsToTheCaveMouth() {
        for map in World.all.values where map.kind == .cave {
            let exit = World.caveExit(from: map.id)
            #expect(exit != nil, "\(map.id) から だっしゅつ できない")
            if let exit {
                let field = World.map(exit.map)
                #expect(field.kind == .field && field.tile(at: exit.point).isPassable, "\(map.id) の だっしゅつ先 \(exit)")
            }
        }
    }

    /// 全滅したときに 目を さます 場所は 街の 床。
    @Test(arguments: Region.allCases)
    func revivePointIsInTown(region: Region) {
        let (id, point) = World.revivePoint(in: region)
        let map = World.map(id)
        #expect(map.kind == .town && map.region == region)
        #expect(map.isWalkable(point), "\(region) の 目ざめる 場所 \(point) が 歩けない")
    }

    /// 街の 道具屋の 品は 宝箱だけの 品を ふくまない。
    @Test func shopsDoNotSellTreasures() {
        for id in MapID.allCases {
            for item in id.townInfo?.stock ?? [] {
                #expect(!item.isTreasure, "\(id) が \(item.name) を 売っている")
            }
        }
    }

    /// 宿代は 旅の 先ほど 高い。
    @Test func innsGetPricier() {
        var last = 0
        for region in Region.allCases {
            let towns = MapID.allCases.filter { $0.isTown && $0.region == region }.compactMap(\.townInfo)
            let cheapest = towns.map(\.innBase).min() ?? 0
            #expect(cheapest >= last, "\(region) の 宿が 前の 県より 安い")
            last = cheapest
        }
    }
}

/// 絵の そろい。
struct ArtTests {
    /// どの 絵の 名前にも 絵が ある（ない絵は むらさきの 四角に なる）。
    @Test func everySpriteHasArt() {
        for id in SpriteID.allCases {
            #expect(SpriteID.art[id] != nil, "\(id) の 絵が ない")
        }
    }

    @Test func spritesAreSixteenSquare() {
        for (id, rows) in SpriteID.art {
            #expect(rows.count == 16 && rows.allSatisfy { $0.count == 16 }, "\(id) の 大きさが 16×16 で ない")
        }
    }

    @Test func everyEnemyHasItsOwnSprite() {
        for kind in EnemyKind.allCases {
            #expect(SpriteID(enemy: kind).rawValue == kind.rawValue, "\(kind.name) の 絵が ない")
        }
    }
}
