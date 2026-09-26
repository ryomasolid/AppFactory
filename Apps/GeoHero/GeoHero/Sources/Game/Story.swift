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
    /// 小樽の オルゴール職人から オルゴールを かえしてもらった（藻岩山の ヒグマのこを しずめる）。
    case musicBox
    /// ラーメン屋から 北大の学生への 出前を あずかった。
    case ramenCarrying
    /// 出前を とどけた。
    case ramenDelivered
    /// ラーメン屋から 出前の お礼をもらった。
    case ramenThanked
    /// 小樽の 倉庫で まいごの ネコを 見つけた（ネコは かいぬしの ところへ 走っていく）。
    case catFound
    /// かいぬしから ネコの お礼をもらった。
    case catReturned
    /// 札幌・小樽の 名所の スタンプを 半分／ぜんぶ あつめて、札幌の案内所から お礼をもらった。
    case sapporoStampHalf
    case sapporoStampAll
    /// 羅臼の エカシから コタンコロカムイ（シマフクロウ）の はねを もらった（羅臼岳の ふぶきが はれる）。
    case kamuiFeather
    /// 中標津の 牧場主から 羅臼の 番屋への 牛乳を あずかった。
    case milkCarrying
    /// 牛乳を とどけた。
    case milkDelivered
    /// 牧場主から 牛乳の お礼をもらった。
    case milkThanked
    /// 知床五湖で まいごの キツネの子を 見つけた。
    case foxFound
    /// レンジャーから キツネの子の お礼をもらった。
    case foxReturned
    /// 知床の 名所の スタンプを 半分／ぜんぶ あつめて、羅臼の案内所から お礼をもらった。
    case shiretokoStampHalf
    case shiretokoStampAll
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
        case .ticketToShiretoko, .musicBox: .bearLord
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
        case .musicBox:
            ["ヒグマの こどもたちが 道を ふさいでいて とおれない。",
             "（しずかな 音色で なだめられたら……）"]
        case .kamuiFeather:
            ["もうれつな ふぶきで まえが 見えない。",
             "とても 山へは 入れない。",
             "（カムイの ちからが あれば……）"]
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
    /// 地方ごとの 押した 名所の スタンプの数（看板を 読んだ数）。
    var stamps: [Region: Int] = [:]

    /// `impliedBy.map(defeatedBosses.contains)` と メソッドを そのまま渡すと、
    /// Release の最適化で 不正なメモリを 読んで落ちた（空港に入ろうとすると クラッシュ）。ふつうに 書く。
    func has(_ flag: StoryFlag) -> Bool {
        if flags.contains(flag) { return true }
        guard let boss = flag.impliedBy else { return false }
        return defeatedBosses.contains(boss)
    }
}

