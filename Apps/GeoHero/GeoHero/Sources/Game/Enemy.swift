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
    // 中標津のまわり
    case deer
    case cod
    case salmon
    // ウトロへむかう道
    case seaEagle
    case snowman
    case orca
    // 知床岬の ほらあな
    case hikarigoke
    case icicleOgre
    case iceBat
    // 羅臼岳の ほらあな（B1・B2）
    case phantomWolf
    case iceGolem
    case blizzardSpirit
    /// 函館山のボス。
    case squidLord
    /// 駒ヶ岳のボス。倒すと 札幌ゆきの きっぷが もらえる。
    case komaLord
    /// 天狗山のボス。小樽の オルゴールを うばった。
    case tengu
    /// 知床岬の ほらあなの ボス。コタンコロカムイの はねを うばった。
    case todoLord
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
    /// - 着いたころなら 2回ほど なぐって倒せる（ひと振りでは まず倒れない）。
    ///   3体に囲まれると HP が2〜3割まで へる（回復しながら 進む 手ごたえ）。
    ///   ひと振りで 倒せて 楽すぎる、と いわれたので 体力を 2発ぶんに 上げた（2026-09-29）。
    /// - 2レベル足りないと 3体には まず勝てない（1体なら勝てる）。
    ///   札幌の敵を LV2 で楽に倒せてしまったので、体力と守備力を 着くころのレベルに合わせた。
    /// - 函館エリアに 松前・大沼・駒ヶ岳の3か所を足したとき、札幌から先の敵は 3か所ぶん うしろへ ずらし、
    ///   前に その順番に いた敵の 強さを 引きついだ（着くころのレベルが 3つ上がるため）。
    ///   いちばん奥の 羅臼岳の3か所だけ 新しく決めた。
    var stats: Stats {
        switch self {
        case .potato: Stats(name: "ポテトー", maxHP: 7, attack: 5, defense: 2, agility: 2, exp: 2, gold: 3)
        case .kelpSlime: Stats(name: "こんぶスライム", maxHP: 6, attack: 6, defense: 4, agility: 1, exp: 3, gold: 4)
        case .seagull: Stats(name: "うみねこ", maxHP: 7, attack: 5, defense: 2, agility: 2, exp: 2, gold: 3)
        case .squidKid: Stats(name: "イカのこぶん", maxHP: 11, attack: 6, defense: 3, agility: 2, exp: 3, gold: 4)
        case .scallop: Stats(name: "ホタテキッド", maxHP: 11, attack: 7, defense: 3, agility: 2, exp: 4, gold: 5)
        case .squidRice: Stats(name: "いかめしくん", maxHP: 10, attack: 6, defense: 4, agility: 1, exp: 4, gold: 5)
        case .nightBat: Stats(name: "やけいコウモリ", maxHP: 14, attack: 8, defense: 3, agility: 3, exp: 4, gold: 5)
        case .hairyCrab: Stats(name: "けがにへい", maxHP: 13, attack: 8, defense: 5, agility: 1, exp: 5, gold: 7)
        case .brickGolem: Stats(name: "あかレンガゴーレム", maxHP: 12, attack: 8, defense: 6, agility: 1, exp: 5, gold: 7)
        case .sakuraSpirit: Stats(name: "さくらのせい", maxHP: 24, attack: 11, defense: 8, agility: 2, exp: 5, gold: 7)
        case .matsumaeZuke: Stats(name: "まつまえづけ", maxHP: 23, attack: 12, defense: 10, agility: 2, exp: 4, gold: 6)
        case .kitamaeShip: Stats(name: "きたまえぶね", maxHP: 23, attack: 11, defense: 10, agility: 2, exp: 5, gold: 7)
        case .apple: Stats(name: "ななえりんご", maxHP: 27, attack: 13, defense: 9, agility: 4, exp: 5, gold: 8)
        case .dango: Stats(name: "くしだんご", maxHP: 24, attack: 13, defense: 13, agility: 3, exp: 6, gold: 9)
        case .junsai: Stats(name: "じゅんさいスライム", maxHP: 25, attack: 13, defense: 11, agility: 3, exp: 7, gold: 10)
        case .lavaSlime: Stats(name: "ようがんスライム", maxHP: 29, attack: 15, defense: 12, agility: 2, exp: 7, gold: 10)
        case .pumiceGolem: Stats(name: "かるいしゴーレム", maxHP: 27, attack: 14, defense: 14, agility: 1, exp: 7, gold: 10)
        case .sulfurSmoke: Stats(name: "いおうけむり", maxHP: 31, attack: 15, defense: 10, agility: 5, exp: 6, gold: 9)
        case .cornSoldier: Stats(name: "とうきびへい", maxHP: 38, attack: 18, defense: 15, agility: 3, exp: 9, gold: 10)
        case .ramenGhost: Stats(name: "ラーメンおばけ", maxHP: 38, attack: 19, defense: 14, agility: 4, exp: 10, gold: 10)
        case .lambSheep: Stats(name: "ジンギスひつじ", maxHP: 36, attack: 18, defense: 16, agility: 4, exp: 11, gold: 12)
        case .squirrel: Stats(name: "エゾリス", maxHP: 36, attack: 18, defense: 16, agility: 4, exp: 11, gold: 11)
        case .fox: Stats(name: "きたきつね", maxHP: 38, attack: 18, defense: 14, agility: 6, exp: 12, gold: 10)
        case .snowFestival: Stats(name: "ゆきまつりぞう", maxHP: 36, attack: 18, defense: 17, agility: 3, exp: 13, gold: 13)
        case .flyingSquirrel: Stats(name: "エゾモモンガ", maxHP: 42, attack: 20, defense: 14, agility: 7, exp: 13, gold: 14)
        case .maitake: Stats(name: "まいたけおばけ", maxHP: 39, attack: 18, defense: 19, agility: 9, exp: 22, gold: 24)
        case .salamander: Stats(name: "サンショウウオ", maxHP: 40, attack: 20, defense: 17, agility: 6, exp: 17, gold: 19)
        case .bearCub: Stats(name: "ヒグマのこ", maxHP: 51, attack: 24, defense: 25, agility: 6, exp: 24, gold: 26)
        case .fishOwl: Stats(name: "シマフクロウ", maxHP: 55, attack: 25, defense: 20, agility: 7, exp: 19, gold: 21)
        case .woodpecker: Stats(name: "クマゲラ", maxHP: 53, attack: 25, defense: 22, agility: 2, exp: 15, gold: 16)
        case .deer: Stats(name: "エゾシカ", maxHP: 57, attack: 26, defense: 24, agility: 8, exp: 28, gold: 30)
        case .cod: Stats(name: "タラこぞう", maxHP: 49, attack: 25, defense: 34, agility: 3, exp: 35, gold: 36)
        case .salmon: Stats(name: "のぼりシャケ", maxHP: 55, attack: 26, defense: 26, agility: 6, exp: 31, gold: 34)
        case .seaEagle: Stats(name: "オオワシ", maxHP: 57, attack: 27, defense: 30, agility: 9, exp: 36, gold: 38)
        case .snowman: Stats(name: "ゆきおとこ", maxHP: 49, attack: 26, defense: 40, agility: 3, exp: 44, gold: 45)
        case .orca: Stats(name: "シャチまる", maxHP: 55, attack: 27, defense: 32, agility: 7, exp: 40, gold: 42)
        case .hikarigoke: Stats(name: "ひかりゴケ", maxHP: 57, attack: 28, defense: 36, agility: 2, exp: 46, gold: 48)
        case .icicleOgre: Stats(name: "つららおに", maxHP: 49, attack: 29, defense: 46, agility: 6, exp: 55, gold: 56)
        case .iceBat: Stats(name: "こおりコウモリ", maxHP: 55, attack: 28, defense: 38, agility: 9, exp: 50, gold: 51)
        case .phantomWolf: Stats(name: "まぼろしオオカミ", maxHP: 53, attack: 30, defense: 46, agility: 11, exp: 60, gold: 64)
        case .iceGolem: Stats(name: "りゅうひょうゴーレム", maxHP: 50, attack: 30, defense: 50, agility: 4, exp: 70, gold: 72)
        case .blizzardSpirit: Stats(name: "ふぶきのせいれい", maxHP: 51, attack: 29, defense: 48, agility: 10, exp: 65, gold: 68)
        case .squidLord: Stats(name: "イカのぬし", maxHP: 166, attack: 20, defense: 10, agility: 6, exp: 35, gold: 80)
        case .komaLord: Stats(name: "駒ヶ岳のぬし", maxHP: 315, attack: 28, defense: 16, agility: 7, exp: 200, gold: 150)
        case .tengu: Stats(name: "天狗", maxHP: 446, attack: 36, defense: 20, agility: 9, exp: 180, gold: 150)
        case .todoLord: Stats(name: "トドのぬし", maxHP: 798, attack: 48, defense: 32, agility: 11, exp: 200, gold: 240)
        case .bearLord: Stats(name: "ヒグマのぬし", maxHP: 600, attack: 37, defense: 26, agility: 10, exp: 150, gold: 180)
        case .guardian: Stats(name: "知床の守護神", maxHP: 1007, attack: 50, defense: 36, agility: 13, exp: 0, gold: 0)
        }
    }

    /// ボスは 話しかけて始まる戦闘。群れず、逃げられない。
    var isBoss: Bool {
        switch self {
        case .squidLord, .komaLord, .tengu, .bearLord, .todoLord, .guardian: true
        default: false
        }
    }

    /// 最後の相手。倒すと物語が終わる。
    var isFinalBoss: Bool { self == .guardian }

    /// こうげき の ほかに 使う わざ。その土地の 題材に ちなむ。
    /// 空なら こうげき だけ。
    var specialMoves: [EnemyMove] {
        switch self {
        case .potato: [.boost(.defense, "かわを あつくした")]
        case .kelpSlime: [.heal("だしを すった")]
        case .seagull: [.magic("はねを とばした")]
        case .squidKid: [.magic("すみを はいた")]
        case .scallop: [.boost(.defense, "からを とじた")]
        case .squidRice: [.heal("ごはんを つめた")]
        case .nightBat: [.magic("ちょうおんぱを はなった")]
        case .hairyCrab: [.boost(.attack, "はさみを といだ")]
        case .brickGolem: [.boost(.defense, "レンガを つんだ")]
        case .sakuraSpirit: [.magic("はなふぶきを よんだ"), .heal("ヒールを となえた")]
        case .matsumaeZuke: [.boost(.attack, "ねばりけを ました")]
        case .kitamaeShip: [.magic("たいほうを うった")]
        case .apple: [.heal("みつを なめた")]
        case .dango: [.boost(.defense, "くしを さした")]
        case .junsai: [.magic("ぬめりを とばした"), .heal("ヒールを となえた")]
        case .lavaSlime: [.magic("ファイアを となえた")]
        case .pumiceGolem: [.boost(.defense, "みを かためた"), .smash]
        case .sulfurSmoke: [.magic("どくけむりを はいた")]
        case .cornSoldier: [.boost(.attack, "ひげを ふった")]
        case .ramenGhost: [.magic("スープを かけた")]
        case .lambSheep: [.smash]
        case .squirrel: [.heal("きのみを かじった")]
        case .fox: [.magic("きつねびを はなった")]
        case .snowFestival: [.magic("ゆきだまを なげた"), .boost(.defense, "ゆきを かためた")]
        case .flyingSquirrel: [.magic("かぜを おこした")]
        case .maitake: [.magic("ほうしを まいた"), .heal("ヒールを となえた")]
        case .salamander: [.heal("きずを なおした")]
        case .bearCub: [.smash, .boost(.attack, "ほえた")]
        case .fishOwl: [.magic("かぜを おこした")]
        case .woodpecker: [.smash]
        case .deer: [.smash]
        case .cod: [.boost(.defense, "うろこを かためた")]
        case .salmon: [.heal("げんきを だした"), .smash]
        case .seaEagle: [.smash, .magic("かぜを おこした")]
        case .snowman: [.magic("ふぶきを はいた"), .boost(.attack, "むねを たたいた")]
        case .orca: [.smash, .magic("しおを ふきかけた")]
        case .hikarigoke: [.magic("ひかりを はなった"), .heal("ヒールを となえた")]
        case .icicleOgre: [.magic("つららを ふらせた"), .boost(.attack, "ぼうを ふりあげた")]
        case .iceBat: [.magic("こおりの いきを はいた")]
        case .phantomWolf: [.smash, .boost(.agility, "かすみに きえた")]
        case .iceGolem: [.boost(.defense, "こおりを まとった"), .smash]
        case .blizzardSpirit: [.magic("ふぶきを おこした"), .heal("ヒールを となえた")]
        case .squidLord:
            [.magic("すみを はいた"), .boost(.defense, "みを かためた"), .boost(.attack, "あしを ふった")]
        case .komaLord:
            [.magic("ふんかを おこした"), .boost(.attack, "マグマを ためた"), .smash]
        case .tengu:
            [.magic("かまいたちを よんだ"), .boost(.agility, "かぜを まとった"),
             .boost(.defense, "はねで みを つつんだ"), .heal("ヒールを となえた")]
        case .bearLord:
            [.smash, .boost(.attack, "ちからを ためた"), .boost(.agility, "かけだした"),
             .heal("はちみつを なめた")]
        case .todoLord:
            [.magic("こおりの いきを はいた"), .boost(.defense, "みを まるめた"),
             .boost(.attack, "きばを むいた"), .smash, .heal("ヒールを となえた")]
        case .guardian:
            [.magic("ふぶきを おこした"), .smash, .boost(.attack, "ちからを ためた"),
             .boost(.defense, "こおりを まとった"), .boost(.agility, "かぜを まとった"),
             .heal("ハイヒールを となえた")]
        }
    }

    /// こうげき の かわりに わざを 使う 割合（分母）。ボスは 半分、ほかは 3回に1回。
    var specialChance: Int { isBoss ? 2 : 3 }
}

