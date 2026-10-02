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
    /// 新幹線の駅。のると ほかの県へ 行ける（ひらいた県だけ）。
    case station = "A"
    /// 田んぼ（東北の 米どころ）。歩ける。
    case paddy = "p"
    /// 雪原。歩ける。
    case snow = "n"
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

/// 東北の 6つの県。県ごとに フィールドが1枚あり、新幹線で 行き来する。
/// 青森 → 秋田 → 岩手 → 宮城 → 福島 → 山形 の順に たどる（ひとつ前の 県の ぬしを 倒すと 次の 県へ 行ける）。
enum Region: String, Codable, CaseIterable, CodingKeyRepresentable {
    case aomori, akita, iwate, miyagi, fukushima, yamagata

    /// 旅の順番（0 から）。
    var order: Int { Region.allCases.firstIndex(of: self) ?? 0 }

    /// 「青森県」。
    var name: String {
        switch self {
        case .aomori: "青森県"
        case .akita: "秋田県"
        case .iwate: "岩手県"
        case .miyagi: "宮城県"
        case .fukushima: "福島県"
        case .yamagata: "山形県"
        }
    }

    /// 「青森」（県を つけない みじかい名前。一覧で使う）。
    var shortName: String { String(name.dropLast()) }

    /// その県の フィールド。
    var field: MapID {
        switch self {
        case .aomori: .aomoriField
        case .akita: .akitaField
        case .iwate: .iwateField
        case .miyagi: .miyagiField
        case .fukushima: .fukushimaField
        case .yamagata: .yamagataField
        }
    }

    /// 新幹線の駅の名前。
    var stationName: String {
        switch self {
        case .aomori: "新青森駅"
        case .akita: "秋田駅"
        case .iwate: "盛岡駅"
        case .miyagi: "仙台駅"
        case .fukushima: "福島駅"
        case .yamagata: "山形駅"
        }
    }

    /// 新幹線で着いたときの札。
    var banner: PlaceBanner {
        switch self {
        case .aomori: PlaceBanner(name: "青森県", reading: "あおもりけん", tagline: "りんごと ねぶたの 本州の きた")
        case .akita: PlaceBanner(name: "秋田県", reading: "あきたけん", tagline: "竿燈と なまはげの 米どころ")
        case .iwate: PlaceBanner(name: "岩手県", reading: "いわてけん", tagline: "本州で いちばん ひろい 県")
        case .miyagi: PlaceBanner(name: "宮城県", reading: "みやぎけん", tagline: "杜の都と 日本三景")
        case .fukushima: PlaceBanner(name: "福島県", reading: "ふくしまけん", tagline: "赤べこと 磐梯山の 県")
        case .yamagata: PlaceBanner(name: "山形県", reading: "やまがたけん", tagline: "さくらんぼと 樹氷の 県")
        }
    }

    /// 県の まつり。ぬしを 倒すと もどる。
    var festival: String {
        switch self {
        case .aomori: "青森ねぶた祭"
        case .akita: "秋田竿燈まつり"
        case .iwate: "盛岡さんさ踊り"
        case .miyagi: "仙台七夕まつり"
        case .fukushima: "福島わらじまつり"
        case .yamagata: "山形花笠まつり"
        }
    }

    /// この県の ぬし（倒すと まつりが もどり、次の県へ 行ける）。
    var lord: EnemyKind {
        switch self {
        case .aomori: .yukioni
        case .akita: .namahageKing
        case .iwate: .mitsuishiOni
        case .miyagi: .datemaru
        case .fukushima: .tenagaAshinaga
        case .yamagata: .guardian
        }
    }

    /// この県の 中ボス（1つめの ほらあなの ボス）。
    var subBoss: EnemyKind {
        switch self {
        case .aomori: .hachirotaro
        case .akita: .tatsuko
        case .iwate: .ryusendoLord
        case .miyagi: .giantOyster
        case .fukushima: .abukumaLord
        case .yamagata: .yamaderaCicada
        }
    }

    /// ひとつ前の 県。
    var previous: Region? { order > 0 ? Region.allCases[order - 1] : nil }
    var next: Region? { order + 1 < Region.allCases.count ? Region.allCases[order + 1] : nil }
}

/// 地図の しゅるい。
enum MapKind: Equatable {
    case field, town, cave, interior
}

