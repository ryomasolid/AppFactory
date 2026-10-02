import Foundation

/// 物語の進みぐあい。人と話したり 頼まれごとを片づけたりすると 立つ。セーブに残す。
/// ボスを倒したかは `defeatedBosses` のほうで持つ。
/// 県が 6つ あり 印が 多いので、名前（"aomori.heard" など）で 見分ける。
struct StoryFlag: Hashable, Codable, RawRepresentable, ExpressibleByStringLiteral, CustomStringConvertible {
    let rawValue: String

    init(rawValue: String) { self.rawValue = rawValue }
    init(stringLiteral value: String) { rawValue = value }
    init(from decoder: Decoder) throws { rawValue = try decoder.singleValueContainer().decode(String.self) }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var description: String { rawValue }

    /// 守護神を 倒した（クリア）。立てなくても 守護神を 倒していれば 立っている。
    static let cleared: StoryFlag = "cleared"
    /// 6県の ちしき検定に ぜんぶ 合格した。立てなくても そろえば 立っている。
    static let allExams: StoryFlag = "allExams"

    /// 県の ちしき検定に 合格した。
    static func examPassed(_ region: Region) -> StoryFlag { StoryFlag(rawValue: "\(region.rawValue).exam") }
    /// 県の 名所の スタンプを 半分／ぜんぶ あつめて 案内所から お礼を もらった。
    static func stampHalf(_ region: Region) -> StoryFlag { StoryFlag(rawValue: "\(region.rawValue).stampHalf") }
    static func stampAll(_ region: Region) -> StoryFlag { StoryFlag(rawValue: "\(region.rawValue).stampAll") }
    /// まもの ずかんの お礼を もらった（だんかいごと）。
    static func bookReward(_ step: Int) -> StoryFlag { StoryFlag(rawValue: "book.\(step)") }

    /// このボスを倒していれば、立っていなくても 立っていることにする。
    /// 関所を ひらく 印は ボスを 倒す 前に 立つので、倒したあとの セーブでも 止められないように。
    var impliedBy: EnemyKind? { Story.implications[self] }

    /// 関所（`Warp.needs`）で止められたときの せりふ。
    var gateLines: [String] { Story.gates[self] ?? ["さきへ すすめない。"] }
}

/// どこまで進んだか。話す相手の せりふを決めるのに使う。
struct StoryProgress {
    var flags: Set<StoryFlag>
    var defeatedBosses: Set<EnemyKind>
    /// 県ごとの 押した 名所の スタンプの数（看板を 読んだ数）。
    var stamps: [Region: Int] = [:]
    /// まもの ずかんに のった 数（倒した 種類）。
    var seen = 0

    /// `impliedBy.map(defeatedBosses.contains)` と メソッドを そのまま渡すと、
    /// Release の最適化で 不正なメモリを 読んで落ちた（元祖で 空港に入ろうとすると クラッシュ）。ふつうに 書く。
    func has(_ flag: StoryFlag) -> Bool {
        if flags.contains(flag) { return true }
        if flag == .cleared { return defeatedBosses.contains(.guardian) }
        if flag == .allExams {
            for region in Region.allCases where !flags.contains(.examPassed(region)) { return false }
            return true
        }
        guard let boss = flag.impliedBy else { return false }
        return defeatedBosses.contains(boss)
    }

    /// その県へ 新幹線で 行けるか（ひとつ前の 県の ぬしを 倒すと きっぷが もらえる）。
    func canTravel(to region: Region) -> Bool {
        guard let previous = region.previous else { return true }
        return defeatedBosses.contains(previous.lord)
    }

    /// その県の まつりが もどったか。
    func festivalRestored(_ region: Region) -> Bool { defeatedBosses.contains(region.lord) }
}

