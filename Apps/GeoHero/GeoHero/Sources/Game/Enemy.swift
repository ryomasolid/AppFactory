import Foundation

/// 北海道に出る敵。能力値の階段はそのままに、題材だけ日本のものにしてある。
/// 場所ごとに その土地の題材を2種ずつ出す（`Maps.swift` の遭遇表）。旅の順に並べてある。
enum EnemyKind: String, Codable, CaseIterable {
    // 函館のまわり
    case potato
    case kelpSlime
    case seagull
    // 函館山のふもと
    case squidKid
    case scallop
    case squidRice
    // 函館山の ほらあな
    case nightBat
    case hairyCrab
    case brickGolem
    // 札幌へむかう道
    case cornSoldier
    case ramenGhost
    case lambSheep
    // 藻岩山へむかう道
    case squirrel
    case fox
    case snowFestival
    // 藻岩山の ほらあな B1
    case flyingSquirrel
    case maitake
    case salamander
    // 藻岩山の ほらあな B2
    case bearCub
    case fishOwl
    case woodpecker
    // 知床へむかう道
    case deer
    case cod
    case salmon
    // 羅臼岳へむかう道
    case seaEagle
    case snowman
    case orca
    // 羅臼岳の ほらあな B1
    case hikarigoke
    case icicleOgre
    case iceBat
    // 羅臼岳の ほらあな B2
    case phantomWolf
    case iceGolem
    case blizzardSpirit
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
        case .seagull: Stats(name: "うみねこ", maxHP: 3, attack: 6, defense: 2, agility: 2, exp: 2, gold: 3)
        case .squidKid: Stats(name: "イカのこぶん", maxHP: 4, attack: 7, defense: 3, agility: 2, exp: 3, gold: 4)
        case .scallop: Stats(name: "ホタテキッド", maxHP: 4, attack: 8, defense: 3, agility: 2, exp: 4, gold: 5)
        case .squidRice: Stats(name: "いかめしくん", maxHP: 4, attack: 7, defense: 4, agility: 1, exp: 4, gold: 5)
        case .nightBat: Stats(name: "やけいコウモリ", maxHP: 4, attack: 8, defense: 3, agility: 3, exp: 4, gold: 5)
        case .hairyCrab: Stats(name: "けがにへい", maxHP: 5, attack: 8, defense: 5, agility: 1, exp: 5, gold: 7)
        case .brickGolem: Stats(name: "あかレンガゴーレム", maxHP: 5, attack: 8, defense: 6, agility: 1, exp: 5, gold: 7)
        case .cornSoldier: Stats(name: "とうきびへい", maxHP: 5, attack: 8, defense: 4, agility: 2, exp: 4, gold: 6)
        case .ramenGhost: Stats(name: "ラーメンおばけ", maxHP: 5, attack: 9, defense: 4, agility: 2, exp: 5, gold: 7)
        case .lambSheep: Stats(name: "ジンギスひつじ", maxHP: 5, attack: 9, defense: 4, agility: 2, exp: 5, gold: 7)
        case .squirrel: Stats(name: "エゾリス", maxHP: 5, attack: 8, defense: 4, agility: 4, exp: 5, gold: 8)
        case .fox: Stats(name: "きたきつね", maxHP: 6, attack: 9, defense: 5, agility: 4, exp: 7, gold: 10)
        case .snowFestival: Stats(name: "ゆきまつりぞう", maxHP: 6, attack: 9, defense: 5, agility: 3, exp: 6, gold: 9)
        case .flyingSquirrel: Stats(name: "エゾモモンガ", maxHP: 6, attack: 9, defense: 5, agility: 5, exp: 6, gold: 9)
        case .maitake: Stats(name: "まいたけおばけ", maxHP: 7, attack: 10, defense: 6, agility: 1, exp: 7, gold: 10)
        case .salamander: Stats(name: "サンショウウオ", maxHP: 7, attack: 10, defense: 6, agility: 2, exp: 7, gold: 10)
        case .bearCub: Stats(name: "ヒグマのこ", maxHP: 9, attack: 11, defense: 7, agility: 3, exp: 8, gold: 12)
        case .fishOwl: Stats(name: "シマフクロウ", maxHP: 12, attack: 12, defense: 8, agility: 6, exp: 11, gold: 15)
        case .woodpecker: Stats(name: "クマゲラ", maxHP: 10, attack: 11, defense: 7, agility: 5, exp: 9, gold: 13)
        case .deer: Stats(name: "エゾシカ", maxHP: 11, attack: 11, defense: 7, agility: 5, exp: 9, gold: 13)
        case .cod: Stats(name: "タラこぞう", maxHP: 13, attack: 12, defense: 8, agility: 3, exp: 11, gold: 16)
        case .salmon: Stats(name: "のぼりシャケ", maxHP: 12, attack: 12, defense: 7, agility: 3, exp: 10, gold: 14)
        case .seaEagle: Stats(name: "オオワシ", maxHP: 13, attack: 16, defense: 11, agility: 7, exp: 13, gold: 18)
        case .snowman: Stats(name: "ゆきおとこ", maxHP: 14, attack: 22, defense: 18, agility: 9, exp: 22, gold: 30)
        case .orca: Stats(name: "シャチまる", maxHP: 15, attack: 19, defense: 14, agility: 6, exp: 17, gold: 24)
        case .hikarigoke: Stats(name: "ひかりゴケ", maxHP: 14, attack: 18, defense: 14, agility: 2, exp: 15, gold: 20)
        case .icicleOgre: Stats(name: "つららおに", maxHP: 16, attack: 24, defense: 20, agility: 6, exp: 24, gold: 32)
        case .iceBat: Stats(name: "こおりコウモリ", maxHP: 15, attack: 21, defense: 16, agility: 7, exp: 19, gold: 26)
        case .phantomWolf: Stats(name: "まぼろしオオカミ", maxHP: 18, attack: 26, defense: 22, agility: 10, exp: 28, gold: 38)
        case .iceGolem: Stats(name: "りゅうひょうゴーレム", maxHP: 20, attack: 28, defense: 30, agility: 3, exp: 35, gold: 45)
        case .blizzardSpirit: Stats(name: "ふぶきのせいれい", maxHP: 19, attack: 27, defense: 26, agility: 8, exp: 31, gold: 42)
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