enum MapID: String, Codable, CaseIterable {
    // ── 青森 ──
    case aomoriField, aomori, hirosaki, hachinohe, towadako, hakkoda1, hakkoda2, osorezan1, osorezan2
    case nebutaHouse, aomoriHouse, hirosakiCastle, ringoHouse, matagiHouse, hachinoheHouse
    // ── 秋田 ──
    case akitaField, akita, kakunodate, oga, tazawako, shinzan1, shinzan2
    case kantoHouse, akitaHouse, bukeyashiki, kabazaikuHouse, namahageHouse, ogaHouse
    // ── 岩手 ──
    case iwateField, morioka, hiraizumi, tono, ryusendo1, ryusendo2, iwatesan1, iwatesan2
    case wankoHouse, nanbuHouse, chusonji, hiraizumiHouse, tonoHouse, magariya
    // ── 宮城 ──
    case miyagiField, sendai, matsushima, naruko, oysterCave, aobayama1, aobayama2
    case tanabataHouse, sendaiHouse, museum, zuiganji, matsushimaHouse, kokeshiHouse
    // ── 福島 ──
    case fukushimaField, aizu, kitakata, fukushima, abukumado, bandai1, bandai2
    case tsurugajo, akabekoHouse, kuraHouse, ramenHouse, warajiHouse, momoHouse
    // ── 山形 ──
    case yamagataField, yamagata, tendo, sakata, yamadera1, yamadera2, zao1, zao2, zao3
    case hanagasaHouse, imoniHouse, shogiHouse, tendoHouse, sankyoSouko, sakataHouse
    /// 宿屋と道具屋の中。どの街から入っても ここを使い、出るときに元の街へ戻る。
    case innInside, shopInside

    private var map: GameMap? { World.all[self] }

    /// 漢字の地名。フィールドの目印の下や 看板に出す。
    var placeName: String? { map?.label }

    /// どの県の地図か。宿屋・道具屋の中は 入ってきた街で決まるので nil。
    var region: Region? { map?.region }

    var kind: MapKind { map?.kind ?? .interior }

    /// 県の フィールドか。
    var isField: Bool { kind == .field }

    /// ほらあなか。
    var isCave: Bool { kind == .cave }

    /// 宿屋・道具屋・家の中か。
    var isInterior: Bool { kind == .interior }

    /// 街の 家の中か。
    var isHouse: Bool { isInterior && self != .innInside && self != .shopInside }

    /// 街かどうか（宿屋・道具屋から戻る先になれるか）。
    var isTown: Bool { townInfo != nil }

    /// 街ごとの ちがい。街でなければ nil。
    var townInfo: TownInfo? { map?.town }
}

/// 真ん中に しばらく出す 地名の札（街に入ったとき・新幹線で着いたとき）。
struct PlaceBanner: Equatable {
    let name: String
    let reading: String
    let tagline: String
}

/// 街ごとの ちがい。奥の街ほど 宿代は高く、道具屋の品ぞろえは強くなる。
/// 地形・人数・家の数は地図のほうで変える。
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
}

/// フィールドの区域。目印（街・ほらあな）ごとに 出る敵を決める。
/// いちばん近い目印の表を使うので、**次の目印へ近づくほど敵が強くなる**。
struct EncounterArea: Equatable {
    /// どの目印のまわりか（メッセージやテストで見分けるため）。
    let name: String
    /// この区域の中心。**ひとつとは限らない**。
    /// 海や山で へだてられて まわり道になる土地は、目印だけを中心にすると
    /// 先の区域が食いこんでしまうので、通り道にも中心を足して押し返す。
    let around: [Point]
    let enemies: [EnemyKind]
    /// この区域の 戦いで「ちしき」を 出す 街。
    var quizTown: MapID?

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
    let kind: MapKind
    /// どの県か。宿屋・道具屋の中は nil（入ってきた街で決まる）。
    let region: Region?
    /// フィールドの目印の下に出す 漢字の地名（街・ほらあな）。
    let label: String?
    /// 街なら その街の 宿代・品ぞろえ。
    let town: TownInfo?
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
    /// ここで 戦うと「ちしき」を 出す 街（街は 自分、ほらあな・家は ちかくの 街）。
    let quizTown: MapID?

    var width: Int { tiles.first?.count ?? 0 }
    var height: Int { tiles.count }

    func contains(_ point: Point) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < width && point.y < height
    }

    func tile(at point: Point) -> Tile {
        contains(point) ? tiles[point.y][point.x] : outside
    }

    /// 駅のマス（フィールドに ひとつ）。
    var station: Point? {
        for (y, row) in tiles.enumerated() {
            if let x = row.firstIndex(of: .station) { return Point(x: x, y: y) }
        }
        return nil
    }

    /// そのマスが どの区域か。いちばん近い中心を選ぶ。
    /// 区域は 旅の順に並べてあるので、同じ距離なら 先に書いたほう（弱いほう）になる。
    func area(at point: Point) -> EncounterArea? {
        encounterAreas.min { $0.distance(to: point) < $1.distance(to: point) }
    }

    /// そのマスで出る敵。区域があればそちら、なければ地形で決める。
    /// 区域は **道の上もふくめて** 全部のマスをおおう。道だけ安全だと、
    /// 街から街まで一度も戦わずに歩けてしまう。駅の上では 出ない。
    func encounterTable(at point: Point) -> [EnemyKind]? {
        if tile(at: point) == .station { return nil }
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
        kind: MapKind,
        region: Region?,
        label: String? = nil,
        town: TownInfo? = nil,
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
        /// ここで 戦うと「ちしき」を 出す 街（街なら 書かなくてよい）。
        quizTown: MapID? = nil,
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
        self.kind = kind
        self.region = region
        self.label = label ?? town?.name
        self.town = town
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
        self.quizTown = quizTown ?? (kind == .town ? id : nil)
    }
}
