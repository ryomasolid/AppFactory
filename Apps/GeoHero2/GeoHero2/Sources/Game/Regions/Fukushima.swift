import Foundation

// MARK: - 福島県
//
// 福島で わらじまつりの 世話役に 話を きき、会津の 鶴ヶ城の 城代に あぶくま洞へ 入る ゆるしを もらう。
// あぶくま洞の 石筍の ぬし（中ボス）を 倒すと、喜多方の 赤べこが 磐梯山の 道を 案内してくれる。
// 手長足長（ぬし）を 倒すと 大わらじが もどり、山形へ 行ける。

extension StoryFlag {
    /// わらじまつりの 世話役から 話を きいた。
    static let fukushimaHeard: StoryFlag = "fukushima.heard"
    /// 鶴ヶ城の 城代から あぶくま洞へ 入る ゆるしを もらった。
    static let fukushimaAbukuma: StoryFlag = "fukushima.abukuma"
    /// 赤べこが 磐梯山の 道を 案内してくれる。
    static let fukushimaBandai: StoryFlag = "fukushima.bandai"
}

extension Story {
    static let fukushimaGates: [StoryFlag: [String]] = [
        .fukushimaAbukuma: ["あぶくま洞の 入口に 立て札が ある。",
                            "「ぬし あばれる。 立ち入り禁止 ─ 鶴ヶ城 城代」",
                            "（城代の ゆるしが あれば……）"],
        .fukushimaBandai: ["磐梯山の 山道は きりが こくて 道が わからない。",
                           "（道を しる 案内が あれば……）"],
    ]

    static let fukushimaImplications: [StoryFlag: EnemyKind] = [
        .fukushimaHeard: .abukumaLord,
        .fukushimaAbukuma: .abukumaLord,
        .fukushimaBandai: .tenagaAshinaga,
    ]

    static func fukushimaHint(_ p: StoryProgress) -> [String]? {
        if !p.has(.fukushimaHeard) {
            return ["ちょうろう「福島では わらじまつりの 大わらじが ぬすまれたそうじゃ。",
                    "　福島の まちの わらじまつりの 世話役に 話を きけ。」"]
        }
        if !p.has(.fukushimaAbukuma) {
            return ["ちょうろう「会津の 鶴ヶ城の 城代を たずねよ。",
                    "　会津若松は 福島の 南西、猪苗代湖の 西じゃ。」"]
        }
        if !p.defeatedBosses.contains(.abukumaLord) {
            return ["ちょうろう「あぶくま洞は 福島の 南東、阿武隈の 山の ふもとじゃ。",
                    "　福島の ものの 話を きいておけば ちしきで おいうちが きまるぞ。」"]
        }
        if !p.has(.fukushimaBandai) {
            return ["ちょうろう「磐梯山の 道は 喜多方の 赤べこが しっておる。",
                    "　喜多方は 会津若松の 北じゃ。」"]
        }
        if !p.defeatedBosses.contains(.tenagaAshinaga) {
            return ["ちょうろう「磐梯山は 猪苗代湖の 北じゃ。 手長足長は ふたりで ひとつの 巨人。",
                    "　会津で 白虎の刀と 会津塗の鎧を そろえて いどむのじゃ。」"]
        }
        return nil
    }
}

extension Errand {
    /// 喜多方の ラーメン屋 → 会津若松の 町の 人。
    static let fukushimaRamen = Errand(
        id: "fukushima.ramen", package: "喜多方ラーメン",
        ask: ["ラーメンや「会津若松の だんなに 出前を たのまれてね。",
              "　めんが のびないうちに たのむよ！ 会津は 喜多方の 南だ。」"],
        reminder: ["ラーメンや「はやく 会津の だんなへ！ のびちまう！」"],
        thanks: ["ラーメンや「まにあったか！ ありがとよ。", "　これは 出前の おだちんだ。」"],
        after: ["ラーメンや「喜多方ラーメンは ひらたい ちぢれめんが じまんさ。",
                "　朝から ラーメンを たべる『朝ラー』も あるんだぞ。」"],
        delivered: ["だんな「おお、喜多方ラーメン！ まだ あつあつだ。」"],
        idle: ["だんな「会津の おいわいには こづゆを たべるんだ。",
               "　磐梯山の 北には いろいろな 色の 五色沼も あるぞ。」"],
        gold: 250, items: [.momo]
    )
}

