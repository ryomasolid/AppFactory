import Foundation

// MARK: - 秋田県
//
// 秋田で 竿燈の さしてに 話を きき、角館の 武家屋敷の おくさまから たつこへの ことづてを もらう。
// 田沢湖の たつこ（中ボス）を しずめると、男鹿の なまはげの 長老が なまはげの めんを くれ、真山へ 入れる。
// なまはげ大王（ぬし）を 倒すと 竿燈まつりが もどり、岩手へ 行ける。

extension StoryFlag {
    /// 竿燈の さしてから 話を きいた。
    static let akitaHeard: StoryFlag = "akita.heard"
    /// 武家屋敷の おくさまから たつこへの ことづてを もらった（田沢湖の ほこらに 入れる）。
    static let akitaTazawa: StoryFlag = "akita.tazawa"
    /// なまはげの 長老から なまはげの めんを もらった（真山に 入れる）。
    static let akitaMask: StoryFlag = "akita.mask"
}

extension Story {
    static let akitaGates: [StoryFlag: [String]] = [
        .akitaTazawa: ["湖の 水が うずを まいていて ほこらに ちかづけない。",
                       "（たつこを しずめる ことづてが あれば……）"],
        .akitaMask: ["真山の 入口に しめなわが はってある。",
                     "なまはげの 山だ。 よそものは 入れない ようだ。",
                     "（男鹿の 長老の ゆるしが あれば……）"],
    ]

    static let akitaImplications: [StoryFlag: EnemyKind] = [
        .akitaHeard: .tatsuko,
        .akitaTazawa: .tatsuko,
        .akitaMask: .namahageKing,
    ]

    static func akitaHint(_ p: StoryProgress) -> [String]? {
        if !p.has(.akitaHeard) {
            return ["ちょうろう「秋田では 竿燈の あかりが きえたと いう。",
                    "　秋田の まちの 竿燈まつり会館で さしての 親方に 話を きけ。」"]
        }
        if !p.has(.akitaTazawa) {
            return ["ちょうろう「たつこの ことなら 角館の 武家屋敷の おくさまじゃ。",
                    "　角館は 秋田の 東、田んぼを こえた さきじゃ。」"]
        }
        if !p.defeatedBosses.contains(.tatsuko) {
            return ["ちょうろう「田沢湖は 角館の 北。 湖の 東の ほとりに ほこらが ある。",
                    "　角館の ものの 話を きいておけば ちしきで おいうちが きまるぞ。」"]
        }
        if !p.has(.akitaMask) {
            return ["ちょうろう「真山へは 男鹿の なまはげの 長老の ゆるしが いる。",
                    "　男鹿は 秋田の 北西、男鹿半島の さきじゃ。」"]
        }
        if !p.defeatedBosses.contains(.namahageKing) {
            return ["ちょうろう「真山は 男鹿の まちの 北東の 山じゃ。",
                    "　なまはげ大王は ちからが つよい。 角館で なまはげの包丁を そろえて いどめ。」"]
        }
        return nil
    }
}

extension Errand {
    /// 秋田の きりたんぽ屋 → 男鹿の 漁師。
    static let akitaKiritanpo = Errand(
        id: "akita.kiritanpo", package: "きりたんぽ",
        ask: ["おかみ「男鹿の 漁師さんに きりたんぽを とどけて くれない？",
              "　男鹿は 秋田の 北西、男鹿半島の さきよ。」"],
        reminder: ["おかみ「きりたんぽは 男鹿の 漁師さんに たのんだわよ。」"],
        thanks: ["おかみ「とどけて くれたのね！ ありがとう。", "　これは おだちんよ。」"],
        after: ["おかみ「きりたんぽ鍋には 比内地鶏の だしが いちばん！」"],
        delivered: ["りょうし「おお、秋田の きりたんぽ！", "　しょっつる鍋と いっしょに くうか。」"],
        idle: ["りょうし「しょっつるは ハタハタで つくる 魚しょうゆだ。",
               "　しょっつる鍋は 男鹿の 冬の ごちそうよ。」"],
        gold: 120, items: [.iburigakko]
    )
}

