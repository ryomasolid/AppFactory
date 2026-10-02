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

/// 敵は1〜3体で出てくるので、袋叩きにされても3体は倒しきれる体力にしてある。
/// 東北は 6県 24か所と 旅が長いので、LV30 まで ある。
enum LevelTable {
    static let rows: [LevelRow] = [
        LevelRow(maxHP: 24, maxMP: 0, attack: 5, defense: 4, agility: 4, exp: 0),
        LevelRow(maxHP: 32, maxMP: 5, attack: 7, defense: 5, agility: 5, exp: 8),
        LevelRow(maxHP: 40, maxMP: 9, attack: 9, defense: 7, agility: 7, exp: 25),
        LevelRow(maxHP: 48, maxMP: 13, attack: 12, defense: 9, agility: 8, exp: 55),
        LevelRow(maxHP: 56, maxMP: 16, attack: 14, defense: 11, agility: 10, exp: 100),
        LevelRow(maxHP: 64, maxMP: 20, attack: 17, defense: 13, agility: 11, exp: 170),
        LevelRow(maxHP: 72, maxMP: 24, attack: 20, defense: 15, agility: 13, exp: 270),
        LevelRow(maxHP: 80, maxMP: 28, attack: 23, defense: 17, agility: 14, exp: 400),
        LevelRow(maxHP: 88, maxMP: 32, attack: 26, defense: 19, agility: 16, exp: 570),
        LevelRow(maxHP: 96, maxMP: 36, attack: 29, defense: 21, agility: 17, exp: 780),
        LevelRow(maxHP: 104, maxMP: 40, attack: 32, defense: 23, agility: 19, exp: 1050),
        LevelRow(maxHP: 112, maxMP: 45, attack: 35, defense: 25, agility: 20, exp: 1400),
        LevelRow(maxHP: 120, maxMP: 50, attack: 38, defense: 27, agility: 22, exp: 1800),
        LevelRow(maxHP: 128, maxMP: 55, attack: 41, defense: 29, agility: 23, exp: 2250),
        LevelRow(maxHP: 136, maxMP: 60, attack: 44, defense: 31, agility: 25, exp: 2750),
        LevelRow(maxHP: 144, maxMP: 65, attack: 47, defense: 33, agility: 26, exp: 3310),
        LevelRow(maxHP: 152, maxMP: 70, attack: 50, defense: 35, agility: 28, exp: 3940),
        LevelRow(maxHP: 160, maxMP: 75, attack: 53, defense: 37, agility: 29, exp: 4640),
        LevelRow(maxHP: 168, maxMP: 80, attack: 56, defense: 39, agility: 31, exp: 5420),
        LevelRow(maxHP: 176, maxMP: 85, attack: 59, defense: 41, agility: 32, exp: 6280),
        LevelRow(maxHP: 184, maxMP: 90, attack: 62, defense: 43, agility: 34, exp: 7230),
        LevelRow(maxHP: 192, maxMP: 95, attack: 65, defense: 45, agility: 35, exp: 8270),
        LevelRow(maxHP: 200, maxMP: 100, attack: 68, defense: 47, agility: 37, exp: 9410),
        LevelRow(maxHP: 208, maxMP: 105, attack: 71, defense: 49, agility: 38, exp: 10650),
        LevelRow(maxHP: 216, maxMP: 110, attack: 74, defense: 51, agility: 40, exp: 12000),
        LevelRow(maxHP: 224, maxMP: 115, attack: 77, defense: 53, agility: 41, exp: 13460),
        LevelRow(maxHP: 232, maxMP: 120, attack: 80, defense: 55, agility: 43, exp: 15040),
        LevelRow(maxHP: 240, maxMP: 125, attack: 83, defense: 57, agility: 44, exp: 16740),
        LevelRow(maxHP: 248, maxMP: 130, attack: 86, defense: 59, agility: 46, exp: 18570),
        LevelRow(maxHP: 256, maxMP: 135, attack: 89, defense: 61, agility: 47, exp: 20530),
    ]