extension LostQuest {
    /// 白虎隊の 剣舞を ならいに 会津へ いった 福島の こども。
    static let byakko = LostQuest(
        id: "fukushima.byakko",
        ask: ["ももの のうか「むすこが 白虎隊の 剣舞を ならうって",
              "　会津へ いったきり かえって こないんだ。",
              "　会津若松は 福島の 南西だ。 さがして くれないか。」"],
        thanks: ["ももの のうか「かえってきた！ ありがとう！",
                 "　うちの もも、もっていっておくれ。」"],
        after: ["ももの のうか「福島の ももは 夏が しゅん。",
                "　あまくて じゅわっと するぞ。」"],
        lost: ["こども「剣舞の れんしゅうしてたら おそく なっちゃった……",
               "　え、父ちゃんが しんぱいしてる？ かえらなきゃ！」",
               "こどもは 福島の ほうへ かけていった。"],
        home: ["こども「えいっ！ 白虎隊の 剣舞、うまく なったでしょ！」"],
        gold: 150, items: [.momo, .momo]
    )
}

extension Resident {
    func fukushimaScene(_ p: StoryProgress) -> StoryScene? {
        switch self {
        case .warajiMaster:
            if p.defeatedBosses.contains(.tenagaAshinaga) {
                return StoryScene(lines: [
                    "せわやく「大わらじが もどった！ わっしょい！",
                    "　さいごは 山形だ。 花笠まつりの 笠が ちってしまったらしい。",
                    "　駅から 新幹線で 山形へ いってくれ。」",
                ])
            }
            if p.has(.fukushimaBandai) {
                return StoryScene(lines: [
                    "せわやく「赤べこの 案内で 磐梯山へ！",
                    "　磐梯山は 猪苗代湖の 北だ。」",
                ])
            }
            if p.defeatedBosses.contains(.abukumaLord) {
                return StoryScene(lines: [
                    "せわやく「あぶくま洞の ぬしを たおしたか！",
                    "　あとは 磐梯山だ。 会津の 城代に しらせると いい。」",
                ])
            }
            if p.has(.fukushimaHeard) {
                return StoryScene(lines: [
                    "せわやく「会津の 鶴ヶ城の 城代を たずねてくれ。",
                    "　会津若松は 福島の 南西、猪苗代湖の 西だ。」",
                ])
            }
            return StoryScene(lines: [
                "せわやく「おれは わらじまつりの 世話役だ。",
                "　わらじまつりでは 長さ 12メートルの 大わらじを かついで まちを ねりあるく。",
                "　ところが 磐梯山の 手長足長が 大わらじを もっていっちまった。",
                "　磐梯山へ のぼるなら 会津の 鶴ヶ城の 城代に たのむしか ない。」",
            ], sets: [.fukushimaHeard])

        case .castleWarden:
            if p.defeatedBosses.contains(.tenagaAshinaga) {
                return StoryScene(lines: [
                    "じょうだい「手長足長を しりぞけたか。 みごとじゃ。",
                    "　会津の ひとびとも よろこんで おる。」",
                ])
            }
            if p.defeatedBosses.contains(.abukumaLord) {
                return StoryScene(lines: [
                    "じょうだい「あぶくま洞の ぬしを たおすとは あっぱれ！",
                    "　磐梯山の 道は きりが こい。 喜多方に すむ 赤べこが 案内してくれよう。",
                    "　赤べこは むかし お寺を たてる 手つだいを した えらい 牛の 子孫じゃ。」",
                ])
            }
            if p.has(.fukushimaAbukuma) {
                return StoryScene(lines: [
                    "じょうだい「あぶくま洞は 福島の 南東じゃ。",
                    "　ぬしを たおして ちからを しめして まいれ。」",
                ])
            }
            if p.has(.fukushimaHeard) {
                return StoryScene(lines: [
                    "じょうだい「磐梯山へ のぼりたいと？ 手長足長は おそろしい 巨人じゃ。",
                    "　まずは あぶくま洞の ぬしを たおして ちからを しめしてみよ。",
                    "　洞の 立ち入りを ゆるす。」",
                    "あぶくま洞へ 入る ゆるしを もらった！",
                ], sets: [.fukushimaAbukuma])
            }
            return StoryScene(lines: [
                "じょうだい「わしは 鶴ヶ城の 城代じゃ。",
                "　鶴ヶ城は 白い かべと 赤い かわらの 城。",
                "　……なにか ようか？ 福島の まちが さわがしいと きくが。」",
            ])

        case .akabekoKeeper:
            if p.has(.fukushimaBandai) {
                return StoryScene(lines: [
                    "赤べこ「モォー！」",
                    "（磐梯山へ いこう、と いっている ようだ）",
                ])
            }
            if p.defeatedBosses.contains(.abukumaLord) {
                return StoryScene(lines: [
                    "赤べこ「モォー……モォー！」",
                    "赤べこは くびを ゆらゆら ふって 山の ほうを 見ている。",
                    "赤べこが 磐梯山の 道を 案内してくれる ことに なった！",
                ], sets: [.fukushimaBandai])
            }
            return StoryScene(lines: [
                "赤べこ「モォー。」",
                "赤べこは じっと こちらを 見ている。",
            ])

        case .ramenMaster: return Errand.fukushimaRamen.giverScene(p)
        case .aizuReceiver: return Errand.fukushimaRamen.receiverScene(p)
        case .peachFarmer: return LostQuest.byakko.seekerScene(p)
        case .lostByakko: return LostQuest.byakko.lostScene()
        case .byakkoHome: return LostQuest.byakko.homeScene()
        case .fukushimaGuide: return Story.stampScene(.fukushima, p, towns: "福島・会津若松・喜多方", gift: .kitakataRamen)
        case .fukushimaExaminer: return Story.examScene(.fukushima, p)

        case .fukushimaDancer:
            return StoryScene(lines: [
                "かつぎて「わっしょい！ わっしょい！",
                "　大わらじが もどって 福島の 夏が きたぞ！」",
            ])

        case .okiagariMaker:
            return StoryScene(lines: [
                "みんげいや「赤い 牛の 赤べこと、たおしても おきあがる 起き上がり小法師。",
                "　どちらも 会津の えんぎものさ。」",
            ])

        default: return nil
        }
    }
}

