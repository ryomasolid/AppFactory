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
    /// 空港。きっぷがあれば となりの地方へ とべる。
    case airport = "A"
    /// さくらの木（街の中）。通れない。
    case blossom = "k"
    case townFloor = "_"
    case house = "H"
    /// やどやの屋根（青）。遠目でも どちらの家か わかるように色を分ける。
    case innRoof = "I"
    /// どうぐやの屋根（緑）。
    case shopRoof = "S"
    case fountain = "w"
    /// 街の出口。矢印を描いて、壁のすきまが外へ抜ける道だと分かるようにする。
    case exit = "E"
    /// 街の名前を書いた看板。通れないが、A で しらべると 街の説明が出る。
    case signpost = "P"
    case wall = "#"
    case caveFloor = ","
    case stairsUp = "U"
    case stairsDown = "D"
    // 建物
    case houseWall = "W"
    case innSign = "Y"
    case shopSign = "Z"
    case door = "d"
    case woodFloor = "o"
    /// カウンター。通れないが、越しに奥の人と話せる。
    case counter = "K"
    case bed = "Q"
    case shelf = "L"
    case innerWall = "X"
    /// 建物の中の部屋の外側（真っ黒）。部屋だけが浮かび上がって見えるようにする。
    case darkness = "V"

    var isPassable: Bool {
        switch self {
        case .mountain, .water, .house, .innRoof, .shopRoof, .fountain, .wall,
             .houseWall, .innSign, .shopSign, .counter, .bed, .shelf, .innerWall, .darkness, .signpost, .blossom: false
        default: true
        }
    }
}

/// 地方。地方ごとに フィールドが1枚あり、空港から ひこうきで行き来する。
/// 函館エリア → 札幌・小樽 → 知床 の順にたどる。
enum Region: String, CaseIterable {
    case hakodate, sapporo, shiretoko

    /// その地方の フィールド。
    var field: MapID {
        switch self {
        case .hakodate: .hakodateArea
        case .sapporo: .sapporoArea
        case .shiretoko: .shiretokoArea
        }
    }

    /// ひこうきで着いたときの札。
    var banner: PlaceBanner {
        switch self {
        case .hakodate: PlaceBanner(name: "函館エリア", reading: "はこだて えりあ", tagline: "旅の はじまりの 道南")
        case .sapporo: PlaceBanner(name: "札幌・小樽", reading: "さっぽろ・おたる", tagline: "北の 大きな 街と みなと町")
        case .shiretoko: PlaceBanner(name: "知床", reading: "しれとこ", tagline: "ちの はての 半島")
        }
    }
}

enum MapID: String, Codable, CaseIterable {
    /// 地方の フィールド。函館エリアは 1枚きりだったころの名前（field）でセーブに残る。
    case hakodateArea = "field"
    case sapporoArea, shiretokoArea
    /// 街。函館エリアは 函館・松前・大沼、札幌・小樽は 札幌・小樽、知床は 羅臼。
    case hakodate, matsumae, onuma
    case sapporo, otaru, jozankei
    case rausu
    /// ほらあな。
    case hakodateyama, komagatake
    case tenguyama, moiwa1, moiwa2
    case rausudake1, rausudake2
    /// 宿屋と道具屋の中。どの街から入っても ここを使い、出るときに元の街へ戻る。
    case innInside, shopInside
    /// 街の 家の中。1軒ずつ ちがい、宝箱や ヒントをくれる人がいる。出るときは 入った扉の前へ戻る。
    case bugyosho, asaichiSouko, motomachiHouse, bukeyashiki, tsukemonoya, ryoshiHouse, noukaHouse, dangoya, yamagoya, glassKobo, tokeidaiHouse, sapporoHouse, doucho, susukinoHouse, orgelDo, otaruSouko, onsenHouse