/// 話しかけたときに起きること。せりふを出したあと、ごほうびを渡して 印を立てる。
struct StoryScene: Equatable {
    var lines: [String]
    var gold = 0
    var items: [Item] = []
    var sets: [StoryFlag] = []
    /// HP・MPを ぜんぶ なおす（温泉の 足湯）。
    var heals = false
    /// せりふの あとで ちしき検定を はじめる。
    var startsExam: Region?
}

/// 物語にかかわる人。進みぐあいで せりふが変わり、出たり消えたりする。
/// 地図には 数字の印で置く（`GameMap` の `residents`）。せりふは 県ごとの ファイル（`Regions/`）に書く。
enum Resident: String, CaseIterable {
    // ── 青森 ──
    case nebutashi, matagi, appleFarmer, hachinoheMarket, jomonMother, lostJomonKid, jomonKidHome
    case aomoriGuide, aomoriExaminer, aomoriDancer, shamisen, itako
    // ── 秋田 ──
    case kantoMaster, bukeLady, namahageElder, kiritanpoCook, ogaFisher, dogOwner, lostAkitaDog, akitaDogHome
    case akitaGuide, akitaExaminer, akitaDancer, kabaCrafter
    // ── 岩手 ──
    case sansaMaster, kataribe, chusonjiMonk, wankoHost, hiraizumiPilgrim, zashikiHost, lostZashiki, zashikiHome
    case iwateGuide, iwateExaminer, iwateDancer, nanbuSmith
    // ── 宮城 ──
    case tanabataMaster, boatman, zuiganjiMonk, kokeshiCarver, sendaiKid, curator, sendaiMother, lostSendaiKid
    case sendaiKidHome, miyagiGuide, miyagiExaminer, miyagiDancer, narukoYumori
    // ── 福島 ──
    case warajiMaster, castleWarden, akabekoKeeper, ramenMaster, aizuReceiver, peachFarmer, lostByakko, byakkoHome
    case fukushimaGuide, fukushimaExaminer, fukushimaDancer, okiagariMaker
    // ── 山形 ──
    case hanagasaMaster, shogiMaster, sakataBoatman, imoniCook, sakataMerchant, cherryFarmer, lostCherryKid
    case cherryKidHome, yamagataGuide, yamagataExaminer, yamagataDancer, basho

    /// いま地図に出ているか。迷子は 見つけると 消え、家に もどった すがたが 出る。まつりの おどり手は まつりが もどってから。
    func isPresent(_ progress: StoryProgress) -> Bool {
        switch self {
        case .lostJomonKid: !progress.has(LostQuest.jomonKid.found)
        case .jomonKidHome: progress.has(LostQuest.jomonKid.found)
        case .lostAkitaDog: !progress.has(LostQuest.akitaDog.found)
        case .akitaDogHome: progress.has(LostQuest.akitaDog.found)
        case .lostZashiki: !progress.has(LostQuest.zashiki.found)
        case .zashikiHome: progress.has(LostQuest.zashiki.found)
        case .lostSendaiKid: !progress.has(LostQuest.sendaiKid.found)
        case .sendaiKidHome: progress.has(LostQuest.sendaiKid.found)
        case .lostByakko: !progress.has(LostQuest.byakko.found)
        case .byakkoHome: progress.has(LostQuest.byakko.found)
        case .lostCherryKid: !progress.has(LostQuest.cherryKid.found)
        case .cherryKidHome: progress.has(LostQuest.cherryKid.found)
        case .aomoriDancer: progress.festivalRestored(.aomori)
        case .akitaDancer: progress.festivalRestored(.akita)
        case .iwateDancer: progress.festivalRestored(.iwate)
        case .miyagiDancer: progress.festivalRestored(.miyagi)
        case .fukushimaDancer: progress.festivalRestored(.fukushima)
        case .yamagataDancer: progress.festivalRestored(.yamagata)
        default: true
        }
    }

