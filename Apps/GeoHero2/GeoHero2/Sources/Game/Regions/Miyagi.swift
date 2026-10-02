import Foundation

// MARK: - 宮城県
//
// 仙台で 七夕の かざり職人に 話を きき、松島の 船頭に 潮の ひく 時を おそわる。
// 島の ほらあなの 大がきの ぬし（中ボス）を 倒すと 竹に雀の 紋の かぎが 出てくる。
// 瑞巌寺の おしょうに 見せて 青葉山の 門を ひらき、独眼竜の よろい（ぬし）を 倒すと 七夕が もどり、福島へ 行ける。

extension StoryFlag {
    /// 七夕の かざり職人から 話を きいた。
    static let miyagiHeard: StoryFlag = "miyagi.heard"
    /// 松島の 船頭に 潮の ひく 時を おそわった（島の ほらあなに 入れる）。
    static let miyagiTide: StoryFlag = "miyagi.tide"
    /// 瑞巌寺の おしょうに 青葉山の 門を ひらく ゆるしを もらった。
    static let miyagiGate: StoryFlag = "miyagi.gate"
}

extension Story {
    static let miyagiGates: [StoryFlag: [String]] = [
        .miyagiTide: ["ほらあなの 入口は 海の 水に しずんでいる。",
                      "（潮の ひく 時を しる 人が いれば……）"],
        .miyagiGate: ["青葉山の 城あとの 門が かたく とざされている。",
                      "門には 竹に すずめの 紋が ある。",
                      "（この 紋の かぎが あれば……）"],
    ]

    static let miyagiImplications: [StoryFlag: EnemyKind] = [
        .miyagiHeard: .giantOyster,
        .miyagiTide: .giantOyster,
        .miyagiGate: .datemaru,
    ]

    static func miyagiHint(_ p: StoryProgress) -> [String]? {
        if !p.has(.miyagiHeard) {
            return ["ちょうろう「仙台では 七夕の かざりが きえたそうじゃ。",
                    "　仙台の まちの 七夕の かざり職人に 話を きけ。」"]
        }
        if !p.has(.miyagiTide) {
            return ["ちょうろう「松島の 遊覧船の 船頭を たずねよ。",
                    "　松島は 仙台の 北東、海ぞいの まちじゃ。」"]
        }
        if !p.defeatedBosses.contains(.giantOyster) {
            return ["ちょうろう「島の ほらあなは 松島の 東、橋を わたった さきじゃ。",
                    "　松島の ものの 話を きいておけば ちしきで おいうちが きまるぞ。」"]
        }
        if !p.has(.miyagiGate) {
            return ["ちょうろう「その かぎの 紋を 松島の 瑞巌寺の おしょうに 見せよ。」"]
        }
        if !p.defeatedBosses.contains(.datemaru) {
            return ["ちょうろう「青葉山は 仙台の 西じゃ。",
                    "　仙台で 伊達の刀と 伊達の具足を そろえて いどむのじゃ。」"]
        }
        return nil
    }
}

extension Errand {
    /// 鳴子の こけし職人 → 仙台の 公園の こども。
    static let miyagiKokeshi = Errand(
        id: "miyagi.kokeshi", package: "鳴子こけし",
        ask: ["こけししょくにん「仙台の 公園の 男の子に こけしを たのまれとってな。",
              "　とどけて くれんか。 仙台は 鳴子の 南東じゃ。」"],
        reminder: ["こけししょくにん「こけしは 仙台の 公園の 男の子に たのむぞ。」"],
        thanks: ["こけししょくにん「とどけて くれたか！ よろこんどったか？", "　これは おれいじゃ。」"],
        after: ["こけししょくにん「こけしの 顔は 職人ごとに ちがうんじゃ。",
                "　わしの こけしは 目が やさしいじゃろ？」"],
        delivered: ["こども「わあ、鳴子こけし！",
                    "　首を まわすと キュッて なった！」"],
        idle: ["こども「仙台は 東北で いちばん 人が 多い まちなんだって！」"],
        gold: 200, items: [.zundaMochi]
    )
}