    static var maxLevel: Int { rows.count }

    static func row(_ level: Int) -> LevelRow {
        rows[min(max(level, 1), maxLevel) - 1]
    }
}

enum Spell: String, Codable, CaseIterable, Identifiable {
    case heal
    case fire
    case escape
    case thunder
    case highHeal
    case flame
    case shield
    case bolt
    case fullHeal
    case inferno
    case storm

    /// 呪文の はたらき。
    enum Effect: Equatable {
        /// HP を なおす（`power` の はばで。fullHeal は ぜんぶ）。
        case heal
        /// 敵 1体に 守備力を 無視した ダメージ。
        case single
        /// 敵 みんなに 守備力を 無視した ダメージ。
        case all
        /// この たたかいの あいだ しゅびが 1.5倍。
        case defend
        /// ほらあなから 入口へ ぬけだす（フィールドだけ）。
        case escape
    }

    var id: String { rawValue }

    var name: String {
        switch self {
        case .heal: "ヒール"
        case .fire: "ファイア"
        case .escape: "だっしゅつ"
        case .thunder: "いなずま"
        case .highHeal: "ハイヒール"
        case .flame: "フレイム"
        case .shield: "ガード"
        case .bolt: "らいめい"
        case .fullHeal: "フルヒール"
        case .inferno: "ばくえん"
        case .storm: "だいらいめい"
        }
    }

    var effect: Effect {
        switch self {
        case .heal, .highHeal, .fullHeal: .heal
        case .fire, .flame, .inferno: .single
        case .thunder, .bolt, .storm: .all
        case .shield: .defend
        case .escape: .escape
        }
    }

    var mpCost: Int {
        switch self {
        case .heal: 3
        case .fire: 2
        case .escape: 4
        case .thunder: 5
        case .highHeal: 6
        case .flame: 6
        case .shield: 4
        case .bolt: 10
        case .fullHeal: 12
        case .inferno: 12
        case .storm: 18
        }
    }

    var learnLevel: Int {
        switch self {
        case .heal: 2
        case .fire: 4
        case .escape: 6
        case .thunder: 7
        case .highHeal: 9
        case .flame: 11
        case .shield: 13
        case .bolt: 16
        case .fullHeal: 19
        case .inferno: 22
        case .storm: 26
        }
    }

    /// 回復量または与えるダメージの幅。攻撃呪文は守備力を無視する。
    var power: ClosedRange<Int> {
        switch self {
        case .heal: 20...28
        case .fire: 12...16
        case .thunder: 15...22
        case .highHeal: 60...80
        case .flame: 40...50
        case .bolt: 40...55
        case .fullHeal: 9999...9999
        case .inferno: 90...110
        case .storm: 85...105
        case .escape, .shield: 0...0
        }
    }

    var isHealing: Bool { effect == .heal }
    /// 敵に ダメージを あたえる 呪文か。
    var isAttack: Bool { effect == .single || effect == .all }
    /// フィールドで となえられるか。
    var isFieldUsable: Bool { effect == .heal || effect == .escape }
    /// 戦いで となえられるか。
    var isBattleUsable: Bool { effect != .escape }

    /// 説明（じゅもんの 画面に 出す）。
    var note: String {
        switch effect {
        case .heal: self == .fullHeal ? "HPを ぜんぶ かいふく" : "HPを \(power.lowerBound)〜\(power.upperBound) かいふく"
        case .single: "敵1体に \(power.lowerBound)〜\(power.upperBound)"
        case .all: "敵みんなに \(power.lowerBound)〜\(power.upperBound)"
        case .defend: "たたかいの あいだ しゅびが あがる"
        case .escape: "ほらあなの いりぐちへ もどる"
        }
    }
}