extension LostQuest {
    /// 角館へ 走っていった 秋田犬。
    static let akitaDog = LostQuest(
        id: "akita.dog",
        ask: ["かいぬし「うちの 秋田犬の ハチが いなくなったの。",
              "　角館の 武家屋敷の ほうへ 走って いったって……」"],
        thanks: ["かいぬし「ハチ！ もどってきたのね！ ありがとう。」"],
        after: ["かいぬし「秋田犬は 秋田うまれの 大きな 犬。",
                "　かしこくて やさしいのよ。」"],
        lost: ["秋田犬「ワン！」",
               "ハチは かいぬしの いる 秋田の まちへ かけていった。"],
        home: ["ハチ「ワンワン！」", "しっぽを ぶんぶん ふっている。"],
        gold: 50, items: [.kiritanpo, .kiritanpo]
    )
}

extension Resident {
    func akitaScene(_ p: StoryProgress) -> StoryScene? {
        switch self {
        case .kantoMaster:
            if p.defeatedBosses.contains(.namahageKing) {
                return StoryScene(lines: [
                    "さしての おやかた「竿燈が もどった！ どっこいしょー！",
                    "　岩手でも さんさ踊りの たいこが きえたらしい。",
                    "　駅から 新幹線で 盛岡へ いってくれ。」",
                ])
            }
            if p.defeatedBosses.contains(.tatsuko) {
                return StoryScene(lines: [
                    "さしての おやかた「たつこを しずめたか！",
                    "　竿燈の あかりは 男鹿の なまはげ大王が もっているだと？",
                    "　真山へは 男鹿の なまはげの 長老に たのんでみな。」",
                ])
            }
            if p.has(.akitaTazawa) {
                return StoryScene(lines: [
                    "さしての おやかた「その ことづてを もって 田沢湖へ いくんだ。",
                    "　田沢湖は 角館の 北だ。」",
                ])
            }
            if p.has(.akitaHeard) {
                return StoryScene(lines: [
                    "さしての おやかた「角館の 武家屋敷の おくさまを たずねてくれ。",
                    "　角館は 秋田の 東、田んぼの むこうだ。」",
                ])
            }
            return StoryScene(lines: [
                "さしての おやかた「おれは 竿燈の さしての 親方だ。",
                "　竿燈は ちょうちんを 稲穂に みたてて 豊作を いのる まつり。",
                "　ところが 田沢湖から りゅうが あらわれて",
                "　竿燈の あかりを ぜんぶ さらって いっちまった。",
                "　りゅうの ことは 角館の 武家屋敷の おくさまが くわしい。」",
            ], sets: [.akitaHeard])

        case .bukeLady:
            if p.defeatedBosses.contains(.tatsuko) {
                return StoryScene(lines: [
                    "おくさま「たつこも きっと ほっと したでしょう。",
                    "　冬に なると 八郎太郎が 田沢湖へ かよってくるから",
                    "　田沢湖は 冬も こおらない……そんな 伝説が あるのよ。」",
                ])
            }
            if p.has(.akitaTazawa) {
                return StoryScene(lines: [
                    "おくさま「田沢湖は 角館の 北。",
                    "　ほこらは 湖の 東の ほとりに あるわ。」",
                ])
            }
            if p.has(.akitaHeard) {
                return StoryScene(lines: [
                    "おくさま「田沢湖の りゅうは たつこ。 むかしは うつくしい むすめで、",
                    "　いつまでも うつくしく いたいと ねがって りゅうに なったの。",
                    "　十和田湖の 八郎太郎とは 夫婦だと いう 伝説が あるわ。",
                    "　あなた、八郎太郎に あったのね？ この ことづてを たつこに。",
                    "　八郎太郎の ぶじを しれば うずも しずまる はずよ。」",
                    "たつこへの ことづてを あずかった！",
                ], sets: [.akitaTazawa])
            }
            return StoryScene(lines: [
                "おくさま「ここは 角館の 武家屋敷。",
                "　角館は『みちのくの 小京都』と よばれる まちなのよ。",
                "　……竿燈の 親方の おつかい？ まずは 親方に 話を きいてらっしゃい。」",
            ])

        case .namahageElder:
            if p.defeatedBosses.contains(.namahageKing) {
                return StoryScene(lines: [
                    "ちょうろう「なまはげ大王も めを さました。",
                    "　なまはげは 本当は 山から くる 神さまの つかい。",
                    "　なまけものを こらしめ、わざわいを はらうのじゃ。」",
                ])
            }
            if p.has(.akitaMask) {
                return StoryScene(lines: [
                    "ちょうろう「その めんを つけて 真山の しめなわを くぐれ。",
                    "　真山は まちの 北東の 山じゃ。」",
                ])
            }
            if p.defeatedBosses.contains(.tatsuko) {
                return StoryScene(lines: [
                    "ちょうろう「たつこを しずめた ゆうしゃか。 ならば たのむ。",
                    "　なまはげ大王が まおうに あやつられ、竿燈の あかりを 真山に とじこめた。",
                    "　この なまはげの めんを もっていけ。",
                    "　これが あれば 真山の しめなわを とおれる。」",
                    "なまはげの めんを てにいれた！",
                ], sets: [.akitaMask])
            }
            return StoryScene(lines: [
                "ちょうろう「わしは なまはげの 長老じゃ。",
                "　なまはげは 大みそかの 夜に『泣ぐ子は いねがー』と 家を まわる。",
                "　真山は なまはげの 山。 よそものは 入れぬぞ。」",
            ])

        case .kiritanpoCook: return Errand.akitaKiritanpo.giverScene(p)
        case .ogaFisher: return Errand.akitaKiritanpo.receiverScene(p)
        case .dogOwner: return LostQuest.akitaDog.seekerScene(p)
        case .lostAkitaDog: return LostQuest.akitaDog.lostScene()
        case .akitaDogHome: return LostQuest.akitaDog.homeScene()
        case .akitaGuide: return Story.stampScene(.akita, p, towns: "秋田・角館・男鹿", gift: .kiritanpo)
        case .akitaExaminer: return Story.examScene(.akita, p)

        case .akitaDancer:
            return StoryScene(lines: [
                "さしてて「どっこいしょー どっこいしょ！",
                "　竿燈が もどって 秋田の 夜空が あかるいよ！」",
            ])

        case .kabaCrafter:
            return StoryScene(lines: [
                "しょくにん「これは 樺細工。 山桜の 木の 皮で つくる 角館の 工芸さ。",
                "　つやつやの 茶筒が 人気なんだよ。」",
            ])

        default: return nil
        }
    }
}

