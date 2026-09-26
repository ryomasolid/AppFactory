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

    /// このボスを倒していれば、立っていなくても 立っていることにする。
    /// 手形の仕組みより前のセーブで、もう ぬしを倒している人を 山の前で止めないため。
    var impliedBy: EnemyKind? {
        switch self {
        case .hakodateyamaPass: .squidLord
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
        default:
            ["さきへ すすめない。"]
        }
    }
}

/// どこまで進んだか。話す相手の せりふを決めるのに使う。
struct StoryProgress {
    var flags: Set<StoryFlag>
    var defeatedBosses: Set<EnemyKind>

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

    /// いま地図に出ているか。
    func isPresent(_ progress: StoryProgress) -> Bool {
        switch self {
        case .lostChild: !progress.has(.childFound)
        case .childAtHome: progress.has(.childFound)
        default: true
        }
    }

    /// 話しかけたときの場面。
    func scene(_ progress: StoryProgress) -> StoryScene {
        let squidGone = progress.defeatedBosses.contains(.squidLord)
        switch self {
        case .magistrate:
            if squidGone {
                return StoryScene(lines: [
                    "ぶぎょう「みごとじゃ。 みなとに イカが もどったと きいた。",
                    "　北の 札幌でも ようすが おかしいと いう。",
                    "　たのんだぞ、ゆうしゃどの。」",
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
        }
    }

    /// この人が 言うかもしれない せりふ ぜんぶ（`QuizTests` で 答えが街で聞けるかを見る）。
    var everyLine: [String] {
        let bosses: [Set<EnemyKind>] = [[], [.squidLord]]
        let flagSets: [Set<StoryFlag>] = (0..<(1 << StoryFlag.allCases.count)).map { mask in
            Set(StoryFlag.allCases.enumerated().filter { mask & (1 << $0.offset) != 0 }.map(\.element))
        }
        return bosses.flatMap { defeated in
            flagSets.flatMap { scene(StoryProgress(flags: $0, defeatedBosses: defeated)).lines }
        }
    }
}
