import Foundation

// MARK: - 北海道（函館エリア・札幌・小樽・知床）
//
// 地理の勇者 1.4 の 物語を そのまま 移した。印（StoryFlag）の 名前は 1.4 の セーブに
// のこっているので 変えない（"heardFromFisher" など。東北の 印は "aomori.heard" の 形）。
// 函館で 奉行・殿様の 話を きいて 函館山（イカのぬし）→ 駒ヶ岳（駒ヶ岳のぬし）→ ひこうきで 札幌へ。
// 天狗山（天狗）→ オルゴールで 藻岩山（ヒグマのぬし）→ ひこうきで 知床へ。
// 知床岬（トドのぬし）→ カムイの はねで 羅臼岳（知床の守護神）。
// 守護神を 解きはなつと 新函館北斗駅から 新幹線で 東北（青森）へ 行ける（2.0）。

extension StoryFlag {
    static let heardFromFisher: StoryFlag = "heardFromFisher"
    static let hakodateyamaPass: StoryFlag = "hakodateyamaPass"
    static let childFound: StoryFlag = "childFound"
    static let childReturned: StoryFlag = "childReturned"
    static let fisherThanked: StoryFlag = "fisherThanked"
    static let fireCharm: StoryFlag = "fireCharm"
    static let cygnetFound: StoryFlag = "cygnetFound"
    static let cygnetReturned: StoryFlag = "cygnetReturned"
    static let rangerThanked: StoryFlag = "rangerThanked"
    /// 函館エリアの スタンプ（1.4 では 地方が 函館だけ だったころの 名前）。
    static let stampHalf: StoryFlag = "stampHalf"
    static let stampAll: StoryFlag = "stampAll"
    static let musicBox: StoryFlag = "musicBox"
    static let ramenCarrying: StoryFlag = "ramenCarrying"
    static let ramenDelivered: StoryFlag = "ramenDelivered"
    static let ramenThanked: StoryFlag = "ramenThanked"
    static let catFound: StoryFlag = "catFound"
    static let catReturned: StoryFlag = "catReturned"
    static let sapporoStampHalf: StoryFlag = "sapporoStampHalf"
    static let sapporoStampAll: StoryFlag = "sapporoStampAll"
    static let kamuiFeather: StoryFlag = "kamuiFeather"
    static let milkCarrying: StoryFlag = "milkCarrying"
    static let milkDelivered: StoryFlag = "milkDelivered"
    static let milkThanked: StoryFlag = "milkThanked"
    static let foxFound: StoryFlag = "foxFound"
    static let foxReturned: StoryFlag = "foxReturned"
    static let shiretokoStampHalf: StoryFlag = "shiretokoStampHalf"
    static let shiretokoStampAll: StoryFlag = "shiretokoStampAll"
    static let ticketToSapporo: StoryFlag = "ticketToSapporo"
    static let ticketToShiretoko: StoryFlag = "ticketToShiretoko"

    /// 北海道の 印 ぜんぶ（テストと せりふの 洗い出しに 使う）。
    static let hokkaido: [StoryFlag] = [
        .heardFromFisher, .hakodateyamaPass, .childFound, .childReturned, .fisherThanked, .fireCharm,
        .cygnetFound, .cygnetReturned, .rangerThanked, .stampHalf, .stampAll, .musicBox, .ramenCarrying,
        .ramenDelivered, .ramenThanked, .catFound, .catReturned, .sapporoStampHalf, .sapporoStampAll,
        .kamuiFeather, .milkCarrying, .milkDelivered, .milkThanked, .foxFound, .foxReturned,
        .shiretokoStampHalf, .shiretokoStampAll, .ticketToSapporo, .ticketToShiretoko,
    ]
}

extension Story {
    static let hokkaidoGates: [StoryFlag: [String]] = [
        .hakodateyamaPass: ["山の いりぐちに さくが ある。",
                            "ばんにん「函館山は いま 立ち入り禁止だ。",
                            "　五稜郭の 奉行さまの てがたを もってきな。」"],
        .fireCharm: ["山の いりぐちから あつい けむりが ふきだしている。",
                     "とても さきへは すすめない。",
                     "（火よけの おふだが あれば……）"],
        .ticketToSapporo: ["かかりいん「札幌ゆきの きっぷを おもちですか？",
                           "　……きっぷが ないと おのせ できません。",
                           "　いまは 駒ヶ岳の けむりで とばない びんも おおくて。」"],
        .musicBox: ["ヒグマの こどもたちが 道を ふさいでいて とおれない。",
                    "（しずかな 音色で なだめられたら……）"],
        .kamuiFeather: ["もうれつな ふぶきで まえが 見えない。",
                        "とても 山へは 入れない。",
                        "（カムイの ちからが あれば……）"],
        .ticketToShiretoko: ["かかりいん「知床ゆきの きっぷを おもちですか？",
                             "　……きっぷが ないと おのせ できません。」"],
    ]

    /// 手形の仕組みより前のセーブで、もう ぬしを倒している人を 山の前で止めないため。
    /// きっぷは ボスを倒すと もらえるので、印を立てずに ここで決める。
    static let hokkaidoImplications: [StoryFlag: EnemyKind] = [
        .hakodateyamaPass: .squidLord,
        .fireCharm: .komaLord,
        .ticketToSapporo: .komaLord,
        .ticketToShiretoko: .bearLord,
        .musicBox: .bearLord,
        .kamuiFeather: .guardian,
    ]

