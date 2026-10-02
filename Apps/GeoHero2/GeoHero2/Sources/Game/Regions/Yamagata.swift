import Foundation

// MARK: - 山形県
//
// さいごの 県。山形で 花笠の 師匠に 話を きき、天童の 将棋名人に 山寺の 門を とおる ゆるしを もらう。
// 山寺の 大ぜみ（中ボス）を 倒すと、酒田の 山居倉庫の 問屋が 紅花の ぬのを くれ、蔵王へ 入れる。
// 蔵王の お釜で 東北の 守護神（ラスボス）を 解きはなつと 花笠まつりが もどり、エンディング。

extension StoryFlag {
    /// 花笠の 師匠から 話を きいた。
    static let yamagataHeard: StoryFlag = "yamagata.heard"
    /// 天童の 将棋名人から 山寺の 門を とおる ゆるしを もらった。
    static let yamagataPass: StoryFlag = "yamagata.pass"
    /// 酒田の 問屋から 紅花の ぬのを もらった（蔵王に 入れる）。
    static let yamagataBenibana: StoryFlag = "yamagata.benibana"
}

extension Story {
    static let yamagataGates: [StoryFlag: [String]] = [
        .yamagataPass: ["山寺の 石段の 門で 門番が とおせんぼ している。",
                        "もんばん「天童の 名人の ゆるしが なければ とおせぬ！」"],
        .yamagataBenibana: ["蔵王の 山道が 樹氷の かべで とざされている。",
                            "（樹氷を とかす 紅の ちからが あれば……）"],
    ]

    static let yamagataImplications: [StoryFlag: EnemyKind] = [
        .yamagataHeard: .yamaderaCicada,
        .yamagataPass: .yamaderaCicada,
        .yamagataBenibana: .guardian,
    ]

    static func yamagataHint(_ p: StoryProgress) -> [String]? {
        if !p.has(.yamagataHeard) {
            return ["ちょうろう「さいごは 山形じゃ。 花笠まつりの 笠の 花が ちってしまった。",
                    "　山形の まちの 花笠の 師匠に 話を きけ。」"]
        }
        if !p.has(.yamagataPass) {
            return ["ちょうろう「山寺の 門番は 天童の 将棋名人の 弟子じゃ。",
                    "　天童は 山形の 北じゃ。」"]
        }
        if !p.defeatedBosses.contains(.yamaderaCicada) {
            return ["ちょうろう「山寺は 天童の 東の 岩山じゃ。",
                    "　天童の ものの 話を きいておけば ちしきで おいうちが きまるぞ。」"]
        }
        if !p.has(.yamagataBenibana) {
            return ["ちょうろう「蔵王の 樹氷の かべは 紅花の 紅で とけると いう。",
                    "　酒田の 山居倉庫の 問屋を たずねよ。 酒田は 最上川の 河口じゃ。」"]
        }
        if !p.defeatedBosses.contains(.guardian) {
            return ["ちょうろう「蔵王は 山形の 南東。 お釜で 守護神が まっておる。",
                    "　ふかい ほらあなじゃ。 芋煮と さくらんぼを たっぷり もっていけ。」"]
        }
        return nil
    }
}

extension Errand {
    /// 山形の 芋煮屋 → 酒田の 最上川の 船頭。
    static let yamagataImoni = Errand(
        id: "yamagata.imoni", package: "芋煮の なべ",
        ask: ["おかみ「酒田の 船頭さんに 芋煮を とどけて くれないかい？",
              "　酒田は 最上川を くだった 海の そばよ。」"],
        reminder: ["おかみ「芋煮は 酒田の 船頭さんに たのむわね。」"],
        thanks: ["おかみ「とどけて くれたのね！ ありがとう。", "　これは おれいよ。」"],
        after: ["おかみ「山形の 芋煮は 牛肉と しょうゆ味。",
                "　庄内では 豚肉と みそ味なのよ。」"],
        delivered: ["せんどう「山形の 芋煮！ 舟の 上で くうと うまいんだ。」"],
        idle: ["せんどう「最上川は 日本三大急流の ひとつ。",
               "　舟下りでは 最上川舟唄を うたうんだぞ。」"],
        gold: 300, items: [.sakuranbo]
    )
}

