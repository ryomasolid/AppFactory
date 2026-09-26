import Foundation

/// 北海道に出る敵。能力値の階段はそのままに、題材だけ日本のものにしてある。
/// 場所ごとに その土地の題材を2種ずつ出す（`Maps.swift` の遭遇表）。旅の順に並べてある。
enum EnemyKind: String, Codable, CaseIterable {
    // ── 函館エリア ──
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
    // 松前へむかう道
    case sakuraSpirit
    case matsumaeZuke
    case kitamaeShip
    // 大沼のまわり
    case apple
    case dango
    case junsai
    // 駒ヶ岳の ほらあな
    case lavaSlime
    case pumiceGolem
    case sulfurSmoke
    // ── 札幌・小樽 ──
    // 札幌のまわり
    case cornSoldier
    case ramenGhost
    case lambSheep
    // 小樽へむかう道
    case squirrel
    case fox
    case snowFestival
    // 天狗山の ほらあな
    case flyingSquirrel
    case maitake
    case salamander
    // 藻岩山の ほらあな（B1・B2）
    case bearCub
    case fishOwl
    case woodpecker
    // ── 知床 ──
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
    /// 駒ヶ岳のボス。倒すと 札幌ゆきの きっぷが もらえる。
    case komaLord
    /// 天狗山のボス。小樽の オルゴールを うばった。
    case tengu
    /// 藻岩山のボス。倒すと 知床ゆきの きっぷが もらえる。
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
    /// 敵は1〜3体で出てくる。強さは「そのエリアに着くころのレベル・装備」に合わせてある
    /// （`EncounterTests.everyPlaceIsBeatableOnArrival` の表）。
    /// - 着いたころなら ほぼひと振りで倒せて、3体に囲まれても HP が4〜6割のこる。
    /// - 2レベル足りないと 3体には まず勝てない（1体なら勝てる）。
    ///   札幌の敵を LV2 で楽に倒せてしまったので、体力と守備力を 着くころのレベルに合わせた。
    /// - 函館エリアに 松前・大沼・駒ヶ岳の3か所を足したとき、札幌から先の敵は 3か所ぶん うしろへ ずらし、
    ///   前に その順番に いた敵の 強さを 引きついだ（着くころのレベルが 3つ上がるため）。
    ///   いちばん奥の 羅臼岳の3か所だけ 新しく決めた。
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
        case .sakuraSpirit: Stats(name: "さくらのせい", maxHP: 13, attack: 12, defense: 8, agility: 2, exp: 5, gold: 7)
        case .matsumaeZuke: Stats(name: "まつまえづけ", maxHP: 13, attack: 12, defense: 10, agility: 2, exp: 4, gold: 6)
        case .kitamaeShip: Stats(name: "きたまえぶね", maxHP: 14, attack: 11, defense: 10, agility: 2, exp: 5, gold: 7)
        case .apple: Stats(name: "ななえりんご", maxHP: 14, attack: 14, defense: 9, agility: 4, exp: 5, gold: 8)
        case .dango: Stats(name: "くしだんご", maxHP: 15, attack: 13, defense: 13, agility: 3, exp: 6, gold: 9)
        case .junsai: Stats(name: "じゅんさいスライム", maxHP: 14, attack: 14, defense: 11, agility: 3, exp: 7, gold: 10)
        case .lavaSlime: Stats(name: "ようがんスライム", maxHP: 16, attack: 16, defense: 12, agility: 2, exp: 7, gold: 10)
        case .pumiceGolem: Stats(name: "かるいしゴーレム", maxHP: 17, attack: 15, defense: 14, agility: 1, exp: 7, gold: 10)
        case .sulfurSmoke: Stats(name: "いおうけむり", maxHP: 16, attack: 16, defense: 10, agility: 5, exp: 6, gold: 9)
        case .cornSoldier: Stats(name: "とうきびへい", maxHP: 18, attack: 17, defense: 14, agility: 3, exp: 8, gold: 12)
        case .ramenGhost: Stats(name: "ラーメンおばけ", maxHP: 19, attack: 17, defense: 13, agility: 4, exp: 9, gold: 13)
        case .lambSheep: Stats(name: "ジンギスひつじ", maxHP: 20, attack: 17, defense: 14, agility: 4, exp: 11, gold: 15)
        case .squirrel: Stats(name: "エゾリス", maxHP: 20, attack: 19, defense: 16, agility: 4, exp: 10, gold: 14)
        case .fox: Stats(name: "きたきつね", maxHP: 21, attack: 19, defense: 14, agility: 6, exp: 9, gold: 13)
        case .snowFestival: Stats(name: "ゆきまつりぞう", maxHP: 22, attack: 18, defense: 17, agility: 3, exp: 11, gold: 16)
        case .flyingSquirrel: Stats(name: "エゾモモンガ", maxHP: 22, attack: 21, defense: 14, agility: 7, exp: 13, gold: 18)
        case .maitake: Stats(name: "まいたけおばけ", maxHP: 24, attack: 21, defense: 19, agility: 9, exp: 22, gold: 30)
        case .salamander: Stats(name: "サンショウウオ", maxHP: 22, attack: 21, defense: 17, agility: 6, exp: 17, gold: 24)
        case .bearCub: Stats(name: "ヒグマのこ", maxHP: 31, attack: 25, defense: 25, agility: 6, exp: 24, gold: 32)
        case .fishOwl: Stats(name: "シマフクロウ", maxHP: 30, attack: 26, defense: 20, agility: 7, exp: 19, gold: 26)
        case .woodpecker: Stats(name: "クマゲラ", maxHP: 30, attack: 26, defense: 22, agility: 2, exp: 15, gold: 20)
        case .deer: Stats(name: "エゾシカ", maxHP: 32, attack: 27, defense: 24, agility: 8, exp: 28, gold: 38)
        case .cod: Stats(name: "タラこぞう", maxHP: 32, attack: 26, defense: 34, agility: 3, exp: 35, gold: 45)
        case .salmon: Stats(name: "のぼりシャケ", maxHP: 34, attack: 27, defense: 26, agility: 6, exp: 31, gold: 42)
        case .seaEagle: Stats(name: "オオワシ", maxHP: 35, attack: 30, defense: 30, agility: 9, exp: 36, gold: 48)
        case .snowman: Stats(name: "ゆきおとこ", maxHP: 35, attack: 29, defense: 40, agility: 3, exp: 44, gold: 56)
        case .orca: Stats(name: "シャチまる", maxHP: 37, attack: 30, defense: 32, agility: 7, exp: 40, gold: 52)
        case .hikarigoke: Stats(name: "ひかりゴケ", maxHP: 32, attack: 31, defense: 36, agility: 2, exp: 46, gold: 60)
        case .icicleOgre: Stats(name: "つららおに", maxHP: 29, attack: 32, defense: 46, agility: 6, exp: 55, gold: 70)
        case .iceBat: Stats(name: "こおりコウモリ", maxHP: 34, attack: 31, defense: 38, agility: 9, exp: 50, gold: 64)
        case .phantomWolf: Stats(name: "まぼろしオオカミ", maxHP: 29, attack: 34, defense: 46, agility: 11, exp: 60, gold: 80)
        case .iceGolem: Stats(name: "りゅうひょうゴーレム", maxHP: 30, attack: 34, defense: 50, agility: 4, exp: 70, gold: 90)
        case .blizzardSpirit: Stats(name: "ふぶきのせいれい", maxHP: 30, attack: 35, defense: 48, agility: 10, exp: 65, gold: 85)
        case .squidLord: Stats(name: "イカのぬし", maxHP: 70, attack: 20, defense: 10, agility: 6, exp: 60, gold: 80)
        case .komaLord: Stats(name: "駒ヶ岳のぬし", maxHP: 110, attack: 28, defense: 16, agility: 7, exp: 100, gold: 150)
        case .tengu: Stats(name: "天狗", maxHP: 170, attack: 36, defense: 20, agility: 9, exp: 180, gold: 250)
        case .bearLord: Stats(name: "ヒグマのぬし", maxHP: 260, attack: 45, defense: 26, agility: 10, exp: 250, gold: 300)
        case .guardian: Stats(name: "知床の守護神", maxHP: 380, attack: 56, defense: 36, agility: 13, exp: 0, gold: 0)
        }
    }

    /// ボスは 話しかけて始まる戦闘。群れず、逃げられない。
    var isBoss: Bool {
        switch self {
        case .squidLord, .komaLord, .tengu, .bearLord, .guardian: true
        default: false
        }
    }

    /// ボスの まもり（すみの まく など）の枚数。のこっているうちは こうげき・呪文の ダメージが 半分になり、
    /// 「ちしき」で1問 正解するたびに 1枚 やぶれる。奥のボスほど 多い。
    var veilLayers: Int {
        switch self {
        case .squidLord: 3
        case .komaLord: 4
        case .tengu: 4
        case .bearLord: 5
        case .guardian: 6
        default: 0
        }
    }

    /// まもりの名前。メッセージに出す。
    var veilName: String {
        switch self {
        case .komaLord: "ほのおの たてがみ"
        case .tengu: "天狗の かくれみの"
        case .bearLord: "山の かご"
        case .guardian: "ふぶきの まく"
        default: "すみの まく"
        }
    }

    /// 最後の相手。倒すと物語が終わる。
    var isFinalBoss: Bool { self == .guardian }

    /// 守護神の ふぶき のダメージ（守備力を無視）。
    static let breathPower: ClosedRange<Int> = 18...26
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