extension QuizBank {
    static let akita: [MapID: [Quiz]] = [
        .akita: [
            Quiz(question: "秋田で 夏に ひらかれる ちょうちんの まつりは？", choices: ["ねぶた祭", "竿燈まつり", "花笠まつり"], answer: 1),
            Quiz(question: "竿燈の ちょうちんは なにに みたてている？", choices: ["稲穂", "りんご", "星"], answer: 0),
            Quiz(question: "秋田県の 県の さかなは？", choices: ["サケ", "タイ", "ハタハタ"], answer: 2),
            Quiz(question: "秋田の 名物 きりたんぽは なにで つくる？", choices: ["ごはん", "こむぎこ", "いも"], answer: 0),
            Quiz(question: "秋田うまれの 大きな 犬は？", choices: ["柴犬", "秋田犬", "土佐犬"], answer: 1),
            Quiz(question: "秋田の 西に ひろがる 海は？", choices: ["太平洋", "オホーツク海", "日本海"], answer: 2),
            Quiz(question: "秋田の 有名な お米は？", choices: ["コシヒカリ", "あきたこまち", "ゆめぴりか"], answer: 1),
            Quiz(question: "大曲で ひらかれる 有名な ものは？", choices: ["雪まつり", "将棋大会", "花火大会"], answer: 2),
        ],
        .kakunodate: [
            Quiz(question: "角館の 武家屋敷を いろどる 花は？", choices: ["しだれざくら", "ひまわり", "あじさい"], answer: 0),
            Quiz(question: "角館は なにの まちなみで 有名？", choices: ["蔵", "武家屋敷", "合掌造り"], answer: 1),
            Quiz(question: "山桜の 木の 皮で つくる 角館の 工芸は？", choices: ["南部鉄器", "こけし", "樺細工"], answer: 2),
            Quiz(question: "日本一 ふかい 湖は？", choices: ["琵琶湖", "田沢湖", "十和田湖"], answer: 1),
            Quiz(question: "田沢湖の 伝説で りゅうに なった むすめは？", choices: ["たつこ", "かぐや姫", "おとひめ"], answer: 0),
            Quiz(question: "秋田の 名物の ほそい うどんは？", choices: ["讃岐うどん", "きしめん", "稲庭うどん"], answer: 2),
            Quiz(question: "むかし 田沢湖だけに いた さかなは？", choices: ["アユ", "クニマス", "マグロ"], answer: 1),
            Quiz(question: "角館は『みちのくの 〇〇』と よばれる。〇〇は？", choices: ["小京都", "小江戸", "小樽"], answer: 0),
        ],
        .oga: [
            Quiz(question: "男鹿で 大みそかに 家を まわる ものは？", choices: ["なまはげ", "サンタ", "かっぱ"], answer: 0),
            Quiz(question: "なまはげの かけごえは？", choices: ["ラッセラー", "ワッショイ", "泣ぐ子は いねがー"], answer: 2),
            Quiz(question: "干拓されて 大潟村に なった 湖は？", choices: ["宍道湖", "八郎潟", "霞ヶ浦"], answer: 1),
            Quiz(question: "男鹿半島の さきの 灯台が ある みさきは？", choices: ["入道崎", "宗谷岬", "足摺岬"], answer: 0),
            Quiz(question: "ハタハタで つくる 秋田の 魚しょうゆは？", choices: ["ナンプラー", "しょっつる", "いしる"], answer: 1),
            Quiz(question: "八郎潟が 見わたせる 男鹿の 山は？", choices: ["岩木山", "鳥海山", "寒風山"], answer: 2),
        ],
    ]
}