    /// 話しかけたときの場面。
    func scene(_ progress: StoryProgress) -> StoryScene {
        aomoriScene(progress) ?? akitaScene(progress) ?? iwateScene(progress)
            ?? miyagiScene(progress) ?? fukushimaScene(progress) ?? yamagataScene(progress)
            ?? StoryScene(lines: ["……"])
    }

    /// 地図に 描く 絵。
    var sprite: SpriteID {
        switch self {
        case .nebutashi, .kantoMaster, .sansaMaster, .tanabataMaster, .warajiMaster, .hanagasaMaster,
             .ogaFisher, .boatman, .sakataBoatman, .nanbuSmith, .kokeshiCarver, .ramenMaster, .kiritanpoCook,
             .wankoHost, .imoniCook, .okiagariMaker, .kabaCrafter, .appleFarmer, .peachFarmer, .cherryFarmer,
             .narukoYumori, .sakataMerchant:
            .fisherman
        case .matagi: .hunter
        case .chusonjiMonk, .zuiganjiMonk, .basho, .hiraizumiPilgrim: .monk
        case .castleWarden, .shogiMaster, .curator: .magistrate
        case .namahageElder, .kataribe, .itako: .elder
        case .lostJomonKid, .jomonKidHome, .lostSendaiKid, .sendaiKidHome, .lostCherryKid, .cherryKidHome,
             .sendaiKid, .lostByakko, .byakkoHome:
            .child
        case .lostAkitaDog, .akitaDogHome: .akitaDog
        case .lostZashiki, .zashikiHome: .zashiki
        case .akabekoKeeper: .akabeko
        case .aomoriDancer, .akitaDancer, .iwateDancer, .miyagiDancer, .fukushimaDancer, .yamagataDancer: .dancer
        default: .villager
        }
    }

    /// この人から もらえる ゴールドの 合計（お礼は 1度ずつ）。お金の つりあいを たしかめるのに使う。
    var totalGold: Int {
        var flags: Set<StoryFlag> = []
        var total = 0
        let everyStamp = Dictionary(uniqueKeysWithValues: Region.allCases.map { ($0, World.stampTotal(in: $0)) })
        for defeated in [Set<EnemyKind>(), Set(EnemyKind.allCases.filter(\.isBoss))] {
            for _ in 0..<8 {
                let scene = scene(StoryProgress(flags: flags, defeatedBosses: defeated, stamps: everyStamp,
                                                seen: EnemyKind.allCases.count))
                total += scene.gold
                flags.formUnion(scene.sets)
            }
        }
        return total
    }

    /// この人が 言うかもしれない せりふ ぜんぶ（`QuizTests` で 答えが街で聞けるかを見る）。
    /// 印の組み合わせは ぜんぶだと 多すぎるので、話しかけて 立った 印を つみあげる すじみちを、
    /// ボスを ひとりずつ 倒していく だんかいごとに たどる。
    var everyLine: [String] {
        let bosses = EnemyKind.allCases.filter(\.isBoss)
        var lines: [String] = []
        let stampSets: [[Region: Int]] = [[:], Dictionary(uniqueKeysWithValues: Region.allCases.map {
            ($0, (World.stampTotal(in: $0) + 1) / 2)
        }), Dictionary(uniqueKeysWithValues: Region.allCases.map { ($0, World.stampTotal(in: $0)) })]
        for count in 0...bosses.count {
            let defeated = Set(bosses.prefix(count))
            for stamps in stampSets {
                var flags: Set<StoryFlag> = Story.allFlags.filter { flag in
                    // 関所の 印は ボスより 前に 立つので、だんかいに あわせて 立てておく。
                    guard let boss = flag.impliedBy else { return false }
                    return defeated.contains(boss)
                }
                for _ in 0..<6 {
                    let scene = scene(StoryProgress(flags: flags, defeatedBosses: defeated, stamps: stamps, seen: 0))
                    lines += scene.lines
                    flags.formUnion(scene.sets)
                }
            }
        }
        return lines
    }
}