/// 道具と装備。名前は 東北の その土地の 名産に ちなむ。
/// 内部の名前は セーブに 残るので 変えない。見せる名前だけ 変える。
/// 回復の道具・武器・よろいは 旅の順に 強く、高くなる。上等な品は 貯めないと 買えない。
enum Item: String, Codable, CaseIterable, Identifiable, CodingKeyRepresentable {
    // 回復の道具（旅の順）
    case apple
    case senbeiJiru
    case iburigakko
    case kiritanpo
    case nanbuSenbei
    case wankoSoba
    case zundaMochi
    case gyutan
    case momo
    case kitakataRamen
    case sakuranbo
    case imoni
    // 宝箱で 見つかる めずらしい 道具（店では 売っていない）
    case hanabi
    case shakudama
    case matagiBell
    case hinaiChicken
    case mishirazuGaki
    case dadachamame
    case yonezawaBeef
    case hitomebore
    // 武器
    case bunaStick
    case ringoBokuto
    case nebutaHoko
    case tsugaruKatana
    case namahageHocho
    case nanbuSword
    case konjikiTachi
    case dateKatana
    case byakkoKatana
    case mogamiNaginata
    case juhyoSword
    case matsuriSword
    // よろい
    case hanten
    case koginCoat
    case nebutaHappi
    case hirosakiArmor
    case akitaSugiArmor
    case nanbuArmor
    case fujiwaraArmor
    case dateArmor
    case aizuArmor
    case benibanaArmor
    case juhyoArmor
    case matsuriArmor
    // かざり（ひとつだけ 身につける）
    case kingyoNebuta
    case kabaInro
    case nanbuFurin
    case narukoKokeshi
    case akabeko
    case okiagari
    case tanzaku
    case oushou

    enum Kind: Equatable {
        case consumable
        case weapon(power: Int)
        case armor(power: Int)
        case charm(Charm)
    }

    /// かざりの ききめ。
    enum Charm: Equatable {
        /// 能力が ふえる。
        case boost(Growth, Int)
        /// 戦いで もらえる ゴールドが 1.5倍。
        case moreGold
        /// 戦いで 1回だけ たおれても おきあがる。
        case revive
        /// 「ちしきの チャンス」が 出やすい。
        case moreQuiz
    }

    /// 道具の ききめ。
    enum Effect: Equatable {
        case hp(ClosedRange<Int>)
        case mp(ClosedRange<Int>)
        /// 戦いで 敵みんなに ダメージ（守備力を 無視）。
        case blastAll(ClosedRange<Int>)
        /// 戦いから かならず にげる（ボスからは にげられない）。
        case escape
        /// 食べると 能力が ずっと 上がる。
        case grow(Growth, Int)
    }

    /// 名産を 食べて ずっと 上がる 能力（かざりでも 上がる）。
    enum Growth: String, Codable, Equatable, CodingKeyRepresentable {
        case attack, defense, agility, maxHP, maxMP

        var label: String {
            switch self {
            case .attack: "こうげき"
            case .defense: "しゅび"
            case .agility: "すばやさ"
            case .maxHP: "さいだいHP"
            case .maxMP: "さいだいMP"
            }
        }
    }

    var id: String { rawValue }