extension LostQuest {
    /// 酒田の 港を 見に いった 天童の こども。
    static let cherryKid = LostQuest(
        id: "yamagata.kid",
        ask: ["さくらんぼ のうか「むすめが 酒田の 港を 見にいくって でかけたきり……",
              "　酒田は 天童から 西へ、最上川を くだった さきだ。」"],
        thanks: ["さくらんぼ のうか「かえってきた！ ありがとう！",
                 "　うちの さくらんぼだ。 もっていって くれ。」"],
        after: ["さくらんぼ のうか「さくらんぼは 6月が しゅん。",
                "　ひとつぶ ひとつぶ 手で つむんだよ。」"],
        lost: ["こども「大きな 船を 見てたら かえりかたが わからなく なっちゃった……",
               "　え、父ちゃんが？ かえる！」",
               "こどもは 天童の ほうへ かけていった。"],
        home: ["こども「酒田の 港、大きかったよ！」"],
        gold: 200, items: [.sakuranbo, .sakuranbo]
    )
}

extension Resident {
    func yamagataScene(_ p: StoryProgress) -> StoryScene? {
        switch self {
        case .hanagasaMaster:
            if p.defeatedBosses.contains(.guardian) {
                return StoryScene(lines: [
                    "ししょう「花笠が もどった！ ヤッショ マカショ！",
                    "　東北の 6つの まつりが ぜんぶ もどったのは あなたの おかげよ。」",
                ])
            }
            if p.has(.yamagataBenibana) {
                return StoryScene(lines: [
                    "ししょう「紅花の ぬのを もって 蔵王へ！",
                    "　蔵王は 山形の 南東よ。 守護神を たのんだわ。」",
                ])
            }
            if p.defeatedBosses.contains(.yamaderaCicada) {
                return StoryScene(lines: [
                    "ししょう「山寺に しずけさが もどった……山の 神さまの 声が きこえるわ。",
                    "　『蔵王の 樹氷の かべは 紅花の 紅で ひらく』ですって。",
                    "　紅花は むかし 酒田の 港から 北前船で はこばれたの。",
                    "　酒田の 山居倉庫の 問屋さんなら もっているはずよ。」",
                ])
            }
            if p.has(.yamagataPass) {
                return StoryScene(lines: [
                    "ししょう「山寺は 天童の 東の 岩山よ。",
                    "　大ぜみを しずめて しずけさを とりもどして。」",
                ])
            }
            if p.has(.yamagataHeard) {
                return StoryScene(lines: [
                    "ししょう「天童の 将棋名人を たずねてみて。",
                    "　天童は 山形の 北よ。」",
                ])
            }
            return StoryScene(lines: [
                "ししょう「わたしは 花笠踊りの 師匠。",
                "　花笠まつりでは 紅花の 笠を もって『ヤッショ マカショ』と おどるの。",
                "　でも 蔵王の 守護神が あやつられて、笠の 花が ぜんぶ ちってしまった。",
                "　蔵王へ いくには 山の 神さまの 声を きかなきゃ。",
                "　でも 山寺に 大ぜみが すみついて うるさくて なにも きこえない。",
                "　山寺の 門番は 天童の 将棋名人の 弟子よ。」",
            ], sets: [.yamagataHeard])

        case .shogiMaster:
            if p.defeatedBosses.contains(.yamaderaCicada) {
                return StoryScene(lines: [
                    "めいじん「山寺の 大ぜみを しずめたか。 みごとな 一手じゃ。",
                    "　春には 舞鶴山で 人間将棋を やる。 見にきなされ。」",
                ])
            }
            if p.has(.yamagataPass) {
                return StoryScene(lines: [
                    "めいじん「その 駒を 山寺の 門番に 見せなされ。",
                    "　山寺は 天童の 東じゃ。」",
                ])
            }
            if p.has(.yamagataHeard) {
                return StoryScene(lines: [
                    "めいじん「花笠の 師匠の たのみか。 よかろう。",
                    "　山寺の 門番は わしの 弟子。 この 王将の 駒を 見せれば とおすじゃろう。」",
                    "王将の 駒を あずかった！",
                ], sets: [.yamagataPass])
            }
            return StoryScene(lines: [
                "めいじん「わしは 将棋の 名人じゃ。",
                "　天童は 将棋の 駒の 生産量 日本一。 駒に 字を 書く 職人も おおい。」",
            ])

        case .sakataMerchant:
            if p.defeatedBosses.contains(.guardian) {
                return StoryScene(lines: [
                    "とんや「守護神さまが もどられたか！",
                    "　今年の 庄内米は きっと 豊作じゃ。」",
                ])
            }
            if p.has(.yamagataBenibana) {
                return StoryScene(lines: [
                    "とんや「その ぬのを 蔵王の 樹氷の かべに かかげるのじゃ。」",
                ])
            }
            if p.defeatedBosses.contains(.yamaderaCicada) {
                return StoryScene(lines: [
                    "とんや「蔵王へ いく？ ならば これじゃ。",
                    "　紅花で そめた ぬの。 むかし 北前船で 上方へ はこんだ 山形の たからよ。",
                    "　この 紅なら 樹氷の かべも とけるじゃろう。」",
                    "紅花の ぬのを てにいれた！",
                ], sets: [.yamagataBenibana])
            }
            return StoryScene(lines: [
                "とんや「ここは 山居倉庫。 庄内平野の お米を しまう 倉庫じゃ。",
                "　むかしは 北前船で 紅花や 米を 上方へ はこんだもんじゃ。」",
            ])

        case .imoniCook: return Errand.yamagataImoni.giverScene(p)
        case .sakataBoatman: return Errand.yamagataImoni.receiverScene(p)
        case .cherryFarmer: return LostQuest.cherryKid.seekerScene(p)
        case .lostCherryKid: return LostQuest.cherryKid.lostScene()
        case .cherryKidHome: return LostQuest.cherryKid.homeScene()
        case .yamagataGuide: return Story.stampScene(.yamagata, p, towns: "山形・天童・酒田", gift: .sakuranbo)
        case .yamagataExaminer: return Story.examScene(.yamagata, p)

        case .yamagataDancer:
            return StoryScene(lines: [
                "おどりて「ヤッショ マカショ！",
                "　花笠が もどって 山形の 夏が きたよ！」",
            ])

        case .basho:
            return StoryScene(lines: [
                "たびの はいじん「わたしは 旅の 俳人。",
                "　山寺で『閑さや 岩にしみ入る 蝉の声』と よんだのじゃ。",
                "　いまは 大きな せみが うるさくて 句も よめぬ……」",
            ])

        default: return nil
        }
    }
}