/// おつかい（出前）。たのむ人 → とどけ先 → たのむ人に お礼。
struct Errand {
    let id: String
    /// 何を あずかるか（「りんごの はこ」）。
    let package: String
    /// はじめて 話したときの たのみごと。
    let ask: [String]
    /// あずかったまま もういちど 話したとき。
    let reminder: [String]
    /// とどけたあとに もどってきたとき（お礼の 行は あとに 足す）。
    let thanks: [String]
    /// お礼の あとの ひとこと。
    let after: [String]
    /// とどけ先の 人の よろこび。
    let delivered: [String]
    /// とどけ先の 人の ふだんの せりふ。
    let idle: [String]
    let gold: Int
    var items: [Item] = []

    var carrying: StoryFlag { StoryFlag(rawValue: "\(id).carrying") }
    var done: StoryFlag { StoryFlag(rawValue: "\(id).delivered") }
    var thanked: StoryFlag { StoryFlag(rawValue: "\(id).thanked") }
    var flags: [StoryFlag] { [carrying, done, thanked] }

    func giverScene(_ progress: StoryProgress) -> StoryScene {
        if progress.has(thanked) { return StoryScene(lines: after) }
        if progress.has(done) {
            return StoryScene(lines: thanks + Story.rewardLines(gold: gold, items: items), gold: gold, items: items,
                              sets: [thanked])
        }
        if progress.has(carrying) { return StoryScene(lines: reminder) }
        return StoryScene(lines: ask + ["\(package)を あずかった。"], sets: [carrying])
    }

    func receiverScene(_ progress: StoryProgress) -> StoryScene {
        if progress.has(carrying), !progress.has(done) {
            return StoryScene(lines: delivered + ["\(package)を とどけた。"], sets: [done])
        }
        return StoryScene(lines: idle)
    }
}

/// 迷子さがし。さがしている人 → 迷子を 見つける（迷子は 家へ もどる）→ お礼。
struct LostQuest {
    let id: String
    /// さがしている人の たのみ。
    let ask: [String]
    /// 見つけたあと もどったとき（お礼の 行は あとに 足す）。
    let thanks: [String]
    /// お礼の あとの ひとこと。
    let after: [String]
    /// 迷子に 話しかけたとき（最後に 家へ もどっていく）。
    let lost: [String]
    /// 家に もどった 迷子の せりふ。
    let home: [String]
    var gold = 0
    var items: [Item] = []

    var found: StoryFlag { StoryFlag(rawValue: "\(id).found") }
    var returned: StoryFlag { StoryFlag(rawValue: "\(id).returned") }
    var flags: [StoryFlag] { [found, returned] }

    func seekerScene(_ progress: StoryProgress) -> StoryScene {
        if progress.has(returned) { return StoryScene(lines: after) }
        if progress.has(found) {
            return StoryScene(lines: thanks + Story.rewardLines(gold: gold, items: items), gold: gold, items: items,
                              sets: [returned])
        }
        return StoryScene(lines: ask)
    }

    func lostScene() -> StoryScene { StoryScene(lines: lost, sets: [found]) }
    func homeScene() -> StoryScene { StoryScene(lines: home) }
}

/// 物語の 共通の 部品と 表。
enum Story {
    /// 関所の せりふ（県ごとの 表を まとめる）。
    static let gates: [StoryFlag: [String]] = aomoriGates
        .merging(akitaGates) { first, _ in first }
        .merging(iwateGates) { first, _ in first }
        .merging(miyagiGates) { first, _ in first }
        .merging(fukushimaGates) { first, _ in first }
        .merging(yamagataGates) { first, _ in first }
        .merging([
            .cleared: ["つよい やみの ちからが ただよっていて すすめない。",
                       "（東北の 守護神を 解きはなてば……）"],
            .allExams: ["おくから まがまがしい けはいが する。",
                        "かべに こう きざまれている。",
                        "「東北 六県の ちしきを きわめし もの のみ とおる」",
                        "（6県の ちしき検定に ぜんぶ 合格すると ひらく）"],
        ]) { first, _ in first }