    var name: String {
        switch self {
        case .apple: "りんご"
        case .senbeiJiru: "せんべい汁"
        case .iburigakko: "いぶりがっこ"
        case .kiritanpo: "きりたんぽ"
        case .nanbuSenbei: "南部せんべい"
        case .wankoSoba: "わんこそば"
        case .zundaMochi: "ずんだもち"
        case .gyutan: "牛たん"
        case .momo: "福島の もも"
        case .kitakataRamen: "喜多方ラーメン"
        case .sakuranbo: "さくらんぼ"
        case .imoni: "芋煮"
        case .hanabi: "大曲の花火"
        case .shakudama: "大曲の尺玉"
        case .matagiBell: "マタギの鈴"
        case .hinaiChicken: "比内地鶏"
        case .mishirazuGaki: "身しらず柿"
        case .dadachamame: "だだちゃ豆"
        case .yonezawaBeef: "米沢牛"
        case .hitomebore: "ひとめぼれ"
        case .bunaStick: "ブナの棒"
        case .ringoBokuto: "りんごの木刀"
        case .nebutaHoko: "ねぶたの矛"
        case .tsugaruKatana: "津軽の刀"
        case .namahageHocho: "なまはげの包丁"
        case .nanbuSword: "南部鉄の剣"
        case .konjikiTachi: "金色堂の太刀"
        case .dateKatana: "伊達の刀"
        case .byakkoKatana: "白虎の刀"
        case .mogamiNaginata: "最上のなぎなた"
        case .juhyoSword: "樹氷の剣"
        case .matsuriSword: "まつりの剣"
        case .hanten: "木綿のはんてん"
        case .koginCoat: "こぎん刺しの服"
        case .nebutaHappi: "ねぶたのはっぴ"
        case .hirosakiArmor: "弘前藩士の鎧"
        case .akitaSugiArmor: "秋田杉の鎧"
        case .nanbuArmor: "南部鉄の鎧"
        case .fujiwaraArmor: "藤原氏の鎧"
        case .dateArmor: "伊達の具足"
        case .aizuArmor: "会津塗の鎧"
        case .benibanaArmor: "紅花の鎧"
        case .juhyoArmor: "樹氷の鎧"
        case .matsuriArmor: "まつりの鎧"
        case .kingyoNebuta: "金魚ねぶた"
        case .kabaInro: "樺細工の印籠"
        case .nanbuFurin: "南部鉄の風鈴"
        case .narukoKokeshi: "鳴子こけし"
        case .akabeko: "赤べこ"
        case .okiagari: "起き上がり小法師"
        case .tanzaku: "七夕の短冊"
        case .oushou: "天童の王将"
        }
    }

    var kind: Kind {
        switch self {
        case .apple, .senbeiJiru, .iburigakko, .kiritanpo, .nanbuSenbei, .wankoSoba, .zundaMochi, .gyutan,
             .momo, .kitakataRamen, .sakuranbo, .imoni,
             .hanabi, .shakudama, .matagiBell, .hinaiChicken, .mishirazuGaki, .dadachamame, .yonezawaBeef, .hitomebore:
            .consumable
        case .bunaStick: .weapon(power: 2)
        case .ringoBokuto: .weapon(power: 5)
        case .nebutaHoko: .weapon(power: 9)
        case .tsugaruKatana: .weapon(power: 13)
        case .namahageHocho: .weapon(power: 17)
        case .nanbuSword: .weapon(power: 21)
        case .konjikiTachi: .weapon(power: 26)
        case .dateKatana: .weapon(power: 31)
        case .byakkoKatana: .weapon(power: 36)
        case .mogamiNaginata: .weapon(power: 42)
        case .juhyoSword: .weapon(power: 48)
        case .matsuriSword: .weapon(power: 55)
        case .hanten: .armor(power: 2)
        case .koginCoat: .armor(power: 4)
        case .nebutaHappi: .armor(power: 7)
        case .hirosakiArmor: .armor(power: 10)
        case .akitaSugiArmor: .armor(power: 13)
        case .nanbuArmor: .armor(power: 16)
        case .fujiwaraArmor: .armor(power: 20)
        case .dateArmor: .armor(power: 24)
        case .aizuArmor: .armor(power: 28)
        case .benibanaArmor: .armor(power: 32)
        case .juhyoArmor: .armor(power: 37)
        case .matsuriArmor: .armor(power: 42)
        case .kingyoNebuta: .charm(.moreGold)
        case .kabaInro: .charm(.boost(.agility, 8))
        case .nanbuFurin: .charm(.boost(.defense, 6))
        case .narukoKokeshi: .charm(.boost(.maxMP, 15))
        case .akabeko: .charm(.boost(.maxHP, 30))
        case .okiagari: .charm(.revive)
        case .tanzaku: .charm(.moreQuiz)
        case .oushou: .charm(.boost(.attack, 6))
        }
    }

