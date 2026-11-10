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
        // 東北を 北海道の あと（LV15 から）に つないだので、上を 足した（2.0）。
        LevelRow(maxHP: 264, maxMP: 140, attack: 92, defense: 63, agility: 48, exp: 22620),
        LevelRow(maxHP: 272, maxMP: 145, attack: 95, defense: 65, agility: 50, exp: 24840),
        LevelRow(maxHP: 280, maxMP: 150, attack: 98, defense: 67, agility: 51, exp: 27190),
        LevelRow(maxHP: 288, maxMP: 155, attack: 101, defense: 69, agility: 53, exp: 29670),
        LevelRow(maxHP: 296, maxMP: 160, attack: 104, defense: 71, agility: 54, exp: 32280),
        LevelRow(maxHP: 304, maxMP: 165, attack: 107, defense: 73, agility: 56, exp: 35020),
        LevelRow(maxHP: 312, maxMP: 170, attack: 110, defense: 75, agility: 57, exp: 37890),
        LevelRow(maxHP: 320, maxMP: 175, attack: 113, defense: 77, agility: 59, exp: 40890),
        LevelRow(maxHP: 328, maxMP: 180, attack: 116, defense: 79, agility: 60, exp: 44020),
        LevelRow(maxHP: 336, maxMP: 185, attack: 119, defense: 81, agility: 62, exp: 47280),
        LevelRow(maxHP: 344, maxMP: 190, attack: 122, defense: 83, agility: 63, exp: 50670),
        LevelRow(maxHP: 352, maxMP: 195, attack: 125, defense: 85, agility: 65, exp: 54190),
        LevelRow(maxHP: 360, maxMP: 200, attack: 128, defense: 87, agility: 66, exp: 57840),
        LevelRow(maxHP: 368, maxMP: 205, attack: 131, defense: 89, agility: 68, exp: 61620),
        LevelRow(maxHP: 376, maxMP: 210, attack: 134, defense: 91, agility: 69, exp: 65530),
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
        case .thunder: 8
        case .highHeal: 6
        case .flame: 5
        case .shield: 6
        case .bolt: 14
        case .fullHeal: 16
        case .inferno: 16
        case .storm: 24
        }
    }

    var learnLevel: Int {
        switch self {
        // 北海道で おぼえる 4つは 1.4 の まま。東北で おぼえる ものは 北海道の あと（LV15〜）に ずらした。
        case .heal: 2
        case .fire: 4
        case .escape: 6
        case .highHeal: 7
        case .flame: 8
        case .thunder: 21
        case .shield: 27
        case .bolt: 30
        case .fullHeal: 33
        case .inferno: 36
        case .storm: 40
        }
    }

    /// 回復量または与えるダメージの幅。攻撃呪文は守備力を無視する。
    var power: ClosedRange<Int> {
        switch self {
        case .heal: 20...28
        case .fire: 10...14
        case .thunder: 50...70
        case .highHeal: 60...80
        case .flame: 25...32
        case .bolt: 75...100
        case .fullHeal: 9999...9999
        case .inferno: 145...175
        case .storm: 130...160
        case .escape, .shield: 0...0
        }
    }

    /// その レベルで となえたときの 回復量。ヒール・ハイヒールは 北海道（〜LV15）までは 1.4 の まま、
    /// 東北では さいだいHP に あわせて ふえる（東北を 北海道の あとに つないだので、ふえないと 効かなくなる）。
    func healRange(level: Int) -> ClosedRange<Int> {
        guard self == .heal || self == .highHeal, level > 15 else { return power }
        let scale = Double(LevelTable.row(level).maxHP) / Double(LevelTable.row(15).maxHP)
        return Int(Double(power.lowerBound) * scale)...Int(Double(power.upperBound) * scale)
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

/// 道具と装備。名前は 北海道・東北の その土地の 名産に ちなむ。
/// 内部の名前は セーブに 残るので 変えない。見せる名前だけ 変える。
/// 回復の道具・武器・よろいは 旅の順に 強く、高くなる。上等な品は 貯めないと 買えない。
enum Item: String, Codable, CaseIterable, Identifiable, CodingKeyRepresentable {
    // ── 北海道（1.4 から。セーブに 残るので 名前は 変えない）──
    case herb, ikameshi, dango, misoRamen, onsenTamago, milk, ikuraDon
    case hanabi, bearBell, walnut, soybean, hakka, melon
    case woodStick, squidSpear, copperSword, katana, steelSword, glassSword, orcaSpear
    case clothes, scallopPlate, leatherArmor, samuraiArmor, chainMail, herringMail, attush, driftIceArmor
    // ── 東北 ──
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
    case omagariHanabi
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
        case .herb: "ハスカップ"
        case .ikameshi: "いかめし"
        case .dango: "大沼だんご"
        case .misoRamen: "みそラーメン"
        case .onsenTamago: "温泉たまご"
        case .milk: "しぼりたて牛乳"
        case .ikuraDon: "いくら丼"
        case .hanabi: "函館の花火"
        case .bearBell: "クマよけの鈴"
        case .walnut: "オニグルミ"
        case .soybean: "十勝の大豆"
        case .hakka: "北見のハッカ"
        case .melon: "夕張メロン"
        case .woodStick: "ヤチダモの棒"
        case .squidSpear: "イカつりの銛"
        case .copperSword: "五稜郭の槍"
        case .katana: "松前の刀"
        case .steelSword: "時計台の剣"
        case .glassSword: "小樽ガラスの剣"
        case .orcaSpear: "シャチの銛"
        case .clothes: "木綿のはんてん"
        case .scallopPlate: "ホタテの胸当て"
        case .leatherArmor: "五稜郭の鎧"
        case .samuraiArmor: "松前藩士の鎧"
        case .chainMail: "雪まつりの鎧"
        case .herringMail: "ニシンのうろこ鎧"
        case .attush: "アットゥシ"
        case .driftIceArmor: "流氷の鎧"
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
        case .omagariHanabi: "大曲の花火"
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
        case .hanten: "津軽のどてら"
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
        case .herb, .ikameshi, .dango, .misoRamen, .onsenTamago, .milk, .ikuraDon,
             .hanabi, .bearBell, .walnut, .soybean, .hakka, .melon:
            .consumable
        case .woodStick: .weapon(power: 2)
        case .squidSpear: .weapon(power: 5)
        case .copperSword: .weapon(power: 8)
        case .katana: .weapon(power: 11)
        case .steelSword: .weapon(power: 16)
        case .glassSword: .weapon(power: 19)
        case .orcaSpear: .weapon(power: 23)
        case .clothes: .armor(power: 2)
        case .scallopPlate: .armor(power: 4)
        case .leatherArmor: .armor(power: 6)
        case .samuraiArmor: .armor(power: 9)
        case .chainMail: .armor(power: 12)
        case .herringMail: .armor(power: 15)
        case .attush: .armor(power: 18)
        case .driftIceArmor: .armor(power: 21)
        case .apple, .senbeiJiru, .iburigakko, .kiritanpo, .nanbuSenbei, .wankoSoba, .zundaMochi, .gyutan,
             .momo, .kitakataRamen, .sakuranbo, .imoni,
             .omagariHanabi, .shakudama, .matagiBell, .hinaiChicken, .mishirazuGaki, .dadachamame, .yonezawaBeef, .hitomebore:
            .consumable
        case .bunaStick: .weapon(power: 24)
        case .ringoBokuto: .weapon(power: 27)
        case .nebutaHoko: .weapon(power: 31)
        case .tsugaruKatana: .weapon(power: 35)
        case .namahageHocho: .weapon(power: 39)
        case .nanbuSword: .weapon(power: 43)
        case .konjikiTachi: .weapon(power: 48)
        case .dateKatana: .weapon(power: 53)
        case .byakkoKatana: .weapon(power: 58)
        case .mogamiNaginata: .weapon(power: 64)
        case .juhyoSword: .weapon(power: 70)
        case .matsuriSword: .weapon(power: 77)
        case .hanten: .armor(power: 22)
        case .koginCoat: .armor(power: 24)
        case .nebutaHappi: .armor(power: 27)
        case .hirosakiArmor: .armor(power: 30)
        case .akitaSugiArmor: .armor(power: 33)
        case .nanbuArmor: .armor(power: 36)
        case .fujiwaraArmor: .armor(power: 40)
        case .dateArmor: .armor(power: 44)
        case .aizuArmor: .armor(power: 48)
        case .benibanaArmor: .armor(power: 52)
        case .juhyoArmor: .armor(power: 57)
        case .matsuriArmor: .armor(power: 62)
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
        case .herb: .hp(25...35)
        case .ikameshi: .hp(45...55)
        case .dango: .mp(6...9)
        case .misoRamen: .hp(80...100)
        case .onsenTamago: .mp(15...20)
        case .milk: .mp(25...32)
        case .ikuraDon: .hp(130...160)
        case .hanabi: .blastAll(30...45)
        case .bearBell: .escape
        case .walnut: .grow(.attack, 2)
        case .soybean: .grow(.defense, 2)
        case .hakka: .grow(.agility, 2)
        case .melon: .grow(.maxHP, 10)
        // 東北は 北海道の いくら丼・牛乳の つづき（LV15 から）。
        case .apple: .hp(160...190)
        case .senbeiJiru: .hp(190...220)
        case .iburigakko: .mp(30...40)
        case .kiritanpo: .hp(220...260)
        case .nanbuSenbei: .mp(40...50)
        case .wankoSoba: .hp(260...300)
        case .zundaMochi: .mp(55...65)
        case .gyutan: .hp(310...360)
        case .momo: .mp(70...85)
        case .kitakataRamen: .hp(380...430)
        case .sakuranbo: .mp(95...115)
        case .imoni: .hp(9999...9999)
        case .omagariHanabi: .blastAll(150...200)
        case .shakudama: .blastAll(260...320)
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
        case .herb: 8
        case .ikameshi: 18
        case .dango: 30
        case .misoRamen: 45
        case .onsenTamago: 60
        case .milk: 90
        case .ikuraDon: 100
        case .hanabi: 80
        case .bearBell: 40
        case .walnut, .soybean, .hakka, .melon: 300
        case .woodStick: 5
        case .squidSpear: 45
        case .copperSword: 100
        case .katana: 260
        case .steelSword: 550
        case .glassSword: 900
        case .orcaSpear: 1500
        case .clothes: 10
        case .scallopPlate: 50
        case .leatherArmor: 120
        case .samuraiArmor: 300
        case .chainMail: 450
        case .herringMail: 850
        case .attush: 1300
        case .driftIceArmor: 1900
        // 東北の 値段は 東北の 敵の ゴールドに あわせて「何回 たたかえば 買えるか」を 2 と そろえた（2.0）。
        case .apple: 120
        case .senbeiJiru: 180
        case .iburigakko: 250
        case .kiritanpo: 300
        case .nanbuSenbei: 400
        case .wankoSoba: 450
        case .zundaMochi: 550
        case .gyutan: 650
        case .momo: 700
        case .kitakataRamen: 900
        case .sakuranbo: 850
        case .imoni: 1450
        case .omagariHanabi: 400
        case .shakudama: 1200
        case .matagiBell: 200
        case .hinaiChicken, .mishirazuGaki, .dadachamame, .yonezawaBeef, .hitomebore: 1500
        case .bunaStick: 100
        case .ringoBokuto: 1150
        case .nebutaHoko: 1950
        case .tsugaruKatana: 3000
        case .namahageHocho: 4000
        case .nanbuSword: 5500
        case .konjikiTachi: 7000
        case .dateKatana: 9000
        case .byakkoKatana: 10500
        case .mogamiNaginata: 12500
        case .juhyoSword: 13500
        case .matsuriSword: 18500
        case .hanten: 200
        case .koginCoat: 1300
        case .nebutaHappi: 2100
        case .hirosakiArmor: 3200
        case .akitaSugiArmor: 4500
        case .nanbuArmor: 5500
        case .fujiwaraArmor: 7500
        case .dateArmor: 9500
        case .aizuArmor: 11000
        case .benibanaArmor: 13000
        case .juhyoArmor: 13000
        case .matsuriArmor: 18500
        case .kingyoNebuta, .kabaInro, .nanbuFurin, .narukoKokeshi, .akabeko, .okiagari, .tanzaku, .oushou: 4000
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
        case .hanabi, .bearBell, .walnut, .soybean, .hakka, .melon,
             .omagariHanabi, .shakudama, .matagiBell, .hinaiChicken, .mishirazuGaki, .dadachamame, .yonezawaBeef, .hitomebore,
             .juhyoSword, .matsuriSword, .juhyoArmor, .matsuriArmor: true
        default: isCharm
        }
    }

    /// ハスカップ（いちばん 安い 回復の道具）の回復量。
    static var herbPower: ClosedRange<Int> {
        if case let .hp(range) = Item.herb.effect { return range }
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
    var weapon: Item? = .woodStick
    /// そうび中のよろい。はずしていれば nil。
    var armor: Item? = .clothes
    /// そうび中の かざり。
    var charm: Item?
    /// 持ちもの。買った・拾った装備も、はずしたあと売れるようにここに残る。
    var inventory: [Item: Int] = [.herb: 2, .woodStick: 1, .clothes: 1]
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

    var herbCount: Int { inventory[.herb, default: 0] }

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

    /// 身につけている 装備が 持ちものに なければ 足す（古い セーブで 装備だけ 持っていたとき）。
    mutating func normalizeInventory() {
        for item in [weapon, armor, charm].compactMap({ $0 }) where !owns(item) {
            inventory[item, default: 0] += 1
        }
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
