import Foundation

// MARK: - 岩手県
//
// 盛岡で さんさ踊りの 師匠から 三ツ石の 鬼の 話を きき、遠野の 語り部に 龍泉洞の とおりふだを もらう。
// 龍泉洞の ドラゴンブルー（中ボス）を 倒して 地底湖の 水を くみ、平泉の 中尊寺の おしょうに おふだを かいてもらう。
// おふだで 岩手山の 結界を やぶり、三ツ石の 鬼（ぬし）を 倒すと さんさ踊りが もどり、宮城へ 行ける。

extension StoryFlag {
    /// さんさ踊りの 師匠から 話を きいた。
    static let iwateHeard: StoryFlag = "iwate.heard"
    /// 遠野の 語り部から 龍泉洞の とおりふだを もらった。
    static let iwateCave: StoryFlag = "iwate.cave"
    /// 中尊寺の おしょうから 結界を やぶる おふだを もらった（岩手山に 入れる）。
    static let iwateSeal: StoryFlag = "iwate.seal"
}

extension Story {
    static let iwateGates: [StoryFlag: [String]] = [
        .iwateCave: ["龍泉洞の 入口に ばんにんが 立っている。",
                     "ばんにん「いまは 中で ぬしが あばれて あぶない。",
                     "　遠野の 語り部さまの とおりふだが なければ 入れられん。」"],
        .iwateSeal: ["岩手山の 入口に 鬼の 結界が はられている。",
                     "見えない かべに はじきかえされた。",
                     "（結界を やぶる おふだが あれば……）"],
    ]

    static let iwateImplications: [StoryFlag: EnemyKind] = [
        .iwateHeard: .ryusendoLord,
        .iwateCave: .ryusendoLord,
        .iwateSeal: .mitsuishiOni,
    ]

    static func iwateHint(_ p: StoryProgress) -> [String]? {
        if !p.has(.iwateHeard) {
            return ["ちょうろう「盛岡では さんさ踊りの たいこが ならなく なった。",
                    "　盛岡の まちの さんさの 師匠に 話を きけ。」"]
        }
        if !p.has(.iwateCave) {
            return ["ちょうろう「龍泉洞へは 遠野の 語り部の とおりふだが いる。",
                    "　遠野は 盛岡の 東、北上川を わたった さきじゃ。」"]
        }
        if !p.defeatedBosses.contains(.ryusendoLord) {
            return ["ちょうろう「龍泉洞は 遠野の 北、岩泉の 山の なかじゃ。",
                    "　遠野の ものの 話を きいておけば ちしきで おいうちが きまるぞ。」"]
        }
        if !p.has(.iwateSeal) {
            return ["ちょうろう「地底湖の 水を 平泉の 中尊寺の おしょうに とどけよ。",
                    "　平泉は 盛岡の 南、北上川ぞいを くだった さきじゃ。」"]
        }
        if !p.defeatedBosses.contains(.mitsuishiOni) {
            return ["ちょうろう「岩手山は 盛岡の 北西じゃ。 鬼は おそろしく つよい。",
                    "　平泉で 金色堂の太刀を そろえて いどむのじゃ。」"]
        }
        return nil
    }
}

extension Errand {
    /// 盛岡の そば屋 → 平泉に おまいりに きた おばあさん。
    static let iwateSoba = Errand(
        id: "iwate.soba", package: "そばの 出前",
        ask: ["そばやの おかみ「平泉の 中尊寺に おまいりに いった おばあさんに",
              "　出前を たのまれてね。 とどけて くれないかい？",
              "　平泉は 盛岡の 南、北上川ぞいよ。」"],
        reminder: ["そばやの おかみ「出前は 平泉の おばあさんに たのむわね。」"],
        thanks: ["そばやの おかみ「とどけて くれたのね！ たすかったわ。", "　これは おだちんよ。」"],
        after: ["そばやの おかみ「わんこそばは『じゃんじゃん』『どんどん』と",
                "　かけごえを かけて おかわりを いれるのよ。」"],
        delivered: ["おばあさん「まあ、盛岡の おそば！ ありがたや。」"],
        idle: ["おばあさん「中尊寺の 金色堂を おがみに きたのよ。",
               "　金ぴかで まぶしいほどじゃった。」"],
        gold: 160, items: [.nanbuSenbei]
    )
}