    /// 回復の道具の ききめ。装備なら nil。
    var effect: Effect? {
        switch self {
        case .apple: .hp(25...35)
        case .senbeiJiru: .hp(45...55)
        case .iburigakko: .mp(6...9)
        case .kiritanpo: .hp(80...100)
        case .nanbuSenbei: .mp(15...20)
        case .wankoSoba: .hp(130...160)
        case .zundaMochi: .mp(25...32)
        case .gyutan: .hp(190...230)
        case .momo: .mp(40...50)
        case .kitakataRamen: .hp(260...300)
        case .sakuranbo: .mp(60...75)
        case .imoni: .hp(9999...9999)
        case .hanabi: .blastAll(40...55)
        case .shakudama: .blastAll(120...150)
        case .matagiBell: .escape
        case .hinaiChicken: .grow(.attack, 2)
        case .mishirazuGaki: .grow(.defense, 2)
        case .dadachamame: .grow(.agility, 2)
        case .yonezawaBeef: .grow(.maxHP, 10)
        case .hitomebore: .grow(.maxMP, 5)
        default: nil
        }
    }

    var price: Int {
        switch self {
        case .apple: 8
        case .senbeiJiru: 18
        case .iburigakko: 25
        case .kiritanpo: 40
        case .nanbuSenbei: 55
        case .wankoSoba: 80
        case .zundaMochi: 85
        case .gyutan: 140
        case .momo: 130
        case .kitakataRamen: 190
        case .sakuranbo: 180
        case .imoni: 300
        case .hanabi: 80
        case .shakudama: 240
        case .matagiBell: 40
        case .hinaiChicken, .mishirazuGaki, .dadachamame, .yonezawaBeef, .hitomebore: 300
        case .bunaStick: 5
        case .ringoBokuto: 45
        case .nebutaHoko: 120
        case .tsugaruKatana: 260
        case .namahageHocho: 450
        case .nanbuSword: 700
        case .konjikiTachi: 1000
        case .dateKatana: 1400
        case .byakkoKatana: 1900
        case .mogamiNaginata: 2500
        case .juhyoSword: 3200
        case .matsuriSword: 5000
        case .hanten: 10
        case .koginCoat: 50
        case .nebutaHappi: 130
        case .hirosakiArmor: 280
        case .akitaSugiArmor: 480
        case .nanbuArmor: 720
        case .fujiwaraArmor: 1050
        case .dateArmor: 1450
        case .aizuArmor: 1950
        case .benibanaArmor: 2600
        case .juhyoArmor: 3300
        case .matsuriArmor: 5000
        case .kingyoNebuta, .kabaInro, .nanbuFurin, .narukoKokeshi, .akabeko, .okiagari, .tanzaku, .oushou: 800
        }
    }

    /// 装備の上がり幅（武器はこうげき、鎧はしゅび）。消耗品・かざりは0。
    var power: Int {
        switch kind {
        case .consumable, .charm: 0
        case .weapon(let power), .armor(let power): power
        }
    }

    var isCharm: Bool { if case .charm = kind { true } else { false } }
    /// 身につけるもの（武器・よろい・かざり）か。
    var isGear: Bool { kind != .consumable }

    /// 戦いの「どうぐ」で 使えるか（能力が 上がる 名産は フィールドで ゆっくり 食べる）。
    var isBattleUsable: Bool {
        switch effect {
        case .hp?, .mp?, .blastAll?, .escape?: true
        case .grow?, nil: false
        }
    }

    /// 店には 並べない めずらしい もの（宝箱・お礼・検定の ごほうび）。
    var isTreasure: Bool {
        switch self {
        case .hanabi, .shakudama, .matagiBell, .hinaiChicken, .mishirazuGaki, .dadachamame, .yonezawaBeef, .hitomebore,
             .juhyoSword, .matsuriSword, .juhyoArmor, .matsuriArmor: true
        default: isCharm
        }
    }