extension LostQuest {
    /// 松島へ 遊覧船を 見に いって 迷子に なった こども。
    static let sendaiKid = LostQuest(
        id: "miyagi.kid",
        ask: ["おかあさん「むすめが いないの。 遊覧船を 見たいって いってたから",
              "　松島へ いったのかも……。 松島は 仙台の 北東よ。」"],
        thanks: ["おかあさん「もどってきたわ！ ほんとうに ありがとう。」"],
        after: ["おかあさん「こんどは いっしょに 遊覧船に のるのよ。」"],
        lost: ["こども「船を 見てたら おうちが わからなく なっちゃった……",
               "　え、ママが まってるの？ かえる！」",
               "こどもは 仙台の ほうへ かけていった。"],
        home: ["こども「松島の 島って 260も あるんだよ！」"],
        gold: 100, items: [.gyutan]
    )
}

extension Resident {
    func miyagiScene(_ p: StoryProgress) -> StoryScene? {
        switch self {
        case .tanabataMaster:
            if p.defeatedBosses.contains(.datemaru) {
                return StoryScene(lines: [
                    "かざりしょくにん「七夕の かざりが もどった！ ありがとう！",
                    "　福島でも わらじまつりの 大わらじが きえたそうだ。",
                    "　駅から 新幹線で 福島へ いってくれ。」",
                ])
            }
            if p.has(.miyagiGate) {
                return StoryScene(lines: [
                    "かざりしょくにん「青葉山の 門が ひらくのか！",
                    "　青葉山は 仙台の 西。 むかし 仙台城が あった 山だ。」",
                ])
            }
            if p.defeatedBosses.contains(.giantOyster) {
                return StoryScene(lines: [
                    "かざりしょくにん「竹に すずめの 紋の かぎ……？",
                    "　それは 伊達家の 紋だ。 松島の 瑞巌寺の おしょうに 見せてみな。」",
                ])
            }
            if p.has(.miyagiTide) {
                return StoryScene(lines: [
                    "かざりしょくにん「島の ほらあなは 松島の 東、橋を わたった さきだ。」",
                ])
            }
            if p.has(.miyagiHeard) {
                return StoryScene(lines: [
                    "かざりしょくにん「松島の 遊覧船の 船頭を たずねてくれ。",
                    "　松島は 仙台の 北東、海ぞいの まちだ。」",
                ])
            }
            return StoryScene(lines: [
                "かざりしょくにん「おれは 七夕の かざり職人。",
                "　仙台七夕まつりの かざりは 紙で つくる『七つ飾り』。",
                "　ところが ある夜、かざりが ぜんぶ 糸で ひっぱられて",
                "　松島の 海の ほうへ きえちまったんだ。",
                "　松島の 遊覧船の 船頭が なにか 見たかも しれない。」",
            ], sets: [.miyagiHeard])

        case .boatman:
            if p.defeatedBosses.contains(.giantOyster) {
                return StoryScene(lines: [
                    "せんどう「海が すきとおって きた！ カキも げんきに なるぞ。",
                    "　遊覧船で 島めぐりも できるように なった。」",
                ])
            }
            if p.has(.miyagiTide) {
                return StoryScene(lines: [
                    "せんどう「いまなら 潮が ひいとる。",
                    "　島の ほらあなは 福浦橋を わたった さきだ。」",
                ])
            }
            if p.has(.miyagiHeard) {
                return StoryScene(lines: [
                    "せんどう「七夕の かざり？ ああ、見たとも。",
                    "　島の ほらあなへ 大きな カキの ばけものが ひきこんでいった。",
                    "　入口は 潮が ひかないと 海の 下だ。 潮の 時間を おしえよう。」",
                    "潮の ひく 時を おそわった！",
                ], sets: [.miyagiTide])
            }
            return StoryScene(lines: [
                "せんどう「わしは 松島の 遊覧船の 船頭。",
                "　宮城の 海は 太平洋。 海の パイナップル『ホヤ』も とれるぞ。」",
            ])

        case .zuiganjiMonk:
            if p.defeatedBosses.contains(.datemaru) {
                return StoryScene(lines: [
                    "おしょう「よろいも しずまった ようじゃな。",
                    "　政宗公も きっと よろこんで おられよう。」",
                ])
            }
            if p.has(.miyagiGate) {
                return StoryScene(lines: [
                    "おしょう「その かぎで 青葉山の 門を ひらきなされ。",
                    "　青葉山は 仙台の 西じゃ。」",
                ])
            }
            if p.defeatedBosses.contains(.giantOyster) {
                return StoryScene(lines: [
                    "おしょう「竹に 雀……伊達家の 紋じゃ。 これは 青葉山の 城あとの 門の かぎ。",
                    "　あそこに 政宗公の よろいが まつられて おったが、",
                    "　まおうの けはいが するのう。 門を ひらく ことを ゆるそう。」",
                    "青葉山の 門を ひらく ゆるしを もらった！",
                ], sets: [.miyagiGate])
            }
            return StoryScene(lines: [
                "おしょう「ここは 瑞巌寺。 伊達政宗公が たてなおした 寺じゃ。",
                "　松島の 海を まもる 寺でも あるのじゃよ。」",
            ])

        case .kokeshiCarver: return Errand.miyagiKokeshi.giverScene(p)
        case .sendaiKid: return Errand.miyagiKokeshi.receiverScene(p)
        case .sendaiMother: return LostQuest.sendaiKid.seekerScene(p)
        case .lostSendaiKid: return LostQuest.sendaiKid.lostScene()
        case .sendaiKidHome: return LostQuest.sendaiKid.homeScene()
        case .miyagiGuide: return Story.stampScene(.miyagi, p, towns: "仙台・松島・鳴子", gift: .gyutan)
        case .miyagiExaminer: return Story.examScene(.miyagi, p)
        case .curator: return Story.curatorScene(p)

        case .miyagiDancer:
            return StoryScene(lines: [
                "むすめ「七夕の かざりが もどったよ！",
                "　ふきながしが 風に ゆれて きれい！」",
            ])

        case .narukoYumori:
            return StoryScene(lines: [
                "ゆもり「鳴子の 足湯で ひとやすみ していきな。",
                "　笹かまぼこを つまみながら 入るのが さいこうだぞ。」",
                "あたたかい 温泉に 足を ひたした。",
                "HPと MPが ぜんぶ かいふくした！",
            ], heals: true)

        default: return nil
        }
    }
}