    /// 漢字の地名。フィールドの目印の下や 看板に出す。街・ほらあな・空港の行き先。
    var placeName: String? {
        switch self {
        case .hakodate: "函館"
        case .matsumae: "松前"
        case .onuma: "大沼"
        case .sapporo: "札幌"
        case .otaru: "小樽"
        case .jozankei: "定山渓"
        case .rausu: "羅臼"
        case .hakodateyama: "函館山"
        case .komagatake: "駒ヶ岳"
        case .tenguyama: "天狗山"
        case .moiwa1, .moiwa2: "藻岩山"
        case .rausudake1, .rausudake2: "羅臼岳"
        default: nil
        }
    }

    /// どの地方の地図か。宿屋・道具屋の中は 入ってきた街で決まるので nil。
    var region: Region? {
        switch self {
        case .hakodateArea, .hakodate, .matsumae, .onuma, .hakodateyama, .komagatake: .hakodate
        case .sapporoArea, .sapporo, .otaru, .jozankei, .tenguyama, .moiwa1, .moiwa2: .sapporo
        case .shiretokoArea, .rausu, .rausudake1, .rausudake2: .shiretoko
        default: nil
        }
    }

    /// 地方の フィールドか。
    var isField: Bool { Region.allCases.contains { $0.field == self } }

    /// ほらあなか。
    var isCave: Bool {
        switch self {
        case .hakodateyama, .komagatake, .tenguyama, .moiwa1, .moiwa2, .rausudake1, .rausudake2: true
        default: false
        }
    }

    /// 宿屋・道具屋の中か。
    var isInterior: Bool { self == .innInside || self == .shopInside || isHouse }

    /// 街の 家の中か。
    var isHouse: Bool { World.houses.contains(self) }

    /// 街かどうか（宿屋・道具屋から戻る先になれるか）。
    var isTown: Bool { townInfo != nil }

    /// 街ごとの ちがい。街でなければ nil。
    var townInfo: TownInfo? {
        switch self {
        case .hakodate: .hakodate
        case .matsumae: .matsumae
        case .onuma: .onuma
        case .sapporo: .sapporo
        case .otaru: .otaru
        case .jozankei: .jozankei
        case .rausu: .rausu
        default: nil
        }
    }
}

/// 真ん中に しばらく出す 地名の札（街に入ったとき・ひこうきで着いたとき）。
struct PlaceBanner: Equatable {
    let name: String
    let reading: String
    let tagline: String
}

/// 街ごとの ちがい。奥の街ほど 宿代は高く、道具屋の品ぞろえは強くなる。
/// 地形・人数・家の数は地図（`Maps.swift`）のほうで変える。
struct TownInfo: Equatable {
    /// 漢字の名前と よみ。街に入ったときの札と 看板に出す。
    let name: String
    let reading: String
    /// ひとことの説明（「みなとの 街」など）。
    let tagline: String
    /// 宿代は `base + レベル × perLevel`。
    let innBase: Int
    let innPerLevel: Int
    /// 道具屋の品ぞろえ。まだ早い装備も、もう用のない装備も置かない。
    let stock: [Item]

    var banner: PlaceBanner { PlaceBanner(name: name, reading: reading, tagline: tagline) }