extension QuizBank {
    static let yamagata: [MapID: [Quiz]] = [
        .yamagata: [
            Quiz(question: "山形で 笠を もって おどる まつりは？", choices: ["花笠まつり", "竿燈まつり", "ねぶた祭"], answer: 0),
            Quiz(question: "山形県が 生産量 日本一の くだものは？", choices: ["りんご", "さくらんぼ", "みかん"], answer: 1),
            Quiz(question: "河原で 大なべを かこむ 山形の 秋の 行事は？", choices: ["花見", "雪合戦", "芋煮会"], answer: 2),
            Quiz(question: "山形県の 県の 花は？", choices: ["紅花", "ひまわり", "さくら"], answer: 0),
            Quiz(question: "蔵王の 樹氷の よびなは？", choices: ["ゆきだるま", "スノーモンスター", "こおりおに"], answer: 1),
            Quiz(question: "蔵王の 山頂の エメラルド色の 火口湖は？", choices: ["摩周湖", "田沢湖", "御釜"], answer: 2),
            Quiz(question: "花笠まつりの かけごえは？", choices: ["ヤッショ マカショ", "ラッセラー", "わっしょい"], answer: 0),
            Quiz(question: "山形の 南の 米沢で 有名な 牛肉は？", choices: ["松阪牛", "米沢牛", "神戸牛"], answer: 1),
        ],
        .tendo: [
            Quiz(question: "天童が 生産量 日本一の ものは？", choices: ["将棋の 駒", "こけし", "鉄びん"], answer: 0),
            Quiz(question: "山寺の 正式な 名前は？", choices: ["中尊寺", "瑞巌寺", "立石寺"], answer: 2),
            Quiz(question: "芭蕉の 句『閑さや 岩にしみ入る ○の声』の ○は？", choices: ["鳥", "蝉", "風"], answer: 1),
            Quiz(question: "山寺の 石段の かずは？", choices: ["約1000段", "約100段", "約10000段"], answer: 0),
            Quiz(question: "人が 駒に なる 天童の 春の 行事は？", choices: ["人間ピラミッド", "人間ばしご", "人間将棋"], answer: 2),
            Quiz(question: "山形県が 産地の 西洋なしは？", choices: ["ラ・フランス", "二十世紀", "幸水"], answer: 0),
        ],
        .sakata: [
            Quiz(question: "酒田で 海に そそぐ 日本三大急流は？", choices: ["北上川", "最上川", "信濃川"], answer: 1),
            Quiz(question: "酒田に ある 米を しまった 古い 倉庫は？", choices: ["赤レンガ倉庫", "正倉院", "山居倉庫"], answer: 2),
            Quiz(question: "酒田の まわりに ひろがる 米どころの 平野は？", choices: ["庄内平野", "関東平野", "石狩平野"], answer: 0),
            Quiz(question: "酒田の 北に そびえる『出羽富士』は？", choices: ["岩木山", "鳥海山", "磐梯山"], answer: 1),
            Quiz(question: "むかし 酒田から 紅花や 米を はこんだ 船は？", choices: ["北前船", "黒船", "青函連絡船"], answer: 0),
            Quiz(question: "酒田が めんしている 海は？", choices: ["太平洋", "オホーツク海", "日本海"], answer: 2),
            Quiz(question: "最上川の 舟下りで うたわれる 歌は？", choices: ["最上川舟唄", "ソーラン節", "こきりこ節"], answer: 0),
        ],
    ]
}