    /// 北海道の 長老の 助言。守護神を 解きはなって 東北へ わたったら nil（東北の 助言に うつる）。
    static func hokkaidoHint(_ p: StoryProgress) -> [String]? {
        let bosses = p.defeatedBosses
        if !p.has(.hakodateyamaPass) {
            return ["ちょうろう「函館山は 奉行所が とじておる。",
                    "　五稜郭の 奉行に あかしを みせれば ひらくはずじゃ。",
                    "　五稜郭は 街の 北。 港の ものが なにか 見たらしいぞ。」"]
        }
        if !bosses.contains(.squidLord) {
            return ["ちょうろう「ぬしとの たたかいでは ちしきの チャンスが よく くる。",
                    "　函館の ことを よく しっておけば おいうちが きまるはずじゃ。",
                    "　街の ものの はなしを きいておくのじゃぞ。」"]
        }
        if !p.has(.fireCharm) {
            return ["ちょうろう「よくぞ ぬしを たおした。",
                    "　つぎは 駒ヶ岳じゃが、火よけの おふだが いる。",
                    "　松前の 殿様を たずねよ。 函館湾を まわった 西の はてじゃ。」"]
        }
        if !bosses.contains(.komaLord) {
            return ["ちょうろう「駒ヶ岳は 大沼の 北じゃ。",
                    "　大沼の ものの はなしを きいておけば",
                    "　ちしきの チャンスで おいうちが きまるぞ。」"]
        }
        if !bosses.contains(.tengu), !p.has(.musicBox) {
            return ["ちょうろう「札幌の 赤れんが庁舎の 長官を たずねよ。",
                    "　小樽の 天狗山には 天狗が おる。",
                    "　小樽の ことを しっておけば ちしきで おいうちが きまるぞ。」"]
        }
        if !p.has(.musicBox) {
            return ["ちょうろう「天狗を こらしめたか。",
                    "　小樽の オルゴール職人に しらせて やるのじゃ。」"]
        }
        if !bosses.contains(.bearLord) {
            return ["ちょうろう「藻岩山は 札幌の 南西じゃ。",
                    "　札幌の ものの はなしを きいておくのじゃぞ。」"]
        }
        if !p.has(.kamuiFeather) {
            return ["ちょうろう「知床では 羅臼の エカシを たずねよ。",
                    "　羅臼は 中標津から 東の 海ぞいを いった さきじゃ。",
                    "　トドのぬしは 知床岬の ほらあなに おる。」"]
        }
        if !bosses.contains(.guardian) {
            return ["ちょうろう「のこるは 羅臼岳の 守護神。",
                    "　はげしい ふぶきを おこす。",
                    "　知床の ことを よく しり、HPに よゆうを もって いどむのじゃ。」"]
        }
        if !p.has(.aomoriHeard) {
            return ["ちょうろう「よくぞ 北海道の 守護神を 解きはなった。",
                    "　じゃが 海の むこうの 東北でも まおうが まつりの 火を けしたと いう。",
                    "　函館エリアの 新函館北斗駅から 新幹線で 青森へ ゆけ。",
                    "　青森に ついたら ねぶたの家の ねぶた師に 話を きくのじゃ。」"]
        }
        return nil
    }

    static func hokkaidoBossGreeting(_ kind: EnemyKind) -> [String]? {
        switch kind {
        case .squidLord:
            ["シュルルル……",
             "イカのぬし「みなとの さかなは わたしのものだ。",
             "　すみで まっくろに してやろう！」"]
        case .komaLord:
            ["ヒヒーン……！",
             "駒ヶ岳のぬし「この 山の 火は わたしのものだ。",
             "　ひこうきも 人も 近づけさせぬ！」"]
        case .tengu:
            ["ヒュウウ……",
             "天狗「わっはっは！ この オルゴールの 音は わしの ものじゃ。",
             "　うちわの かぜで ふきとばしてくれる！」"]
        case .todoLord:
            ["オウッ オウッ……！",
             "トドのぬし「この はねは わたさんぞ。",
             "　つめたい 海の そこへ しずめてくれる！」"]
        case .bearLord:
            ["グオオオ……",
             "ヒグマのぬし「この山は とおさん。",
             "　まおうさまの じゃまは させん！」"]
        case .guardian:
            ["ゴゴゴ……",
             "知床の守護神「……ちが、ながれて いる な。",
             "　だが われは まおうの もの。",
             "　ふぶきの なかで ねむるが よい！」",
             "（あやつられた 守護神が おそいかかってきた！）"]
        default: nil
        }
    }

    static func hokkaidoBossDefeated(_ kind: EnemyKind) -> [String]? {
        switch kind {
        case .squidLord:
            ["イカのぬしを たおした！",
             "みなとに さかなが もどってきた。",
             "五稜郭の 奉行に しらせに いこう。"]
        case .komaLord:
            ["駒ヶ岳のぬしを たおした！",
             "山の けむりが おさまり、空が はれていく。",
             "大沼の ひとびとから おれいに",
             "札幌ゆきの ひこうきの きっぷを もらった！",
             "函館の 東の 函館空港から とべる。"]
        case .tengu:
            ["天狗を たおした！",
             "天狗は うちわを おとして 山の おくへ にげていった。",
             "とられた オルゴールも おちている。",
             "小樽の オルゴール職人に しらせに いこう。"]
        case .todoLord:
            ["トドのぬしを たおした！",
             "トドのぬしは 海へ にげていった。",
             "あとに 大きな はねが のこっている。",
             "羅臼の エカシに しらせに いこう。"]
        case .bearLord:
            ["ヒグマのぬしを たおした！",
             "藻岩山に しずけさが もどった。",
             "札幌の ひとびとから おれいに",
             "知床ゆきの ひこうきの きっぷを もらった！",
             "南東の 新千歳空港から とべる。"]
        case .guardian:
            ["知床の守護神を たおした！",
             "守護神の まわりの ふぶきが はれていく……",
             "知床の守護神「……われに かえった。 れいを いう、北の ゆうしゃよ。",
             "　まおうの かげは 海を わたり、東北へ のがれた。",
             "　東北の 守護神も あやつられて おるはずじゃ。」",
             "北海道に へいわが もどった！",
             "ひとびとから おれいに 東北ゆきの 新幹線の きっぷを もらった！",
             "（函館エリアの 新函館北斗駅から 青森へ いけるように なった）"]
        default: nil
        }
    }



