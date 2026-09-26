import Foundation

/// 物語の進みぐあい。人と話したり 頼まれごとを片づけたりすると 立つ。セーブに残す。
/// ボスを倒したかは `defeatedBosses` のほうで持つ。
enum StoryFlag: String, Codable, CaseIterable {
    /// 港の親方から イカのぬしを見た話を聞き、証拠の すみを あずかった。
    case heardFromFisher
    /// 五稜郭の奉行から 函館山へ入る てがたを もらった。
    case hakodateyamaPass
    /// 元町で 迷子を見つけた（子は母のところへ走っていく）。
    case childFound
    /// 母から 迷子のお礼をもらった。
    case childReturned
    /// イカのぬしを倒したあと、親方から お礼をもらった。
    case fisherThanked
    /// 松前の殿様から 駒ヶ岳へ入る 火よけの おふだを もらった。
    case fireCharm
    /// 大沼で まいごの 白鳥の ひなを 見つけた（ひなは 岸へ およいでいく）。
    case cygnetFound
    /// 白鳥の せわがかりから ひなの お礼をもらった。
    case cygnetReturned
    /// 駒ヶ岳のぬしを倒したあと、大沼の山守から お礼をもらった。
    case rangerThanked
    /// 名所の スタンプを 半分 あつめて、案内所から お礼をもらった。
    case stampHalf
    /// 名所の スタンプを ぜんぶ あつめて、案内所から お礼をもらった。
    case stampAll
    /// 札幌ゆきの ひこうきの きっぷ。駒ヶ岳のぬしを倒すと もらえる。
    case ticketToSapporo
    /// 知床ゆきの ひこうきの きっぷ。藻岩山の ヒグマのぬしを倒すと もらえる。
    case ticketToShiretoko

    /// このボスを倒していれば、立っていなくても 立っていることにする。
    /// 手形の仕組みより前のセーブで、もう ぬしを倒している人を 山の前で止めないため。
    /// きっぷは ボスを倒すと もらえるので、印を立てずに ここで決める。
    var impliedBy: EnemyKind? {
        switch self {
        case .hakodateyamaPass: .squidLord
        case .fireCharm, .ticketToSapporo: .komaLord
        case .ticketToShiretoko: .bearLord
        default: nil
        }
    }

    /// 関所（`Warp.needs`）で止められたときの せりふ。
    var gateLines: [String] {
        switch self {
        case .hakodateyamaPass:
            ["山の いりぐちに さくが ある。",
             "ばんにん「函館山は いま 立ち入り禁止だ。",
             "　五稜郭の 奉行さまの てがたを もってきな。」"]
        case .fireCharm:
            ["山の いりぐちから あつい けむりが ふきだしている。",
             "とても さきへは すすめない。",
             "（火よけの おふだが あれば……）"]
        case .ticketToSapporo:
            ["かかりいん「札幌ゆきの きっぷを おもちですか？",
             "　……きっぷが ないと おのせ できません。",
             "　いまは 駒ヶ岳の けむりで とばない びんも おおくて。」"]
        case .ticketToShiretoko:
            ["かかりいん「知床ゆきの きっぷを おもちですか？",
             "　……きっぷが ないと おのせ できません。」"]
        default:
            ["さきへ すすめない。"]
        }
    }
}

/// どこまで進んだか。話す相手の せりふを決めるのに使う。
struct StoryProgress {
    var flags: Set<StoryFlag>
    var defeatedBosses: Set<EnemyKind>
    /// 押した 名所の スタンプの数（函館エリアの 看板を 読んだ数）。
    var stamps = 0

    func has(_ flag: StoryFlag) -> Bool {
        flags.contains(flag) || flag.impliedBy.map(defeatedBosses.contains) == true
    }
}

/// 話しかけたときに起きること。せりふを出したあと、ごほうびを渡して 印を立てる。
struct StoryScene: Equatable {
    var lines: [String]
    var gold = 0
    var items: [Item] = []
    var sets: [StoryFlag] = []
}

/// 物語にかかわる人。進みぐあいで せりふが変わり、出たり消えたりする。
/// 地図には 数字の印で置く（`GameMap` の `residents`）。
enum Resident: String, CaseIterable {
    /// 五稜郭の奉行。函館山へ入る てがたを出す。
    case magistrate
    /// 港の漁師の親方。イカのぬしを見た。
    case fisherBoss
    /// 朝市で 迷子の子をさがしている母。
    case mother
    /// 元町の坂で 迷子になっている子。見つけると 母のところへ走っていく。
    case lostChild
    /// 母のところへ帰った子。
    case childAtHome
    /// 港の子。イカが もどるのを待っている。
    case portKid
    /// 函館の 観光案内所の人。名所の スタンプを 見て お礼をくれる。
    case guide
    /// 松前の殿様。駒ヶ岳へ入る 火よけの おふだを もつ。
    case lord
    /// 大沼の山守。駒ヶ岳の ようすを 教える。
    case ranger
    /// 大沼の 白鳥の せわがかり。まいごの ひなを さがしている。
    case swanKeeper
    /// 湖の 島で まいごになっている 白鳥の ひな。見つけると 岸へ およいでいく。
    case lostCygnet
    /// せわがかりの ところへ もどった ひな。
    case cygnetHome

    /// いま地図に出ているか。
    func isPresent(_ progress: StoryProgress) -> Bool {
        switch self {
        case .lostChild: !progress.has(.childFound)
        case .childAtHome: progress.has(.childFound)
        case .lostCygnet: !progress.has(.cygnetFound)
        case .cygnetHome: progress.has(.cygnetFound)
        default: true
        }
    }

