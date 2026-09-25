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
    /// 函館山のボス。
    case squidLord
    /// 藻岩山のボス。
    case bearLord
    /// 羅臼岳のラスボス。
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

    /// すばやさ。フィールドの敵は 勇者よりはっきり遅くする。
    /// 敵は1〜3体で出るので、先を越されると3発まとめて食らう。
    /// そのエリアに入りたてのレベルで 先手率 85% 以上になる値にしてある
    /// （きたきつねだけは きつねなので フィールドで いちばん速い）。
    /// ほらあなの敵は 下げていない（奥ほど 手ごわく感じるように）。
    ///
    /// 敵は1〜3体で出てくる。3体に囲まれても勝ちきれるよう、
    /// 「そのエリアに入りたてのレベルなら ひと振りで倒せる」体力にしてある。
    /// 守備力は高いままなので、レベルが足りないと固い。
    var stats: Stats {
        switch self {
        case .potato: Stats(name: "ポテトー", maxHP: 4, attack: 6, defense: 2, agility: 2, exp: 2, gold: 3)
        case .kelpSlime: Stats(name: "こんぶスライム", maxHP: 3, attack: 7, defense: 4, agility: 1, exp: 3, gold: 4)
        case .scallop: Stats(name: "ホタテキッド", maxHP: 4, attack: 8, defense: 3, agility: 2, exp: 4, gold: 5)
        case .fox: Stats(name: "きたきつね", maxHP: 6, attack: 9, defense: 5, agility: 4, exp: 7, gold: 10)
        case .cod: Stats(name: "タラこぞう", maxHP: 13, attack: 12, defense: 8, agility: 3, exp: 11, gold: 16)
        case .snowman: Stats(name: "ゆきおとこ", maxHP: 14, attack: 22, defense: 18, agility: 9, exp: 22, gold: 30)
        case .iceGolem: Stats(name: "りゅうひょうゴーレム", maxHP: 20, attack: 28, defense: 30, agility: 3, exp: 35, gold: 45)
        case .squidLord: Stats(name: "イカのぬし", maxHP: 70, attack: 20, defense: 10, agility: 6, exp: 60, gold: 80)
        case .bearLord: Stats(name: "ヒグマのぬし", maxHP: 130, attack: 32, defense: 20, agility: 8, exp: 150, gold: 200)
        case .guardian: Stats(name: "知床の守護神", maxHP: 240, attack: 42, defense: 28, agility: 12, exp: 0, gold: 0)
        }
    }

    /// ボスは 話しかけて始まる戦闘。群れず、逃げられない。
    var isBoss: Bool {
        switch self {
        case .squidLord, .bearLord, .guardian: true
        default: false
        }
    }

    /// ボスの まもり（すみの まく など）の枚数。のこっているうちは こうげき・呪文の ダメージが 半分になり、
    /// 「ちしき」で1問 正解するたびに 1枚 やぶれる。奥のボスほど 多い。
    var veilLayers: Int {
        switch self {
        case .squidLord: 3
        case .bearLord: 4
        case .guardian: 5
        default: 0
        }
    }

    /// まもりの名前。メッセージに出す。
    var veilName: String {
        switch self {
        case .bearLord: "山の かご"
        case .guardian: "ふぶきの まく"
        default: "すみの まく"
        }
    }

    /// 最後の相手。倒すと物語が終わる。
    var isFinalBoss: Bool { self == .guardian }

    /// 守護神の ふぶき のダメージ（守備力を無視）。
    static let breathPower: ClosedRange<Int> = 14...20
}

/// 戦いに出ている1体。同じ種類が並ぶので A / B / C を付けて呼び分ける。
struct Enemy: Equatable, Identifiable {
    let id: Int
    let kind: EnemyKind
    var hp: Int
    /// 同じ種類が2体以上いるときの番号（0 なら付けない）。
    var suffix: Int

    init(_ kind: EnemyKind, id: Int = 0, suffix: Int = 0) {
        self.id = id
        self.kind = kind
        self.hp = kind.stats.maxHP
        self.suffix = suffix
    }

    var name: String {
        guard suffix > 0 else { return kind.stats.name }
        let letters = ["", "A", "B", "C", "D"]
        return kind.stats.name + (suffix < letters.count ? letters[suffix] : "\(suffix)")
    }

    var isDead: Bool { hp <= 0 }
}

/// 出てくる敵の組み方。
enum EnemyGroup {
    /// 一度に出る数。ボスは必ず1体。
    static let sizeRange = 1...3

    /// 同じ表から何体か選ぶ。同じ種類が重なったら A / B / C を振る。
    static func random(from table: [EnemyKind], rng: inout some RandomSource) -> [Enemy] {
        guard !table.isEmpty else { return [] }
        let count = rng.next(in: sizeRange)
        let kinds = (0..<count).map { _ in table[rng.next(in: 0...(table.count - 1))] }
        return numbered(kinds)
    }

    /// 同じ種類が2体以上あるものだけ番号を振る。
    static func numbered(_ kinds: [EnemyKind]) -> [Enemy] {
        var totals: [EnemyKind: Int] = [:]
        for kind in kinds { totals[kind, default: 0] += 1 }
        var seen: [EnemyKind: Int] = [:]
        return kinds.enumerated().map { index, kind in
            guard totals[kind, default: 0] > 1 else { return Enemy(kind, id: index) }
            seen[kind, default: 0] += 1
            return Enemy(kind, id: index, suffix: seen[kind] ?? 0)
        }
    }

    /// 「ポテトーが 2ひき あらわれた！」の形にまとめる。
    static func encounterText(_ enemies: [Enemy]) -> String {
        var order: [EnemyKind] = []
        var totals: [EnemyKind: Int] = [:]
        for enemy in enemies {
            if totals[enemy.kind] == nil { order.append(enemy.kind) }
            totals[enemy.kind, default: 0] += 1
        }
        let parts = order.map { kind -> String in
            let count = totals[kind] ?? 0
            return count > 1 ? "\(kind.stats.name) \(count)ひき" : kind.stats.name
        }
        return parts.joined(separator: "と") + "が あらわれた！"
    }
}