    /// りんご（いちばん 安い 回復の道具）の回復量。
    static var herbPower: ClosedRange<Int> {
        if case let .hp(range) = Item.apple.effect { return range }
        return 0...0
    }

    /// ききめの説明（道具屋・どうぐの画面に出す）。
    var effectNote: String {
        switch (kind, effect) {
        case let (_, .hp(range)?): range.lowerBound >= 9999 ? "つかうと HPが ぜんぶ かいふく" : "つかうと HPが \(range.lowerBound)〜\(range.upperBound) かいふく"
        case let (_, .mp(range)?): "つかうと MPが \(range.lowerBound)〜\(range.upperBound) かいふく"
        case let (_, .blastAll(range)?): "たたかいで 敵みんなに \(range.lowerBound)〜\(range.upperBound) の ダメージ"
        case (_, .escape?): "たたかいで かならず にげられる（ボスは むり）"
        case let (_, .grow(growth, amount)?): "たべると \(growth.label)が ずっと +\(amount)"
        case let (.weapon(power), _): "そうびすると こうげき +\(power)"
        case let (.armor(power), _): "そうびすると しゅび +\(power)"
        case let (.charm(charm), _):
            switch charm {
            case let .boost(growth, amount): "みにつけると \(growth.label) +\(amount)"
            case .moreGold: "たたかいの ゴールドが 1.5ばい"
            case .revive: "たたかいで 1かい たおれても おきあがる"
            case .moreQuiz: "ちしきの チャンスが でやすい"
            }
        default: ""
        }
    }
}

struct Hero: Codable, Equatable {
    /// 名前を決めずに始めたときの名前。
    static let defaultName = "そら"
    /// 名前の長さの上限。
    static let maxNameLength = 6

    var name = Hero.defaultName
    var level = 1
    var exp = 0
    var gold = 20
    var hp = LevelTable.row(1).maxHP
    var mp = LevelTable.row(1).maxMP
    /// そうび中のぶき。はずしていれば nil（素手）。
    var weapon: Item? = .bunaStick
    /// そうび中のよろい。はずしていれば nil。
    var armor: Item? = .hanten
    /// そうび中の かざり。
    var charm: Item?
    /// 持ちもの。買った・拾った装備も、はずしたあと売れるようにここに残る。
    var inventory: [Item: Int] = [.apple: 3, .bunaStick: 1, .hanten: 1]
    /// 名産を 食べて ずっと 上がった ぶん。
    var growth: [Item.Growth: Int] = [:]

    var base: LevelRow { LevelTable.row(level) }

    /// かざりで ふえる ぶん。
    private func charmBonus(_ growth: Item.Growth) -> Int {
        if case let .charm(.boost(kind, amount))? = charm?.kind, kind == growth { return amount }
        return 0
    }

    private func bonus(_ kind: Item.Growth) -> Int { growth[kind, default: 0] + charmBonus(kind) }

    var maxHP: Int { base.maxHP + bonus(.maxHP) }
    var maxMP: Int { base.maxMP + bonus(.maxMP) }
    var agility: Int { base.agility + bonus(.agility) }

    var attack: Int { base.attack + (weapon?.power ?? 0) + bonus(.attack) }
    var defense: Int { base.defense + (armor?.power ?? 0) + bonus(.defense) }

    /// いま 身につけている かざりの ききめ。
    var charmEffect: Item.Charm? {
        if case let .charm(effect)? = charm?.kind { return effect }
        return nil
    }

    /// そうび中のぶき・よろい・かざりの名前（はずしていれば「なし」）。
    var weaponName: String { weapon?.name ?? "なし" }
    var armorName: String { armor?.name ?? "なし" }
    var charmName: String { charm?.name ?? "なし" }