extension QuizBank {
    static let fukushima: [MapID: [Quiz]] = [
        .fukushima: [
            Quiz(question: "福島市で 大きな わらじを かつぐ まつりは？", choices: ["わらじまつり", "ねぶた祭", "竿燈まつり"], answer: 0),
            Quiz(question: "福島市が 産地として 有名な くだものは？", choices: ["みかん", "もも", "パイナップル"], answer: 1),
            Quiz(question: "『UFOの里』と よばれる 福島市の 町は？", choices: ["大洗町", "白川町", "飯野町"], answer: 2),
            Quiz(question: "『種まきうさぎ』の 雪形が 出る 福島市の 西の 山は？", choices: ["吾妻山", "岩木山", "月山"], answer: 0),
            Quiz(question: "福島県は 都道府県で 何番めに ひろい？", choices: ["1番", "3番", "10番"], answer: 1),
            Quiz(question: "福島県の 海ぞいの 地方の よびなは？", choices: ["中通り", "会津", "浜通り"], answer: 2),
        ],
        .aizu: [
            Quiz(question: "会津若松に ある 白い かべの お城は？", choices: ["鶴ヶ城", "姫路城", "弘前城"], answer: 0),
            Quiz(question: "戊辰戦争で たたかった 会津の 少年たちの 隊は？", choices: ["新選組", "白虎隊", "奇兵隊"], answer: 1),
            Quiz(question: "会津の 赤い 牛の 郷土玩具は？", choices: ["だるま", "こけし", "赤べこ"], answer: 2),
            Quiz(question: "たおしても おきあがる 会津の 人形は？", choices: ["起き上がり小法師", "こけし", "はにわ"], answer: 0),
            Quiz(question: "会津に つたわる うるしの 工芸は？", choices: ["輪島塗", "会津塗", "津軽塗"], answer: 1),
            Quiz(question: "会津の まちの 東に ある 大きな 湖は？", choices: ["猪苗代湖", "田沢湖", "十和田湖"], answer: 0),
            Quiz(question: "磐梯山の 北に ある いろいろな 色の 沼は？", choices: ["尾瀬沼", "八郎潟", "五色沼"], answer: 2),
            Quiz(question: "会津の おいわいの すいものは？", choices: ["芋煮", "こづゆ", "せんべい汁"], answer: 1),
        ],
        .kitakata: [
            Quiz(question: "喜多方の 名物の めんは？", choices: ["喜多方ラーメン", "稲庭うどん", "盛岡冷麺"], answer: 0),
            Quiz(question: "喜多方は なにが 多い まち？", choices: ["洋館", "蔵", "武家屋敷"], answer: 1),
            Quiz(question: "赤べこの 伝説で 寺を たてるのを てつだったのは？", choices: ["白い 馬", "黒い 犬", "赤い 牛"], answer: 2),
            Quiz(question: "『宝の山よ』と うたわれる 会津の 山は？", choices: ["磐梯山", "岩手山", "鳥海山"], answer: 0),
            Quiz(question: "磐梯山に すんでいたと いう 伝説の 巨人は？", choices: ["ダイダラボッチ", "手長足長", "一つ目小僧"], answer: 1),
            Quiz(question: "猪苗代湖の べつの よびなは？", choices: ["瑠璃湖", "白鳥湖", "天鏡湖"], answer: 2),
        ],
    ]
}