extension QuizBank {
    static let miyagi: [MapID: [Quiz]] = [
        .sendai: [
            Quiz(question: "仙台で 8月に ひらかれる かざりの まつりは？", choices: ["七夕まつり", "竿燈まつり", "ねぶた祭"], answer: 0),
            Quiz(question: "仙台の まちを ひらいた 戦国大名は？", choices: ["上杉謙信", "伊達政宗", "武田信玄"], answer: 1),
            Quiz(question: "みどりが 多い 仙台の よびなは？", choices: ["水の都", "花の都", "杜の都"], answer: 2),
            Quiz(question: "仙台の 名物の やきにくは？", choices: ["ジンギスカン", "牛たん", "ホルモン"], answer: 1),
            Quiz(question: "えだまめを つぶして つくる 仙台の あんは？", choices: ["ずんだ", "こしあん", "うぐいす"], answer: 0),
            Quiz(question: "仙台の まちを ながれる 川は？", choices: ["隅田川", "鴨川", "広瀬川"], answer: 2),
            Quiz(question: "伊達政宗の かぶとの かざりの かたちは？", choices: ["三日月", "太陽", "星"], answer: 0),
            Quiz(question: "伊達政宗の あだなは？", choices: ["甲斐の虎", "独眼竜", "越後の龍"], answer: 1),
        ],
        .matsushima: [
            Quiz(question: "松島は なにの ひとつ？", choices: ["日本三名園", "日本三景", "日本三大祭"], answer: 1),
            Quiz(question: "松島湾に うかぶ 島の かずは？", choices: ["約2600", "約26", "約260"], answer: 2),
            Quiz(question: "松島湾で 養殖が さかんな 貝は？", choices: ["カキ", "ホタテ", "アサリ"], answer: 0),
            Quiz(question: "伊達政宗が たてなおした 松島の お寺は？", choices: ["金閣寺", "瑞巌寺", "中尊寺"], answer: 1),
            Quiz(question: "日本三景は 松島・天橋立と どこ？", choices: ["宮島", "富士山", "屋久島"], answer: 0),
            Quiz(question: "宮城で 養殖される『海の パイナップル』は？", choices: ["ウニ", "ナマコ", "ホヤ"], answer: 2),
            Quiz(question: "宮城県の 東に ひろがる 海は？", choices: ["日本海", "太平洋", "瀬戸内海"], answer: 1),
        ],
        .naruko: [
            Quiz(question: "首を まわすと キュッと なる 鳴子の 人形は？", choices: ["こけし", "だるま", "赤べこ"], answer: 0),
            Quiz(question: "鳴子は なにで 有名な まち？", choices: ["砂丘", "港", "温泉"], answer: 2),
            Quiz(question: "鳴子の ちかくの 紅葉の 名所の 谷は？", choices: ["黒部峡谷", "鳴子峡", "大歩危"], answer: 1),
            Quiz(question: "宮城県で そだてられる お米は？", choices: ["ひとめぼれ", "あきたこまち", "つや姫"], answer: 0),
            Quiz(question: "宮城名物の 笹の 葉の かたちの かまぼこは？", choices: ["ちくわ", "笹かまぼこ", "なると"], answer: 1),
            Quiz(question: "宮城・岩手・秋田に またがる 山は？", choices: ["岩木山", "月山", "栗駒山"], answer: 2),
        ],
    ]
}