    /// ボスを 倒せば 立っていることにする 印（県ごとの 表を まとめる）。
    static let implications: [StoryFlag: EnemyKind] = aomoriImplications
        .merging(akitaImplications) { first, _ in first }
        .merging(iwateImplications) { first, _ in first }
        .merging(miyagiImplications) { first, _ in first }
        .merging(fukushimaImplications) { first, _ in first }
        .merging(yamagataImplications) { first, _ in first }

    /// 物語の 印 ぜんぶ（テストと せりふの 洗い出しに 使う）。
    static var allFlags: Set<StoryFlag> {
        var flags = Set(gates.keys).union(implications.keys)
        for errand in Errand.all { flags.formUnion(errand.flags) }
        for quest in LostQuest.all { flags.formUnion(quest.flags) }
        for region in Region.allCases {
            flags.formUnion([.examPassed(region), .stampHalf(region), .stampAll(region)])
        }
        for step in curatorSteps.indices { flags.insert(.bookReward(step)) }
        return flags
    }

    /// お礼の 行（「90ゴールドを てにいれた！」「りんごを 2つ てにいれた！」）。
    static func rewardLines(gold: Int, items: [Item]) -> [String] {
        var lines: [String] = []
        if gold > 0 { lines.append("\(gold)ゴールドを てにいれた！") }
        var order: [Item] = []
        var counts: [Item: Int] = [:]
        for item in items {
            if counts[item] == nil { order.append(item) }
            counts[item, default: 0] += 1
        }
        for item in order {
            let count = counts[item] ?? 1
            lines.append(count > 1 ? "\(item.name)を \(count)つ てにいれた！" : "\(item.name)を てにいれた！")
        }
        return lines
    }

    // MARK: - 案内所（めいしょ スタンプ）

    /// 案内所の 場面。半分で 県の 回復の道具、ぜんぶで ゴールド。
    static func stampScene(_ region: Region, _ progress: StoryProgress, towns: String, gift: Item) -> StoryScene {
        let total = World.stampTotal(in: region)
        let half = (total + 1) / 2
        let stamps = progress.stamps[region, default: 0]
        let area = region.name
        let prize = 150 + 100 * region.order
        if progress.has(.stampAll(region)) {
            return StoryScene(lines: [
                "あんないじょ「\(area)の 名所を ぜんぶ まわるなんて！",
                "　あなたは りっぱな めいしょ はかせね。」",
            ])
        }
        if stamps >= total {
            return StoryScene(lines: [
                "あんないじょ「まあ！ スタンプが \(total)こ ぜんぶ そろってる！",
                "　これは めいしょ はかせへの ごほうびよ。」",
                "\(prize)ゴールドを てにいれた！",
            ], gold: prize, sets: [.stampHalf(region), .stampAll(region)])
        }
        if stamps >= half, !progress.has(.stampHalf(region)) {
            return StoryScene(lines: [
                "あんないじょ「スタンプが \(stamps)こ！ もう 半分ね。",
                "　たびの おともに どうぞ。 のこりも がんばって！」",
                "\(gift.name)を 3つ てにいれた！",
            ], items: [gift, gift, gift], sets: [.stampHalf(region)])
        }
        return StoryScene(lines: [
            "あんないじょ「ようこそ \(area)へ！ 名所の かんばんを よむと",
            "　めいしょ スタンプが たまるの。 \(towns)に あるわ。",
            "　いま \(stamps)こ ／ \(total)こ。 \(half)こで \(gift.name)、",
            "　ぜんぶ そろえば \(prize)ゴールド あげる！」",
        ])
    }

    // MARK: - ちしき検定

    /// 検定の 問題の かず。ぜんぶ 正解で 合格。
    static let examLength = 5