extension World {
    /// 福島の 出口の 前（全滅したら ここで 目を さます）。
    static let fukushimaGate = Point(x: 12, y: 12)

    static var fukushimaMaps: [GameMap] {
        [fukushimaField, fukushimaTown, aizu, kitakata, abukumado, bandai1, bandai2,
         tsurugajo, akabekoHouse, kuraHouse, ramenHouse, warajiHouse, momoHouse]
    }

    /// 福島県。56×36 マス。東は 太平洋（浜通り）、阿武隈高地を はさんで 中通りに 福島と 福島駅、南東に あぶくま洞。
    /// 奥羽山脈の 西が 会津で、会津盆地に 喜多方と 会津若松、まんなかに 磐梯山と 猪苗代湖。北に 吾妻山。
    static let fukushimaField = GameMap(
        id: .fukushimaField,
        name: "福島県",
        kind: .field,
        region: .fukushima,
        rows: [
            "MM................hhMMMMhh........................~~~~~~",
            "MM................hhMMMMhh..hhhch.................~~~~~~",
            "MM................hhMMMMhh.hhMMMhh..............c.~~~~~~",
            "MM................hhMMMMhh.hMMMMMh................~~~~~~",
            "MM..fffffffff.....hhMMMMhh.hhMMMhh......hhhhhhh...~~~~~~",
            "MM..ffcffffff.....hhMMMMhh..hhhhh.......hhhhhhh...~~~~~~",
            "MM..fffffffff.....hhMMMMhh..............hhhhhhh...~~~~~~",
            "MM..fffffffff.....hhMMMMhh..............hhhhhhh...~~~~~~",
            "MM..fffffffff.....hhMMMMhh..............hhhhhhh...~~~~~~",
            "MM..fffffffff.....hhMMMMhh.......T..A...hhhhhhh...~~~~~~",
            "MM................hhMMMMhh.......====...hhMMMhh...~~~~~~",
            "MM.....T..........hhMMMMhh.......=......hhMMMhh...~~~~~~",
            "MM.....==.........hhMMMMhh.......=......hhMMMhh...~~~~~~",
            "MM......=.........hhMMMMhh.......=......hhMMMhh...~~~~~~",
            "MM.ppppp=pppp.....hhMMMMhh.......=......hhMMMhh...~~~~~~",
            "MM.ppppp=pppp.....hhMMMMhh.......=......hhMMMhh...~~~~~~",
            "MM.ppppp=pppp.....hhMMMMhh.......=......hhMMMhh...~~~~~~",
            "MM.ppppp=pppp.....hhMMMMhh.......=......hhMMMhh...~~~~~~",
            "MM.ppppp=pppp..~.~hhMMMMhh.......=......hhMMMhh...~~~~~~",
            "MM.ppppp=pppp...~.MhMMMMhh.......=......hhMMMhh...~~~~~~",
            "MM.ppppp=pppp...hhChhMMMhh.......=......hhMMMhh...~~~~~~",
            "MM.ppppp=pppp..====Mhh...........=......hhMMMhh...~~~~~~",
            "MM.ppppp=pppp..=MMMMMh........fff=ffff..hhMMMhh...~~~~~~",
            "MM.ppppp=pppp..=hMMMhh........fff=ffff..hhMMMhh...~~~~~~",
            "MM.ppppp=pppp..=hhhhh.........fff=ffff..hhMMMhh...~~~~~~",
            "MM......=......=========================hhhhhhh...~~~~~~",
            "MM......T=======...~~~~~......ffffffff.=hhhhhhh...~~~~~~",
            "MM......=........~~~~~~~~~....ffffffff.=hhhhhhh...~~~~~~",
            "MM..............~~~~~~~~~~~...ffffffff.=hhhhhhh...~~~~~~",
            "MM..............~~~~~~~~~~~...ffffffff.=hhhhhhh...~~~~~~",
            "MM..............~~~~~~~~~~~...ffffffff.=hhhhhhh...~~~~~~",
            "MM...............~~~~~~~~~.............=..........~~~~~~",
            "MMhhhhhhhhhhhhh....~~~~~...............=.....C....~~~~~~",
            "MMhhhhhhhhhhhhh...........c............=======....~~~~~~",
            "MMMMMMMMMMMMMMM................................c..~~~~~~",
            "MMMMMMMMMMMMMMM...................................~~~~~~"
        ],
        outside: .mountain,
        warps: [
            Point(x: 33, y: 9): Warp(to: .fukushima, at: Point(x: 12, y: 12)),
            Point(x: 8, y: 26): Warp(to: .aizu, at: Point(x: 13, y: 14)),
            Point(x: 7, y: 11): Warp(to: .kitakata, at: Point(x: 9, y: 9)),
            // あぶくま洞は 城代の ゆるし、磐梯山は 赤べこの 案内で ひらく。
            Point(x: 45, y: 32): Warp(to: .abukumado, at: Point(x: 11, y: 11), needs: .fukushimaAbukuma),
            Point(x: 18, y: 20): Warp(to: .bandai1, at: Point(x: 11, y: 11), needs: .fukushimaBandai),
        ],
        chestRewards: [.gold(450), .item(.kitakataRamen), .item(.hanabi), .item(.yonezawaBeef), .gold(500)],
        encounterAreas: [
            EncounterArea(name: "福島のまわり",
                          around: [Point(x: 33, y: 10), Point(x: 36, y: 10), Point(x: 33, y: 18), Point(x: 39, y: 30), Point(x: 45, y: 33)],
                          enemies: Balance.places[16].enemies, quizTown: .fukushima),
            EncounterArea(name: "会津へむかう道", around: [Point(x: 8, y: 27), Point(x: 15, y: 25), Point(x: 18, y: 21), Point(x: 25, y: 25)],
                          enemies: Balance.places[17].enemies, quizTown: .aizu),
            EncounterArea(name: "喜多方へむかう道", around: [Point(x: 7, y: 12), Point(x: 8, y: 6), Point(x: 8, y: 18)],
                          enemies: Balance.places[17].enemies, quizTown: .kitakata),
        ],
        markerFloor: .grass
    )

