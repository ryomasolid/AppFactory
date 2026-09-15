import Foundation

struct Point: Hashable, Codable {
    var x: Int
    var y: Int

    static func + (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

enum Direction: String, Codable, CaseIterable {
    case up, down, left, right

    var delta: Point {
        switch self {
        case .up: Point(x: 0, y: -1)
        case .down: Point(x: 0, y: 1)
        case .left: Point(x: -1, y: 0)
        case .right: Point(x: 1, y: 0)
        }
    }
}

enum Tile: Character, CaseIterable {
    case grass = "."
    case forest = "f"
    case hills = "h"
    case mountain = "M"
    case water = "~"
    case road = "="
    case bridge = "b"
    case town = "T"
    case cave = "C"
    case townFloor = "_"
    case house = "H"
    case fountain = "w"
    case exit = "E"
    case wall = "#"
    case caveFloor = ","
    case stairsUp = "U"
    case stairsDown = "D"

    var isPassable: Bool {
        switch self {
        case .mountain, .water, .house, .fountain, .wall: false
        default: true
        }
    }
}

enum MapID: String, Codable, CaseIterable {
    case village, field, cave1, cave2
}

struct Warp: Equatable {
    let to: MapID
    let at: Point
}

enum NPCRole: Equatable {
    case innkeeper
    case shopkeeper
    case elder
    case villager(lines: [String])
}

struct NPC: Equatable {
    let position: Point
    let role: NPCRole
}

enum ChestReward: Equatable {
    case gold(Int)
    case item(Item)
}

struct Chest: Equatable {
    let id: String
    let position: Point
    let reward: ChestReward
}

struct GameMap {
    let id: MapID
    let name: String
    let tiles: [[Tile]]
    let outside: Tile
    let warps: [Point: Warp]
    let npcs: [NPC]
    let chests: [Chest]
    let boss: Point?
    /// 地形ごとに出る敵。載っていない地形では遭遇しない。
    let encounters: [Tile: [EnemyKind]]

    var width: Int { tiles.first?.count ?? 0 }
    var height: Int { tiles.count }

    func contains(_ point: Point) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < width && point.y < height
    }

    func tile(at point: Point) -> Tile {
        contains(point) ? tiles[point.y][point.x] : outside
    }

    func npc(at point: Point) -> NPC? { npcs.first { $0.position == point } }
    func chest(at point: Point) -> Chest? { chests.first { $0.position == point } }

    /// 歩いて入れるか（地形・人・宝箱・ボスで判定）。
    func isWalkable(_ point: Point) -> Bool {
        contains(point) && tile(at: point).isPassable && npc(at: point) == nil && chest(at: point) == nil && boss != point
    }

    /// 文字列の地図から作る。人・宝箱・ボスの印は足元の床に置き換え、登場順に `villagers` / `chestRewards` を割り当てる。
    init(
        id: MapID,
        name: String,
        rows: [String],
        outside: Tile,
        warps: [Point: Warp],
        villagers: [[String]] = [],
        chestRewards: [ChestReward] = [],
        encounters: [Tile: [EnemyKind]] = [:]
    ) {
        var tiles: [[Tile]] = []
        var npcs: [NPC] = []
        var chests: [Chest] = []
        var boss: Point?
        var villagerIndex = 0
        for (y, row) in rows.enumerated() {
            var line: [Tile] = []
            for (x, char) in row.enumerated() {
                let point = Point(x: x, y: y)
                switch char {
                case "i": npcs.append(NPC(position: point, role: .innkeeper)); line.append(.townFloor)
                case "s": npcs.append(NPC(position: point, role: .shopkeeper)); line.append(.townFloor)
                case "e": npcs.append(NPC(position: point, role: .elder)); line.append(.townFloor)
                case "t":
                    let lines = villagerIndex < villagers.count ? villagers[villagerIndex] : ["……"]
                    villagerIndex += 1
                    npcs.append(NPC(position: point, role: .villager(lines: lines)))
                    line.append(.townFloor)
                case "c":
                    let reward = chests.count < chestRewards.count ? chestRewards[chests.count] : .gold(10)
                    chests.append(Chest(id: "\(id.rawValue)-\(chests.count)", position: point, reward: reward))
                    line.append(.caveFloor)
                case "B": boss = point; line.append(.caveFloor)
                default: line.append(Tile(rawValue: char) ?? outside)
                }
            }
            tiles.append(line)
        }
        self.id = id
        self.name = name
        self.tiles = tiles
        self.outside = outside
        self.warps = warps
        self.npcs = npcs
        self.chests = chests
        self.boss = boss
        self.encounters = encounters
    }
}