extension LostQuest {
    /// 遠野の 曲り家から 盛岡の 石割桜へ でかけた ざしきわらし。
    static let zashiki = LostQuest(
        id: "iwate.zashiki",
        ask: ["あるじ「うちの ざしきわらしが いなくなった！",
              "　ざしきわらしが いる 家は さかえると いう。",
              "　盛岡の 石割桜を 見に いったのでは……」"],
        thanks: ["あるじ「おお、もどってきた！ これで 家も あんたいじゃ。",
                 "　おれいに これを うけとって くだされ。」"],
        after: ["あるじ「ざしきわらしは こどもの すがたで 家に すむ。",
                "　見た ものには しあわせが くるそうじゃ。」"],
        lost: ["ざしきわらし「……クスクス。 さくらを 見てたの。",
               "　おうちに かえるね。」",
               "ざしきわらしは ふっと きえた。"],
        home: ["ざしきわらし「クスクス……」", "なんだか しあわせな きぶんに なった。"],
        gold: 200, items: [.wankoSoba]
    )
}

extension Resident {
    func iwateScene(_ p: StoryProgress) -> StoryScene? {
        switch self {
        case .sansaMaster:
            if p.defeatedBosses.contains(.mitsuishiOni) {
                return StoryScene(lines: [
                    "ししょう「さんさが もどった！ サッコラ チョイワヤッセ！",
                    "　宮城の 仙台でも 七夕の かざりが きえたそうじゃ。",
                    "　駅から 新幹線で 仙台へ いっておくれ。」",
                ])
            }
            if p.has(.iwateSeal) {
                return StoryScene(lines: [
                    "ししょう「おふだを もって 岩手山へ。 盛岡の 北西じゃ。",
                    "　鬼は ちからが つよい。 HPに 気を つけるのじゃぞ。」",
                ])
            }
            if p.defeatedBosses.contains(.ryusendoLord) {
                return StoryScene(lines: [
                    "ししょう「地底湖の 水を くんだか！",
                    "　平泉の 中尊寺の おしょうに とどけて おふだを かいて もらうのじゃ。",
                    "　平泉は 盛岡の 南、北上川ぞいを くだった さきじゃ。」",
                ])
            }
            if p.has(.iwateCave) {
                return StoryScene(lines: [
                    "ししょう「龍泉洞は 遠野の 北、岩泉の 山の なか。",
                    "　地底湖の 水を くんでくるのじゃ。」",
                ])
            }
            if p.has(.iwateHeard) {
                return StoryScene(lines: [
                    "ししょう「遠野の 語り部を たずねるのじゃ。",
                    "　遠野は 盛岡の 東、北上川の 橋を わたった さきじゃ。」",
                ])
            }
            return StoryScene(lines: [
                "ししょう「わしは さんさ踊りの 師匠じゃ。",
                "　むかし 岩手山の 鬼が 三ツ石の 神さまに こらしめられ、",
                "　二度と こないと ちかって 岩に 手形を おした。",
                "　この 鬼の 手形が『岩手』の 名の もとなのじゃ。",
                "　よろこんだ 人びとが 三ツ石を かこんで おどったのが さんさ踊り。",
                "　ところが その 鬼が もどってきて たいこが ならなく なった。",
                "　鬼を おさえる おふだは 中尊寺の おしょうしか かけぬが、",
                "　すみを する 龍泉洞の 地底湖の 水が いる。",
                "　龍泉洞へは 遠野の 語り部に たのむと よい。」",
            ], sets: [.iwateHeard])

        case .kataribe:
            if p.defeatedBosses.contains(.ryusendoLord) {
                return StoryScene(lines: [
                    "かたりべ「ドラゴンブルーを しずめたか。",
                    "　これも あたらしい 遠野の 物語に なるのう。」",
                ])
            }
            if p.has(.iwateCave) {
                return StoryScene(lines: [
                    "かたりべ「龍泉洞は 遠野の 北、岩泉の 山の なか。",
                    "　とおりふだを ばんにんに 見せるのじゃ。」",
                ])
            }
            if p.has(.iwateHeard) {
                return StoryScene(lines: [
                    "かたりべ「さんさの 師匠の つかいか。 よかろう。",
                    "　龍泉洞の 地底湖の そこには いま まおうの てさきが すみついておる。",
                    "　この とおりふだを ばんにんに 見せれば 入れてくれる。」",
                    "龍泉洞の とおりふだを てにいれた！",
                ], sets: [.iwateCave])
            }
            return StoryScene(lines: [
                "かたりべ「わしは 遠野の 語り部。 むかしばなしを かたるのが しごとじゃ。",
                "　遠野物語には かっぱ、ざしきわらし、山の ふしぎが いっぱい。",
                "　……ほう、なにか こまりごとかの？ 盛岡の 人に 話を きいてきなされ。」",
            ])

        case .chusonjiMonk:
            if p.defeatedBosses.contains(.mitsuishiOni) {
                return StoryScene(lines: [
                    "おしょう「鬼も 山へ かえったか。 ありがたい ことじゃ。",
                    "　金色堂は 奥州藤原氏が ねがった へいわの すがた なのじゃよ。」",
                ])
            }
            if p.has(.iwateSeal) {
                return StoryScene(lines: [
                    "おしょう「その おふだを 岩手山の 結界に かざすのじゃ。」",
                ])
            }
            if p.defeatedBosses.contains(.ryusendoLord) {
                return StoryScene(lines: [
                    "おしょう「おお、龍泉洞の 地底湖の 水！ すきとおって おるのう。",
                    "　この 水で すみを すって……よし、できた。",
                    "　鬼の 結界を やぶる おふだじゃ。 岩手山へ もっていきなされ。」",
                    "結界やぶりの おふだを てにいれた！",
                ], sets: [.iwateSeal])
            }
            return StoryScene(lines: [
                "おしょう「ここは 中尊寺。 金色堂は 奥州藤原氏が たてた 金色の お堂じゃ。",
                "　芭蕉も 平泉を おとずれ『夏草や 兵どもが 夢の跡』と よんだ。",
                "　……おふだが ほしい？ すみに つかう 地底湖の 水が なくてはのう。」",
            ])

        case .wankoHost: return Errand.iwateSoba.giverScene(p)
        case .hiraizumiPilgrim: return Errand.iwateSoba.receiverScene(p)
        case .zashikiHost: return LostQuest.zashiki.seekerScene(p)
        case .lostZashiki: return LostQuest.zashiki.lostScene()
        case .zashikiHome: return LostQuest.zashiki.homeScene()
        case .iwateGuide: return Story.stampScene(.iwate, p, towns: "盛岡・平泉・遠野", gift: .wankoSoba)
        case .iwateExaminer: return Story.examScene(.iwate, p)

        case .iwateDancer:
            return StoryScene(lines: [
                "おどりて「サッコラ チョイワヤッセ！",
                "　さんさの たいこが 盛岡じゅうに ひびいてるよ！」",
            ])

        case .nanbuSmith:
            return StoryScene(lines: [
                "てっきしょくにん「これは 南部鉄器。 盛岡と 奥州で つくる 鉄の 工芸だ。",
                "　鉄びんで わかした お湯は まろやかに なるんだぞ。」",
            ])

        default: return nil
        }
    }
}