    /// 福島。北西の 丘から 吾妻山が 見える。
    static let fukushimaTown = GameMap(
        id: .fukushima,
        name: "ふくしま",
        kind: .town,
        region: .fukushima,
        town: TownInfo(name: "福島", reading: "ふくしま", tagline: "ももと わらじの まち",
                       innBase: 10, innPerLevel: 7,
                       stock: [.gyutan, .momo, .kitakataRamen, .dateKatana, .byakkoKatana, .dateArmor, .aizuArmor]),
        rows: [
            "##########################",
            "#hhhhh___________________#",
            "#hhPhh__HHHHH____HHH__t__#",
            "#hhhhh__WWdWW____WdW_____#",
            "#______________________6_#",
            "#__t_____P_______________#",
            "#________________________#",
            "#__III____SSS______t_____#",
            "#__YdW____ZdW____3_______#",
            "#________________________#",
            "#_t_____e______________P_#",
            "#____________t___________#",
            "#__________c_____________#",
            "###########EEEE###########"
        ],
        outside: .grass,
        warps: [
            Point(x: 10, y: 3): Warp(to: .warajiHouse, at: Point(x: 4, y: 4)),
            Point(x: 18, y: 3): Warp(to: .momoHouse, at: Point(x: 4, y: 4)),
            Point(x: 4, y: 8): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 8): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(11...14, row: 13, to: .fukushimaField, at: Point(x: 33, y: 10))) { first, _ in first },
        villagers: [
            ["おばさん「福島市は ももの 産地として 有名なのよ。",
             "　夏は あまい もも が いっぱい！」"],
            ["おとこ「西に 見えるのが 吾妻山。",
             "　春には 山に『種まきうさぎ』の 雪形が 出るんだ。」"],
            ["がくせい「福島県は 北海道、岩手に つぐ",
             "　3番めに ひろい 県なんだよ。」"],
            ["おじいさん「福島県は 会津・中通り・浜通りの 3つに わかれる。",
             "　海ぞいが 浜通り、ここ 福島市は 中通りじゃ。」"],
            ["こども「飯野町は『UFOの里』なんだよ！",
             "　UFOを 見たって 人が いっぱい いるんだって。」"],
        ],
        residents: ["3": .fukushimaExaminer, "6": .fukushimaDancer],
        plaques: [
            Point(x: 3, y: 2): Plaque(title: "吾妻山", lines: [
                "かんばんに こう かいてある。",
                "「吾妻小富士 てんぼう」",
                "まあるい 火口の 山が 見える。",
            ]),
            Point(x: 9, y: 5): Plaque(title: "花見山", lines: [
                "かんばんに こう かいてある。",
                "「花見山公園」",
                "春は 山じゅうが 花で つつまれる。",
            ]),
            Point(x: 23, y: 10): Plaque(title: "UFO", lines: [
                "かんばんに こう かいてある。",
                "「UFOふれあい館（飯野町）」",
                "UFOの 里の 資料館。",
            ]),
        ],
        chestRewards: [.item(.momo)]
    )

    /// 会津若松。北に 鶴ヶ城、北西の 丘が 飯盛山。
    static let aizu = GameMap(
        id: .aizu,
        name: "あいづわかまつ",
        kind: .town,
        region: .fukushima,
        town: TownInfo(name: "会津若松", reading: "あいづわかまつ", tagline: "鶴ヶ城と 赤べこの まち",
                       innBase: 11, innPerLevel: 7,
                       stock: [.kitakataRamen, .momo, .byakkoKatana, .aizuArmor]),
        rows: [
            "#############################",
            "#______###########__________#",
            "#_P____#__HHHHH__#____t_____#",
            "#______#__HHHHH__#__________#",
            "#______#__WWdWW__#___HHH____#",
            "#__t___#______P__#___WdW____#",
            "#______####_######__________#",
            "#___________________________#",
            "#___III_____SSS________1____#",
            "#___YdW_____ZdW_____________#",
            "#___________________________#",
            "#_t______e________2_____P___#",
            "#___________________________#",
            "#ffff______t______________c_#",
            "#ffff_3_____________________#",
            "############EEEE#############"
        ],
        outside: .grass,
        warps: [
            Point(x: 12, y: 4): Warp(to: .tsurugajo, at: Point(x: 4, y: 4)),
            Point(x: 22, y: 5): Warp(to: .akabekoHouse, at: Point(x: 4, y: 4)),
            Point(x: 5, y: 9): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 13, y: 9): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(12...15, row: 15, to: .fukushimaField, at: Point(x: 8, y: 27))) { first, _ in first },
        villagers: [
            ["おばさん「鶴ヶ城は 白い かべに 赤い かわらの お城よ。」"],
            ["おじいさん「白虎隊は 戊辰戦争で たたかった 会津の 少年たちじゃ。",
             "　飯盛山に ねむって おる。」"],
            ["しょくにん「会津塗は うるしを ぬった 会津の 伝統の 漆器さ。」"],
            ["たびびと「まちの 東の 猪苗代湖は 日本で 4番めに 大きい 湖なんだ。」"],
        ],
        residents: ["1": .fukushimaGuide, "2": .lostByakko, "3": .aizuReceiver],
        plaques: [
            Point(x: 2, y: 2): Plaque(title: "飯盛山", lines: [
                "かんばんに こう かいてある。",
                "「飯盛山」",
                "白虎隊士の お墓が ある 山。",
            ]),
            Point(x: 14, y: 5): Plaque(title: "鶴ヶ城", lines: [
                "かんばんに こう かいてある。",
                "「鶴ヶ城（会津若松城）」",
                "赤い かわらの 天守が かがやく 城。",
            ]),
            Point(x: 24, y: 11): Plaque(title: "七日町", lines: [
                "かんばんに こう かいてある。",
                "「七日町通り」",
                "むかしの 店が ならぶ レトロな 通り。",
            ]),
        ],
        chestRewards: [.item(.kitakataRamen)]
    )

    /// 喜多方。蔵と ラーメンの まち。
    static let kitakata = GameMap(
        id: .kitakata,
        name: "きたかた",
        kind: .town,
        region: .fukushima,
        town: TownInfo(name: "喜多方", reading: "きたかた", tagline: "蔵と ラーメンの まち",
                       innBase: 11, innPerLevel: 7,
                       stock: [.kitakataRamen, .momo, .byakkoKatana, .aizuArmor]),
        rows: [
            "######################",
            "#__HHH____HHH____HHH_#",
            "#__WdW____WdW____WWW_#",
            "#____________________#",
            "#_P______t________P__#",
            "#____________________#",
            "#_III___SSS____t_____#",
            "#_YdW___ZdW__________#",
            "#____________________#",
            "#__t____e_______c____#",
            "#######EEEE###########"
        ],
        outside: .grass,
        warps: [
            Point(x: 4, y: 2): Warp(to: .ramenHouse, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 2): Warp(to: .kuraHouse, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 7): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 9, y: 7): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(7...10, row: 10, to: .fukushimaField, at: Point(x: 7, y: 12))) { first, _ in first },
        villagers: [
            ["おばさん「喜多方は 蔵の まち。 4000ちかくの 蔵が あるんだって。」"],
            ["おとこ「『会津磐梯山は 宝の山よ』って 民謡、しってるかい？」"],
            ["おじいさん「磐梯山には むかし 手長足長と いう 巨人が",
             "　すんでいたそうな。」"],
        ],
        plaques: [
            Point(x: 2, y: 4): Plaque(title: "蔵", lines: [
                "かんばんに こう かいてある。",
                "「喜多方 蔵の まちなみ」",
                "白かべや れんがの 蔵が ならぶ。",
            ]),
            Point(x: 18, y: 4): Plaque(title: "ラーメン", lines: [
                "かんばんに こう かいてある。",
                "「喜多方ラーメン 発祥の 地」",
                "ひらたい ちぢれめんの しょうゆ味。",
            ]),
        ],
        chestRewards: [.gold(200)]
    )

    /// あぶくま洞。石灰岩の 山の 鍾乳洞。
    static let abukumado = cave(
        .abukumado, name: "あぶくま洞", label: "あぶくま洞", region: .fukushima,
        rows: [
            "#####################",
            "#,,,,,,,,,B,,,,,,,,,#",
            "#,###,,,,,,,,,,,###,#",
            "#,#c#,,###,###,,#c#,#",
            "#,#,#,,#,,,,,#,,#,#,#",
            "#,,,,,,#,###,#,,,,,,#",
            "###,####,#,#,####,###",
            "#,,,#,,,,#,#,,,,#,,,#",
            "#,#,#,####,####,#,#,#",
            "#,#,,,#,,,,,,,#,,,#,#",
            "#,#####,#####,#####,#",
            "#,,,,,,,,,U,,,,,,,,,#",
            "#####################"
        ],
        warps: [Point(x: 10, y: 11): Warp(to: .fukushimaField, at: Point(x: 45, y: 33))],
        chestRewards: [.gold(480), .item(.momo)],
        bossKind: .abukumaLord, enemies: Balance.places[18].enemies, quizTown: .fukushima
    )

    static let bandai1 = cave(
        .bandai1, name: "磐梯山 B1", label: "磐梯山", region: .fukushima,
        rows: [
            "###################",
            "#c,,,#,,,,,,,#,,,c#",
            "#,##,#,#####,#,##,#",
            "#,#,,,,#,,,#,,,,#,#",
            "#,#,####,#,#,####,#",
            "#,,,#,,,,#,,,,#,,,#",
            "###,#,########,#,##",
            "#D#,#,,,,,,,,,,#,,#",
            "#,#,######,###,##,#",
            "#,,,,,,,,#,,,#,,,,#",
            "#,#######,##,####,#",
            "#,,,,,,,,,U,,,,,,,#",
            "###################"
        ],
        warps: [
            Point(x: 10, y: 11): Warp(to: .fukushimaField, at: Point(x: 18, y: 21)),
            Point(x: 1, y: 7): Warp(to: .bandai2, at: Point(x: 6, y: 8)),
        ],
        chestRewards: [.item(.mishirazuGaki), .gold(520)],
        enemies: Balance.places[19].enemies, quizTown: .aizu
    )

    static let bandai2 = cave(
        .bandai2, name: "磐梯山 火口", region: .fukushima,
        rows: [
            "###############",
            "#,,,,,,B,,,,,,#",
            "#,~~,,,,,,,~~,#",
            "#,~~,,,,,,,~~,#",
            "#,,,,##,##,,,,#",
            "##,###,c,###,##",
            "#,,,#,,,,,#,,,#",
            "#,#,#,###,#,#,#",
            "#,#,,,,U,,,,#,#",
            "###############"
        ],
        warps: [Point(x: 7, y: 8): Warp(to: .bandai1, at: Point(x: 1, y: 8))],
        chestRewards: [.item(.shakudama)],
        bossKind: .tenagaAshinaga, enemies: Balance.places[19].enemies, quizTown: .aizu
    )

    // MARK: 家の中

    static let tsurugajo = house(
        .tsurugajo, name: "鶴ヶ城 天守",
        rows: [
            "XXXXXXXXX",
            "XLLL1LLcX",
            "XoooooooX",
            "XtooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .aizu, region: .fukushima, door: Point(x: 12, y: 4),
        villagers: [["さむらい「会津の 武士の 子は『ならぬことは ならぬものです』と",
                     "　おしえられて そだったのじゃ。」"]],
        residents: ["1": .castleWarden], chestRewards: [.gold(200)]
    )

    static let akabekoHouse = house(
        .akabekoHouse, name: "民芸品の 店",
        rows: [
            "XXXXXXXXX",
            "XLLL1LLcX",
            "XooKKKooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .aizu, region: .fukushima, door: Point(x: 22, y: 5),
        villagers: [],
        residents: ["1": .okiagariMaker], chestRewards: [.item(.momo)]
    )

    static let kuraHouse = house(
        .kuraHouse, name: "赤べこの 蔵",
        rows: [
            "XXXXXXXXX",
            "XLLo1oLcX",
            "XoooooooX",
            "XoooootoX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .kitakata, region: .fukushima, door: Point(x: 11, y: 2),
        villagers: [["くらの あるじ「赤べこは 赤い 牛が お寺を たてる 手つだいを した",
                     "　伝説から うまれたんじゃ。",
                     "　猪苗代湖は 天鏡湖とも よばれる きれいな 湖じゃぞ。」"]],
        residents: ["1": .akabekoKeeper], chestRewards: [.item(.kitakataRamen)]
    )

    static let ramenHouse = house(
        .ramenHouse, name: "ラーメンや",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLcX",
            "XooKKKooX",
            "Xoo1ooooX",
            "XooooootX",
            "XXXXdXXXX",
        ],
        town: .kitakata, region: .fukushima, door: Point(x: 4, y: 2),
        villagers: [["おきゃく「朝から ラーメン！ これが 喜多方の『朝ラー』さ。」"]],
        residents: ["1": .ramenMaster], chestRewards: [.gold(150)]
    )

    static let warajiHouse = house(
        .warajiHouse, name: "わらじまつりの 会所",
        rows: [
            "XXXXXXXXX",
            "XLL1oLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .fukushima, region: .fukushima, door: Point(x: 10, y: 3),
        villagers: [],
        residents: ["1": .warajiMaster], chestRewards: [.item(.kitakataRamen)]
    )

    static let momoHouse = house(
        .momoHouse, name: "ももの 農家",
        rows: [
            "XXXXXXXXX",
            "XLLo1o2cX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .fukushima, region: .fukushima, door: Point(x: 18, y: 3),
        villagers: [],
        residents: ["1": .peachFarmer, "2": .byakkoHome], chestRewards: [.item(.momo)]
    )
}
