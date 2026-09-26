import Foundation

/// セーブ内容。宿屋に泊まったときとメニューの「セーブ」で書き出す。
struct SaveData: Codable, Equatable {
    var hero: Hero
    var map: MapID
    var position: Point
    var openedChests: Set<String>
    /// 倒したボス。どこまで進んだかを覚えておく。
    var defeatedBosses: Set<EnemyKind> = []
    /// 物語の進みぐあい。
    var storyFlags: Set<StoryFlag> = []
    /// 宿屋・道具屋の中でセーブしたとき、出る先の街と扉の前。
    var lastTown: MapID = World.startMap
    var interiorReturn: Point?
}

extension SaveData {
    /// あとから足した項目は なくても読む（物語の仕組みより前のセーブを そのまま続けられるように）。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hero = try c.decode(Hero.self, forKey: .hero)
        map = try c.decode(MapID.self, forKey: .map)
        position = try c.decode(Point.self, forKey: .position)
        openedChests = try c.decode(Set<String>.self, forKey: .openedChests)
        defeatedBosses = try c.decodeIfPresent(Set<EnemyKind>.self, forKey: .defeatedBosses) ?? []
        storyFlags = try c.decodeIfPresent(Set<StoryFlag>.self, forKey: .storyFlags) ?? []
        lastTown = try c.decodeIfPresent(MapID.self, forKey: .lastTown) ?? World.startMap
        interiorReturn = try c.decodeIfPresent(Point.self, forKey: .interiorReturn)
    }
}

enum SaveStore {
    // 進みぐあいの持ちかたを変えたので v2。古いセーブは読まない。
    static let key = "geohero.save.v2"

    static func load(from defaults: UserDefaults = .standard) -> SaveData? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SaveData.self, from: data)
    }

    static func save(_ save: SaveData, to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(save) else { return }
        defaults.set(data, forKey: key)
    }

    static func delete(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