    /// みなとの街。旅のはじめなので 安く、そろえも いちばん下。
    static let hakodate = TownInfo(name: "函館", reading: "はこだて", tagline: "みなとの 街",
                                   innBase: 2, innPerLevel: 3,
                                   stock: [.herb, .copperSword, .leatherArmor])
    /// 城と さくらの 町。函館の つぎに たずねる。
    static let matsumae = TownInfo(name: "松前", reading: "まつまえ", tagline: "城と さくらの 町",
                                   innBase: 3, innPerLevel: 3,
                                   stock: [.herb, .copperSword, .leatherArmor])
    /// 湖の ほとりの 町。駒ヶ岳の ふもと。
    static let onuma = TownInfo(name: "大沼", reading: "おおぬま", tagline: "駒ヶ岳を うつす 湖の 町",
                                innBase: 3, innPerLevel: 4,
                                stock: [.herb, .copperSword, .leatherArmor])
    /// 大きな街。鋼の剣が ここで買える。
    static let sapporo = TownInfo(name: "札幌", reading: "さっぽろ", tagline: "北の 大きな 街",
                                  innBase: 4, innPerLevel: 5,
                                  stock: [.herb, .copperSword, .leatherArmor, .steelSword])
    /// 運河の みなと町。札幌の となりで、品ぞろえも 札幌と ほぼ同じ。
    static let otaru = TownInfo(name: "小樽", reading: "おたる", tagline: "運河と ガラスの みなと町",
                                innBase: 5, innPerLevel: 5,
                                stock: [.herb, .leatherArmor, .steelSword])
    /// 山あいの 温泉街。札幌の 南西、藻岩山の さき。
    static let jozankei = TownInfo(name: "定山渓", reading: "じょうざんけい", tagline: "かっぱの すむ 温泉街",
                                   innBase: 5, innPerLevel: 6,
                                   stock: [.herb, .steelSword, .chainMail])
    /// さいはての町。運ぶのが大変なぶん 宿も品も高い。銅の剣・革の鎧は もう置かない。
    static let rausu = TownInfo(name: "羅臼", reading: "らうす", tagline: "知床の さいはての 町",
                                innBase: 6, innPerLevel: 8,
                                stock: [.herb, .steelSword, .chainMail])
}

/// フィールドの区域。目印（街・ほらあな）ごとに 出る敵を決める。
/// いちばん近い目印の表を使うので、**次の目印へ近づくほど敵が強くなる**。
struct EncounterArea: Equatable {
    /// どの目印のまわりか（メッセージやテストで見分けるため）。
    let name: String
    /// この区域の中心。**ひとつとは限らない**。
    /// 海でへだてられて まわり道になる土地は、目印だけを中心にすると
    /// 先の区域が食いこんでしまうので、通り道にも中心を足して押し返す。
    let around: [Point]
    let enemies: [EnemyKind]

    init(name: String, around: [Point], enemies: [EnemyKind]) {
        self.name = name
        self.around = around
        self.enemies = enemies
    }

    func distance(to point: Point) -> Int {
        around.map { abs($0.x - point.x) + abs($0.y - point.y) }.min() ?? .max
    }
}

/// 名所の看板。板には 短い名前、しらべると 説明が出る。
struct Plaque: Equatable {
    /// 板に書く名前（2〜3文字。それより長いと 板からはみ出す）。
    let title: String
    let lines: [String]
}

/// 名所の看板の 見分け（「めいしょ スタンプ」の記録に使う）。
struct PlaqueID: Hashable, Codable {
    let map: MapID
    let point: Point
}

struct Warp: Equatable {
    let to: MapID
    let at: Point
    /// この敵を倒していないと入れない。順番に進ませるための関所。
    var requires: EnemyKind?
    /// この印が立っていないと入れない。街の人の頼みを片づけて 道をひらく関所。
    var needs: StoryFlag?
}

enum NPCRole: Equatable {
    case innkeeper
    case shopkeeper
    case elder
    case villager(lines: [String])
    /// 物語にかかわる人。進みぐあいで せりふが変わる（`Story.swift`）。
    case resident(Resident)
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
    /// そのマップのボス。`boss` のマスで話しかけると この敵と戦う。
    let bossKind: EnemyKind?
    /// 地形ごとに出る敵。載っていない地形では遭遇しない。ほらあなで使う。
    let encounters: [Tile: [EnemyKind]]
    /// 区域ごとに出る敵。こちらがあれば 地形より優先する。フィールドで使う。
    let encounterAreas: [EncounterArea]
    /// A で しらべると読める 名所の看板（`P` のマス）。載っていない看板は 街の名前を出す。
    let plaques: [Point: Plaque]

    var width: Int { tiles.first?.count ?? 0 }
    var height: Int { tiles.count }