    /// 合格の ごほうび（県ごとに ちがう かざり）。
    static func examReward(_ region: Region) -> Item {
        switch region {
        case .aomori: .kingyoNebuta
        case .akita: .kabaInro
        case .iwate: .nanbuFurin
        case .miyagi: .narukoKokeshi
        case .fukushima: .akabeko
        case .yamagata: .oushou
        }
    }

    /// 検定の 先生の 場面。合格していなければ 検定を はじめる。
    static func examScene(_ region: Region, _ progress: StoryProgress) -> StoryScene {
        if progress.has(.examPassed(region)) {
            return StoryScene(lines: [
                "けんていいん「\(region.name)の ちしき検定 合格者 どの！",
                "　ほかの 県の 検定にも ちょうせん してみては いかが？",
                "　6県 ぜんぶ 合格すると なにかが おこるとか……」",
            ])
        }
        return StoryScene(lines: [
            "けんていいん「ここは \(region.name)の ちしき検定の 会場です。",
            "　\(region.shortName)の 問題を \(examLength)もん 出します。",
            "　ぜんぶ 正解なら 合格！ \(examReward(region).name)を さしあげます。",
            "　答えは \(region.shortName)の 人や 名所の かんばんが おしえて くれますよ。」",
        ], startsExam: region)
    }

    // MARK: - まもの ずかん

    /// 学芸員の ごほうびの だんかい（ずかんに のった 数と ごほうび）。
    static let curatorSteps: [(count: Int, gold: Int, item: Item)] = [
        (30, 300, .tanzaku),
        (60, 800, .okiagari),
        (EnemyKind.allCases.count, 0, .matsuriSword),
    ]

    static func curatorScene(_ progress: StoryProgress) -> StoryScene {
        let total = EnemyKind.allCases.count
        for (step, reward) in curatorSteps.enumerated() where !progress.has(.bookReward(step)) {
            guard progress.seen >= reward.count else {
                return StoryScene(lines: [
                    "がくげいいん「ここは 東北の いきもの・名物の 博物館。",
                    "　あなたの まもの ずかんは いま \(progress.seen)しゅるい ／ \(total)しゅるい。",
                    "　\(reward.count)しゅるい あつまったら \(reward.item.name)を あげましょう。",
                    "　（ずかんは メニューの『きろく』で 見られます）」",
                ])
            }
            return StoryScene(lines: [
                "がくげいいん「ずかんが \(progress.seen)しゅるいも！ すばらしい しらべっぷりです。",
                "　これは けんきゅうの おれいです。」",
            ] + rewardLines(gold: reward.gold, items: [reward.item]),
            gold: reward.gold, items: [reward.item], sets: [.bookReward(step)])
        }
        return StoryScene(lines: [
            "がくげいいん「まもの ずかんを ぜんぶ うめた ひとは あなたが はじめて！",
            "　東北の ことなら あなたに きけば まちがいなしですね。」",
        ])
    }

    // MARK: - 長老の 助言

    /// 長老の 助言。どこまで 進んだかで 言うことを 変える。どの 街の 長老も 同じ ことを 言う。
    static func elderHint(_ progress: StoryProgress) -> [String] {
        for region in Region.allCases {
            if let hint = hint(for: region, progress) { return hint }
        }
        if !progress.has(.allExams) {
            return ["ちょうろう「よくぞ 東北に へいわを とりもどした。",
                    "　下北半島の 恐山の おくに まだ やみの けはいが のこっておる。",
                    "　6県の ちしき検定を きわめれば おくへ すすめるはずじゃ。」"]
        }
        if !progress.defeatedBosses.contains(.maouShadow) {
            return ["ちょうろう「恐山の おくに ひそむ まおうの かげ……",
                    "　そなたなら きっと うちはらえよう。",
                    "　青森の 下北半島、むつ湾の 北じゃ。」"]
        }
        return ["ちょうろう「まおうの かげまで うちはらうとは。",
                "　そなたこそ しんの ちりの ゆうしゃじゃ。」"]
    }