extension World {
    /// 秋田の 出口の 前（全滅したら ここで 目を さます）。
    static let akitaGate = Point(x: 13, y: 17)

    static var akitaMaps: [GameMap] {
        [akitaField, akitaTown, kakunodate, oga, tazawako, shinzan1, shinzan2,
         kantoHouse, akitaHouse, bukeyashiki, kabazaikuHouse, namahageHouse, ogaHouse]
    }

    /// 秋田県。56×36 マス。
    /// 西は 日本海、北西に つきでた 男鹿半島（真山）と 干拓地の 八郎潟。海ぞいに 秋田と 秋田駅。
    /// 東へ 田んぼを こえて 角館、その 北に 田沢湖。南西に 鳥海山、東は 奥羽山脈。
    static let akitaField = GameMap(
        id: .akitaField,
        name: "秋田県",
        kind: .field,
        region: .akita,
        rows: [
            "~~~~~~~~~~~~~~....ffffffMMMMMMMMMMMffffff........hhMMMMM",
            "~~~~~~~~~~~~~~....ffcfffMMMMMMMMMMMffffff........hhMMMMM",
            "~~~~~~~~~~~~~~....fffffffffffffffffffffff........hhMMMMM",
            "~~~~~~~~~~~~~.....fffffffffffffffffffffff........hhMMMMM",
            "~~~~~~~~~~~~~...................................MhhMMMMM",
            "~~~~~~~~~~~~~..................................MMMhMMMMM",
            "~~~~~~~~~~~~~..pppppppp........................MMMhMMMMM",
            "~~~~~~~~~~~~~..p~~~pppp..................fffff.MMMhMMMMM",
            "~~~~~..........p~~~pppp.................f~~~~cf.MhhMMMMM",
            "~~~..MMM.......p~~~pppp................f~~~~~~~f.hhMMMMM",
            "~~..hhhCh......pppppppp................f~~~~~~~f.hhMMMMM",
            "~~.c.hh===.....pppppppp................f~~~~~~~f.hhMMMMM",
            "~~...T...=.....pppppppp.fffffff.........f~~~~~C..hhMMMMM",
            "~~~..=...=.....pppppppp.fffffff..........fffff=..hhMMMMM",
            "~~~~~=====bb===.........fffffff...............=..hhMMMMM",
            "~~~~~~~~~~~~..==........fffffff...............=..hhMMMMM",
            "~~~~~~~~~~~~...=........fffffff...............=..hhMMMMM",
            "~~~~~~~~~~~~~..=..............................=..hhMMMMM",
            "~~~~~~~~~~~~~..=..............................=..hhMMMMM",
            "~~~~~~~~~~~~~..=T..A...................T......=..hhMMMMM",
            "~~~~~~~~~~~~~..====================..==========..hhMMMMM",
            "~~~~~~~~~~~~~.....................=..=...........hhMMMMM",
            "~~~~~~~~~~~~~~..............pppppp=pp=ppp........hhMMMMM",
            "~~~~~~~~~~~~~~..............pppppp=pp=ppp........hhMMMMM",
            "~~~~~~~~~~~~~~..............pppppp====ppp........hhMMMMM",
            "~~~~~~~~~~~~~~..............ppppppppppppp........hhMMMMM",
            "~~~~~~~~~~~~~~..............ppppppppppppp........hhMMMMM",
            "~~~~~~~~~~~~~...............ppppppppppppp........hhMMMMM",
            "~~~~~~~~~~~~~...............ppppppppppppffffffff.hhMMMMM",
            "~~~~~~~~~~~~~...........................ffffffff.hhMMMMM",
            "~~~~~~~~~~~~~..hhhhh....................ffffffff.hhMMMMM",
            "~~~~~~~~~~~~~hhhMMMhhh..................fffffffc.hhMMMMM",
            "~~~~~~~~~~~~~hhMMMMMhh..................ffffffff.hhMMMMM",
            "~~~~~~~~~~~~.hhhMMMhhh..................ffffffff.hhMMMMM",
            "~~~~~~~~~~~~...hhhhh.............................hhMMMMM",
            "~~~~~~~~~~~~..c..................................hhMMMMM"
        ],
        outside: .water,
        warps: [
            Point(x: 16, y: 19): Warp(to: .akita, at: Point(x: 13, y: 17)),
            Point(x: 5, y: 12): Warp(to: .oga, at: Point(x: 7, y: 10)),
            Point(x: 39, y: 19): Warp(to: .kakunodate, at: Point(x: 12, y: 16)),
            // 田沢湖は たつこへの ことづて、真山は なまはげの めんで ひらく。
            Point(x: 46, y: 12): Warp(to: .tazawako, at: Point(x: 11, y: 12), needs: .akitaTazawa),
            Point(x: 7, y: 10): Warp(to: .shinzan1, at: Point(x: 11, y: 11), needs: .akitaMask),
        ],
        chestRewards: [.gold(150), .item(.hanabi), .item(.hinaiChicken), .item(.kiritanpo), .gold(200)],
        encounterAreas: [
            EncounterArea(name: "秋田のまわり", around: [Point(x: 16, y: 20), Point(x: 19, y: 20), Point(x: 15, y: 16), Point(x: 25, y: 20)],
                          enemies: Balance.places[4].enemies, quizTown: .akita),
            EncounterArea(name: "角館へむかう道",
                          around: [Point(x: 39, y: 20), Point(x: 34, y: 24), Point(x: 46, y: 14), Point(x: 45, y: 30), Point(x: 44, y: 6)],
                          enemies: Balance.places[5].enemies, quizTown: .kakunodate),
            EncounterArea(name: "男鹿へむかう道",
                          around: [Point(x: 5, y: 13), Point(x: 9, y: 14), Point(x: 7, y: 11), Point(x: 18, y: 9), Point(x: 28, y: 6)],
                          enemies: Balance.places[5].enemies, quizTown: .oga),
        ],
        markerFloor: .grass
    )