    /// 持っているもの。消耗品・ぶき・よろい・かざりの順に並べる。
    var belongings: [(item: Item, count: Int)] {
        return Item.allCases.compactMap { item in
            let count = inventory[item, default: 0]
            return count > 0 ? (item, count) : nil
        }
    }

    func owns(_ item: Item) -> Bool { inventory[item, default: 0] > 0 }
    func isEquipped(_ item: Item) -> Bool { weapon == item || armor == item || charm == item }

    var spells: [Spell] { Spell.allCases.filter { $0.learnLevel <= level } }

    var isDead: Bool { hp <= 0 }

    var herbCount: Int { inventory[.apple, default: 0] }

    /// 持っている 消耗品。
    var consumables: [(item: Item, count: Int)] { belongings.filter { $0.item.kind == .consumable } }
    /// 戦いの「どうぐ」に 並べるもの。
    var battleItems: [(item: Item, count: Int)] { consumables.filter { $0.item.isBattleUsable } }

    /// その道具を フィールドで いま使って 意味があるか（HPも MPも まんたんなら つかえない）。
    func canUse(_ item: Item) -> Bool {
        switch item.effect {
        case .hp?: hp < maxHP
        case .mp?: mp < maxMP
        case .grow?: true
        case .blastAll?, .escape?, nil: false
        }
    }

    /// 回復の道具の ききめを 受ける。なおった量を返す（HP・MP の 回復だけ）。
    mutating func apply(_ effect: Item.Effect, rng: inout some RandomSource) -> (amount: Int, isMP: Bool) {
        switch effect {
        case let .hp(range):
            return (heal(rng.next(in: range)), false)
        case let .mp(range):
            let before = mp
            mp = min(maxMP, mp + rng.next(in: range))
            return (mp - before, true)
        case let .grow(growth, amount):
            grow(growth, by: amount)
            return (amount, false)
        case .blastAll, .escape:
            return (0, false)
        }
    }

    /// 能力を ずっと 上げる。さいだいHP・MP なら その分 HP・MP も ふえる。
    mutating func grow(_ growth: Item.Growth, by amount: Int) {
        self.growth[growth, default: 0] += amount
        if growth == .maxHP { hp += amount }
        if growth == .maxMP { mp += amount }
    }

    mutating func restoreFully() {
        hp = maxHP
        mp = maxMP
    }

    mutating func heal(_ amount: Int) -> Int {
        let before = hp
        hp = min(maxHP, hp + amount)
        return hp - before
    }

    /// レベルが1つ上がったときの中身。画面はこれを見て並べる。
    struct LevelUp: Equatable, Hashable {
        let name: String
        let level: Int
        /// 伸びた能力値だけ。伸びなかったものは入れない。
        let gains: [Gain]
        /// このレベルで覚えた呪文。
        let learned: [Spell]

        struct Gain: Equatable, Hashable {
            let label: String
            let before: Int
            let after: Int
        }

        var headline: String { "\(name)は レベル\(level)に あがった！" }

        /// 画面を使わないところ（確認用の起動引数など）で出す文字列。
        var messages: [String] {
            [headline]
                + gains.map { "\($0.label) \($0.before)→\($0.after)" }
                + learned.map { "\($0.name)を おぼえた！" }
        }
    }

    /// レベルアップの前後で見せる能力値（つよさの画面と同じ、装備こみの値）。
    private struct StatLine: Equatable {
        let maxHP: Int, maxMP: Int, attack: Int, defense: Int, agility: Int

        init(_ hero: Hero) {
            maxHP = hero.maxHP; maxMP = hero.maxMP
            attack = hero.attack; defense = hero.defense; agility = hero.agility
        }
    }