    /// 案内所の 場面。半分で ハスカップ、ぜんぶで ゴールド。
    static func hokkaidoStampScene(_ region: Region, _ p: StoryProgress,
                                   half halfFlag: StoryFlag, all allFlag: StoryFlag, towns: String) -> StoryScene {
        let total = World.stampTotal(in: region)
        let half = (total + 1) / 2
        let stamps = p.stamps[region, default: 0]
        let area = region.banner.name
        if p.has(allFlag) {
            return StoryScene(lines: [
                "あんないじょ「\(area)の 名所を ぜんぶ まわるなんて！",
                "　あなたは りっぱな めいしょ はかせね。」",
            ])
        }
        if stamps >= total {
            return StoryScene(lines: [
                "あんないじょ「まあ！ スタンプが \(total)こ ぜんぶ そろってる！",
                "　これは めいしょ はかせへの ごほうびよ。」",
                "200ゴールドを てにいれた！",
            ], gold: 200, sets: [halfFlag, allFlag])
        }
        if stamps >= half, !p.has(halfFlag) {
            return StoryScene(lines: [
                "あんないじょ「スタンプが \(stamps)こ！ もう 半分ね。",
                "　たびの おともに どうぞ。 のこりも がんばって！」",
                "ハスカップを 3つ てにいれた！",
            ], items: [.herb, .herb, .herb], sets: [halfFlag])
        }
        return StoryScene(lines: [
            "あんないじょ「ようこそ \(area)へ！ 名所の かんばんを よむと",
            "　めいしょ スタンプが たまるの。 \(towns)に あるわ。",
            "　いま \(stamps)こ ／ \(total)こ。 \(half)こで ハスカップ、",
            "　ぜんぶ そろえば 200ゴールド あげる！」",
        ])
    }
}

extension Resident {
    /// 北海道の 人。
    static let hokkaido: [Resident] = [
        .magistrate, .fisherBoss, .mother, .lostChild, .childAtHome, .portKid, .guide, .sapporoGuide, .governor,
        .ramenChef, .student, .musicBoxMaker, .lostCat, .catHome, .catOwner, .yumori, .kappa, .ekashi, .rancher,
        .banyaOyaji, .foxRanger, .lostFox, .foxHome, .shiretokoGuide, .lord, .ranger, .swanKeeper, .lostCygnet,
        .cygnetHome,
    ]

    /// 北海道の 迷子は 見つけると 消え、家に もどった すがたが 出る。北海道の 人で なければ nil。
    func hokkaidoPresence(_ p: StoryProgress) -> Bool? {
        switch self {
        case .lostChild: !p.has(.childFound)
        case .childAtHome: p.has(.childFound)
        case .lostCygnet: !p.has(.cygnetFound)
        case .cygnetHome: p.has(.cygnetFound)
        case .lostCat: !p.has(.catFound)
        case .catHome: p.has(.catFound)
        case .lostFox: !p.has(.foxFound)
        case .foxHome: p.has(.foxFound)
        default: nil
        }
    }

    var hokkaidoSprite: SpriteID? {
        switch self {
        case .magistrate, .lord, .governor: .magistrate
        case .ekashi: .elder
        case .fisherBoss, .ranger, .ramenChef, .yumori, .musicBoxMaker, .rancher, .banyaOyaji: .fisherman
        case .lostChild, .childAtHome, .portKid, .student: .child
        case .mother, .guide, .sapporoGuide, .shiretokoGuide, .swanKeeper, .catOwner, .foxRanger: .villager
        case .lostFox, .foxHome: .fox
        case .lostCygnet, .cygnetHome: .cygnet
        case .lostCat, .catHome: .cat
        case .kappa: .kappa
        default: nil
        }
    }