    func contains(_ point: Point) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < width && point.y < height
    }

    func tile(at point: Point) -> Tile {
        contains(point) ? tiles[point.y][point.x] : outside
    }

    /// そのマスが どの区域か。いちばん近い中心を選ぶ。
    /// 区域は 旅の順に並べてあるので、同じ距離なら 先に書いたほう（弱いほう）になる。
    func area(at point: Point) -> EncounterArea? {
        encounterAreas.min { $0.distance(to: point) < $1.distance(to: point) }
    }

    /// そのマスで出る敵。区域があればそちら、なければ地形で決める。
    /// 区域は **道の上もふくめて** 全部のマスをおおう。道だけ安全だと、
    /// 街から街まで一度も戦わずに歩けてしまう。
    func encounterTable(at point: Point) -> [EnemyKind]? {
        if !encounterAreas.isEmpty { return area(at: point)?.enemies }
        return encounters[tile(at: point)]
    }

    /// いま出ている人。迷子のように 進みぐあいで 出たり消えたりする人がいる。
    func npcs(_ progress: StoryProgress) -> [NPC] {
        npcs.filter { npc in
            if case let .resident(resident) = npc.role { return resident.isPresent(progress) }
            return true
        }
    }

    func npc(at point: Point, _ progress: StoryProgress? = nil) -> NPC? {
        (progress.map(npcs) ?? npcs).first { $0.position == point }
    }
    func chest(at point: Point) -> Chest? { chests.first { $0.position == point } }

    /// 歩いて入れるか（地形・人・宝箱・ボスで判定）。
    /// ボスは 倒すと いなくなるので、そのあとは `bossRemains` に false を渡して 通れるようにする。
    /// `progress` を渡すと、いまは いない人のマスも 通れる（渡さなければ 全員いることにする）。
    func isWalkable(_ point: Point, bossRemains: Bool = true, progress: StoryProgress? = nil) -> Bool {
        contains(point) && tile(at: point).isPassable && npc(at: point, progress) == nil && chest(at: point) == nil
            && !(bossRemains && boss == point)
    }

    /// 文字列の地図から作る。人・宝箱・ボスの印は足元の床に置き換え、登場順に `villagers` / `chestRewards` を割り当てる。
    init(
        id: MapID,
        name: String,
        rows: [String],
        outside: Tile,
        warps: [Point: Warp],
        villagers: [[String]] = [],
        /// 数字の印（1〜9）に置く 物語の人。
        residents: [Character: Resident] = [:],
        plaques: [Point: Plaque] = [:],
        chestRewards: [ChestReward] = [],
        bossKind: EnemyKind? = nil,
        encounters: [Tile: [EnemyKind]] = [:],
        encounterAreas: [EncounterArea] = [],
        /// 人・宝箱の印（i・s・e・t・c）の足元に敷く床。
        markerFloor: Tile = .townFloor
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
                case "i": npcs.append(NPC(position: point, role: .innkeeper)); line.append(markerFloor)
                case "s": npcs.append(NPC(position: point, role: .shopkeeper)); line.append(markerFloor)
                case "e": npcs.append(NPC(position: point, role: .elder)); line.append(markerFloor)
                case "t":
                    let lines = villagerIndex < villagers.count ? villagers[villagerIndex] : ["……"]
                    villagerIndex += 1
                    npcs.append(NPC(position: point, role: .villager(lines: lines)))
                    line.append(markerFloor)
                case "c":
                    let reward = chests.count < chestRewards.count ? chestRewards[chests.count] : .gold(10)
                    chests.append(Chest(id: "\(id.rawValue)-\(chests.count)", position: point, reward: reward))
                    line.append(markerFloor)
                case "B": boss = point; line.append(.caveFloor)
                case let mark where residents[mark] != nil:
                    npcs.append(NPC(position: point, role: .resident(residents[mark]!)))
                    line.append(markerFloor)
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
        self.bossKind = bossKind
        self.boss = boss
        self.encounters = encounters
        self.encounterAreas = encounterAreas
        self.plaques = plaques
    }
}