extension QuizBank {
    static let iwate: [MapID: [Quiz]] = [
        .morioka: [
            Quiz(question: "盛岡の 名物で 小さな おわんで つぎつぎ たべる そばは？", choices: ["ざるそば", "わんこそば", "出雲そば"], answer: 1),
            Quiz(question: "盛岡で 夏に ひらかれる たいこの おどりは？", choices: ["さんさ踊り", "阿波踊り", "花笠踊り"], answer: 0),
            Quiz(question: "岩の われめから はえた 盛岡の さくらは？", choices: ["三春滝桜", "根尾谷淡墨桜", "石割桜"], answer: 2),
            Quiz(question: "盛岡や 奥州で つくられる 鉄の 工芸は？", choices: ["南部鉄器", "有田焼", "輪島塗"], answer: 0),
            Quiz(question: "盛岡の 北西に そびえる『南部片富士』は？", choices: ["鳥海山", "岩手山", "磐梯山"], answer: 1),
            Quiz(question: "『岩手』の 名前の もとに なった ものは？", choices: ["山の かたち", "川の 名前", "鬼の 手形"], answer: 2),
            Quiz(question: "岩手県は 本州で 何番めに ひろい？", choices: ["1番", "2番", "3番"], answer: 0),
            Quiz(question: "盛岡を ながれる 東北で いちばん 長い 川は？", choices: ["最上川", "北上川", "阿武隈川"], answer: 1),
        ],
        .hiraizumi: [
            Quiz(question: "平泉に ある 金色の お堂は？", choices: ["金閣", "中尊寺金色堂", "銀閣"], answer: 1),
            Quiz(question: "平泉で さかえた 一族は？", choices: ["奥州藤原氏", "伊達氏", "津軽氏"], answer: 0),
            Quiz(question: "平泉が えらばれた ものは？", choices: ["世界自然遺産", "日本三景", "世界文化遺産"], answer: 2),
            Quiz(question: "平泉で『夏草や 兵どもが 夢の跡』と よんだ 人は？", choices: ["紫式部", "松尾芭蕉", "宮沢賢治"], answer: 1),
            Quiz(question: "平泉の 浄土庭園で 有名な お寺は？", choices: ["毛越寺", "東大寺", "清水寺"], answer: 0),
            Quiz(question: "岩手うまれで『銀河鉄道の夜』を 書いた 人は？", choices: ["夏目漱石", "太宰治", "宮沢賢治"], answer: 2),
        ],
        .tono: [
            Quiz(question: "遠野に つたわる 話を あつめた 本は？", choices: ["遠野物語", "源氏物語", "竹取物語"], answer: 0),
            Quiz(question: "遠野物語を 書いた 人は？", choices: ["芥川龍之介", "柳田国男", "石川啄木"], answer: 1),
            Quiz(question: "遠野の カッパ淵に すむと いわれる ものは？", choices: ["てんぐ", "ゆきおんな", "かっぱ"], answer: 2),
            Quiz(question: "家に すむと しあわせを よぶ こどもの すがたの ものは？", choices: ["ざしきわらし", "こなきじじい", "いったんもめん"], answer: 0),
            Quiz(question: "人と 馬が ひとつ屋根の 下で くらした 遠野の 家は？", choices: ["合掌造り", "曲り家", "武家屋敷"], answer: 1),
            Quiz(question: "岩泉に ある 日本三大鍾乳洞の ひとつは？", choices: ["秋芳洞", "玉泉洞", "龍泉洞"], answer: 2),
            Quiz(question: "龍泉洞の 地底湖の 青さの よびなは？", choices: ["ドラゴンブルー", "エメラルドグリーン", "スカイブルー"], answer: 0),
        ],
    ]
}