extension World {
    /// 仙台の 出口の 前（全滅したら ここで 目を さます）。
    static let sendaiGate = Point(x: 14, y: 17)

    static var miyagiMaps: [GameMap] {
        [miyagiField, sendai, matsushima, naruko, oysterCave, aobayama1, aobayama2,
         tanabataHouse, sendaiHouse, museum, zuiganji, matsushimaHouse, kokeshiHouse]
    }

    /// 宮城県。56×36 マス。東は 太平洋、北東の 松島湾に 小さな 島が ならぶ（島の ほらあなは 橋の さき）。
    /// まんなかに 仙台と 仙台駅、すぐ 西に 青葉山。北西に 鳴子と 栗駒山、北に 大崎平野の 田んぼ。
    /// 南東に 牡鹿半島と 金華山、南西に 蔵王。
    static let miyagiField = GameMap(
        id: .miyagiField,
        name: "宮城県",
        kind: .field,
        region: .miyagi,
        rows: [
            "MMMMhhhhhhh...................................~~~~~~~~~~",
            "MMMMhhMMMMMh..................................~~~~~~~~~~",
            "MMMMhMMMMMMMh.................................~~~~~~~~~~",
            "MMMMhMMMMMMMh.................................~~~~~~~~~~",
            "MMMMhMMMMMMMh.................................~~~~~~~~~~",
            "MMMMhhMMMMMh........ppppppppppppppppp.........~~~~~~~~~~",
            "MMMMhhhhhhh.........ppppppppppppppppp.........~~~~~~~~~~",
            "MMMMhh.c............ppppppppppppppppp........~~~~~~~~~~~",
            "MMMMhh..............ppppppppppppppppp........~~~~~~~~~~~",
            "MMMMhh....T..hhh....ppppppppppppppppp......c~~~~~~~~~~~~",
            "MMMMhh....=========.ppppppppppppppppp.......~~~~~~~~~~~~",
            "MMMMhh.......hhh..=.ppppppppppppppppp......~~~~~~~~~~~~~",
            "MMMMhh.......hhh..=.ppppppppppppppppp......~~~~~~~~~~~~~",
            "MMMMhh.......hhh..=...................T...~~~~~~~~~~~~~~",
            "MMMMhh.......hhh..=.................===...~~~~~f~~~~~~~~",
            "MMMMhh............=.................=.==bbb=b=~~~~~~~~~~",
            "MMMMhh............==============....=..~f~~~~=C.~~~~~~~~",
            "MMMMhh..fffffffff..............=....=..~~~f~~==.~~~~~~~~",
            "MMMMhh..fffffffff......hhhhh...=....=..~~~~~~f~~~~~~~~~~",
            "MMMMhh..fffffffff.....hhfCfhh..=....=..~~f~~~~~~f~~~~~~~",
            "MMMMhh..fffffffff.....hff=ffh..T..A.=..~~~~~~~~~~~~~~~~~",
            "MMMMhh..fffffffff.....hhf============....~~~f~~~~~~~~~~~",
            "MMMMhh..fffffffff......hhhhh.............~~~~~f~~~~~~~~~",
            "MMMMhh..fffffffff.........................~~~~~~~~~~~~~~",
            "MMMMhh....................................~~~~~~~~~~~~~~",
            "MMMMhh........................ffffffff...~~~~~~~~~~~~~~~",
            "MMMMhh........................ffffffff..~~~~~~~~~~~~~~~~",
            "MMMMhh........................ffffffff...~~~~~~~~~~~~~~~",
            "MMMMhh.hhhhh..................ffffffff....hhhhhh~~~~~~~~",
            "MMMMhhhMMMMMh.................ffffffff~~~hhhhhhhh~~~~~~~",
            "MMMMhhMMMMMMMh................ffffffff~~~~hhhhhchh~~~~~~",
            "MMMMhhMMMMMMMh................ffffffff~~~~~~hhhh~~~~~~~~",
            "MMMMhhMMMMMMMh.........................~~~~~~~~~~~~MMM~~",
            "MMMMhhhMMMMMh.c........................~~~~~~~~~~~~MMM~~",
            "MMMMhh.hhhhh.........................c.~~~~~~~~~~~~MMM~~",
            "MMMMhh..................................~~~~~~~~~~~~~~~~"
        ],
        outside: .water,
        warps: [
            Point(x: 31, y: 20): Warp(to: .sendai, at: Point(x: 14, y: 17)),
            Point(x: 38, y: 13): Warp(to: .matsushima, at: Point(x: 11, y: 13)),
            Point(x: 10, y: 9): Warp(to: .naruko, at: Point(x: 6, y: 9)),
            // 島の ほらあなは 潮の ひく 時、青葉山は 瑞巌寺の ゆるしで ひらく。
            Point(x: 46, y: 16): Warp(to: .oysterCave, at: Point(x: 9, y: 9), needs: .miyagiTide),
            Point(x: 25, y: 19): Warp(to: .aobayama1, at: Point(x: 11, y: 11), needs: .miyagiGate),
        ],
        chestRewards: [.gold(350), .item(.zundaMochi), .item(.hanabi), .item(.mishirazuGaki), .gold(400)],
        encounterAreas: [
            EncounterArea(name: "仙台のまわり", around: [Point(x: 31, y: 21), Point(x: 34, y: 21), Point(x: 25, y: 20), Point(x: 31, y: 28)],
                          enemies: Balance.places[12].enemies, quizTown: .sendai),
            EncounterArea(name: "松島へむかう道",
                          around: [Point(x: 38, y: 14), Point(x: 36, y: 17), Point(x: 46, y: 17), Point(x: 44, y: 29), Point(x: 42, y: 8)],
                          enemies: Balance.places[13].enemies, quizTown: .matsushima),
            EncounterArea(name: "鳴子へむかう道",
                          around: [Point(x: 10, y: 10), Point(x: 18, y: 12), Point(x: 22, y: 16), Point(x: 12, y: 28), Point(x: 25, y: 6)],
                          enemies: Balance.places[13].enemies, quizTown: .naruko),
        ],
        markerFloor: .grass
    )

