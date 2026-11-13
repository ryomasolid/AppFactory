import CryptoKit
import Foundation
import Observation

/// 冒険の進み具合。プレイヤーの状態は Application Support に JSON で置く。デーモンはその場かぎり。
@MainActor
@Observable
final class Game {
    private(set) var player: PlayerState
    var demon: Demon?
    private(set) var quests: [Quest] = []
    private let fileURL: URL?
    private let now: () -> Date

    init(fileURL: URL?, seed: PlayerState = PlayerState(), now: @escaping () -> Date = { .now }) {
        self.fileURL = fileURL
        self.now = now
        var loaded = seed
        if let fileURL, let data = try? Data(contentsOf: fileURL), let saved = try? JSONDecoder().decode(PlayerState.self, from: data) {
            loaded = saved
        }
        let today = now()
        player = Leveling.reconcile(loaded, today: DayString.of(today), yesterday: DayString.yesterday(of: today))
        shuffle()
        save()
    }

    static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appending(path: "player.json")
    }

    /// ふだんの起動。初めての起動なら旧版のデータを引き継ぐ。
    static func open() -> Game {
        let url = defaultURL
        if FileManager.default.fileExists(atPath: url.path) { return Game(fileURL: url) }
        return Game(fileURL: url, seed: LegacyStore.load() ?? PlayerState())
    }

    // MARK: - 遊び

    func shuffle() {
        quests = Array(Catalog.quests.shuffled().prefix(Catalog.questsToShow))
    }

    func summonDemon() {
        demon = Demon(hp: Leveling.demonHp(level: player.level), maxHp: Leveling.demonHp(level: player.level))
        shuffle()
    }

    enum Outcome {
        case hit(damage: Int, quest: Quest)
        case defeated(bonusExp: Int, bonusGold: Int, quest: Quest)
    }

    /// クエスト達成 → デーモンにダメージ。倒したら討伐ボーナス。
    func complete(_ quest: Quest) -> (Outcome, [Achievement])? {
        guard var current = demon else { return nil }
        var next = Leveling.completeQuest(player, quest: quest, today: DayString.of(now()))
        let damage = Leveling.damage(of: quest)
        current.hp = max(current.hp - damage, 0)
        let outcome: Outcome
        if current.hp == 0 {
            let bonus = Leveling.defeatBonus(level: player.level)
            next = Leveling.defeat(next)
            demon = nil
            outcome = .defeated(bonusExp: bonus.exp, bonusGold: bonus.gold, quest: quest)
        } else {
            demon = current
            outcome = .hit(damage: damage, quest: quest)
        }
        let (checked, fresh) = Leveling.withAchievements(next)
        player = checked
        save()
        return (outcome, fresh)
    }

    func buy(_ item: ShopItem) -> Bool {
        guard let next = Leveling.buy(item, state: player) else { return false }
        player = Leveling.withAchievements(next).0
        save()
        return true
    }

    private func save() {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(player).write(to: fileURL, options: .atomic)
        } catch {
            print("冒険の記録を保存できませんでした: \(error)")
        }
    }
}

/// 旧 React Native 版（1.x）が端末に残したプレイヤーの状態を読む。
///
/// 旧版は AsyncStorage のキー `@player_state_v2`（1.0 のころは `@player_state`）に PlayerState の JSON 文字列を置いていた。
/// iOS での置き場所は `Application Support/<バンドルID>/RCTAsyncLocalStorage_V1/`（さらに古い版は `Documents/` 直下）。
/// 1024文字を超える値は manifest では null になり、キーの MD5（小文字16進）の名前の別ファイルに入る。
/// 読むだけで消さない。
enum LegacyStore {
    static let directoryName = "RCTAsyncLocalStorage_V1"
    static let keys = ["@player_state_v2", "@player_state"]

    static func candidateDirectories(bundleID: String = Bundle.main.bundleIdentifier ?? "") -> [URL] {
        let fm = FileManager.default
        var dirs: [URL] = []
        if let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            dirs.append(support.appending(path: bundleID).appending(path: directoryName))
        }
        if let documents = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            dirs.append(documents.appending(path: directoryName))
        }
        return dirs
    }

    static func load(from directories: [URL] = candidateDirectories()) -> PlayerState? {
        for dir in directories {
            guard let manifest = try? Data(contentsOf: dir.appending(path: "manifest.json")) else { continue }
            if let state = parse(manifest: manifest, readFile: { key in
                try? String(contentsOf: dir.appending(path: md5(key)), encoding: .utf8)
            }) {
                return state
            }
        }
        return nil
    }

    static func parse(manifest: Data, readFile: (String) -> String?) -> PlayerState? {
        guard let object = try? JSONSerialization.jsonObject(with: manifest) as? [String: Any] else { return nil }
        for key in keys {
            let raw: String?
            switch object[key] {
            case let inline as String: raw = inline
            case is NSNull: raw = readFile(key)
            default: raw = nil
            }
            if let raw, let state = try? JSONDecoder().decode(PlayerState.self, from: Data(raw.utf8)) {
                return state
            }
        }
        return nil
    }

    static func md5(_ key: String) -> String {
        Insecure.MD5.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