    func hokkaidoScene(_ p: StoryProgress) -> StoryScene? {
        let squidGone = p.defeatedBosses.contains(.squidLord)
        switch self {
        case .magistrate:
            if p.defeatedBosses.contains(.komaLord) {
                return StoryScene(lines: [
                    "ぶぎょう「駒ヶ岳の けむりも おさまった。 みごとじゃ。",
                    "　札幌ゆきの ひこうきは 街の 東の 函館空港から でる。",
                    "　北の 札幌でも ようすが おかしいと いう。 たのんだぞ。」",
                ])
            }
            if squidGone {
                return StoryScene(lines: [
                    "ぶぎょう「みごとじゃ。 みなとに イカが もどったと きいた。",
                    "　だが 北の 駒ヶ岳が けむりを ふき、ひこうきも とばぬ。",
                    "　山へ 入るには 火よけの おふだが いる。",
                    "　松前の 殿様が もっておられる。 松前は 西の はてじゃ。」",
                ])
            }
            if p.has(.hakodateyamaPass) {
                return StoryScene(lines: [
                    "ぶぎょう「てがたを みせれば 山の ばんにんが とおす。",
                    "　函館山は 街の みなみ、海ぞいの 道の さきじゃ。」",
                ])
            }
            if p.has(.heardFromFisher) {
                return StoryScene(lines: [
                    "ぶぎょう「……この まっくろな すみ。 まことで あったか。",
                    "　よかろう。 函館山へ 入る てがたを さずける。",
                    "　ぬしを たおし、みなとを とりもどしてくれ。」",
                    "函館山の てがたを てにいれた！",
                ], sets: [.hakodateyamaPass])
            }
            return StoryScene(lines: [
                "ぶぎょう「わしは この 五稜郭の 奉行じゃ。",
                "　函館山に ばけものが でたと いうが、 まことか？",
                "　たしかな あかしが なければ 山は ひらけぬ。",
                "　みなとの 親方が なにか 見たと きく。」",
            ])

        case .fisherBoss:
            if squidGone {
                if p.has(.fisherThanked) {
                    return StoryScene(lines: [
                        "おやかた「今夜は イカそうめんで おいわいだ！",
                        "　函館の イカは すきとおってて うまいんだぞ。」",
                    ])
                }
                return StoryScene(lines: [
                    "おやかた「おう！ イカが みなとに もどってきたぞ！",
                    "　これは 漁師 みんなからの おれいだ。」",
                    "60ゴールドを てにいれた！",
                ], gold: 60, sets: [.fisherThanked])
            }
            if p.has(.heardFromFisher) {
                return StoryScene(lines: [
                    "おやかた「その すみを 五稜郭の 奉行さまに みせな。",
                    "　五稜郭は 街の 北。 星の かたちの 堀が めじるしだ。」",
                ])
            }
            return StoryScene(lines: [
                "おやかた「ゆうしゃ だと？ ……なら きいてくれ。",
                "　夜の 海で、函館山の ほうへ およぐ",
                "　ばかでかい イカの かげを 見たんだ。",
                "　あみに のこってた この すみが あかしだ。",
                "　奉行さまに みせりゃ 山を あけてくれるだろう。」",
                "イカのぬしの すみを あずかった。",
            ], sets: [.heardFromFisher])

        case .mother:
            if p.has(.childReturned) {
                return StoryScene(lines: [
                    "おかあさん「この子ったら、八幡坂の 上から",
                    "　みなとを ながめるのが すきなのよ。」",
                ])
            }
            if p.has(.childFound) {
                return StoryScene(lines: [
                    "おかあさん「ああ、ぶじで よかった！",
                    "　みつけて くれて ありがとう。 これを どうぞ。」",
                    "ハスカップを 2つ てにいれた！",
                ], items: [.herb, .herb], sets: [.childReturned])
            }
            return StoryScene(lines: [
                "おかあさん「むすこが どこにも いないの。",
                "　元町の 坂で あそぶって いってたのに……",
                "　元町は 街の 南、函館山の ふもとよ。」",
            ])

        case .lostChild:
            return StoryScene(lines: [
                "まいごの こども「ママと はぐれちゃった……",
                "　え？ 朝市で まってるの？ ありがとう！」",
                "こどもは 朝市の ほうへ はしっていった。",
            ], sets: [.childFound])

        case .childAtHome:
            return StoryScene(lines: [
                "こども「坂の 上から みなとが ぜんぶ 見えるんだよ！",
                "　こんどは ママと いっしょに いくんだ。」",
            ])

        case .portKid:
            if squidGone {
                return StoryScene(lines: [
                    "こども「イカが みなとに もどってきた！",
                    "　ゆうしゃさま、ありがとう！」",
                ])
            }
            return StoryScene(lines: [
                "こども「みなとに イカが よりつかなくなっちゃった。",
                "　イカは 函館の 市の さかな なのに！」",
            ])

        case .guide:
            return Story.hokkaidoStampScene(.hakodate, p, half: .stampHalf, all: .stampAll,
                                   towns: "函館・松前・大沼")

        case .sapporoGuide:
            return Story.hokkaidoStampScene(.sapporo, p, half: .sapporoStampHalf, all: .sapporoStampAll,
                                   towns: "札幌・小樽・定山渓")

        case .lord:
            if p.defeatedBosses.contains(.komaLord) {
                return StoryScene(lines: [
                    "とのさま「駒ヶ岳の ぬしを しずめたか。 あっぱれじゃ。",
                    "　春には 城の さくらを 見に まいれ。",
                    "　松前の さくらは 250しゅるいも あるのじゃぞ。」",
                ])
            }
            if p.has(.fireCharm) {
                return StoryScene(lines: [
                    "とのさま「おふだを もって 駒ヶ岳へ ゆけ。",
                    "　駒ヶ岳は 大沼の 北じゃ。 函館から 北へ のぼれ。」",
                ])
            }
            if squidGone {
                return StoryScene(lines: [
                    "とのさま「そなたが イカのぬしを たおした ゆうしゃか。",
                    "　この 松前藩に つたわる 火よけの おふだを さずける。",
                    "　駒ヶ岳の ぬしを しずめてくれ。」",
                    "火よけの おふだを てにいれた！",
                ], sets: [.fireCharm])
            }
            return StoryScene(lines: [
                "とのさま「わしは 松前藩の 殿様じゃ。",
                "　この 松前城は 北海道で ただ ひとつの 日本式の 城よ。",
                "　……函館山の ばけものも たおせぬ ものに 用は ない。」",
            ])

        case .ranger:
            if p.defeatedBosses.contains(.komaLord) {
                if p.has(.rangerThanked) {
                    return StoryScene(lines: [
                        "やまもり「駒ヶ岳が しずかに なった。",
                        "　あの 山は うまの かたちに 見えるから 駒ヶ岳と いうんだ。」",
                    ])
                }
                return StoryScene(lines: [
                    "やまもり「ぬしを たおしたのか！ これで 大沼も あんしんだ。",
                    "　みんなから あつめた おれいだ。 うけとってくれ。」",
                    "90ゴールドを てにいれた！",
                ], gold: 90, sets: [.rangerThanked])
            }
            if p.has(.fireCharm) {
                return StoryScene(lines: [
                    "やまもり「おお、火よけの おふだ！ それなら 山へ 入れる。",
                    "　駒ヶ岳の ほらあなは 湖の 北東だ。 あつさに 気をつけろ。」",
                ])
            }
            return StoryScene(lines: [
                "やまもり「駒ヶ岳に ぬしが すみついて 山が けむりを ふいてる。",
                "　あつくて だれも 近づけねえ。",
                "　松前の 殿様の 火よけの おふだでも なけりゃ むりだ。」",
            ])

        case .swanKeeper:
            if p.has(.cygnetReturned) {
                return StoryScene(lines: [
                    "せわがかり「冬に なると ハクチョウが シベリアから",
                    "　大沼へ わたってくるのよ。 ひなも げんきに そだってるわ。」",
                ])
            }
            if p.has(.cygnetFound) {
                return StoryScene(lines: [
                    "せわがかり「ああ、ひなが およいで もどってきた！",
                    "　ありがとう。 これは ほんの おれいよ。」",
                    "70ゴールドを てにいれた！",
                ], gold: 70, sets: [.cygnetReturned])
            }
            return StoryScene(lines: [
                "せわがかり「ハクチョウの ひなが 1わ いないの。",
                "　湖には 126もの 島が あって、はしで つながってるの。",
                "　どこかの 島に いると おもうんだけど……」",
            ])

        case .lostCygnet:
            return StoryScene(lines: [
                "ハクチョウの ひな「ピィ……ピィ……」",
                "ひなは せわがかりの ほうへ およいでいった。",
            ], sets: [.cygnetFound])

        case .cygnetHome:
            return StoryScene(lines: [
                "ハクチョウの ひな「ピィ！」",
                "げんきそうだ。",
            ])
        case .governor:
            if p.defeatedBosses.contains(.bearLord) {
                return StoryScene(lines: [
                    "ちょうかん「藻岩山に しずけさが もどった。 れいを いう。",
                    "　知床ゆきの ひこうきは 南東の 新千歳空港から でる。",
                    "　この 赤れんが庁舎は 明治に たてられた 北海道の 役所なのだ。」",
                ])
            }
            if p.has(.musicBox) {
                return StoryScene(lines: [
                    "ちょうかん「オルゴールを とりもどしたか！",
                    "　その 音色なら ヒグマの こどもたちも しずまるだろう。",
                    "　藻岩山は 街の 南西じゃ。 たのんだぞ。」",
                ])
            }
            return StoryScene(lines: [
                "ちょうかん「わたしは 北海道の 長官だ。",
                "　藻岩山に ヒグマのぬしが すみつき、ヒグマの こどもたちが",
                "　山への 道を ふさいでおる。 ロープウェイも とまったままだ。",
                "　小樽の オルゴールの 音色なら しずめられると きくが……」",
            ])

        case .musicBoxMaker:
            if p.has(.musicBox) {
                return StoryScene(lines: [
                    "しょくにん「その オルゴールの 音は 小樽の じまんさ。",
                    "　ヒグマの こどもたちも きっと ねむってしまうよ。」",
                ])
            }
            if p.defeatedBosses.contains(.tengu) {
                return StoryScene(lines: [
                    "しょくにん「天狗を こらしめて くれたのか！",
                    "　とりもどした オルゴールを もっていってくれ。",
                    "　藻岩山の ヒグマの こどもたちを しずめるんだろう？」",
                    "オルゴールを てにいれた！",
                ], sets: [.musicBox])
            }
            return StoryScene(lines: [
                "しょくにん「ここは オルゴール堂。 いちばんの オルゴールを",
                "　天狗山の 天狗に うばわれて しまったんだ！",
                "　天狗山は 街の 南。 あの 天狗は うちわの かぜが おそろしいぞ。」",
            ])

        case .ramenChef:
            if p.has(.ramenThanked) {
                return StoryScene(lines: [
                    "おやじ「札幌の みそラーメンは 寒い 冬に あったまる。",
                    "　この すすきのの 横丁から ひろまったんだぞ。」",
                ])
            }
            if p.has(.ramenDelivered) {
                return StoryScene(lines: [
                    "おやじ「とどけて くれたか！ のびる まえに ありがとうよ。",
                    "　これは 出前の おだちんだ。」",
                    "90ゴールドを てにいれた！",
                ], gold: 90, sets: [.ramenThanked])
            }
            if p.has(.ramenCarrying) {
                return StoryScene(lines: [
                    "おやじ「はやく 北大へ たのむぜ！ のびちまう！",
                    "　北大は 街の 北、ポプラ並木の むこうだ。」",
                ])
            }
            return StoryScene(lines: [
                "おやじ「いいところに きた！ 北大の 学生に 出前を たのまれてな。",
                "　名物の みそラーメン、とどけて くれないか？",
                "　北大は 街の 北の はしだ。」",
                "みそラーメンを あずかった。",
            ], sets: [.ramenCarrying])

        case .student:
            if p.has(.ramenCarrying), !p.has(.ramenDelivered) {
                return StoryScene(lines: [
                    "がくせい「わあ、みそラーメン！ まってました！",
                    "　おやじさんに よろしく つたえてね。」",
                    "みそラーメンを とどけた。",
                ], sets: [.ramenDelivered])
            }
            return StoryScene(lines: [
                "がくせい「北大の はじめの 先生は クラーク博士。",
                "　『少年よ 大志を いだけ』って ことばを のこしたんだ。」",
            ])

        case .catOwner:
            if p.has(.catReturned) {
                return StoryScene(lines: [
                    "かいぬし「ミケは 運河ぞいの 倉庫が すきなのよ。",
                    "　むかしは ニシンを はこぶ 船で にぎわってたんですって。」",
                ])
            }
            if p.has(.catFound) {
                return StoryScene(lines: [
                    "かいぬし「ミケ！ かえってきたのね！",
                    "　ほんとうに ありがとう。 これ、うけとって。」",
                    "ハスカップを 2つ てにいれた！",
                ], items: [.herb, .herb], sets: [.catReturned])
            }
            return StoryScene(lines: [
                "かいぬし「うちの ネコの ミケが いないの。",
                "　運河の むこうの 倉庫の ほうへ いったみたい……」",
            ])

        case .lostCat:
            return StoryScene(lines: [
                "ネコ「ニャー。」",
                "ネコは かいぬしの ほうへ かけていった。",
            ], sets: [.catFound])

        case .catHome:
            return StoryScene(lines: [
                "ネコ「ニャーン。」",
                "まんぞくそうに のどを ならしている。",
            ])

        case .yumori:
            return StoryScene(lines: [
                "ゆもり「定山渓の 足湯で ひとやすみ していきな。」",
                "あたたかい 温泉に 足を ひたした。",
                "HPと MPが ぜんぶ かいふくした！",
            ], heals: true)

        case .kappa:
            return StoryScene(lines: [
                "かっぱ「ケケッ。 おいらは 定山渓の かっぱさ。",
                "　むかし この 川に すむ かっぱが わかものを",
                "　ひきこんだって 伝説が あるんだ。 ……おいらじゃ ないよ？」",
            ])
        case .shiretokoGuide:
            return Story.hokkaidoStampScene(.shiretoko, p, half: .shiretokoStampHalf, all: .shiretokoStampAll,
                                   towns: "中標津・ウトロ・羅臼")

        case .ekashi:
            if p.has(.kamuiFeather) {
                return StoryScene(lines: [
                    "エカシ「はねを もって 羅臼岳へ ゆけ。 ふぶきは はれよう。",
                    "　守護神は はげしい ふぶきを おこす。",
                    "　知床の ことを よく しり、HPに よゆうを もって いどむのじゃ。」",
                ])
            }
            if p.defeatedBosses.contains(.todoLord) {
                return StoryScene(lines: [
                    "エカシ「トドのぬしを たおしたか！",
                    "　これが コタンコロカムイ……村を まもる シマフクロウの はねじゃ。",
                    "　これで 羅臼岳の ふぶきを はらえる。」",
                    "カムイの はねを てにいれた！",
                ], sets: [.kamuiFeather])
            }
            return StoryScene(lines: [
                "エカシ「わしは この 地の エカシ（長老）じゃ。",
                "　知床は アイヌの ことばで シリエトク……『ちの はて』の いみ。",
                "　羅臼岳は まおうの ふぶきに とざされ、守護神も とらわれた。",
                "　ふぶきを はらうには コタンコロカムイの はねが いる。",
                "　はねは 知床岬の ほらあなの トドのぬしが うばっていった。",
                "　岬へは ウトロから 海ぞいの 道を 北へ すすむのじゃ。」",
            ])

        case .rancher:
            if p.has(.milkThanked) {
                return StoryScene(lines: [
                    "ぼくじょうぬし「中標津は 酪農の 町。",
                    "　牛の かずが 人より おおいんだぞ。」",
                ])
            }
            if p.has(.milkDelivered) {
                return StoryScene(lines: [
                    "ぼくじょうぬし「番屋に とどけて くれたか！ たすかったよ。",
                    "　これは おれいだ。」",
                    "120ゴールドを てにいれた！",
                ], gold: 120, sets: [.milkThanked])
            }
            if p.has(.milkCarrying) {
                return StoryScene(lines: [
                    "ぼくじょうぬし「牛乳は 羅臼の 番屋へ たのむよ。",
                    "　羅臼は 東の 海ぞいを ずっと いった さきだ。」",
                ])
            }
            return StoryScene(lines: [
                "ぼくじょうぬし「たびの ひとかい？ ひとつ たのまれて くれないか。",
                "　羅臼の 番屋の おやじに しぼりたての 牛乳を とどけてほしいんだ。」",
                "牛乳を あずかった。",
            ], sets: [.milkCarrying])

        case .banyaOyaji:
            if p.has(.milkCarrying), !p.has(.milkDelivered) {
                return StoryScene(lines: [
                    "ばんやの おやじ「中標津の 牛乳か！ ありがてえ。",
                    "　牧場の あいつに よろしく いっといてくれ。」",
                    "牛乳を とどけた。",
                ], sets: [.milkDelivered])
            }
            return StoryScene(lines: [
                "ばんやの おやじ「羅臼の こんぶは だしの 王さまよ。",
                "　はれた 日には 海の むこうの 国後島も よく 見えるぞ。」",
            ])

        case .foxRanger:
            if p.has(.foxReturned) {
                return StoryScene(lines: [
                    "レンジャー「キタキツネに たべものを あげちゃ だめよ。",
                    "　知床は 世界自然遺産。 どうぶつたちの すみかなの。」",
                ])
            }
            if p.has(.foxFound) {
                return StoryScene(lines: [
                    "レンジャー「キツネの子が もどってきた！ ありがとう。",
                    "　これ、たびに やくだてて。」",
                    "ハスカップを 3つ てにいれた！",
                ], items: [.herb, .herb, .herb], sets: [.foxReturned])
            }
            return StoryScene(lines: [
                "レンジャー「ほごしていた キツネの子が いなくなったの。",
                "　知床五湖の 木道の おくの ほうへ いったみたい……」",
            ])

        case .lostFox:
            return StoryScene(lines: [
                "キツネの子「コンコン……」",
                "キツネの子は レンジャーの ほうへ かけていった。",
            ], sets: [.foxFound])

        case .foxHome:
            return StoryScene(lines: [
                "キツネの子「コン！」",
                "しっぽを ふっている。",
            ])
        default:
            return nil
        }
    }
}