extension World {
    /// 盛岡の 出口の 前（全滅したら ここで 目を さます）。
    static let moriokaGate = Point(x: 13, y: 15)

    static var iwateMaps: [GameMap] {
        [iwateField, morioka, hiraizumi, tono, ryusendo1, ryusendo2, iwatesan1, iwatesan2,
         wankoHouse, nanbuHouse, chusonji, hiraizumiHouse, tonoHouse, magariya]
    }

    /// 岩手県。56×36 マス。まんなかを 北上川が 北から 南へ ながれる。
    /// 西は 奥羽山脈、北西に 岩手山。川の 西に 盛岡と 盛岡駅、南に 平泉。
    /// 川の 東は 北上高地で 遠野、北東の 岩泉に 龍泉洞。東の はしは 三陸の リアス海岸。
    static let iwateField = GameMap(
        id: .iwateField,
        name: "岩手県",
        kind: .field,
        region: .iwate,
        rows: [
            "MMMMhh...................~...........................~~~",
            "MMMMhh...................~........................~~~~~~",
            "MMMMhh...................~......................c~~~~~~~",
            "MMMMhh.c.................~...........................~~~",
            "MMMMhh.....hhhhh.........~....hhhhhhhhhhh............~~~",
            "MMMMhh....hMMMMMh........~....hhhhhhhhhhh............~~~",
            "MMMMhh...hMMMMMMMh.......~....hhhMMMMMhhh....C.......~~~",
            "MMMMhh...hMMMMMMMh.......~....hhhMMMMMhhh....=....~~~~~~",
            "MMMMhh...hMMMMMMMh.......~....hhhMMMMMhhh....=...~~~~~~~",
            "MMMMhh....hMMMMMh........~....hhhMMMMMhhh....=.......~~~",
            "MMMMhh.....hhChh.........~....hhhhhhhhhhh....=.......~~~",
            "MMMMhh.......=...........~....hhhhhhhhhhh....=.......~~~",
            "MMMMhh.......=...........~....hhhhhhhhhhh....=.......~~~",
            "MMMMhh.......=.......T.A.~...................=....~~~~~~",
            "MMMMhh.......============b===................=...~~~~~~~",
            "MMMMhh.................=.~..=fffff....========.......~~~",
            "MMMMhh..fffffffff......=.~..=fffff....=..............~~~",
            "MMMMhh..fffffffff......=.~..=fffff....=..............~~~",
            "MMMMhh..fffffffff......=.~..=fffff....=...........c..~~~",
            "MMMMhh..fffffffff......=.~..=.........T...........~~~~~~",
            "MMMMhh..fffffffff......==b=============..........~~~~~~~",
            "MMMMhh..fffffffff......=.~...........................~~~",
            "MMMMhh..fffffffff.ppppp=p~ppppp......................~~~",
            "MMMMhh............ppppp=p~ppppp......................~~~",
            "MMMMhh............ppppp=p~ppppp.........hhhhhhhh.....~~~",
            "MMMMhh............ppppp=p~ppppp.........hhhhhhhh..~~~~~~",
            "MMMMhh............ppppp=p~ppppp.........hhMMMMhh.~~~~~~~",
            "MMMMhh......ffffffppppp=p~ppppp.........hhMMMMhh.....~~~",
            "MMMMhh......ffffffppppp=p~ppppp.........hhMMMMhh.....~~~",
            "MMMMhh......ffffffppppp=p~..............hhMMMMhh.....~~~",
            "MMMMhh......ffffffff...=.~..............hhhhhhhh.....~~~",
            "MMMMhh......ffffffff...=.~..............hhhhhhhh..~~~~~~",
            "MMMMhh......ffffffff...T.~..............hhhhhhhh.~~~~~~~",
            "MMMMhh......ffffffff.....~...........................~~~",
            "MMMMhh...c...............~..........c................~~~",
            "MMMMhh...................~...........................~~~"
        ],
        outside: .mountain,
        warps: [
            Point(x: 21, y: 13): Warp(to: .morioka, at: Point(x: 13, y: 15)),
            Point(x: 23, y: 32): Warp(to: .hiraizumi, at: Point(x: 11, y: 12)),
            Point(x: 38, y: 19): Warp(to: .tono, at: Point(x: 9, y: 10)),
            // 龍泉洞は 語り部の とおりふだ、岩手山は 中尊寺の おふだで ひらく。
            Point(x: 45, y: 6): Warp(to: .ryusendo1, at: Point(x: 10, y: 10), needs: .iwateCave),
            Point(x: 13, y: 10): Warp(to: .iwatesan1, at: Point(x: 11, y: 10), needs: .iwateSeal),
        ],
        chestRewards: [.gold(250), .item(.hanabi), .item(.dadachamame), .item(.wankoSoba), .gold(300)],
        encounterAreas: [
            EncounterArea(name: "盛岡のまわり", around: [Point(x: 21, y: 14), Point(x: 23, y: 14), Point(x: 14, y: 14), Point(x: 13, y: 11)],
                          enemies: Balance.places[8].enemies, quizTown: .morioka),
            EncounterArea(name: "遠野へむかう道",
                          around: [Point(x: 38, y: 20), Point(x: 32, y: 20), Point(x: 45, y: 15), Point(x: 45, y: 8), Point(x: 48, y: 30)],
                          enemies: Balance.places[9].enemies, quizTown: .tono),
            EncounterArea(name: "平泉へむかう道", around: [Point(x: 23, y: 31), Point(x: 23, y: 25), Point(x: 13, y: 30), Point(x: 9, y: 34)],
                          enemies: Balance.places[9].enemies, quizTown: .hiraizumi),
        ],
        markerFloor: .grass
    )