    /// 秋田。北西の 森が 千秋公園（久保田城あと）、南西は 秋田港。
    static let akitaTown = GameMap(
        id: .akita,
        name: "あきた",
        kind: .town,
        region: .akita,
        town: TownInfo(name: "秋田", reading: "あきた", tagline: "竿燈の ゆれる 港まち",
                       innBase: 4, innPerLevel: 4,
                       stock: [.apple, .senbeiJiru, .kiritanpo, .iburigakko, .tsugaruKatana, .hirosakiArmor, .akitaSugiArmor]),
        rows: [
            "############################",
            "#ffff______________________#",
            "#fPff____HHHHH______t______#",
            "#ffff____WWdWW___________6_#",
            "#f___f_______P_____HHH_____#",
            "#_____t____________WdW_____#",
            "#__________________________#",
            "#______III____SSS______t___#",
            "#______III____SSS__________#",
            "#______YdW____ZdW____3_____#",
            "#__________________________#",
            "#_t_______e______________2_#",
            "#________________45________#",
            "#______________________t___#",
            "#~~~~~~~__________1________#",
            "#~~~~~~~___P_______________#",
            "#~~~~~~~~__________t_______#",
            "#~~~~~~~~~_______________c_#",
            "############EEEE############"
        ],
        outside: .grass,
        warps: [
            Point(x: 11, y: 3): Warp(to: .kantoHouse, at: Point(x: 4, y: 4)),
            Point(x: 20, y: 5): Warp(to: .akitaHouse, at: Point(x: 4, y: 4)),
            Point(x: 8, y: 9): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 15, y: 9): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(12...15, row: 18, to: .akitaField, at: Point(x: 16, y: 20))) { first, _ in first },
        villagers: [
            ["おとこ「秋田の 夏は 竿燈まつり！",
             "　ちょうちんを たくさん さげた 竿を",
             "　手や 肩や 腰に のせて ささえるんだ。」"],
            ["おばさん「竿燈の ちょうちんは 稲穂に みたてて あるのよ。",
             "　お米の 豊作を いのる まつりなの。」"],
            ["りょうし「秋田県の さかなは ハタハタ。",
             "　冬に 雷が なると 浜へ よってくるんだ。」"],
            ["こども「きりたんぽは つぶした ごはんを",
             "　杉の 棒に まいて やくんだよ。」"],
            ["のうか「秋田の お米と いえば あきたこまち！",
             "　ひろい 田んぼで そだてるんだ。」"],
            ["わかもの「大曲の 花火大会は 日本一の 花火師を きめる 大会なんだぞ。",
             "　大曲は 秋田と 角館の あいだに あるんだ。」"],
        ],
        residents: ["1": .akitaDogHome, "2": .akitaGuide, "3": .akitaExaminer, "4": .dogOwner,
                    "5": .kiritanpoCook, "6": .akitaDancer],
        plaques: [
            Point(x: 2, y: 2): Plaque(title: "千秋", lines: [
                "かんばんに こう かいてある。",
                "「千秋公園」",
                "秋田藩の 久保田城の あと。 春は さくらの 名所。",
            ]),
            Point(x: 13, y: 4): Plaque(title: "竿燈", lines: [
                "かんばんに こう かいてある。",
                "「竿燈まつり会館」",
                "まつりで つかう 本物の 竿燈を さわれる。",
            ]),
            Point(x: 11, y: 15): Plaque(title: "秋田港", lines: [
                "かんばんに こう かいてある。",
                "「秋田港 ポートタワー セリオン」",
                "てんぼう台から 日本海を 見わたせる。",
            ]),
        ],
        chestRewards: [.item(.kiritanpo)]
    )

    /// 角館。北は さくらに かこまれた 武家屋敷通り、南を 桧木内川が ながれる。
    static let kakunodate = GameMap(
        id: .kakunodate,
        name: "かくのだて",
        kind: .town,
        region: .akita,
        town: TownInfo(name: "角館", reading: "かくのだて", tagline: "みちのくの 小京都",
                       innBase: 5, innPerLevel: 4,
                       stock: [.kiritanpo, .iburigakko, .tsugaruKatana, .namahageHocho, .akitaSugiArmor]),
        rows: [
            "##########################",
            "#kkkkkkkkkkkkkkkkkkkkkkkk#",
            "#k_____________________k_#",
            "#k_HHHHH__P___HHH___t__k_#",
            "#k_WWdWW______WdW______k_#",
            "#k_____________________k_#",
            "#k__t____1_______P_____k_#",
            "#kkkkkkkk___kkkkkkkkkkkk_#",
            "#________________________#",
            "#__III___SSS___HHH_______#",
            "#__III___SSS___HHH___t___#",
            "#__YdW___ZdW___WWW_______#",
            "#________________________#",
            "#____e_____________P_____#",
            "#~~~~~~~~~~~~~~~~~~~bb~~~#",
            "#____t________________c__#",
            "#________________________#",
            "###########EEEE###########"
        ],
        outside: .grass,
        warps: [
            Point(x: 5, y: 4): Warp(to: .bukeyashiki, at: Point(x: 4, y: 4)),
            Point(x: 15, y: 4): Warp(to: .kabazaikuHouse, at: Point(x: 4, y: 4)),
            Point(x: 4, y: 11): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 10, y: 11): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(11...14, row: 17, to: .akitaField, at: Point(x: 39, y: 20))) { first, _ in first },
        villagers: [
            ["おばさん「角館は 武家屋敷の まちなみが のこる",
             "　『みちのくの 小京都』よ。」"],
            ["おとこ「武家屋敷の しだれざくらは 春に それは きれいなんだ。」"],
            ["おかみ「秋田の 名物 稲庭うどんは ほそくて つるつる。",
             "　手で のばして つくるのよ。」"],
            ["がくせい「田沢湖は 日本一 ふかい 湖。",
             "　むかしは クニマスと いう さかなが 田沢湖だけに いたんだ。」"],
        ],
        residents: ["1": .lostAkitaDog],
        plaques: [
            Point(x: 10, y: 3): Plaque(title: "武家", lines: [
                "かんばんに こう かいてある。",
                "「角館 武家屋敷通り」",
                "黒い 板べいと しだれざくらの 通り。",
            ]),
            Point(x: 17, y: 6): Plaque(title: "樺細工", lines: [
                "かんばんに こう かいてある。",
                "「角館樺細工伝承館」",
                "山桜の 皮で つくる 工芸を 見られる。",
            ]),
            Point(x: 19, y: 13): Plaque(title: "桜並木", lines: [
                "かんばんに こう かいてある。",
                "「桧木内川堤の 桜並木」",
                "2キロも つづく さくらの トンネル。",
            ]),
        ],
        chestRewards: [.gold(60)]
    )

    /// 男鹿。男鹿半島の さきの 小さな まち。北は 日本海。
    static let oga = GameMap(
        id: .oga,
        name: "おが",
        kind: .town,
        region: .akita,
        town: TownInfo(name: "男鹿", reading: "おが", tagline: "なまはげの 半島",
                       innBase: 5, innPerLevel: 5,
                       stock: [.kiritanpo, .iburigakko, .namahageHocho, .akitaSugiArmor]),
        rows: [
            "######################",
            "#~~~~~~~~~~~~~~~~~~~~#",
            "#~~~______P______~~~~#",
            "#~~___HHHHH__________#",
            "#~____WWdWW____t__P__#",
            "#____________________#",
            "#_III___SSS___HHH____#",
            "#_YdW___ZdW___WdW__t_#",
            "#____________________#",
            "#__e____P_____1______#",
            "#_____t______________#",
            "######EEEE############"
        ],
        outside: .grass,
        warps: [
            Point(x: 8, y: 4): Warp(to: .namahageHouse, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 7): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 9, y: 7): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 15, y: 7): Warp(to: .ogaHouse, at: Point(x: 4, y: 4)),
        ].merging(exits(6...9, row: 11, to: .akitaField, at: Point(x: 5, y: 13))) { first, _ in first },
        villagers: [
            ["りょうし「男鹿半島の さきの 入道崎には",
             "　白と 黒の しましまの 灯台が あるんだ。」"],
            ["おじいさん「八郎潟は むかし 日本で 2ばんめに 大きな 湖だった。",
             "　干拓されて いまは 大潟村に なったんだ。」"],
            ["こども「寒風山に のぼると 八郎潟が 見わたせるよ！」"],
        ],
        residents: ["1": .ogaFisher],
        plaques: [
            Point(x: 10, y: 2): Plaque(title: "入道崎", lines: [
                "かんばんに こう かいてある。",
                "「入道崎」",
                "男鹿半島の さき。 しましまの 灯台が たつ。",
            ]),
            Point(x: 18, y: 4): Plaque(title: "寒風山", lines: [
                "かんばんに こう かいてある。",
                "「寒風山」",
                "しばふの 山。 てっぺんから 八郎潟が 見える。",
            ]),
            Point(x: 8, y: 9): Plaque(title: "なまはげ", lines: [
                "かんばんに こう かいてある。",
                "「なまはげ館」",
                "男鹿じゅうの なまはげの めんが ならぶ。",
            ]),
        ],
        chestRewards: []
    )

    /// 田沢湖の ほこら。るりいろの 水の ほらあな。いちばん奥に たつこ。
    static let tazawako = cave(
        .tazawako, name: "田沢湖の ほこら", label: "田沢湖", region: .akita,
        rows: [
            "###################",
            "#~~~~~~,,B,,~~~~~~#",
            "#~~~~~,,,,,,,~~~~~#",
            "#~~~~~~,,,,,~~~~~~#",
            "#,,,~~~~,,,~~~~,,c#",
            "#,#,,,~~,,,~~,,,#,#",
            "#,#~~,,,,#,,,,~~#,#",
            "#,#~~,~~,#,~~,~~#,#",
            "#,,,,,~~,,,~~,,,,,#",
            "###,#,~~~~~~~,#,###",
            "#c,,#,,,,,,,,,#,,,#",
            "#,###,###,###,###,#",
            "#,,,,,,,,,U,,,,,,,#",
            "###################"
        ],
        warps: [Point(x: 10, y: 12): Warp(to: .akitaField, at: Point(x: 46, y: 13))],
        chestRewards: [.gold(150), .item(.iburigakko)],
        bossKind: .tatsuko, enemies: Balance.places[6].enemies, quizTown: .kakunodate
    )

    static let shinzan1 = cave(
        .shinzan1, name: "真山 B1", label: "真山", region: .akita,
        rows: [
            "###################",
            "#,,,,,,#,,,,,#,,,c#",
            "#,####,#,###,#,##,#",
            "#,#,,,,,,#,,,,,#,,#",
            "#,#,######,#####,##",
            "#,,,#,,,,,,,,,#,,,#",
            "###,#,#######,#,#,#",
            "#D#,,,#,,,,,#,,,#,#",
            "#,#,###,###,#####,#",
            "#,,,#c,,#,,,,,,,,,#",
            "#####,###,#######,#",
            "#,,,,,,,,,U,,,,,,,#",
            "###################"
        ],
        warps: [
            Point(x: 10, y: 11): Warp(to: .akitaField, at: Point(x: 7, y: 11)),
            Point(x: 1, y: 7): Warp(to: .shinzan2, at: Point(x: 6, y: 8)),
        ],
        chestRewards: [.item(.hanabi), .gold(180)],
        enemies: Balance.places[7].enemies, quizTown: .oga
    )

    static let shinzan2 = cave(
        .shinzan2, name: "真山 B2", region: .akita,
        rows: [
            "###############",
            "#,,,,,,B,,,,,,#",
            "#,,,,,,,,,,,,,#",
            "#####,,,,,#####",
            "#,,,#,###,#,,,#",
            "#,#,,,#c#,,,#,#",
            "#,#####,#####,#",
            "#,,,,,,,,,,,,,#",
            "######,U,######",
            "###############"
        ],
        warps: [Point(x: 7, y: 8): Warp(to: .shinzan1, at: Point(x: 1, y: 8))],
        chestRewards: [.item(.mishirazuGaki)],
        bossKind: .namahageKing, enemies: Balance.places[7].enemies, quizTown: .oga
    )

    // MARK: 家の中

    static let kantoHouse = house(
        .kantoHouse, name: "竿燈まつり会館",
        rows: [
            "XXXXXXXXX",
            "XLL1oLLcX",
            "XoooooooX",
            "XooooootX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .akita, region: .akita, door: Point(x: 11, y: 3),
        villagers: [["さしてて「いちばん 大きな 竿燈は 50キロも あるんだぞ。",
                     "　それを 手のひら ひとつで ささえるんだ。」"]],
        residents: ["1": .kantoMaster], chestRewards: [.gold(40)]
    )

    static let akitaHouse = house(
        .akitaHouse, name: "みんか",
        rows: [
            "XXXXXXXXX",
            "XcLLoLLLX",
            "XoooooooX",
            "XootooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .akita, region: .akita, door: Point(x: 20, y: 5),
        villagers: [["おばあさん「いぶりがっこは だいこんを いろりの けむりで いぶして",
                     "　つけた 秋田の つけものよ。」"]],
        chestRewards: [.item(.iburigakko)]
    )

    static let bukeyashiki = house(
        .bukeyashiki, name: "武家屋敷",
        rows: [
            "XXXXXXXXX",
            "XLLo1oLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .kakunodate, region: .akita, door: Point(x: 5, y: 4),
        villagers: [],
        residents: ["1": .bukeLady], chestRewards: [.item(.kiritanpo)]
    )

    static let kabazaikuHouse = house(
        .kabazaikuHouse, name: "樺細工の 工房",
        rows: [
            "XXXXXXXXX",
            "XLLLoL1cX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .kakunodate, region: .akita, door: Point(x: 15, y: 4),
        villagers: [],
        residents: ["1": .kabaCrafter], chestRewards: [.gold(70)]
    )

    static let namahageHouse = house(
        .namahageHouse, name: "なまはげの 家",
        rows: [
            "XXXXXXXXX",
            "XLL1oLLLX",
            "XoooooooX",
            "XoooootoX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .oga, region: .akita, door: Point(x: 8, y: 4),
        villagers: [["わかもの「なまはげの めんは 家ごとに ちがうんだ。",
                     "　大みそかの 夜、わかものが なまはげに なって 家を まわる。」"]],
        residents: ["1": .namahageElder]
    )

    static let ogaHouse = house(
        .ogaHouse, name: "りょうしの 家",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLcX",
            "XoooooooX",
            "XotoooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .oga, region: .akita, door: Point(x: 15, y: 7),
        villagers: [["りょうしの つま「男鹿の 冬は ハタハタ漁で いそがしいの。」"]],
        chestRewards: [.item(.hanabi)]
    )
}