    /// 話しかけたときの場面。
    func scene(_ progress: StoryProgress) -> StoryScene {
        let squidGone = progress.defeatedBosses.contains(.squidLord)
        switch self {
        case .magistrate:
            if progress.defeatedBosses.contains(.komaLord) {
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
            if progress.has(.hakodateyamaPass) {
                return StoryScene(lines: [
                    "ぶぎょう「てがたを みせれば 山の ばんにんが とおす。",
                    "　函館山は 街の みなみ、海ぞいの 道の さきじゃ。」",
                ])
            }
            if progress.has(.heardFromFisher) {
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
                if progress.has(.fisherThanked) {
                    return StoryScene(lines: [
                        "おやかた「今夜は イカそうめんで おいわいだ！",
                        "　函館の イカは すきとおってて うまいんだぞ。」",
                    ])
                }
                return StoryScene(lines: [
                    "おやかた「おう！ イカが みなとに もどってきたぞ！",
                    "　これは 漁師 みんなからの おれいだ。」",
                    "100ゴールドを てにいれた！",
                ], gold: 100, sets: [.fisherThanked])
            }
            if progress.has(.heardFromFisher) {
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
            if progress.has(.childReturned) {
                return StoryScene(lines: [
                    "おかあさん「この子ったら、八幡坂の 上から",
                    "　みなとを ながめるのが すきなのよ。」",
                ])
            }
            if progress.has(.childFound) {
                return StoryScene(lines: [
                    "おかあさん「ああ、ぶじで よかった！",
                    "　みつけて くれて ありがとう。 これを どうぞ。」",
                    "薬草を 2つ てにいれた！",
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
            let total = World.stampTotal
            let half = (total + 1) / 2
            if progress.has(.stampAll) {
                return StoryScene(lines: [
                    "あんないじょ「函館エリアの 名所を ぜんぶ まわるなんて！",
                    "　あなたは りっぱな めいしょ はかせね。」",
                ])
            }
            if progress.stamps >= total {
                return StoryScene(lines: [
                    "あんないじょ「まあ！ スタンプが \(total)こ ぜんぶ そろってる！",
                    "　これは めいしょ はかせへの ごほうびよ。」",
                    "300ゴールドを てにいれた！",
                ], gold: 300, sets: [.stampHalf, .stampAll])
            }
            if progress.stamps >= half, !progress.has(.stampHalf) {
                return StoryScene(lines: [
                    "あんないじょ「スタンプが \(progress.stamps)こ！ もう 半分ね。",
                    "　たびの おともに どうぞ。 のこりも がんばって！」",
                    "薬草を 3つ てにいれた！",
                ], items: [.herb, .herb, .herb], sets: [.stampHalf])
            }
            return StoryScene(lines: [
                "あんないじょ「ようこそ 函館へ！ 名所の かんばんを よむと",
                "　めいしょ スタンプが たまるの。 函館・松前・大沼に あるわ。",
                "　いま \(progress.stamps)こ ／ \(total)こ。 \(half)こで 薬草、",
                "　ぜんぶ そろえば 300ゴールド あげる！」",
            ])

        case .lord:
            if progress.defeatedBosses.contains(.komaLord) {
                return StoryScene(lines: [
                    "とのさま「駒ヶ岳の ぬしを しずめたか。 あっぱれじゃ。",
                    "　春には 城の さくらを 見に まいれ。",
                    "　松前の さくらは 250しゅるいも あるのじゃぞ。」",
                ])
            }
            if progress.has(.fireCharm) {
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
            if progress.defeatedBosses.contains(.komaLord) {
                if progress.has(.rangerThanked) {
                    return StoryScene(lines: [
                        "やまもり「駒ヶ岳が しずかに なった。",
                        "　あの 山は うまの かたちに 見えるから 駒ヶ岳と いうんだ。」",
                    ])
                }
                return StoryScene(lines: [
                    "やまもり「ぬしを たおしたのか！ これで 大沼も あんしんだ。",
                    "　みんなから あつめた おれいだ。 うけとってくれ。」",
                    "150ゴールドを てにいれた！",
                ], gold: 150, sets: [.rangerThanked])
            }
            if progress.has(.fireCharm) {
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
            if progress.has(.cygnetReturned) {
                return StoryScene(lines: [
                    "せわがかり「冬に なると ハクチョウが シベリアから",
                    "　大沼へ わたってくるのよ。 ひなも げんきに そだってるわ。」",
                ])
            }
            if progress.has(.cygnetFound) {
                return StoryScene(lines: [
                    "せわがかり「ああ、ひなが およいで もどってきた！",
                    "　ありがとう。 これは ほんの おれいよ。」",
                    "120ゴールドを てにいれた！",
                ], gold: 120, sets: [.cygnetReturned])
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
        }
    }

    /// この人が 言うかもしれない せりふ ぜんぶ（`QuizTests` で 答えが街で聞けるかを見る）。
    /// 印の組み合わせは ぜんぶだと 多すぎるので、ひとつずつ 立てていった すじみちを たどる。
    var everyLine: [String] {
        let bosses: [Set<EnemyKind>] = [[], [.squidLord], [.squidLord, .komaLord], [.squidLord, .komaLord, .bearLord]]
        var flagSets: [Set<StoryFlag>] = [[]]
        for flag in StoryFlag.allCases { flagSets.append(flagSets.last!.union([flag])) }
        for flag in StoryFlag.allCases { flagSets.append([flag]) }
        let stamps = [0, (World.stampTotal + 1) / 2, World.stampTotal]
        return bosses.flatMap { defeated in
            flagSets.flatMap { flags in
                stamps.flatMap { scene(StoryProgress(flags: flags, defeatedBosses: defeated, stamps: $0)).lines }
            }
        }
    }
}