    /// 盛岡。北東の すみに 石割桜、まんなかを 中津川が ながれる。
    static let morioka = GameMap(
        id: .morioka,
        name: "もりおか",
        kind: .town,
        region: .iwate,
        town: TownInfo(name: "盛岡", reading: "もりおか", tagline: "わんこそばと さんさの まち",
                       innBase: 6, innPerLevel: 5,
                       stock: [.kiritanpo, .nanbuSenbei, .wankoSoba, .namahageHocho, .nanbuSword, .akitaSugiArmor, .nanbuArmor]),
        rows: [
            "############################",
            "#______________________k_P_#",
            "#__HHHHH_____HHH_______kk__#",
            "#__WWdWW_____WdW_____t_____#",
            "#_____________________1____#",
            "#_t______P______________6__#",
            "#~~~~~~~~~~~bb~~~~~~~~~~~~~#",
            "#__________________________#",
            "#____III____SSS_____t______#",
            "#____III____SSS____________#",
            "#____YdW____ZdW______3_____#",
            "#__________________________#",
            "#_t______e______4______2___#",
            "#__________________________#",
            "#_______P______t_____c_____#",
            "#__________________________#",
            "############EEEE############"
        ],
        outside: .grass,
        warps: [
            Point(x: 5, y: 3): Warp(to: .wankoHouse, at: Point(x: 4, y: 4)),
            Point(x: 14, y: 3): Warp(to: .nanbuHouse, at: Point(x: 4, y: 4)),
            Point(x: 6, y: 10): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 13, y: 10): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(12...15, row: 16, to: .iwateField, at: Point(x: 21, y: 14))) { first, _ in first },
        villagers: [
            ["おとこ「盛岡の 名物は わんこそば！",
             "　小さな おわんに つぎつぎ そばが 入るんだ。」"],
            ["おばさん「盛岡の 北西に そびえる 岩手山は",
             "　『南部片富士』とも よばれるのよ。」"],
            ["ふなかた「盛岡の まちを ながれる 北上川は",
             "　東北で いちばん 長い 川さ。」"],
            ["がくせい「岩手県は 本州で 1番 ひろい 県なんだって。",
             "　北海道の つぎに ひろいんだ。」"],
            ["おじいさん「盛岡城の あとは 石垣の のこる 公園に なっとる。」"],
        ],
        residents: ["1": .lostZashiki, "2": .iwateGuide, "3": .iwateExaminer, "4": .sansaMaster, "6": .iwateDancer],
        plaques: [
            Point(x: 25, y: 1): Plaque(title: "石割桜", lines: [
                "かんばんに こう かいてある。",
                "「石割桜」",
                "大きな 岩の われめから はえた さくら。",
                "国の 天然記念物。",
            ]),
            Point(x: 9, y: 5): Plaque(title: "鉄器", lines: [
                "かんばんに こう かいてある。",
                "「南部鉄器の 工房」",
                "鉄びんや ふうりんを つくっている。",
            ]),
            Point(x: 8, y: 14): Plaque(title: "盛岡城", lines: [
                "かんばんに こう かいてある。",
                "「盛岡城跡公園」",
                "南部氏の 城あと。 石垣が のこる。",
            ]),
        ],
        chestRewards: [.item(.nanbuSenbei)]
    )

    /// 平泉。北の 森の おくに 中尊寺、南に 毛越寺の 大泉が池。
    static let hiraizumi = GameMap(
        id: .hiraizumi,
        name: "ひらいずみ",
        kind: .town,
        region: .iwate,
        town: TownInfo(name: "平泉", reading: "ひらいずみ", tagline: "金色堂の かがやく まち",
                       innBase: 7, innPerLevel: 6,
                       stock: [.wankoSoba, .nanbuSenbei, .konjikiTachi, .fujiwaraArmor]),
        rows: [
            "########################",
            "#ffffffffffffffffffffff#",
            "#f_____HHHHHH________ff#",
            "#f__P__WWWdWW____t___ff#",
            "#f___________________ff#",
            "#ffff_fffffffffff_fffff#",
            "#______________________#",
            "#_III___SSS___HHH___P__#",
            "#_YdW___ZdW___WdW______#",
            "#______________________#",
            "#_t___e______~~~~~~~___#",
            "#____________~~~~~~~_t_#",
            "#_____P______~~~~~~~_c_#",
            "##########EEEE##########"
        ],
        outside: .grass,
        warps: [
            Point(x: 10, y: 3): Warp(to: .chusonji, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 8): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 9, y: 8): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 15, y: 8): Warp(to: .hiraizumiHouse, at: Point(x: 4, y: 4)),
        ].merging(exits(10...13, row: 13, to: .iwateField, at: Point(x: 23, y: 33))) { first, _ in first },
        villagers: [
            ["あんないにん「中尊寺金色堂は 金箔で おおわれた お堂。",
             "　平泉で さかえた 奥州藤原氏が たてたんだ。」"],
            ["おばさん「平泉は 世界文化遺産に えらばれたのよ。」"],
            ["がくせい「となりの 花巻は 宮沢賢治の ふるさと。",
             "　『銀河鉄道の夜』を 書いた 人さ。」"],
        ],
        plaques: [
            Point(x: 4, y: 3): Plaque(title: "金色堂", lines: [
                "かんばんに こう かいてある。",
                "「中尊寺 金色堂」",
                "900年ほど まえに たてられた 金色の お堂。",
            ]),
            Point(x: 20, y: 7): Plaque(title: "毛越寺", lines: [
                "かんばんに こう かいてある。",
                "「毛越寺」",
                "大きな 池の ある 浄土庭園の お寺。",
            ]),
            Point(x: 6, y: 12): Plaque(title: "高館", lines: [
                "かんばんに こう かいてある。",
                "「高館 義経堂」",
                "松尾芭蕉が『夏草や』の 句を よんだ 場所。",
            ]),
        ],
        chestRewards: [.gold(120)]
    )

    /// 遠野。山に かこまれた 盆地の まち。東に カッパ淵。
    static let tono = GameMap(
        id: .tono,
        name: "とおの",
        kind: .town,
        region: .iwate,
        town: TownInfo(name: "遠野", reading: "とおの", tagline: "民話の ふるさと",
                       innBase: 7, innPerLevel: 5,
                       stock: [.wankoSoba, .nanbuSenbei, .nanbuSword, .nanbuArmor]),
        rows: [
            "######################",
            "#hhhhhhhhhhhhhhhhhhhh#",
            "#h__HHHHH______HHH__h#",
            "#h__WWdWW______WdW__h#",
            "#____________________#",
            "#_t___P____e______t__#",
            "#____________________#",
            "#_III____SSS____~~~__#",
            "#_YdW____ZdW__P_~~~t_#",
            "#_______________~~~__#",
            "#____t___________c___#",
            "########EEEE##########"
        ],
        outside: .grass,
        warps: [
            Point(x: 6, y: 3): Warp(to: .tonoHouse, at: Point(x: 4, y: 4)),
            Point(x: 16, y: 3): Warp(to: .magariya, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 8): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 10, y: 8): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(8...11, row: 11, to: .iwateField, at: Point(x: 38, y: 20))) { first, _ in first },
        villagers: [
            ["がくせい「遠野物語は 遠野に つたわる ふしぎな 話を あつめた 本。",
             "　柳田国男が 書いたんだ。」"],
            ["こども「カッパ淵には かっぱが すむと いわれてるよ！",
             "　きゅうりで つれるかなあ？」"],
            ["おじいさん「ここらの 曲り家は 人と 馬が",
             "　ひとつ屋根の 下で くらす 家なんじゃ。」"],
            ["たびびと「龍泉洞は 岩泉に ある 日本三大鍾乳洞の ひとつ。",
             "　地底湖の 青さは ドラゴンブルーと よばれるんだ。」"],
        ],
        plaques: [
            Point(x: 6, y: 5): Plaque(title: "物語", lines: [
                "かんばんに こう かいてある。",
                "「とおの物語の館」",
                "遠野の 昔話を きける 館。",
            ]),
            Point(x: 14, y: 8): Plaque(title: "カッパ淵", lines: [
                "かんばんに こう かいてある。",
                "「カッパ淵」",
                "かっぱが すむと つたわる 小川の ふち。",
            ]),
        ],
        chestRewards: [.item(.nanbuSenbei)]
    )

    /// 龍泉洞。地底湖の ある 鍾乳洞。
    static let ryusendo1 = cave(
        .ryusendo1, name: "龍泉洞 B1", label: "龍泉洞", region: .iwate,
        rows: [
            "###################",
            "#,,,,,#~~~~~#,,,,c#",
            "#,###,#~~~~~#,###,#",
            "#,#,,,,,~~~,,,,,#,#",
            "#,#,###,,,,,###,#,#",
            "#,,,#~~~#,#~~~#,,,#",
            "###,#~~~#,#~~~#,###",
            "#D,,,,,,,,,,,,,,,,#",
            "#,#####,###,#####,#",
            "#,,,c#,,,#,,,#,,,,#",
            "#####,,#,U,#,,#####",
            "###################"
        ],
        warps: [
            Point(x: 9, y: 10): Warp(to: .iwateField, at: Point(x: 45, y: 7)),
            Point(x: 1, y: 7): Warp(to: .ryusendo2, at: Point(x: 7, y: 8)),
        ],
        chestRewards: [.gold(220), .item(.nanbuSenbei)],
        enemies: Balance.places[10].enemies, quizTown: .tono
    )

    static let ryusendo2 = cave(
        .ryusendo2, name: "龍泉洞 地底湖", region: .iwate,
        rows: [
            "#################",
            "#~~~~~,,B,,~~~~~#",
            "#~~~~,,,,,,,~~~~#",
            "#~~~,,,~~~,,,~~~#",
            "#,,,,~~~~~~~,,,,#",
            "#,##,,~~~~~,,##,#",
            "#,#c,,,,,,,,,#,,#",
            "#,######,######,#",
            "#,,,,,,,U,,,,,,,#",
            "#################"
        ],
        warps: [Point(x: 8, y: 8): Warp(to: .ryusendo1, at: Point(x: 1, y: 8))],
        chestRewards: [.item(.hanabi)],
        bossKind: .ryusendoLord, enemies: Balance.places[10].enemies, quizTown: .tono
    )

    static let iwatesan1 = cave(
        .iwatesan1, name: "岩手山 B1", label: "岩手山", region: .iwate,
        rows: [
            "###################",
            "#c,,,#,,,,,,,#,,,,#",
            "###,,#,#####,#,##,#",
            "#,,,##,#,,,#,,,#,,#",
            "#,#,,,,#,#,####,#,#",
            "#,####,#,#,,,,,,#,#",
            "#,,,,#,,,###,####,#",
            "####,####,,,,#,,,,#",
            "#D,,,,,,,,#,,,,#,c#",
            "#,#######,#,####,##",
            "#,,,,,,,,,U,,,,,,,#",
            "###################"
        ],
        warps: [
            Point(x: 10, y: 10): Warp(to: .iwateField, at: Point(x: 13, y: 11)),
            Point(x: 1, y: 8): Warp(to: .iwatesan2, at: Point(x: 6, y: 8)),
        ],
        chestRewards: [.gold(260), .item(.yonezawaBeef)],
        enemies: Balance.places[11].enemies, quizTown: .morioka
    )

    static let iwatesan2 = cave(
        .iwatesan2, name: "岩手山 B2", region: .iwate,
        rows: [
            "###############",
            "#,,,,,,B,,,,,,#",
            "#,,,,,,,,,,,,,#",
            "####,,,,,,,####",
            "#,,,,,###,,,,,#",
            "#,###,,c,,###,#",
            "#,#,,,###,,,#,#",
            "#,#,#######,#,#",
            "#,,,,,,U,,,,,,#",
            "###############"
        ],
        warps: [Point(x: 7, y: 8): Warp(to: .iwatesan1, at: Point(x: 1, y: 9))],
        chestRewards: [.item(.shakudama)],
        bossKind: .mitsuishiOni, enemies: Balance.places[11].enemies, quizTown: .morioka
    )

    // MARK: 家の中

    static let wankoHouse = house(
        .wankoHouse, name: "そばや",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLcX",
            "XooKKKooX",
            "Xoo1oootX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .morioka, region: .iwate, door: Point(x: 5, y: 3),
        villagers: [["おきゃく「わんこそばを 100ぱい たべたぞ！",
                     "　ふたを しめるまで おかわりが つづくんだ。」"]],
        residents: ["1": .wankoHost], chestRewards: [.item(.wankoSoba)]
    )

    static let nanbuHouse = house(
        .nanbuHouse, name: "南部鉄器の 工房",
        rows: [
            "XXXXXXXXX",
            "XLL1oLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .morioka, region: .iwate, door: Point(x: 14, y: 3),
        villagers: [],
        residents: ["1": .nanbuSmith], chestRewards: [.gold(90)]
    )

    static let chusonji = house(
        .chusonji, name: "中尊寺",
        rows: [
            "XXXXXXXXX",
            "XLLL1LLcX",
            "XoooooooX",
            "XtooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .hiraizumi, region: .iwate, door: Point(x: 10, y: 3),
        villagers: [["こぞう「金色堂の 中には 藤原氏 4代の ひとびとが ねむって おられます。」"]],
        residents: ["1": .chusonjiMonk], chestRewards: [.item(.nanbuSenbei)]
    )

    static let hiraizumiHouse = house(
        .hiraizumiHouse, name: "やすみどころ",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLcX",
            "XoooooooX",
            "Xoo1ooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .hiraizumi, region: .iwate, door: Point(x: 15, y: 8),
        villagers: [],
        residents: ["1": .hiraizumiPilgrim], chestRewards: [.gold(80)]
    )

    static let tonoHouse = house(
        .tonoHouse, name: "語り部の 家",
        rows: [
            "XXXXXXXXX",
            "XLLo1oLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .tono, region: .iwate, door: Point(x: 6, y: 3),
        villagers: [],
        residents: ["1": .kataribe], chestRewards: [.item(.wankoSoba)]
    )

    static let magariya = house(
        .magariya, name: "曲り家",
        rows: [
            "XXXXXXXXX",
            "XLLo1oo2X",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .tono, region: .iwate, door: Point(x: 16, y: 3),
        villagers: [],
        residents: ["1": .zashikiHost, "2": .zashikiHome]
    )
}