extension QuizBank {
    /// 北海道の 問題（1.4 と おなじ）。定山渓の 問題は 札幌、中標津の 問題は 羅臼の 山に まぜてある。
    static let hokkaido: [MapID: [Quiz]] = [
        .hakodate: [
            Quiz(question: "函館山から 見る 名物は？", choices: ["りゅうひょう", "やけい", "おはなばたけ"], answer: 1),
            Quiz(question: "函館にある 星のかたちの 城あとは？", choices: ["五稜郭", "首里城", "大阪城"], answer: 0),
            Quiz(question: "函館の みなとが めんする 海峡は？", choices: ["関門海峡", "宗谷海峡", "津軽海峡"], answer: 2),
            Quiz(question: "函館の 市の さかな は？", choices: ["サケ", "イカ", "タイ"], answer: 1),
            Quiz(question: "函館と 青森を むすんでいた 船は？", choices: ["青函連絡船", "黒船", "宝船"], answer: 0),
            Quiz(question: "函館が ある 半島は？", choices: ["知床半島", "積丹半島", "渡島半島"], answer: 2),
            // 街の看板で 読める問題。歩きまわった ごほうびに なる。
            Quiz(question: "函館の みなとに ならぶ 明治の 倉庫は？", choices: ["時計台", "五稜郭", "赤レンガ倉庫"], answer: 2),
            Quiz(question: "函館で 朝に ひらかれる 市場は？", choices: ["夜市", "朝市", "のみの市"], answer: 1),
        ],
        .matsumae: [
            Quiz(question: "北海道で ただ ひとつの 日本式の 城は？", choices: ["五稜郭", "松前城", "姫路城"], answer: 1),
            Quiz(question: "松前が 名所として しられる 花は？", choices: ["さくら", "ラベンダー", "ひまわり"], answer: 0),
            Quiz(question: "江戸時代に 松前を おさめていた 藩は？", choices: ["薩摩藩", "加賀藩", "松前藩"], answer: 2),
            Quiz(question: "スルメと こんぶで つくる 松前の つけものは？", choices: ["松前漬け", "野沢菜漬け", "奈良漬け"], answer: 0),
            Quiz(question: "日本海を 行き来して 荷を はこんだ 船は？", choices: ["青函連絡船", "北前船", "黒船"], answer: 1),
            Quiz(question: "北海道の いちばん 南の みさきは？", choices: ["宗谷岬", "襟裳岬", "白神岬"], answer: 2),
        ],
        .onuma: [
            Quiz(question: "大沼から 見える 火山は？", choices: ["駒ヶ岳", "富士山", "桜島"], answer: 0),
            Quiz(question: "駒ヶ岳の 名前の もとに なった どうぶつは？", choices: ["くま", "うま", "うし"], answer: 1),
            Quiz(question: "大沼の 名物の おかしは？", choices: ["もみじまんじゅう", "八ツ橋", "大沼だんご"], answer: 2),
            Quiz(question: "日本で はじめて 西洋りんごを そだてた 町は？", choices: ["七飯", "弘前", "松前"], answer: 0),
            Quiz(question: "大沼に うかぶ 島の かずは？", choices: ["12", "126", "1260"], answer: 1),
            Quiz(question: "冬に 大沼へ わたってくる 鳥は？", choices: ["ツバメ", "ペンギン", "ハクチョウ"], answer: 2),
        ],
        .sapporo: [
            Quiz(question: "札幌の まちなかに ある 白い 木の たてものは？", choices: ["五稜郭", "時計台", "赤レンガ倉庫"], answer: 1),
            Quiz(question: "冬の 札幌で ひらかれる まつりは？", choices: ["雪まつり", "ねぶた祭", "祇園祭"], answer: 0),
            Quiz(question: "札幌で 生まれた 名物の ラーメンは？", choices: ["とんこつ", "しょうゆ", "みそ"], answer: 2),
            Quiz(question: "札幌の まんなかを 東西に のびる 公園は？", choices: ["大通公園", "上野公園", "奈良公園"], answer: 0),
            Quiz(question: "札幌の 夜景が 見える 山は？", choices: ["函館山", "藻岩山", "羅臼岳"], answer: 1),
            Quiz(question: "「少年よ 大志を いだけ」と いった 博士は？", choices: ["ペリー", "ザビエル", "クラーク"], answer: 2),
            Quiz(question: "明治に たてられた 北海道の 役所の たてものは？", choices: ["赤れんが庁舎", "五稜郭", "松前城"], answer: 0),
            // 定山渓で 聞ける問題。
            Quiz(question: "定山渓の 川に すむと いわれる いきものは？", choices: ["てんぐ", "かっぱ", "りゅう"], answer: 1),
            Quiz(question: "定山渓は なにで 有名な 町？", choices: ["砂丘", "流氷", "温泉"], answer: 2),
        ],
        .otaru: [
            Quiz(question: "小樽の まちなかを ながれる 古い 水の みちは？", choices: ["運河", "お堀", "滝"], answer: 0),
            Quiz(question: "小樽の 名物の こうげいひんは？", choices: ["うるし", "ガラス", "やきもの"], answer: 1),
            Quiz(question: "むかし 小樽を にぎわせた さかなは？", choices: ["マグロ", "カツオ", "ニシン"], answer: 2),
            Quiz(question: "小樽の 南に そびえる 山は？", choices: ["天狗山", "函館山", "羅臼岳"], answer: 0),
            Quiz(question: "小樽の オルゴール堂で ならぶ ものは？", choices: ["ちょうちん", "オルゴール", "こけし"], answer: 1),
            Quiz(question: "銀行が ならび「北の ウォール街」と よばれた 町は？", choices: ["松前", "羅臼", "小樽"], answer: 2),
        ],
        .rausu: [
            Quiz(question: "羅臼の 名物の 海そうは？", choices: ["わかめ", "こんぶ", "のり"], answer: 1),
            Quiz(question: "羅臼の 海で 見られる 大きな いきものは？", choices: ["シャチ", "ジンベエザメ", "ウミガメ"], answer: 0),
            Quiz(question: "「知床」は アイヌの ことばで どんな いみ？", choices: ["はなの みやこ", "ひの いずる くに", "ちの はて"], answer: 2),
            Quiz(question: "羅臼の 海の むこうに 見える 島は？", choices: ["佐渡島", "国後島", "屋久島"], answer: 1),
            Quiz(question: "中標津の 開陽台で 見えると いわれるのは？", choices: ["地球の まるみ", "富士山", "桜島"], answer: 0),
            Quiz(question: "中標津で さかんな しごとは？", choices: ["みかんづくり", "茶づくり", "酪農"], answer: 2),
        ],
        .utoro: [
            Quiz(question: "知床が えらばれた ものは？", choices: ["世界文化遺産", "世界自然遺産", "日本三景"], answer: 1),
            Quiz(question: "冬に 知床の 海へ ながれつく ものは？", choices: ["りゅうひょう", "やけい", "さくら"], answer: 0),
            Quiz(question: "知床半島の 北に ひろがる 海は？", choices: ["日本海", "瀬戸内海", "オホーツク海"], answer: 2),
            Quiz(question: "ウトロの ちかくに ある 5つの 湖は？", choices: ["富士五湖", "知床五湖", "大沼"], answer: 1),
            Quiz(question: "ウトロの ちかくで 海ぞいに おちる 滝は？", choices: ["オシンコシンの滝", "華厳の滝", "那智の滝"], answer: 0),
            Quiz(question: "ウトロの 港に そびえる 大きな 岩は？", choices: ["夫婦岩", "立岩", "オロンコ岩"], answer: 2),
        ],
    ]
}

