import Foundation

/// セーブ内容。宿屋に泊まったときとメニューの「セーブ」で書き出す。
struct SaveData: Codable, Equatable {
    var hero: Hero
    var map: MapID
    var position: Point
    var openedChests: Set<String>
    /// 倒したボス。どこまで進んだかを覚えておく。
    var defeatedBosses: Set<EnemyKind> = []
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