    private static func hint(for region: Region, _ progress: StoryProgress) -> [String]? {
        switch region {
        case .aomori: aomoriHint(progress)
        case .akita: akitaHint(progress)
        case .iwate: iwateHint(progress)
        case .miyagi: miyagiHint(progress)
        case .fukushima: fukushimaHint(progress)
        case .yamagata: yamagataHint(progress)
        }
    }

    // MARK: - ボスの せりふ

    static func bossGreeting(_ kind: EnemyKind) -> [String] {
        switch kind {
        case .hachirotaro:
            ["ザザァ……",
             "八郎太郎「この 十和田湖は わしの すみかじゃ。",
             "　ひとの 子が なにしに きた。 しずめて くれよう！」"]
        case .yukioni:
            ["ゴオオオ……",
             "ゆきおに「ねぶたの 火は おれさまが いただいた。",
             "　八甲田の 雪に うもれて ねむるが いい！」"]
        case .tatsuko:
            ["……ゴポゴポ……",
             "たつこ「わたしは この 湖の ぬし たつこ。",
             "　まおうさまの いいつけで だれも とおしません！」"]
        case .namahageKing:
            ["ウオオオオ……！",
             "なまはげ大王「なぐごは いねがー！ わるいごは いねがー！",
             "　竿燈の あかりは かえさねぇぞー！」"]
        case .ryusendoLord:
            ["シュウウウ……",
             "ドラゴンブルー「この あおい 水の そこは まおうさまの もの。",
             "　つめたい 地底湖へ ひきずりこんで やる！」"]
        case .mitsuishiOni:
            ["ズシン……ズシン……",
             "三ツ石の 鬼「むかし 三ツ石に とじこめられた うらみ、",
             "　いまこそ はらして くれる！ さんさの たいこは もう ならさん！」"]
        case .giantOyster:
            ["ゴボゴボゴボ……",
             "大がきの ぬし「松島の 海は わしの ものじゃ。",
             "　からの なかに とじこめて やろう！」"]
        case .datemaru:
            ["ガシャン……ガシャン……",
             "独眼竜の よろい「……この 杜の 都は まおうさまが おさめる。",
             "　七夕の かざりは もどらぬ！」"]
        case .abukumaLord:
            ["ピチョン……ピチョン……",
             "石筍の ぬし「8000万年の いしの ちから、",
             "　とくと あじわうが いい！」"]
        case .tenagaAshinaga:
            ["ドドドドド……！",
             "手長「わしらが 手長足長じゃ。」",
             "足長「わらじは もう はかせんぞ。",
             "　この 山で ふみつぶして くれよう！」"]
        case .yamaderaCicada:
            ["ジジジジジジジ……！",
             "山寺の 大ぜみ「しずけさ なんぞ いらぬ！",
             "　この 山を わしの こえで うめつくして やる！」"]
        case .guardian:
            ["ゴゴゴゴ……",
             "東北の 守護神「……北の ゆうしゃか。",
             "　だが われは まおうの もの。",
             "　蔵王の 樹氷と ともに こおりつくが よい！」",
             "（あやつられた 守護神が おそいかかってきた！）"]
        case .maouShadow:
            ["…………",
             "まおうの かげ「よくぞ ここまで きた。",
             "　北海道も 東北も まだ まおうさまの てのひらの うえ。",
             "　この 恐山で やみに かえるが よい！」"]
        default:
            ["ゴゴゴ……"]
        }
    }