/// 話しかけたときに起きること。せりふを出したあと、ごほうびを渡して 印を立てる。
struct StoryScene: Equatable {
    var lines: [String]
    var gold = 0
    var items: [Item] = []
    var sets: [StoryFlag] = []
    /// HP・MPを ぜんぶ なおす（定山渓の 足湯）。
    var heals = false
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
    /// 札幌の 観光案内所の人。札幌・小樽の スタンプを 見る。
    case sapporoGuide
    /// 赤れんが庁舎の 長官。藻岩山の ようすを 教える。
    case governor
    /// すすきのの ラーメン屋の おやじ。北大へ 出前を たのむ。
    case ramenChef
    /// 北大の学生。出前を まっている。
    case student
    /// 小樽の オルゴール職人。天狗に オルゴールを うばわれた。
    case musicBoxMaker
    /// 小樽の 倉庫の かげで まいごに なっている ネコ。
    case lostCat
    /// かいぬしの ところへ もどった ネコ。
    case catHome
    /// ネコの かいぬし。
    case catOwner
    /// 定山渓の 湯守。足湯で HP・MPを なおしてくれる。
    case yumori
    /// 定山渓の 川に すむ かっぱ。
    case kappa
    /// 羅臼の エカシ（アイヌの 長老）。羅臼岳の ふぶきを はらう はねの ことを 知っている。
    case ekashi
    /// 中標津の 牧場主。羅臼の 番屋へ 牛乳を たのむ。
    case rancher
    /// 羅臼の 番屋の おやじ。牛乳を まっている。
    case banyaOyaji
    /// ウトロの レンジャー。まいごの キツネの子を さがしている。
    case foxRanger
    /// 知床五湖の 木道の おくで まいごに なっている キツネの子。
    case lostFox
    /// レンジャーの ところへ もどった キツネの子。
    case foxHome
    /// 羅臼の 観光案内所の人。知床の スタンプを 見る。
    case shiretokoGuide
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
        case .lostCat: !progress.has(.catFound)
        case .catHome: progress.has(.catFound)
        case .lostFox: !progress.has(.foxFound)
        case .foxHome: progress.has(.foxFound)
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
                    "60ゴールドを てにいれた！",
                ], gold: 60, sets: [.fisherThanked])
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
            return Self.stampScene(.hakodate, progress, half: .stampHalf, all: .stampAll,
                                   towns: "函館・松前・大沼")

        case .sapporoGuide:
            return Self.stampScene(.sapporo, progress, half: .sapporoStampHalf, all: .sapporoStampAll,
                                   towns: "札幌・小樽・定山渓")

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
                    "90ゴールドを てにいれた！",
                ], gold: 90, sets: [.rangerThanked])
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
            if progress.defeatedBosses.contains(.bearLord) {
                return StoryScene(lines: [
                    "ちょうかん「藻岩山に しずけさが もどった。 れいを いう。",
                    "　知床ゆきの ひこうきは 南東の 新千歳空港から でる。",
                    "　この 赤れんが庁舎は 明治に たてられた 北海道の 役所なのだ。」",
                ])
            }
            if progress.has(.musicBox) {
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
            if progress.has(.musicBox) {
                return StoryScene(lines: [
                    "しょくにん「その オルゴールの 音は 小樽の じまんさ。",
                    "　ヒグマの こどもたちも きっと ねむってしまうよ。」",
                ])
            }
            if progress.defeatedBosses.contains(.tengu) {
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
            if progress.has(.ramenThanked) {
                return StoryScene(lines: [
                    "おやじ「札幌の みそラーメンは 寒い 冬に あったまる。",
                    "　この すすきのの 横丁から ひろまったんだぞ。」",
                ])
            }
            if progress.has(.ramenDelivered) {
                return StoryScene(lines: [
                    "おやじ「とどけて くれたか！ のびる まえに ありがとうよ。",
                    "　これは 出前の おだちんだ。」",
                    "90ゴールドを てにいれた！",
                ], gold: 90, sets: [.ramenThanked])
            }
            if progress.has(.ramenCarrying) {
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
            if progress.has(.ramenCarrying), !progress.has(.ramenDelivered) {
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
            if progress.has(.catReturned) {
                return StoryScene(lines: [
                    "かいぬし「ミケは 運河ぞいの 倉庫が すきなのよ。",
                    "　むかしは ニシンを はこぶ 船で にぎわってたんですって。」",
                ])
            }
            if progress.has(.catFound) {
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
            return Self.stampScene(.shiretoko, progress, half: .shiretokoStampHalf, all: .shiretokoStampAll,
                                   towns: "中標津・ウトロ・羅臼")

        case .ekashi:
            if progress.has(.kamuiFeather) {
                return StoryScene(lines: [
                    "エカシ「はねを もって 羅臼岳へ ゆけ。 ふぶきは はれよう。",
                    "　守護神は はげしい ふぶきを おこす。",
                    "　知床の ことを よく しり、HPに よゆうを もって いどむのじゃ。」",
                ])
            }
            if progress.defeatedBosses.contains(.todoLord) {
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
            if progress.has(.milkThanked) {
                return StoryScene(lines: [
                    "ぼくじょうぬし「中標津は 酪農の 町。",
                    "　牛の かずが 人より おおいんだぞ。」",
                ])
            }
            if progress.has(.milkDelivered) {
                return StoryScene(lines: [
                    "ぼくじょうぬし「番屋に とどけて くれたか！ たすかったよ。",
                    "　これは おれいだ。」",
                    "120ゴールドを てにいれた！",
                ], gold: 120, sets: [.milkThanked])
            }
            if progress.has(.milkCarrying) {
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
            if progress.has(.milkCarrying), !progress.has(.milkDelivered) {
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
            if progress.has(.foxReturned) {
                return StoryScene(lines: [
                    "レンジャー「キタキツネに たべものを あげちゃ だめよ。",
                    "　知床は 世界自然遺産。 どうぶつたちの すみかなの。」",
                ])
            }
            if progress.has(.foxFound) {
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
        }
    }

    /// 案内所の 場面。半分で ハスカップ、ぜんぶで ゴールド。
    private static func stampScene(_ region: Region, _ progress: StoryProgress,
                                   half halfFlag: StoryFlag, all allFlag: StoryFlag, towns: String) -> StoryScene {
        let total = World.stampTotal(in: region)
        let half = (total + 1) / 2
        let stamps = progress.stamps[region, default: 0]
        let area = region.banner.name
        if progress.has(allFlag) {
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
        if stamps >= half, !progress.has(halfFlag) {
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

    /// この人から もらえる ゴールドの 合計（お礼は 1度ずつ）。お金の つりあいを たしかめるのに使う。
    var totalGold: Int {
        var flags: Set<StoryFlag> = []
        var total = 0
        // 印を ひとつずつ 立てながら 話しかけ、もらった お礼を 足していく。
        for defeated in [Set<EnemyKind>(), [.squidLord, .komaLord, .tengu, .bearLord, .todoLord]] {
            for _ in 0..<8 {
                let progress = StoryProgress(flags: flags, defeatedBosses: defeated, stamps: Dictionary(
                    uniqueKeysWithValues: Region.allCases.map { ($0, World.stampTotal(in: $0)) }))
                let scene = scene(progress)
                total += scene.gold
                flags.formUnion(scene.sets)
            }
        }
        return total
    }

    /// この人が 言うかもしれない せりふ ぜんぶ（`QuizTests` で 答えが街で聞けるかを見る）。
    /// 印の組み合わせは ぜんぶだと 多すぎるので、ひとつずつ 立てていった すじみちを たどる。
    var everyLine: [String] {
        let bosses: [Set<EnemyKind>] = [[], [.squidLord], [.squidLord, .komaLord],
                                         [.squidLord, .komaLord, .tengu], [.squidLord, .komaLord, .tengu, .bearLord],
                                         [.squidLord, .komaLord, .tengu, .bearLord, .todoLord]]
        var flagSets: [Set<StoryFlag>] = [[]]
        for flag in StoryFlag.allCases { flagSets.append(flagSets.last!.union([flag])) }
        for flag in StoryFlag.allCases { flagSets.append([flag]) }
        let stampSets: [[Region: Int]] = [[:], Dictionary(uniqueKeysWithValues: Region.allCases.map {
            ($0, (World.stampTotal(in: $0) + 1) / 2)
        }), Dictionary(uniqueKeysWithValues: Region.allCases.map { ($0, World.stampTotal(in: $0)) })]
        return bosses.flatMap { defeated in
            flagSets.flatMap { flags in
                stampSets.flatMap { scene(StoryProgress(flags: flags, defeatedBosses: defeated, stamps: $0)).lines }
            }
        }
    }
}