/// 強さを 上げる わざで あがる 能力。
enum EnemyBoost: Equatable, Hashable, CaseIterable {
    case attack, defense, agility

    var label: String {
        switch self {
        case .attack: "こうげき"
        case .defense: "しゅび"
        case .agility: "すばやさ"
        }
    }

    /// 何段まで 重ねられるか。
    static let maxStage = 2
}

/// 敵が こうげき の かわりに 使う わざ。文は「〇〇は 〜！」の 〜 の部分。
enum EnemyMove: Equatable {
    /// 守備力を 無視して 当てる 呪文・息。
    case magic(String)
    /// 自分か 仲間の いちばん 弱っている者を 回復する。
    case heal(String)
    /// 自分の 能力を 1段 上げる。
    case boost(EnemyBoost, String)
    /// つうこんの いちげき。ふつうの こうげきの 1.5倍。
    case smash
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

    /// 戦いの あいだに 上げた 能力の段（0〜`EnemyBoost.maxStage`）。
    var boosts: [EnemyBoost: Int] = [:]
    /// もう 回復の わざを 使ったか。ボス でない敵は 1戦に 1回だけ（何度も 治されると 終わらない）。
    var hasHealed = false

    func stage(_ boost: EnemyBoost) -> Int { boosts[boost, default: 0] }

    /// 段ごとに こうげきは 1/4、しゅびは 1/2、すばやさは 1/2 ずつ 上がる。
    var attack: Int { kind.stats.attack * (4 + stage(.attack)) / 4 }
    var defense: Int { kind.stats.defense * (2 + stage(.defense)) / 2 }
    var agility: Int { kind.stats.agility * (2 + stage(.agility)) / 2 }
    var maxHP: Int { kind.stats.maxHP }

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