    /// 経験値を足し、上がったレベルぶんの中身を返す。
    /// レベルが上がったら HP と MP は全快する（つぎの戦いに向かいやすくする）。
    mutating func gainExp(_ amount: Int) -> [LevelUp] {
        exp += amount
        var results: [LevelUp] = []
        while level < LevelTable.maxLevel, exp >= LevelTable.row(level + 1).exp {
            let before = StatLine(self)
            level += 1
            let after = StatLine(self)
            restoreFully()
            results.append(LevelUp(
                name: name,
                level: level,
                gains: Hero.gains(from: before, to: after),
                learned: Spell.allCases.filter { $0.learnLevel == level }
            ))
        }
        return results
    }

    /// 伸びた能力値だけを「もとの値 → あがった値」で並べる。
    private static func gains(from before: StatLine, to after: StatLine) -> [LevelUp.Gain] {
        let all = [
            ("さいだいHP", before.maxHP, after.maxHP),
            ("さいだいMP", before.maxMP, after.maxMP),
            ("こうげき", before.attack, after.attack),
            ("しゅび", before.defense, after.defense),
            ("すばやさ", before.agility, after.agility),
        ]
        return all.compactMap { label, old, new in
            new > old ? LevelUp.Gain(label: label, before: old, after: new) : nil
        }
    }

    /// 手に入れる。武器・よろいは持ちものに加えたうえで、そのまま身につける。
    /// かざりは 何も つけていなければ 身につける（つけかえは 自分で えらぶ）。
    mutating func receive(_ item: Item) {
        inventory[item, default: 0] += 1
        switch item.kind {
        case .consumable: break
        case .weapon: weapon = item
        case .armor: armor = item
        case .charm: if charm == nil { putOn(item) }
        }
    }

    /// 持っている装備を身につける。
    mutating func equip(_ item: Item) {
        guard owns(item) else { return }
        switch item.kind {
        case .consumable: break
        case .weapon: weapon = item
        case .armor: armor = item
        case .charm: putOn(item)
        }
    }

    /// かざりを つけかえる。HP・MP が 上限を こえないように そろえる。
    private mutating func putOn(_ item: Item?) {
        charm = item
        hp = min(hp, maxHP)
        mp = min(mp, maxMP)
    }

    /// 身につけているものをはずす。持ちものには残る。
    mutating func unequip(_ item: Item) {
        if weapon == item { weapon = nil }
        if armor == item { armor = nil }
        if charm == item { putOn(nil) }
    }

    /// 売り値。買い値の半分（最低 1）。
    static func sellPrice(of item: Item) -> Int { max(1, item.price / 2) }

    /// 売る。そうび中のものは売れない。売れたら受け取ったゴールドを返す。
    mutating func sell(_ item: Item) -> Int? {
        guard owns(item), !isEquipped(item) else { return nil }
        inventory[item, default: 0] -= 1
        if inventory[item] == 0 { inventory[item] = nil }
        let paid = Hero.sellPrice(of: item)
        gold += paid
        return paid
    }

    /// 道具を1つ使う。使えなければ false。
    mutating func consume(_ item: Item) -> Bool {
        guard item.kind == .consumable, inventory[item, default: 0] > 0 else { return false }
        inventory[item, default: 0] -= 1
        if inventory[item] == 0 { inventory[item] = nil }
        return true
    }
}

extension Hero {
    /// あとから 足した 項目は なくても 読む（前の セーブを そのまま 続けられるように）。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let fresh = Hero()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? fresh.name
        level = try c.decode(Int.self, forKey: .level)
        exp = try c.decode(Int.self, forKey: .exp)
        gold = try c.decode(Int.self, forKey: .gold)
        hp = try c.decode(Int.self, forKey: .hp)
        mp = try c.decode(Int.self, forKey: .mp)
        weapon = try c.decodeIfPresent(Item.self, forKey: .weapon)
        armor = try c.decodeIfPresent(Item.self, forKey: .armor)
        charm = try c.decodeIfPresent(Item.self, forKey: .charm)
        inventory = try c.decodeIfPresent([Item: Int].self, forKey: .inventory) ?? fresh.inventory
        growth = try c.decodeIfPresent([Item.Growth: Int].self, forKey: .growth) ?? [:]
    }
}
