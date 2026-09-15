import Foundation

/// レベルごとの素の能力値。装備の分は含まない。
struct LevelRow: Equatable {
    let maxHP: Int
    let maxMP: Int
    let attack: Int
    let defense: Int
    let agility: Int
    /// このレベルに上がるのに必要な累計経験値。
    let exp: Int
}

enum LevelTable {
    static let rows: [LevelRow] = [
        LevelRow(maxHP: 15, maxMP: 0, attack: 5, defense: 4, agility: 4, exp: 0),
        LevelRow(maxHP: 22, maxMP: 5, attack: 7, defense: 5, agility: 5, exp: 8),
        LevelRow(maxHP: 28, maxMP: 9, attack: 9, defense: 7, agility: 7, exp: 25),
        LevelRow(maxHP: 35, maxMP: 13, attack: 12, defense: 9, agility: 8, exp: 55),
        LevelRow(maxHP: 42, maxMP: 16, attack: 14, defense: 11, agility: 10, exp: 100),
        LevelRow(maxHP: 50, maxMP: 20, attack: 17, defense: 13, agility: 11, exp: 170),
        LevelRow(maxHP: 57, maxMP: 24, attack: 20, defense: 15, agility: 13, exp: 270),
        LevelRow(maxHP: 65, maxMP: 28, attack: 23, defense: 17, agility: 14, exp: 400),
        LevelRow(maxHP: 72, maxMP: 32, attack: 26, defense: 19, agility: 16, exp: 570),
        LevelRow(maxHP: 80, maxMP: 36, attack: 29, defense: 21, agility: 17, exp: 780),
        LevelRow(maxHP: 88, maxMP: 40, attack: 32, defense: 23, agility: 19, exp: 1050),
        LevelRow(maxHP: 96, maxMP: 45, attack: 35, defense: 25, agility: 20, exp: 1400),
    ]

    static var maxLevel: Int { rows.count }

    static func row(_ level: Int) -> LevelRow {
        rows[min(max(level, 1), maxLevel) - 1]
    }
}

enum Spell: String, Codable, CaseIterable, Identifiable {
    case heal
    case fire
    case highHeal
    case flame

    var id: String { rawValue }

    var name: String {
        switch self {
        case .heal: "ヒール"
        case .fire: "ファイア"
        case .highHeal: "ハイヒール"
        case .flame: "フレイム"
        }
    }

    var mpCost: Int {
        switch self {
        case .heal: 3
        case .fire: 2
        case .highHeal: 6
        case .flame: 5
        }
    }

    var learnLevel: Int {
        switch self {
        case .heal: 2
        case .fire: 4
        case .highHeal: 7
        case .flame: 8
        }
    }

    /// 回復量または与えるダメージの幅。攻撃呪文は守備力を無視する。
    var power: ClosedRange<Int> {
        switch self {
        case .heal: 20...28
        case .fire: 10...14
        case .highHeal: 60...80
        case .flame: 25...32
        }
    }

    var isHealing: Bool { self == .heal || self == .highHeal }
}

enum Item: String, Codable, CaseIterable, Identifiable, CodingKeyRepresentable {
    case herb
    case woodStick
    case copperSword
    case steelSword
    case clothes
    case leatherArmor
    case chainMail

    enum Kind: Equatable {
        case consumable
        case weapon(power: Int)
        case armor(power: Int)
    }

    var id: String { rawValue }

    var name: String {
        switch self {
        case .herb: "薬草"
        case .woodStick: "木の棒"
        case .copperSword: "銅の剣"
        case .steelSword: "鋼の剣"
        case .clothes: "布の服"
        case .leatherArmor: "革の鎧"
        case .chainMail: "鎖帷子"
        }
    }

    var kind: Kind {
        switch self {
        case .herb: .consumable
        case .woodStick: .weapon(power: 2)
        case .copperSword: .weapon(power: 8)
        case .steelSword: .weapon(power: 16)
        case .clothes: .armor(power: 2)
        case .leatherArmor: .armor(power: 6)
        case .chainMail: .armor(power: 12)
        }
    }

    var price: Int {
        switch self {
        case .herb: 8
        case .woodStick: 5
        case .copperSword: 100
        case .steelSword: 550
        case .clothes: 10
        case .leatherArmor: 120
        case .chainMail: 450
        }
    }

    /// 薬草の回復量。
    static let herbPower: ClosedRange<Int> = 25...35
}

struct Hero: Codable, Equatable {
    var name = "ゆうしゃ"
    var level = 1
    var exp = 0
    var gold = 20
    var hp = LevelTable.row(1).maxHP
    var mp = LevelTable.row(1).maxMP
    var weapon: Item = .woodStick
    var armor: Item = .clothes
    var inventory: [Item: Int] = [.herb: 2]

    var base: LevelRow { LevelTable.row(level) }
    var maxHP: Int { base.maxHP }
    var maxMP: Int { base.maxMP }
    var agility: Int { base.agility }

    var attack: Int {
        if case .weapon(let power) = weapon.kind { return base.attack + power }
        return base.attack
    }

    var defense: Int {
        if case .armor(let power) = armor.kind { return base.defense + power }
        return base.defense
    }

    var spells: [Spell] { Spell.allCases.filter { $0.learnLevel <= level } }

    var isDead: Bool { hp <= 0 }

    var herbCount: Int { inventory[.herb, default: 0] }

    mutating func restoreFully() {
        hp = maxHP
        mp = maxMP
    }

    mutating func heal(_ amount: Int) -> Int {
        let before = hp
        hp = min(maxHP, hp + amount)
        return hp - before
    }

    /// 経験値を足し、上がったレベルと覚えた呪文のメッセージを返す。
    /// 上がった分の最大HP/MPは今のHP/MPにも足す（レベルアップで回復したように見せる）。
    mutating func gainExp(_ amount: Int) -> [String] {
        exp += amount
        var messages: [String] = []
        while level < LevelTable.maxLevel, exp >= LevelTable.row(level + 1).exp {
            let old = base
            level += 1
            hp += base.maxHP - old.maxHP
            mp += base.maxMP - old.maxMP
            messages.append("\(name)は レベル\(level)に あがった！")
            for spell in Spell.allCases where spell.learnLevel == level {
                messages.append("\(spell.name)を おぼえた！")
            }
        }
        return messages
    }

    /// 装備は買うとすぐ付け替える（前の装備は手放す）。消耗品は道具袋へ。
    mutating func receive(_ item: Item) {
        switch item.kind {
        case .consumable: inventory[item, default: 0] += 1
        case .weapon: weapon = item
        case .armor: armor = item
        }
    }

    /// 道具を1つ使う。使えなければ nil。
    mutating func consume(_ item: Item) -> Bool {
        guard item.kind == .consumable, inventory[item, default: 0] > 0 else { return false }
        inventory[item, default: 0] -= 1
        if inventory[item] == 0 { inventory[item] = nil }
        return true
    }
}
