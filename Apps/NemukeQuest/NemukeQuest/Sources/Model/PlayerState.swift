import Foundation

/// プレイヤーの状態。キー名は旧 React Native 版の保存形式（JSON）とそろえ、そのまま読めるようにしている。
struct PlayerState: Codable, Equatable, Sendable {
    struct Inventory: Codable, Equatable, Sendable {
        /// EXP の倍率（ブーストを買うと 1.5）。
        var expBoostMultiplier: Double = 1
        /// ストリークフリーズの所持数。
        var streakFreezes: Int = 0
    }

    var level = 1
    var currentExp = 0
    var expToNextLevel = Leveling.baseExp
    var gold = 0
    var questsCompleted = 0
    var unlockedAchievements: [String] = []
    /// 連続活動日数。
    var streak = 0
    var bestStreak = 0
    /// 最後にクエストを達成した日（yyyy-MM-dd・端末の暦）。
    var lastActiveDate: String?
    var demonsDefeated = 0
    var inventory = Inventory()

    init() {}

    /// 旧版の古い保存データには無い項目があるので、無ければ初期値で埋める。
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = PlayerState()
        func number(_ key: CodingKeys) -> Double? {
            (try? c.decodeIfPresent(Double.self, forKey: key)) ?? nil
        }
        level = max(1, Int(number(.level) ?? Double(fallback.level)))
        currentExp = max(0, Int(number(.currentExp) ?? 0))
        expToNextLevel = max(1, Int(number(.expToNextLevel) ?? Double(Leveling.expToNext(level: level))))
        gold = max(0, Int(number(.gold) ?? 0))
        questsCompleted = max(0, Int(number(.questsCompleted) ?? 0))
        unlockedAchievements = (try? c.decodeIfPresent([String].self, forKey: .unlockedAchievements)) ?? nil ?? []
        streak = max(0, Int(number(.streak) ?? 0))
        bestStreak = max(streak, Int(number(.bestStreak) ?? 0))
        lastActiveDate = (try? c.decodeIfPresent(String.self, forKey: .lastActiveDate)) ?? nil
        demonsDefeated = max(0, Int(number(.demonsDefeated) ?? 0))
        inventory = (try? c.decodeIfPresent(Inventory.self, forKey: .inventory)) ?? nil ?? Inventory()
    }

    enum CodingKeys: String, CodingKey {
        case level, currentExp, expToNextLevel, gold, questsCompleted, unlockedAchievements
        case streak, bestStreak, lastActiveDate, demonsDefeated, inventory
    }
}

extension PlayerState.Inventory {
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        expBoostMultiplier = (try? c.decodeIfPresent(Double.self, forKey: .expBoostMultiplier)) ?? nil ?? 1
        streakFreezes = Int((try? c.decodeIfPresent(Double.self, forKey: .streakFreezes)) ?? nil ?? 0)
    }

    enum CodingKeys: String, CodingKey { case expBoostMultiplier, streakFreezes }
}

/// クエスト（現実の小さな眠気対策）。
struct Quest: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let exp: Int
    let gold: Int
}

/// 実績。
struct Achievement: Identifiable, Sendable {
    let id: String
    let title: String
    let detail: String
    let isMet: @Sendable (PlayerState) -> Bool
}

/// 相棒の進化段階。
struct BuddyStage: Equatable, Sendable {
    let minLevel: Int
    let emoji: String
    let title: String
}

/// スリープデーモン（その場のバトルだけの状態で、保存しない）。
struct Demon: Equatable, Sendable {
    var hp: Int
    let maxHp: Int
}

enum ShopItem: Sendable {
    case expBoost, streakFreeze

    var cost: Int {
        switch self {
        case .expBoost: 200
        case .streakFreeze: 80
        }
    }
}