    static func bossDefeated(_ kind: EnemyKind) -> [String] {
        switch kind {
        case .hachirotaro:
            ["八郎太郎を たおした！",
             "八郎太郎「……わしは あやつられて おったのか。",
             "　ねぶたの 火は 八甲田の ゆきおにが もっていった。",
             "　それと……田沢湖の たつこは げんきかのう。」",
             "八郎太郎は 湖の そこへ しずんでいった。",
             "青森の ねぶた師に しらせに いこう。"]
        case .yukioni:
            ["八甲田の ゆきおにを たおした！",
             "ゆきおにが もっていた ねぶたの 火が もどっていく。",
             "青森の 夜空に ねぶたの あかりが ともった！",
             "ねぶた師たちから おれいに",
             "秋田ゆきの 新幹線の きっぷを もらった！",
             "（駅から 秋田県へ いけるように なった）"]
        case .tatsuko:
            ["たつこを たおした！",
             "たつこ「……八郎太郎さまは ぶじなのね。 よかった。",
             "　竿燈の あかりは 男鹿の なまはげ大王が 真山に もっていったわ。」",
             "たつこは るりいろの 湖へ きえていった。",
             "男鹿の なまはげの 長老を たずねよう。"]
        case .namahageKing:
            ["なまはげ大王を たおした！",
             "なまはげ大王「……うおお、めが さめた。 わるがったなぁ。」",
             "秋田の 夜に 竿燈の あかりが もどった！",
             "竿燈の さしてたちから おれいに",
             "岩手ゆきの 新幹線の きっぷを もらった！",
             "（駅から 岩手県へ いけるように なった）"]
        case .ryusendoLord:
            ["ドラゴンブルーを たおした！",
             "地底湖の 水が すきとおった 青に もどっていく。",
             "地底湖の 水を つぼに くんだ。",
             "平泉の 中尊寺の おしょうに とどけよう。"]
        case .mitsuishiOni:
            ["三ツ石の 鬼を たおした！",
             "鬼「まいった！ もう 二度と わるさは しない。",
             "　その しるしに この 岩に 手形を おして いこう。」",
             "鬼は 三ツ石に 手形を のこして 山へ かえっていった。",
             "盛岡に さんさ踊りの たいこが ひびきはじめた！",
             "おれいに 宮城ゆきの 新幹線の きっぷを もらった！",
             "（駅から 宮城県へ いけるように なった）"]
        case .giantOyster:
            ["大がきの ぬしを たおした！",
             "からの なかから ふるい かぎが でてきた。",
             "かぎには 竹に すずめの 紋が ほってある。",
             "瑞巌寺の おしょうに みせに いこう。"]
        case .datemaru:
            ["独眼竜の よろいを たおした！",
             "よろいから くろい もやが ぬけ、しずかに くずれおちた。",
             "仙台の まちに 七夕の かざりが もどった！",
             "おれいに 福島ゆきの 新幹線の きっぷを もらった！",
             "（駅から 福島県へ いけるように なった）"]
        case .abukumaLord:
            ["石筍の ぬしを たおした！",
             "あぶくま洞に しずけさが もどった。",
             "会津の 鶴ヶ城の 城代に しらせに いこう。"]
        case .tenagaAshinaga:
            ["手長足長を たおした！",
             "手長足長は 磐梯山の むこうへ にげていった。",
             "福島の まちに 大わらじが もどった！",
             "おれいに 山形ゆきの 新幹線の きっぷを もらった！",
             "（駅から 山形県へ いけるように なった）"]
        case .yamaderaCicada:
            ["山寺の 大ぜみを たおした！",
             "山寺に しずけさが もどった。",
             "……岩に しみいる 小さな せみの こえだけが きこえる。",
             "山形の 花笠の 師匠に しらせに いこう。"]
        default:
            []
        }
    }
}

extension Errand {
    /// おつかい ぜんぶ。
    static var all: [Errand] { [.aomoriApples, .akitaKiritanpo, .iwateSoba, .miyagiKokeshi, .fukushimaRamen, .yamagataImoni] }
}

extension LostQuest {
    /// 迷子さがし ぜんぶ。
    static var all: [LostQuest] { [.jomonKid, .akitaDog, .zashiki, .sendaiKid, .byakko, .cherryKid] }
}