extension World {
    /// 山形の 出口の 前（全滅したら ここで 目を さます）。
    static let yamagataGate = Point(x: 13, y: 14)

    static var yamagataMaps: [GameMap] {
        [yamagataField, yamagataTown, tendo, sakata, yamadera1, yamadera2, zao1, zao2, zao3,
         hanagasaHouse, imoniHouse, shogiHouse, tendoHouse, sankyoSouko, sakataHouse]
    }

    /// 山形県。56×36 マス。北西は 日本海と 庄内平野（酒田）、北に 鳥海山、まんなかに 月山。
    /// 最上川が 南から 北へ ながれ、西へ まがって 酒田で 海に そそぐ。
    /// 東がわに 山形と 山形駅、北に 天童、その 東に 山寺。南東に 雪の 蔵王。
    static let yamagataField = GameMap(
        id: .yamagataField,
        name: "山形県",
        kind: .field,
        region: .yamagata,
        rows: [
            "~~~~~~....hMMMh.c..................................hhMMM",
            "~~~~~~..hhMMMMMhh..................................hhMMM",
            "~~~~~...hhhMMMhhh..................................hhMMM",
            "~~~~~...hhhhhhhhh..................................hhMMM",
            "~~~~~.....hhhhh.........ffffffcff..................hhMMM",
            "~~~~~ppppppppppp........fffffffff..................hhMMM",
            "~~~~~ppppppppppp........fffffffff..................hhMMM",
            "~~~~.pppTppppppp........fffffffff..................hhMMM",
            "~~~~.ppp=======p........fffffffff..................hhMMM",
            "~~~~~~~~~~~~~~b~~.......fffffffff..................hhMMM",
            "~~~~.ppppppppp=p~.......fffffffff..................hhMMM",
            "~~~~.ppppppppp==b=====================.............hhMMM",
            "~~~..ppppppppppp~....................=.............hhMMM",
            "~~~..ppppppppppp~~~~~~~~~~~~~~~......T........hhh..hhMMM",
            "~~~..ppppppppppp..............~......==========Mhh.hhMMM",
            "~~~..ppppppppppp..............~......=.......hChMh.hhMMM",
            "~~~............hhhhh..........~......=.......h=hhh.hhMMM",
            "~~............hhMMMhh.........~~~~...=........hhh..hhMMM",
            "~~...........hhMMMMMhh...........~...=.............hhMMM",
            "~~...........hhMMMMMhh...........~...=.............hhMMM",
            "~~...........hhMMMMMhh...........~...=.............hhMMM",
            "~............hhMMMMMhh...........~...=.............hhMMM",
            "~....c.......hhMMMMMhh...........~...T..A..........hhMMM",
            "..............hhMMMhh............~...==========....hhMMM",
            "...............hhhhh......fffffff~............=....hhMMM",
            "..........................fffffff~..........nn=nn..hhMMM",
            "..........................fffffff~........nnnn=nnnnhhMMM",
            "..........................fffffff~........nnnnCnnnnhhMMM",
            "..........................fffffff~.......nnnnn=MMnnnhMMM",
            ".................................~.......nnnnMMMMMnnhMMM",
            "........................c........~.......nnnnMMMMMnnhMMM",
            "....................hhhhhhhhhhhhhhhhhhhhh.nnnMMMMMnhhMMM",
            "....................hhhhhhhhhhhhhhhhhhhhh.nnnnMMMnnhhMMM",
            "....................MMMMMMMMMMMMMMMMMMMMM...nnnnn..hhMMM",
            "....................MMMMMMMMMMMMMMMMMMMMM.........chhMMM",
            "....................MMMMMMMMMMMMMMMMMMMMM..........hhMMM"
        ],
        outside: .mountain,
        warps: [
            Point(x: 37, y: 22): Warp(to: .yamagata, at: Point(x: 13, y: 14)),
            Point(x: 37, y: 13): Warp(to: .tendo, at: Point(x: 11, y: 10)),
            Point(x: 8, y: 7): Warp(to: .sakata, at: Point(x: 11, y: 11)),
            // 山寺は 名人の 王将の 駒、蔵王は 紅花の ぬので ひらく。
            Point(x: 46, y: 15): Warp(to: .yamadera1, at: Point(x: 11, y: 11), needs: .yamagataPass),
            Point(x: 46, y: 27): Warp(to: .zao1, at: Point(x: 12, y: 11), needs: .yamagataBenibana),
        ],
        chestRewards: [.gold(600), .item(.sakuranbo), .item(.dadachamame), .item(.imoni), .gold(700)],
        encounterAreas: [
            EncounterArea(name: "山形のまわり", around: [Point(x: 37, y: 23), Point(x: 40, y: 23), Point(x: 37, y: 18), Point(x: 46, y: 25)],
                          enemies: Balance.places[20].enemies, quizTown: .yamagata),
            EncounterArea(name: "天童へむかう道", around: [Point(x: 37, y: 14), Point(x: 42, y: 14), Point(x: 46, y: 16)],
                          enemies: Balance.places[21].enemies, quizTown: .tendo),
            EncounterArea(name: "酒田へむかう道",
                          around: [Point(x: 8, y: 8), Point(x: 14, y: 11), Point(x: 25, y: 11), Point(x: 5, y: 22), Point(x: 17, y: 26)],
                          enemies: Balance.places[21].enemies, quizTown: .sakata),
        ],
        markerFloor: .grass
    )

