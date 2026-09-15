import Foundation

enum EnemyKind: String, Codable, CaseIterable {
    case bigRat
    case mushroom
    case bat
    case wolf
    case goblin
    case skeleton
    case golem
    case darkDragon

    struct Stats: Equatable {
        let name: String
        let maxHP: Int
        let attack: Int
        let defense: Int
        let agility: Int
        let exp: Int
        let gold: Int
    }

    var stats: Stats {
        switch self {
        case .bigRat: Stats(name: "オオネズミ", maxHP: 6, attack: 7, defense: 2, agility: 3, exp: 2, gold: 3)
        case .mushroom: Stats(name: "おばけキノコ", maxHP: 9, attack: 8, defense: 4, agility: 2, exp: 3, gold: 4)
        case .bat: Stats(name: "ヤミコウモリ", maxHP: 8, attack: 10, defense: 3, agility: 9, exp: 4, gold: 5)
        case .wolf: Stats(name: "はぐれオオカミ", maxHP: 18, attack: 15, defense: 8, agility: 10, exp: 9, gold: 12)
        case .goblin: Stats(name: "ゴブリン", maxHP: 26, attack: 20, defense: 12, agility: 7, exp: 14, gold: 20)
        case .skeleton: Stats(name: "ホネのへいし", maxHP: 34, attack: 26, defense: 18, agility: 9, exp: 22, gold: 30)
        case .golem: Stats(name: "イワゴーレム", maxHP: 55, attack: 32, defense: 30, agility: 3, exp: 35, gold: 45)
        case .darkDragon: Stats(name: "ヤミドラゴン", maxHP: 180, attack: 42, defense: 28, agility: 12, exp: 0, gold: 0)
        }
    }

    var isBoss: Bool { self == .darkDragon }

    /// ボスの炎の息のダメージ（守備力を無視）。
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