    /// 仙台。北西の 森に 青葉城あと、北に 七夕の 工房と 博物館、南を 広瀬川が ながれる。
    static let sendai = GameMap(
        id: .sendai,
        name: "せんだい",
        kind: .town,
        region: .miyagi,
        town: TownInfo(name: "仙台", reading: "せんだい", tagline: "七夕と 牛たんの 杜の都",
                       innBase: 8, innPerLevel: 6,
                       stock: [.wankoSoba, .zundaMochi, .gyutan, .konjikiTachi, .dateKatana, .fujiwaraArmor, .dateArmor]),
        rows: [
            "##############################",
            "#ffffff______________________#",
            "#f_P_ff__HHHHH___HHHHH___t___#",
            "#ffffff__WWdWW___WWdWW_______#",
            "#____________________________#",
            "#__t_______P____________6____#",
            "#__ffffffffffffffffffffff____#",
            "#____________________________#",
            "#___III____SSS____HHH____t___#",
            "#___III____SSS____WdW________#",
            "#___YdW____ZdW______________3#",
            "#____________________________#",
            "#_t_______e________45______2_#",
            "#____________________________#",
            "#~~~~~~~~~~~~bb~~~~~~~~~~~~~~#",
            "#_______t________________P___#",
            "#__1____________________c____#",
            "#____________________________#",
            "#############EEEE#############"
        ],
        outside: .grass,
        warps: [
            Point(x: 11, y: 3): Warp(to: .tanabataHouse, at: Point(x: 4, y: 4)),
            Point(x: 19, y: 3): Warp(to: .museum, at: Point(x: 4, y: 4)),
            Point(x: 19, y: 9): Warp(to: .sendaiHouse, at: Point(x: 4, y: 4)),
            Point(x: 5, y: 10): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 12, y: 10): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(13...16, row: 18, to: .miyagiField, at: Point(x: 31, y: 21))) { first, _ in first },
        villagers: [
            ["おとこ「仙台の まちを ひらいたのは 伊達政宗。",
             "　『独眼竜』と よばれた 戦国大名さ。」"],
            ["おばさん「仙台は みどりが 多くて『杜の都』と よばれるのよ。」"],
            ["サラリーマン「仙台の 名物と いえば 牛たん！",
             "　あつく 切って すみびで やくのが うまい。」"],
            ["むすめ「えだまめを つぶした ずんだもちは 仙台の おやつよ。」"],
            ["おじいさん「仙台の まちを ながれる 広瀬川は",
             "　きれいな 水の 川じゃよ。」"],
        ],
        residents: ["1": .sendaiKid, "2": .miyagiGuide, "3": .miyagiExaminer, "4": .sendaiMother,
                    "5": .sendaiKidHome, "6": .miyagiDancer],
        plaques: [
            Point(x: 3, y: 2): Plaque(title: "青葉城", lines: [
                "かんばんに こう かいてある。",
                "「仙台城跡（青葉城跡）」",
                "伊達政宗が きずいた 城の あと。",
            ]),
            Point(x: 11, y: 5): Plaque(title: "定禅寺", lines: [
                "かんばんに こう かいてある。",
                "「定禅寺通」",
                "ケヤキ並木が つづく 杜の都の 大通り。",
            ]),
            Point(x: 25, y: 15): Plaque(title: "広瀬川", lines: [
                "かんばんに こう かいてある。",
                "「広瀬川」",
                "仙台の まちなかを ながれる 清らかな 川。",
            ]),
        ],
        chestRewards: [.item(.zundaMochi)]
    )

    /// 松島。北に 瑞巌寺、南は 松島湾と 島々。
    static let matsushima = GameMap(
        id: .matsushima,
        name: "まつしま",
        kind: .town,
        region: .miyagi,
        town: TownInfo(name: "松島", reading: "まつしま", tagline: "島々の うかぶ 日本三景",
                       innBase: 9, innPerLevel: 6,
                       stock: [.gyutan, .zundaMochi, .dateKatana, .dateArmor]),
        rows: [
            "########################",
            "#______HHHHH___________#",
            "#__P___WWdWW_____t_____#",
            "#______________________#",
            "#_III___SSS___HHH____P_#",
            "#_YdW___ZdW___WdW______#",
            "#______________________#",
            "#__t____e______1___t___#",
            "#~~~~~~~~__~~~~~~~~~~~~#",
            "#~~f~~~~~bb~~~~f~~f~~~~#",
            "#~~~~f~~~__~~~~~~~~~f~~#",
            "#~~~~~~~___P_~~f~~~~~~~#",
            "#~~~f~~~_c__~~~~~~f~~~~#",
            "#~~~~~~~__2_~~~~~~~~~~~#",
            "#########EEE############"
        ],
        outside: .water,
        warps: [
            Point(x: 9, y: 2): Warp(to: .zuiganji, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 5): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 9, y: 5): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 15, y: 5): Warp(to: .matsushimaHouse, at: Point(x: 4, y: 4)),
        ].merging(exits(9...11, row: 14, to: .miyagiField, at: Point(x: 38, y: 14))) { first, _ in first },
        villagers: [
            ["たびびと「松島は 日本三景の ひとつ。",
             "　京都の 天橋立、広島の 宮島と ならぶ ながめさ。」"],
            ["おばさん「松島湾には 約260の 島が うかんでいるのよ。」"],
            ["りょうし「松島湾の カキは ぷりぷりで おいしいぞ。",
             "　冬が しゅんだ。」"],
        ],
        residents: ["1": .boatman, "2": .lostSendaiKid],
        plaques: [
            Point(x: 3, y: 2): Plaque(title: "瑞巌寺", lines: [
                "かんばんに こう かいてある。",
                "「瑞巌寺」",
                "伊達政宗が たてなおした 国宝の 寺。",
            ]),
            Point(x: 21, y: 4): Plaque(title: "五大堂", lines: [
                "かんばんに こう かいてある。",
                "「五大堂」",
                "海に つきでた 小島の お堂。 すかし橋で わたる。",
            ]),
            Point(x: 11, y: 11): Plaque(title: "福浦橋", lines: [
                "かんばんに こう かいてある。",
                "「福浦橋」",
                "福浦島へ わたる 赤い 橋。",
            ]),
        ],
        chestRewards: [.gold(120)]
    )

    /// 鳴子。山に かこまれた 温泉の まち。東に 足湯。
    static let naruko = GameMap(
        id: .naruko,
        name: "なるこ",
        kind: .town,
        region: .miyagi,
        town: TownInfo(name: "鳴子", reading: "なるこ", tagline: "こけしと 温泉の まち",
                       innBase: 8, innPerLevel: 6,
                       stock: [.gyutan, .zundaMochi, .konjikiTachi, .dateArmor]),
        rows: [
            "######################",
            "#hhhhhhhhhhhhhhhhhhhh#",
            "#h__HHH______HHH____h#",
            "#h__WdW__P___WWW__t_h#",
            "#____________________#",
            "#_III____SSS_____ww__#",
            "#_YdW____ZdW__1__ww__#",
            "#____________________#",
            "#__t____e______P_____#",
            "#______________t___c_#",
            "#####EEEE#############"
        ],
        outside: .grass,
        warps: [
            Point(x: 5, y: 3): Warp(to: .kokeshiHouse, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 6): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 10, y: 6): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(5...8, row: 10, to: .miyagiField, at: Point(x: 10, y: 10))) { first, _ in first },
        villagers: [
            ["おばさん「鳴子は 温泉の まち。",
             "　いろんな 色の 湯が わいてるのよ。」"],
            ["おじいさん「秋の 鳴子峡は 紅葉が それは きれいでのう。」"],
            ["のうか「宮城の お米は ひとめぼれ。",
             "　鳴子の まわりでも そだてとるよ。」"],
        ],
        residents: ["1": .narukoYumori],
        plaques: [
            Point(x: 9, y: 3): Plaque(title: "温泉", lines: [
                "かんばんに こう かいてある。",
                "「鳴子温泉 滝の湯」",
                "千年 ちかく つづく 共同浴場。",
            ]),
            Point(x: 15, y: 8): Plaque(title: "鳴子峡", lines: [
                "かんばんに こう かいてある。",
                "「鳴子峡」",
                "ふかい 谷。 秋は 紅葉の 名所。",
            ]),
        ],
        chestRewards: [.item(.gyutan)]
    )

    /// 松島の 島の ほらあな。海の 水が 入りこむ。いちばん奥に 大がきの ぬし。
    static let oysterCave = cave(
        .oysterCave, name: "島の ほらあな", label: "福浦島", region: .miyagi,
        rows: [
            "###################",
            "#~~~~~~,,,,,~~~~~~#",
            "#~~~~~,,,B,,,~~~~~#",
            "#~~~~~~,,,,,~~~~~~#",
            "#c,,~~~~~,~~~~~,,c#",
            "#,,,,,~~~,~~~,,,,,#",
            "#~~~,,,,,,,,,,,~~~#",
            "#~~~,~~~~,~~~~,~~~#",
            "#,,,,,,~~,~~,,,,,,#",
            "#,~~~~,,,,,,,~~~~,#",
            "#,,,,,,~~U~~,,,,,,#",
            "###################"
        ],
        warps: [Point(x: 9, y: 10): Warp(to: .miyagiField, at: Point(x: 46, y: 17))],
        chestRewards: [.gold(300), .item(.zundaMochi)],
        bossKind: .giantOyster, enemies: Balance.places[14].enemies, quizTown: .matsushima
    )

    static let aobayama1 = cave(
        .aobayama1, name: "青葉山 B1", label: "青葉山", region: .miyagi,
        rows: [
            "#####################",
            "#,,,,,,,#,,,,,,,#,,c#",
            "#,#####,#,#####,#,#,#",
            "#,#,,,,,,,#,,,#,,,#,#",
            "#,#,#########,#####,#",
            "#,,,#,,,,,,,#,,,,,,,#",
            "###,#,#####,#####,###",
            "#,,,,,#,,c#,,,,,#,,,#",
            "#,#####,#,#####,#,#,#",
            "#,,,,,,,#,,,,,#,,,#D#",
            "#,#######,###,#####,#",
            "#,,,,,,,,,U,,,,,,,,,#",
            "#####################"
        ],
        warps: [
            Point(x: 10, y: 11): Warp(to: .miyagiField, at: Point(x: 25, y: 20)),
            Point(x: 19, y: 9): Warp(to: .aobayama2, at: Point(x: 10, y: 9)),
        ],
        chestRewards: [.item(.hitomebore), .gold(320)],
        enemies: Balance.places[15].enemies, quizTown: .sendai
    )

    static let aobayama2 = cave(
        .aobayama2, name: "青葉山 B2", region: .miyagi,
        rows: [
            "#################",
            "#,,,,,,,B,,,,,,,#",
            "#,,,,,,,,,,,,,,,#",
            "#,,,###,,,,###,,#",
            "######,,,,,,,####",
            "#,,,,,,##,##,,,,#",
            "#,###,,#,c#,,##,#",
            "#,#,,,,#,,#,,,#,#",
            "#,#,####,,####,,#",
            "#,,,,,,,,U,,,,,,#",
            "#################"
        ],
        warps: [Point(x: 9, y: 9): Warp(to: .aobayama1, at: Point(x: 19, y: 8))],
        chestRewards: [.item(.shakudama)],
        bossKind: .datemaru, enemies: Balance.places[15].enemies, quizTown: .sendai
    )

    // MARK: 家の中

    static let tanabataHouse = house(
        .tanabataHouse, name: "七夕の 工房",
        rows: [
            "XXXXXXXXX",
            "XLL1oLLcX",
            "XoooooooX",
            "XooooootX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .sendai, region: .miyagi, door: Point(x: 11, y: 3),
        villagers: [["でし「七つ飾りの ふきながしは おりひめの 糸を あらわしてるんだ。」"]],
        residents: ["1": .tanabataMaster], chestRewards: [.gold(80)]
    )

    static let museum = house(
        .museum, name: "博物館",
        rows: [
            "XXXXXXXXX",
            "XLLL1LLLX",
            "XoooooooX",
            "XtooooocX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .sendai, region: .miyagi, door: Point(x: 19, y: 3),
        villagers: [["あんないいん「こちらは 伊達政宗の かぶと。",
                     "　大きな 三日月の かざりが ついているでしょう？」"]],
        residents: ["1": .curator], chestRewards: [.item(.gyutan)]
    )

    static let sendaiHouse = house(
        .sendaiHouse, name: "みんか",
        rows: [
            "XXXXXXXXX",
            "XcLLoLLLX",
            "XoooooooX",
            "XootooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .sendai, region: .miyagi, door: Point(x: 19, y: 9),
        villagers: [["おばあさん「仙台の 冬は からっ風が つめたいんじゃ。",
                     "　あったかい 牛たんシチューが いちばんよ。」"]],
        chestRewards: [.gold(100)]
    )

    static let zuiganji = house(
        .zuiganji, name: "瑞巌寺",
        rows: [
            "XXXXXXXXX",
            "XLLL1LLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .matsushima, region: .miyagi, door: Point(x: 9, y: 2),
        villagers: [],
        residents: ["1": .zuiganjiMonk], chestRewards: [.item(.zundaMochi)]
    )

    static let matsushimaHouse = house(
        .matsushimaHouse, name: "カキ小屋",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLcX",
            "XooKKKooX",
            "XoooooooX",
            "XootooooX",
            "XXXXdXXXX",
        ],
        town: .matsushima, region: .miyagi, door: Point(x: 15, y: 5),
        villagers: [["カキやの おじさん「やきガキ くってくか？",
                     "　松島の カキは 小ぶりで あじが こいんだ。」"]],
        chestRewards: [.item(.gyutan)]
    )

    static let kokeshiHouse = house(
        .kokeshiHouse, name: "こけしの 工房",
        rows: [
            "XXXXXXXXX",
            "XLL1oLLcX",
            "XoooooooX",
            "XoooootoX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .naruko, region: .miyagi, door: Point(x: 5, y: 3),
        villagers: [["でし「鳴子の 北西の 栗駒山は",
                     "　宮城・岩手・秋田に またがる 山なんです。」"]],
        residents: ["1": .kokeshiCarver], chestRewards: [.gold(150)]
    )
}