    /// 山形。北西の すみに 霞城（山形城あと）、南を 馬見ヶ崎川が ながれる。
    static let yamagataTown = GameMap(
        id: .yamagata,
        name: "やまがた",
        kind: .town,
        region: .yamagata,
        town: TownInfo(name: "山形", reading: "やまがた", tagline: "花笠と さくらんぼの まち",
                       innBase: 12, innPerLevel: 8,
                       stock: [.kitakataRamen, .sakuranbo, .imoni, .byakkoKatana, .mogamiNaginata, .aizuArmor, .benibanaArmor]),
        rows: [
            "############################",
            "#kkkk______________________#",
            "#k_P____HHHHH____HHH____t__#",
            "#k______WWdWW____WdW_______#",
            "#__________________________#",
            "#__t_____P_____________6___#",
            "#__________________________#",
            "#____III____SSS_____t______#",
            "#____YdW____ZdW______3_____#",
            "#__________________________#",
            "#_t______e________2________#",
            "#__________________________#",
            "#~~~~~~~~~~~bb~~~~~~~~~~~~~#",
            "#____t___________P____c____#",
            "#__________________________#",
            "############EEEE############"
        ],
        outside: .grass,
        warps: [
            Point(x: 10, y: 3): Warp(to: .hanagasaHouse, at: Point(x: 4, y: 4)),
            Point(x: 18, y: 3): Warp(to: .imoniHouse, at: Point(x: 4, y: 4)),
            Point(x: 6, y: 8): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 13, y: 8): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(12...15, row: 15, to: .yamagataField, at: Point(x: 37, y: 23))) { first, _ in first },
        villagers: [
            ["のうか「山形県は さくらんぼの 生産量 日本一！」"],
            ["おばさん「秋には 河原で 芋煮会。",
             "　大なべで 里いもを にて みんなで たべるのよ。」"],
            ["むすめ「山形県の 県の 花は 紅花。",
             "　むかしは 口べにの 材料だったの。」"],
            ["やまおとこ「蔵王の 樹氷は スノーモンスターと よばれる。",
             "　山頂には 御釜と いう エメラルド色の 火口湖も あるんだ。」"],
            ["おじいさん「南の 米沢は 米沢牛が 有名じゃ。」"],
        ],
        residents: ["2": .yamagataGuide, "3": .yamagataExaminer, "6": .yamagataDancer],
        plaques: [
            Point(x: 3, y: 2): Plaque(title: "霞城", lines: [
                "かんばんに こう かいてある。",
                "「霞城公園（山形城跡）」",
                "最上義光の 城あと。 春は さくらの 名所。",
            ]),
            Point(x: 9, y: 5): Plaque(title: "文翔館", lines: [
                "かんばんに こう かいてある。",
                "「文翔館」",
                "大正時代の れんがの 県庁舎。",
            ]),
            Point(x: 17, y: 13): Plaque(title: "芋煮", lines: [
                "かんばんに こう かいてある。",
                "「日本一の 芋煮会フェスティバル」",
                "大きな なべを ショベルカーで かきまぜる。",
            ]),
        ],
        chestRewards: [.item(.imoni)]
    )

    /// 天童。将棋の 駒の まち。西に 舞鶴山。
    static let tendo = GameMap(
        id: .tendo,
        name: "てんどう",
        kind: .town,
        region: .yamagata,
        town: TownInfo(name: "天童", reading: "てんどう", tagline: "将棋の 駒の まち",
                       innBase: 12, innPerLevel: 8,
                       stock: [.sakuranbo, .imoni, .mogamiNaginata, .benibanaArmor]),
        rows: [
            "########################",
            "#______________________#",
            "#_HHHHH___HHH______t___#",
            "#_WWdWW___WdW__________#",
            "#______________________#",
            "#__P_____1_______P_____#",
            "#______________________#",
            "#_III____SSS_____t_____#",
            "#_YdW____ZdW___________#",
            "#______________________#",
            "#_t____e__________c____#",
            "##########EEEE##########"
        ],
        outside: .grass,
        warps: [
            Point(x: 4, y: 3): Warp(to: .shogiHouse, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 3): Warp(to: .tendoHouse, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 8): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 10, y: 8): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(10...13, row: 11, to: .yamagataField, at: Point(x: 37, y: 14))) { first, _ in first },
        villagers: [
            ["しょくにん「天童は 将棋の 駒の 生産量 日本一！」"],
            ["おぼうさん「山寺の 正式な 名前は 立石寺。",
             "　石段は 約1000段 あるのですよ。」"],
            ["おばさん「山形は 西洋なしの ラ・フランスの 産地でも あるのよ。」"],
        ],
        residents: ["1": .basho],
        plaques: [
            Point(x: 3, y: 5): Plaque(title: "舞鶴山", lines: [
                "かんばんに こう かいてある。",
                "「舞鶴山 人間将棋の 会場」",
                "春に 人が 駒に なって 将棋を さす『人間将棋』の 会場。",
            ]),
            Point(x: 17, y: 5): Plaque(title: "温泉", lines: [
                "かんばんに こう かいてある。",
                "「天童温泉」",
                "将棋の まちの 温泉。",
            ]),
        ],
        chestRewards: [.item(.sakuranbo)]
    )

    /// 酒田。日本海の みなとまち。南を 最上川が ながれる。
    static let sakata = GameMap(
        id: .sakata,
        name: "さかた",
        kind: .town,
        region: .yamagata,
        town: TownInfo(name: "酒田", reading: "さかた", tagline: "最上川と 北前船の みなと",
                       innBase: 13, innPerLevel: 8,
                       stock: [.sakuranbo, .imoni, .mogamiNaginata, .benibanaArmor]),
        rows: [
            "########################",
            "#~~~~~~~~~~~~~~~~~~~~~~#",
            "#~~~____P_______~~~~~~~#",
            "#~~______________t_____#",
            "#__HHHHHH____HHH_______#",
            "#__WWWdWW____WdW___P___#",
            "#______________________#",
            "#_III___SSS____t____1__#",
            "#_YdW___ZdW____________#",
            "#_______e_______2______#",
            "#~~~~~~~~~~~bb~~~~~~~~~#",
            "#__t______________c____#",
            "##########EEEE##########"
        ],
        outside: .grass,
        warps: [
            Point(x: 6, y: 5): Warp(to: .sankyoSouko, at: Point(x: 4, y: 4)),
            Point(x: 14, y: 5): Warp(to: .sakataHouse, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 8): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 9, y: 8): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(10...13, row: 12, to: .yamagataField, at: Point(x: 8, y: 8))) { first, _ in first },
        villagers: [
            ["のうか「酒田の まわりは 庄内平野。 お米の 一大産地さ。」"],
            ["りょうし「北に 見える 鳥海山は『出羽富士』とも よばれるんだ。」"],
            ["おばさん「酒田は 日本海に めんした みなとまちよ。」"],
        ],
        residents: ["1": .sakataBoatman, "2": .lostCherryKid],
        plaques: [
            Point(x: 8, y: 2): Plaque(title: "日和山", lines: [
                "かんばんに こう かいてある。",
                "「日和山公園」",
                "船乗りが 海の ようすを 見た 丘。",
            ]),
            Point(x: 19, y: 5): Plaque(title: "山居", lines: [
                "かんばんに こう かいてある。",
                "「山居倉庫」",
                "明治に たてられた 米の 倉庫。 ケヤキ並木が つづく。",
            ]),
        ],
        chestRewards: [.gold(300)]
    )

    /// 山寺（立石寺）。岩山の 石段の ほらあな。
    static let yamadera1 = cave(
        .yamadera1, name: "山寺 B1", label: "山寺", region: .yamagata,
        rows: [
            "###################",
            "#,,,,,,,,#,,,,,,,c#",
            "#,#####,,#,,#####,#",
            "#,#,,,#,,,,,#,,,#,#",
            "#,#,#,#######,#,#,#",
            "#,,,#,,,,,,,,,#,,,#",
            "#####,###,###,#####",
            "#c,,,,#,,,,,#,,,,D#",
            "#,###,#,###,#,###,#",
            "#,,,#,,,#,#,,,#,,,#",
            "###,#####,,,###,###",
            "#,,,,,,,,,U,,,,,,,#",
            "###################"
        ],
        warps: [
            Point(x: 10, y: 11): Warp(to: .yamagataField, at: Point(x: 46, y: 16)),
            Point(x: 17, y: 7): Warp(to: .yamadera2, at: Point(x: 6, y: 8)),
        ],
        chestRewards: [.gold(650), .item(.sakuranbo)],
        enemies: Balance.places[22].enemies, quizTown: .tendo
    )

    static let yamadera2 = cave(
        .yamadera2, name: "山寺 奥之院", region: .yamagata,
        rows: [
            "###############",
            "#,,,,,,B,,,,,,#",
            "#,,,,,,,,,,,,,#",
            "####,,,,,,,####",
            "#,,,,###,###,,#",
            "#,##,#c,,,#,,,#",
            "#,#,,#,###,,#,#",
            "#,#,##,,,,,##,#",
            "#,,,,,,U,,,,,,#",
            "###############"
        ],
        warps: [Point(x: 7, y: 8): Warp(to: .yamadera1, at: Point(x: 17, y: 8))],
        chestRewards: [.item(.juhyoSword)],
        bossKind: .yamaderaCicada, enemies: Balance.places[22].enemies, quizTown: .tendo
    )

    /// 蔵王。3階だての 樹氷の ほらあな。いちばん奥の お釜に 守護神。
    static let zao1 = cave(
        .zao1, name: "蔵王 樹氷原", label: "蔵王", region: .yamagata,
        rows: [
            "#####################",
            "#,,,,,,,,#,,,,,,,,,c#",
            "#,#####,,#,,,#####,,#",
            "#,#,,,#,###,,#,,,#,,#",
            "#,#,#,#,,,,,,#,#,#,##",
            "#,,,#,,,###,,,,#,,,D#",
            "###,#####,#,#####,###",
            "#,,,,,,,,,#,,,,,,,,,#",
            "#,###,#####,#####,#,#",
            "#,#c,,,,,,,,,,,,,#,,#",
            "#,#########,#######,#",
            "#,,,,,,,,,,U,,,,,,,,#",
            "#####################"
        ],
        warps: [
            Point(x: 11, y: 11): Warp(to: .yamagataField, at: Point(x: 46, y: 28)),
            Point(x: 19, y: 5): Warp(to: .zao2, at: Point(x: 10, y: 11)),
        ],
        chestRewards: [.item(.juhyoArmor), .gold(700)],
        enemies: Balance.places[23].enemies, quizTown: .yamagata
    )

    static let zao2 = cave(
        .zao2, name: "蔵王 地蔵岳", region: .yamagata,
        rows: [
            "###################",
            "#D,,,,#,,,,,#,,,,c#",
            "###,#,#,###,#,###,#",
            "#,,,#,,,#,,,,,#,,,#",
            "#,#######,#####,#,#",
            "#,,,,,,,#,,,,,,,#,#",
            "#####,#,#,#####,#,#",
            "#,,,,,#,,,#,,,,,#,#",
            "#,###,#####,###,#,#",
            "#,,,#,,,,,,,,,#,,,#",
            "###,#####,#####,###",
            "#,,,,,,,,U,,,,,,,,#",
            "###################"
        ],
        warps: [
            Point(x: 9, y: 11): Warp(to: .zao1, at: Point(x: 18, y: 5)),
            Point(x: 1, y: 1): Warp(to: .zao3, at: Point(x: 9, y: 9)),
        ],
        chestRewards: [.item(.shakudama)],
        enemies: Balance.places[23].enemies, quizTown: .yamagata
    )

    static let zao3 = cave(
        .zao3, name: "蔵王 お釜", region: .yamagata,
        rows: [
            "#################",
            "#,,,,,,,B,,,,,,,#",
            "#,,~~~~~~~~~~~,,#",
            "#,,~~~~~~~~~~~,,#",
            "#,,,,~~~~~~~,,,,#",
            "##,,,,,,,,,,,,,##",
            "#,,###,,,,,###,,#",
            "#,,#c,,,,,,,#,,,#",
            "#,,#####,####,,,#",
            "#,,,,,,,U,,,,,,,#",
            "#################"
        ],
        warps: [Point(x: 8, y: 9): Warp(to: .zao2, at: Point(x: 2, y: 1))],
        chestRewards: [.item(.imoni)],
        bossKind: .guardian, enemies: Balance.places[23].enemies, quizTown: .yamagata
    )

    // MARK: 家の中

    static let hanagasaHouse = house(
        .hanagasaHouse, name: "花笠の 会所",
        rows: [
            "XXXXXXXXX",
            "XLL1oLLcX",
            "XoooooooX",
            "XooooootX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .yamagata, region: .yamagata, door: Point(x: 10, y: 3),
        villagers: [["でし「花笠は 紅花を かたどった 笠なんです。」"]],
        residents: ["1": .hanagasaMaster], chestRewards: [.gold(250)]
    )

    static let imoniHouse = house(
        .imoniHouse, name: "芋煮や",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLcX",
            "XooKKKooX",
            "Xoo1ooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .yamagata, region: .yamagata, door: Point(x: 18, y: 3),
        villagers: [],
        residents: ["1": .imoniCook], chestRewards: [.item(.imoni)]
    )

    static let shogiHouse = house(
        .shogiHouse, name: "将棋会館",
        rows: [
            "XXXXXXXXX",
            "XLLL1LLcX",
            "XoooooooX",
            "XotoooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .tendo, region: .yamagata, door: Point(x: 4, y: 3),
        villagers: [["こましょくにん「駒の 字は うるしで 書くんだ。",
                     "　『王将』の 駒は とくに ていねいに 書くんだよ。」"]],
        residents: ["1": .shogiMaster], chestRewards: [.gold(300)]
    )

    static let tendoHouse = house(
        .tendoHouse, name: "さくらんぼ農家",
        rows: [
            "XXXXXXXXX",
            "XLLo1o2cX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .tendo, region: .yamagata, door: Point(x: 11, y: 3),
        villagers: [],
        residents: ["1": .cherryFarmer, "2": .cherryKidHome], chestRewards: [.item(.sakuranbo)]
    )

    static let sankyoSouko = house(
        .sankyoSouko, name: "山居倉庫",
        rows: [
            "XXXXXXXXX",
            "XLLL1LLcX",
            "XoooooooX",
            "XoooootoX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .sakata, region: .yamagata, door: Point(x: 6, y: 5),
        villagers: [["くらばん「山居倉庫の 屋根は 二重。",
                     "　夏の あつさから お米を まもるんじゃ。」"]],
        residents: ["1": .sakataMerchant], chestRewards: [.item(.imoni)]
    )

    static let sakataHouse = house(
        .sakataHouse, name: "船問屋",
        rows: [
            "XXXXXXXXX",
            "XcLLoLLLX",
            "XoooooooX",
            "XootooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .sakata, region: .yamagata, door: Point(x: 14, y: 5),
        villagers: [["ふなどんや「北前船は 酒田から 日本海を とおって 上方へ いったんじゃ。」"]],
        chestRewards: [.gold(350)]
    )
}
