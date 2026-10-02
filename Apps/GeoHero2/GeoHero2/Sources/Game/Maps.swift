import Foundation

/// ゲームの全マップ。地図そのものは 県ごとの ファイル（`Regions/`）に 書き、ここで まとめる。
/// 県ごとに フィールドが1枚あり、街・ほらあな・家が のっている。県の あいだは 新幹線（駅）で 行き来する。
/// ワープの到着点はワープ床の隣に置く（到着した瞬間にまた飛ばないように）。
enum World {
    static let startMap: MapID = .aomori
    /// 長老の すぐ下。
    static let startPoint = aomoriStart

    /// 地図 ぜんぶ。
    static let all: [MapID: GameMap] = {
        let maps = aomoriMaps + akitaMaps + iwateMaps + miyagiMaps + fukushimaMaps + yamagataMaps + [innInside, shopInside]
        return Dictionary(maps.map { ($0.id, $0) }) { first, _ in first }
    }()

    static func map(_ id: MapID) -> GameMap {
        all[id] ?? innInside
    }

    /// 全滅したときに戻る場所。いちばん近い街ではなく、その県の はじめの街の入口にそろえる。
    static func revivePoint(in region: Region) -> (map: MapID, point: Point) {
        switch region {
        case .aomori: (.aomori, aomoriGate)
        case .akita: (.akita, akitaGate)
        case .iwate: (.morioka, moriokaGate)
        case .miyagi: (.sendai, sendaiGate)
        case .fukushima: (.fukushima, fukushimaGate)
        case .yamagata: (.yamagata, yamagataGate)
        }
    }

    /// 名所の スタンプを押せる 看板（街の 名所の看板 ぜんぶ）。県ごとに 案内所で ごほうびが もらえる。
    static let stampPlaques: [PlaqueID] = MapID.allCases.filter(\.isTown).flatMap { id in
        map(id).plaques.keys.map { PlaqueID(map: id, point: $0) }
    }
    static func stampPlaques(in region: Region) -> [PlaqueID] { stampPlaques.filter { $0.map.region == region } }
    static func stampTotal(in region: Region) -> Int { stampPlaques(in: region).count }

    /// ほらあなから「だっしゅつ」したときに 出る場所（フィールドの 入口の 下）。ほらあなで なければ nil。
    static func caveExit(from id: MapID) -> (map: MapID, point: Point)? {
        guard id.isCave else { return nil }
        var current = id
        // 下の階から 上の階へ たどって、フィールドの 入口を さがす。
        // 「おりてくる」ワープ（フィールドの ほらあな・上の階の 下り階段）だけを たどる。
        for _ in 0..<5 {
            var found: (MapID, Point)?
            for map in all.values {
                for (point, warp) in map.warps where warp.to == current {
                    let tile = map.tile(at: point)
                    if tile == .cave || tile == .stairsDown { found = (map.id, point) }
                }
            }
            guard let (from, point) = found else { return nil }
            if from.isField { return (from, point + Point(x: 0, y: 1)) }
            current = from
        }
        return nil
    }

    static let innInside = GameMap(
        id: .innInside,
        name: "やどや",
        kind: .interior,
        region: nil,
        rows: [
            "XXXXXXXXX",
            "XQoQoooiX",
            "XoooooKKX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        outside: .darkness,
        warps: [
            // 出口の行き先は 入ってきた街の 扉の前に差し替わる（GameState が見る）。
            Point(x: 4, y: 5): Warp(to: .aomori, at: Point(x: 3, y: 5)),
        ],
        markerFloor: .woodFloor
    )

    static let shopInside = GameMap(
        id: .shopInside,
        name: "どうぐや",
        kind: .interior,
        region: nil,
        rows: [
            "XXXXXXXXX",
            "XLLLsLLLX",
            "XooKKKooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        outside: .darkness,
        warps: [
            Point(x: 4, y: 5): Warp(to: .aomori, at: Point(x: 11, y: 5)),
        ],
        markerFloor: .woodFloor
    )

    /// 家の中を作る。出口は 下の まんなか、入ると その上に立つ。
    /// 出口の行き先は 入った扉の前に差し替わる（GameState が見る）が、地図の上でも 同じ場所を書いておく。
    static func house(_ id: MapID, name: String, rows: [String], town: MapID, region: Region, door: Point,
                      villagers: [[String]], residents: [Character: Resident] = [:],
                      chestRewards: [ChestReward] = []) -> GameMap {
        GameMap(
            id: id, name: name, kind: .interior, region: region, rows: rows, outside: .darkness,
            warps: [Point(x: 4, y: rows.count - 1): Warp(to: town, at: door + Point(x: 0, y: 1))],
            villagers: villagers, residents: residents, chestRewards: chestRewards, quizTown: town,
            markerFloor: .woodFloor
        )
    }

    /// ほらあなを 作る。床は `,`、敵は 床の 上で 出る。
    static func cave(_ id: MapID, name: String, label: String? = nil, region: Region, rows: [String],
                     warps: [Point: Warp], chestRewards: [ChestReward] = [], bossKind: EnemyKind? = nil,
                     enemies: [EnemyKind], quizTown: MapID) -> GameMap {
        GameMap(
            id: id, name: name, kind: .cave, region: region, label: label, rows: rows, outside: .wall, warps: warps,
            chestRewards: chestRewards, bossKind: bossKind, encounters: [.caveFloor: enemies], quizTown: quizTown,
            markerFloor: .caveFloor
        )
    }

    /// 街の 出口（下の `E`）から フィールドへ 出る ワープ。
    static func exits(_ columns: ClosedRange<Int>, row: Int, to field: MapID, at point: Point) -> [Point: Warp] {
        Dictionary(uniqueKeysWithValues: columns.map { (Point(x: $0, y: row), Warp(to: field, at: point)) })
    }
}