extension TownInfo {
    /// みなとの街。旅のはじめなので 安く、そろえも いちばん下。
    static let hakodate = TownInfo(name: "函館", reading: "はこだて", tagline: "みなとの 街",
                                   innBase: 2, innPerLevel: 3,
                                   stock: [.herb, .ikameshi, .squidSpear, .copperSword, .scallopPlate, .leatherArmor])
    /// 城と さくらの 町。函館の つぎに たずねる。
    static let matsumae = TownInfo(name: "松前", reading: "まつまえ", tagline: "城と さくらの 町",
                                   innBase: 3, innPerLevel: 3,
                                   stock: [.herb, .ikameshi, .copperSword, .katana, .leatherArmor, .samuraiArmor])
    /// 湖の ほとりの 町。駒ヶ岳の ふもと。
    static let onuma = TownInfo(name: "大沼", reading: "おおぬま", tagline: "駒ヶ岳を うつす 湖の 町",
                                innBase: 3, innPerLevel: 4,
                                stock: [.herb, .ikameshi, .dango, .katana, .samuraiArmor])
    /// 大きな街。鋼の剣が ここで買える。
    static let sapporo = TownInfo(name: "札幌", reading: "さっぽろ", tagline: "北の 大きな 街",
                                  innBase: 4, innPerLevel: 5,
                                  stock: [.herb, .misoRamen, .dango, .steelSword, .chainMail])
    /// 運河の みなと町。札幌の となりで、品ぞろえも 札幌と ほぼ同じ。
    static let otaru = TownInfo(name: "小樽", reading: "おたる", tagline: "運河と ガラスの みなと町",
                                innBase: 5, innPerLevel: 5,
                                stock: [.herb, .misoRamen, .steelSword, .glassSword, .chainMail, .herringMail])
    /// 山あいの 温泉街。札幌の 南西、藻岩山の さき。
    static let jozankei = TownInfo(name: "定山渓", reading: "じょうざんけい", tagline: "かっぱの すむ 温泉街",
                                   innBase: 5, innPerLevel: 6,
                                   stock: [.herb, .misoRamen, .onsenTamago, .glassSword, .herringMail])
    /// 酪農の町。知床への 空の入口。
    static let nakashibetsu = TownInfo(name: "中標津", reading: "なかしべつ", tagline: "牧場と 空港の 町",
                                       innBase: 5, innPerLevel: 7,
                                       stock: [.herb, .misoRamen, .milk, .glassSword, .attush])
    /// オホーツク海がわの 知床の 町。知床五湖の 入口。
    static let utoro = TownInfo(name: "ウトロ", reading: "うとろ", tagline: "オホーツクの 知床の 町",
                                innBase: 6, innPerLevel: 7,
                                stock: [.herb, .ikuraDon, .milk, .orcaSpear, .attush, .driftIceArmor])
    /// さいはての町。運ぶのが大変なぶん 宿も品も高い。銅の剣・革の鎧は もう置かない。
    static let rausu = TownInfo(name: "羅臼", reading: "らうす", tagline: "知床の さいはての 町",
                                innBase: 6, innPerLevel: 8,
                                stock: [.herb, .ikuraDon, .milk, .orcaSpear, .driftIceArmor])
}

extension World {
    /// 函館の 長老の すぐ下（はじめから の 場所）。
    static let hakodateStart = Point(x: 18, y: 18)
    /// 函館の 出口の 前（全滅したら ここで 目を さます）。
    static let hakodateGate = Point(x: 15, y: 24)
    static let sapporoGate = Point(x: 15, y: 24)
    static let nakashibetsuGate = Point(x: 12, y: 16)
}
