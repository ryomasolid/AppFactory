import Foundation

/// 北海道に出る敵。能力値の階段はそのままに、題材だけ日本のものにしてある。
enum EnemyKind: String, Codable, CaseIterable {
    case potato
    case kelpSlime
    case scallop
    case fox
    case cod
    case snowman
    case iceGolem
    case guardian

    struct Stats: Equatable {
        let name: String
        let maxHP: Int
        let attack: Int
        let defense: Int
        let agility: Int
        let exp: Int
        let gold: Int
    }

    /// 最初のフィールド（いしかりの野）に出る敵は、うっかり迷いこんでも
    /// 2発で倒されない強さに抑えてある（`EncounterTests` で固めている）。
    var stats: Stats {
        switch self {
        case .potato: Stats(name: "ポテトー", maxHP: 6, attack: 7, defense: 2, agility: 3, exp: 2, gold: 3)
        case .kelpSlime: Stats(name: "こんぶスライム", maxHP: 9, attack: 8, defense: 4, agility: 2, exp: 3, gold: 4)
        case .scallop: Stats(name: "ホタテキッド", maxHP: 8, attack: 10, defense: 3, agility: 9, exp: 4, gold: 5)
        case .fox: Stats(name: "きたきつね", maxHP: 14, attack: 11, defense: 5, agility: 10, exp: 7, gold: 10)
        case .cod: Stats(name: "タラこぞう", maxHP: 20, attack: 14, defense: 8, agility: 7, exp: 11, gold: 16)
        case .snowman: Stats(name: "ゆきおとこ", maxHP: 34, attack: 26, defense: 18, agility: 9, exp: 22, gold: 30)
        case .iceGolem: Stats(name: "りゅうひょうゴーレム", maxHP: 55, attack: 32, defense: 30, agility: 3, exp: 35, gold: 45)
        case .guardian: Stats(name: "知床の守護神", maxHP: 180, attack: 42, defense: 28, agility: 12, exp: 0, gold: 0)
        }
    }

    var isBoss: Bool { self == .guardian }

    /// 守護神の ふぶき のダメージ（守備力を無視）。
    static let breathPower: ClosedRange<Int> = 14...20
}

struct Enemy: Equatable {
    let kind: EnemyKind
    var hp: Int

    init(_ kind: EnemyKind) {
        self.kind = kind
        hp = kind.stats.maxHP
    }

    var name: String { kind.stats.name }
    var isDead: Bool { hp <= 0 }
}
