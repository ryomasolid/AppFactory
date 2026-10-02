import Foundation

// MARK: - 青森県
//
// 旅の はじまり。青森で ねぶた師に 話を きき、弘前の マタギの 案内で 十和田湖の ほこらへ。
// 八郎太郎（中ボス）を しずめると ねぶた師が 金魚ねぶたの あかりを くれ、八甲田山へ 入れる。
// ゆきおに（ぬし）を 倒すと ねぶた祭が もどり、秋田へ 行ける。
// クリア後は 下北半島の 恐山（裏ボス）。

extension StoryFlag {
    /// 青森の ねぶた師から 話を きいた。
    static let aomoriHeard: StoryFlag = "aomori.heard"
    /// 弘前の マタギが 奥入瀬の 道を 案内してくれる（十和田湖の ほこらに 入れる）。
    static let aomoriTowada: StoryFlag = "aomori.towada"
    /// ねぶた師から 金魚ねぶたの あかりを もらった（八甲田山に 入れる）。
    static let aomoriLantern: StoryFlag = "aomori.lantern"
}

extension Story {
    static let aomoriGates: [StoryFlag: [String]] = [
        .aomoriTowada: ["湖へ つづく 奥入瀬の 道が たおれた 木で ふさがっている。",
                        "（山に くわしい 人の 案内が あれば……）"],
        .aomoriLantern: ["八甲田の ほらあなは ふぶきで まっくらだ。",
                         "とても 先へは すすめない。",
                         "（つよい あかりが あれば……）"],
    ]

    static let aomoriImplications: [StoryFlag: EnemyKind] = [
        .aomoriHeard: .hachirotaro,
        .aomoriTowada: .hachirotaro,
        .aomoriLantern: .yukioni,
    ]

    static func aomoriHint(_ p: StoryProgress) -> [String]? {
        if !p.has(.aomoriHeard) {
            return ["ちょうろう「ねぶたの 火が きえて 青森は まっくらじゃ。",
                    "　まずは ねぶたの家の ねぶた師に 話を きくのじゃ。",
                    "　ねぶたの家は 街の 北西じゃ。」"]
        }
        if !p.has(.aomoriTowada) {
            return ["ちょうろう「十和田湖へは 弘前の マタギに 案内を たのめ。",
                    "　弘前は 青森の 南西、岩木山の ふもとじゃ。」"]
        }
        if !p.defeatedBosses.contains(.hachirotaro) {
            return ["ちょうろう「十和田湖は 青森の 南東。 湖の 東の ほとりに ほこらが ある。",
                    "　弘前の ものの 話を きいておけば ちしきで おいうちが きまるぞ。」"]
        }
        if !p.has(.aomoriLantern) {
            return ["ちょうろう「八郎太郎を しずめたか！",
                    "　ねぶた師に しらせて やるのじゃ。」"]
        }
        if !p.defeatedBosses.contains(.yukioni) {
            return ["ちょうろう「八甲田山は 青森の 南じゃ。 ほらあなは ふかいぞ。",
                    "　レベルが 6を こえたら 弘前で 津軽の刀を そろえて いどむのじゃ。」"]
        }
        return nil
    }
}

extension Errand {
    /// 弘前の りんご農家 → 八戸の 朝市。
    static let aomoriApples = Errand(
        id: "aomori.apples", package: "りんごの はこ",
        ask: ["のうか「ちょうど よかった！ 八戸の 朝市に りんごを とどけて くれんか。",
              "　八戸は 青森の 南東、太平洋がわの みなとまちじゃ。」"],
        reminder: ["のうか「りんごは 八戸の 朝市の おばさんに たのむぞ。」"],
        thanks: ["のうか「とどけて くれたか！ ありがとさん。", "　これは おれいじゃ。」"],
        after: ["のうか「りんごは 春に 白い 花を さかせるんじゃ。",
                "　青森は りんごの 生産量 日本一なんじゃぞ。」"],
        delivered: ["おばさん「弘前の りんご！ まってたよ。", "　これで 朝市も にぎやかに なるねえ。」"],
        idle: ["おばさん「日曜の 朝は 港で 朝市が ひらくんだよ。", "　八戸の 朝市は 日本でも 大きいほうさ。」"],
        gold: 80, items: [.senbeiJiru]
    )
}

extension LostQuest {
    /// 三内丸山遺跡で 迷子に なった こども。
    static let jomonKid = LostQuest(
        id: "aomori.jomonKid",
        ask: ["おかあさん「むすこが いないの。 三内丸山遺跡を 見に いくって……",
              "　遺跡は まちの 南西の 森の おくよ。」"],
        thanks: ["おかあさん「ああ、ぶじで よかった！ ありがとう。」"],
        after: ["おかあさん「この子ったら 縄文時代が だいすきなの。」"],
        lost: ["こども「大きな 柱の あとを 見てたら まいごに なっちゃった……",
               "　え？ ママが さがしてる？ ありがとう！」",
               "こどもは おかあさんの ほうへ かけていった。"],
        home: ["こども「縄文の むらには 大きな 柱の たてものが あったんだって！」"],
        items: [.apple, .apple, .apple]
    )
}

extension Resident {
    func aomoriScene(_ p: StoryProgress) -> StoryScene? {
        switch self {
        case .nebutashi:
            if p.defeatedBosses.contains(.yukioni) {
                return StoryScene(lines: [
                    "ねぶたし「ねぶたの 火が もどった！ ラッセラー！",
                    "　秋田でも 竿燈の あかりが きえたと いう。",
                    "　駅から 新幹線で 秋田へ いってくれ。」",
                ])
            }
            if p.has(.aomoriLantern) {
                return StoryScene(lines: [
                    "ねぶたし「その あかりで 八甲田の ふぶきを てらすんだ。",
                    "　八甲田山は 街の 南。 ゆきおにに 気をつけろ。」",
                ])
            }
            if p.defeatedBosses.contains(.hachirotaro) {
                return StoryScene(lines: [
                    "ねぶたし「八郎太郎を しずめたか！ そして ねぶたの 火は 八甲田に……",
                    "　よし、この 金魚ねぶたを もっていけ。",
                    "　ねぶたの あかりなら ふぶきの 中でも きえやしない。」",
                    "金魚ねぶたの あかりを てにいれた！",
                ], sets: [.aomoriLantern])
            }
            if p.has(.aomoriHeard) {
                return StoryScene(lines: [
                    "ねぶたし「十和田湖へは 弘前の マタギに 案内を たのむんだ。",
                    "　弘前は 街の 南西、岩木山の ふもとだ。」",
                ])
            }
            return StoryScene(lines: [
                "ねぶたし「わしは ねぶた師。 紙と 竹で ねぶたを つくる しょくにんだ。",
                "　ねぶたは 大きな 人形の 中に あかりを ともす まつりの だしよ。",
                "　だが ある夜、十和田湖から りゅうが とんできて",
                "　ねぶたの 火を ぜんぶ けしていった。 八郎太郎に ちがいない。",
                "　十和田湖へ いくなら 弘前の マタギに 案内を たのむと いい。」",
            ], sets: [.aomoriHeard])

        case .matagi:
            if p.defeatedBosses.contains(.hachirotaro) {
                return StoryScene(lines: [
                    "マタギ「八郎太郎を しずめたか。 さすがだ。",
                    "　八郎太郎は むかし 十和田湖を おわれて 秋田の 八郎潟へ うつったと いう。",
                    "　山の 神さまに かんしゃを わすれるなよ。」",
                ])
            }
            if p.has(.aomoriTowada) {
                return StoryScene(lines: [
                    "マタギ「奥入瀬の 道の たおれた 木は どかしておいた。",
                    "　十和田湖は 青森の 南東。 湖の 東の ほとりに ほこらが ある。」",
                ])
            }
            if p.has(.aomoriHeard) {
                return StoryScene(lines: [
                    "マタギ「ねぶた師の たのみか。 十和田湖の 八郎太郎……",
                    "　湖へ つづく 奥入瀬渓流の 道は たおれた 木で ふさがっておる。",
                    "　よし、わしが 木を どかして 案内しよう。",
                    "　奥入瀬渓流は コケと 滝の きれいな 道じゃ。」",
                    "マタギが 十和田湖への 道を ひらいてくれた！",
                ], sets: [.aomoriTowada])
            }
            return StoryScene(lines: [
                "マタギ「わしは マタギ。 山で くらす かりうどじゃ。",
                "　白神山地の ブナの 森は 青森と 秋田に またがる 世界遺産。",
                "　十和田湖から ながれでる 奥入瀬渓流も うつくしいぞ。」",
            ])

        case .appleFarmer: return Errand.aomoriApples.giverScene(p)
        case .hachinoheMarket: return Errand.aomoriApples.receiverScene(p)
        case .jomonMother: return LostQuest.jomonKid.seekerScene(p)
        case .lostJomonKid: return LostQuest.jomonKid.lostScene()
        case .jomonKidHome: return LostQuest.jomonKid.homeScene()
        case .aomoriGuide: return Story.stampScene(.aomori, p, towns: "青森・弘前・八戸", gift: .senbeiJiru)
        case .aomoriExaminer: return Story.examScene(.aomori, p)

        case .aomoriDancer:
            return StoryScene(lines: [
                "はねと「ラッセラー！ ラッセラー！",
                "　ねぶたが もどって 青森の 夏が かえってきた！」",
            ])

        case .shamisen:
            return StoryScene(lines: [
                "しゃみせんひき「ベン ベン ベン！ これが 津軽三味線。",
                "　たたくように ひく 力強い 音色だろう？」",
            ])

        case .itako:
            if p.has(.cleared) {
                return StoryScene(lines: [
                    "おばば「恐山の おくへは 6県の ちしきを きわめた ものしか すすめぬ。",
                    "　6つの 県の ちしき検定に ぜんぶ 合格してから いくのじゃ。",
                    "　恐山は 下北半島。 むつ湾の 東を 北へ まわるのじゃ。」",
                ])
            }
            return StoryScene(lines: [
                "おばば「下北半島の 恐山は 日本三大霊場の ひとつ。",
                "　いまは やみの けはいが ただよっておる……",
                "　東北の 守護神を 解きはなったら たずねてみるが よい。」",
            ])

        default: return nil
        }
    }
}

extension QuizBank {
    static let aomori: [MapID: [Quiz]] = [
        .aomori: [
            Quiz(question: "青森で 夏に ひらかれる 大きな まつりは？", choices: ["竿燈まつり", "ねぶた祭", "七夕まつり"], answer: 1),
            Quiz(question: "青森県が 生産量 日本一の くだものは？", choices: ["りんご", "みかん", "もも"], answer: 0),
            Quiz(question: "青森市に ある 縄文時代の 大きな 遺跡は？", choices: ["吉野ヶ里遺跡", "登呂遺跡", "三内丸山遺跡"], answer: 2),
            Quiz(question: "むかし 青森と 函館を むすんでいた 船は？", choices: ["北前船", "青函連絡船", "黒船"], answer: 1),
            Quiz(question: "青森市の 北に ひろがる 湾は？", choices: ["陸奥湾", "東京湾", "伊勢湾"], answer: 0),
            Quiz(question: "青森と 北海道を 海の 下で むすぶ トンネルは？", choices: ["関門トンネル", "丹那トンネル", "青函トンネル"], answer: 2),
            Quiz(question: "ねぶたの 人形の 中に ともす ものは？", choices: ["あかり", "こおり", "みず"], answer: 0),
            Quiz(question: "陸奥湾で 養殖が さかんな 貝は？", choices: ["アサリ", "ハマグリ", "ホタテ"], answer: 2),
            Quiz(question: "ねぶた祭の かけごえは？", choices: ["ワッショイ", "ラッセラー", "ヤッショーマカショ"], answer: 1),
        ],
        .hirosaki: [
            Quiz(question: "弘前城の 名所として 有名な 花は？", choices: ["ひまわり", "さくら", "ラベンダー"], answer: 1),
            Quiz(question: "『津軽富士』と よばれる 山は？", choices: ["岩木山", "八甲田山", "岩手山"], answer: 0),
            Quiz(question: "弘前で ひらかれる 扇の かたちの まつりは？", choices: ["花笠まつり", "わらじまつり", "ねぷたまつり"], answer: 2),
            Quiz(question: "津軽に つたわる 力強い 三味線は？", choices: ["長唄", "津軽三味線", "沖縄三線"], answer: 1),
            Quiz(question: "青森と 秋田に またがる ブナの 森の 世界遺産は？", choices: ["白神山地", "屋久島", "知床"], answer: 0),
            Quiz(question: "布に 糸で 模様を さす 津軽の 手芸は？", choices: ["西陣織", "友禅", "こぎん刺し"], answer: 2),
            Quiz(question: "弘前に 多く のこる 明治・大正の たてものは？", choices: ["五重塔", "洋館", "合掌造り"], answer: 1),
            Quiz(question: "十和田湖から ながれでる コケと 滝の 渓流は？", choices: ["奥入瀬渓流", "黒部峡谷", "長瀞"], answer: 0),
        ],
        .hachinohe: [
            Quiz(question: "八戸の 蕪島で ひなを そだてる 鳥は？", choices: ["つる", "ペンギン", "うみねこ"], answer: 2),
            Quiz(question: "八戸の 名物の なべは？", choices: ["せんべい汁", "きりたんぽ鍋", "芋煮"], answer: 0),
            Quiz(question: "八戸港で 水あげが 多い ものは？", choices: ["マグロ", "イカ", "カツオ"], answer: 1),
            Quiz(question: "八戸が めんしている 海は？", choices: ["日本海", "オホーツク海", "太平洋"], answer: 2),
            Quiz(question: "青森県が 生産量 日本一の やさいは？", choices: ["にんにく", "だいこん", "キャベツ"], answer: 0),
            Quiz(question: "八戸の 港で 日曜の 朝に ひらく 市は？", choices: ["夜市", "朝市", "のみの市"], answer: 1),
        ],
    ]
}

extension World {
    /// 長老の すぐ下。
    static let aomoriStart = Point(x: 10, y: 13)
    /// 青森の 出口の 前（全滅したら ここで 目を さます）。
    static let aomoriGate = Point(x: 13, y: 20)

    static var aomoriMaps: [GameMap] {
        [aomoriField, aomoriTown, hirosaki, hachinohe, towadako, hakkoda1, hakkoda2, osorezan1, osorezan2,
         nebutaHouse, aomoriHouse, hirosakiCastle, ringoHouse, matagiHouse, hachinoheHouse]
    }

    /// 青森県。56×36 マス。
    /// まんなかに 陸奥湾、北西に 津軽半島、北東に まさかりの かたちの 下北半島（恐山）。
    /// 湾の 南の はしに 青森と 新青森駅、南西に 弘前と 岩木山・白神山地、南に 八甲田山、南東に 十和田湖、東に 八戸。
    static let aomoriField = GameMap(
        id: .aomoriField,
        name: "青森県",
        kind: .field,
        region: .aomori,
        rows: [
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~.....~~~~~~~~~~~~~~~~~~~~~~~~....c.........~~~~",
            "~~~~~~~~...c..~~~~~~~~~~~~~~~~~~~~~~~~~.............~~~~",
            "~~~~~~~.......~~~~~~~~~~~~~~~~~~~~~~~~~~..hMMMh.....~~~~",
            "~~~~~~.........~~~~~~~~~~~~~~~~~~~~~~~~~~hhMMMhh.....~~~",
            "~~~~~..........~~~~~~~~~~~~~~~~~~~~~~~~~~hhhhhhh.....~~~",
            "~~~~~..........~~~~~~~~~~~~~~~~~~~~~~~~~~hhhChhh.....~~~",
            "~~~~...........~~~~~~~~~~~~~~~~~~~~~~~~~~~hh=====....~~~",
            "~~~~............~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.=....~~~",
            "~~~~..fffffff...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.=....~~~",
            "~~~~..fffffff...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.=....~~~",
            "~~~...fffffff....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..=....~~~",
            "~~~...fffffff....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..=....~~~",
            "~~~...fffffff....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..=....~~~",
            "~~~...............~~~~~~~~~~~~~~~~~~~~~~~~~~~...=.....~~",
            "~~..............................................=.....~~",
            "~~..................A...T.......................=.....~~",
            "~~.......ppppppp..===============================.....~~",
            "~~...hhh.ppppppp..=.....=......ff=fff........=ffffff..~~",
            "~~..hMMMhppppppp..=.....====...ff=fff........=ffffff..~~",
            "~~.hMMMMMppppppp..=......hhChh.ff=fff........=ffffff..~~",
            "~~.hMMMMMppppppp..=....hhMM.MMhh.======......=ffffff..~~",
            "~~.hMMMMMh..=======...hMMMMMMMMMh.....=......=ffffff..~~",
            "~~..hMMMh...=.........hMMMMMMMMMh.....=......=........~~",
            "~~...hhh....T.........hMMMMMMMMMh.....=......=====....~~",
            "~~.....................hhMMMMMhh......=======....=....~~",
            "~~.......................hhhhh.......fffff..=....T....~~",
            "~~.................................ff~~~~~ff=.........~~",
            "~~................................ff~~~~~~~f=.........~~",
            "~~.fffffffffff...................ff~~~~~~~~~Cf........~~",
            "~~~fffffffffff...................ff~~~~~~~~~ff......c.~~",
            "~~~fffffffffff...................ff~~~~~~~~~ff........~~",
            "~~~ffcffffffff....................ff~~~~~~~ff.........~~",
            "~~~hhhhhhhffff.....................fc~~~~~ff..........~~",
            "~~~hhhhhhhffff.......................fffff............~~",
            "~~~hhhhhhhffff........................................~~"
        ],
        outside: .water,
        warps: [
            Point(x: 24, y: 16): Warp(to: .aomori, at: Point(x: 13, y: 20)),
            Point(x: 12, y: 24): Warp(to: .hirosaki, at: Point(x: 12, y: 17)),
            Point(x: 49, y: 26): Warp(to: .hachinohe, at: Point(x: 11, y: 11)),
            // 十和田湖は マタギの 案内、八甲田山は 金魚ねぶたの あかりで ひらく。
            Point(x: 44, y: 29): Warp(to: .towadako, at: Point(x: 8, y: 11), needs: .aomoriTowada),
            Point(x: 27, y: 20): Warp(to: .hakkoda1, at: Point(x: 11, y: 10), needs: .aomoriLantern),
            // 恐山は 守護神を 解きはなってから。
            Point(x: 44, y: 6): Warp(to: .osorezan1, at: Point(x: 11, y: 9), needs: .cleared),
        ],
        chestRewards: [.gold(60), .gold(100), .item(.matagiBell), .item(.senbeiJiru), .item(.koginCoat)],
        encounterAreas: [
            EncounterArea(name: "青森のまわり", around: [Point(x: 24, y: 17), Point(x: 20, y: 17), Point(x: 29, y: 17)],
                          enemies: Balance.places[0].enemies, quizTown: .aomori),
            EncounterArea(name: "弘前へむかう道", around: [Point(x: 12, y: 25), Point(x: 16, y: 20), Point(x: 7, y: 30), Point(x: 10, y: 8)],
                          enemies: Balance.places[1].enemies, quizTown: .hirosaki),
            EncounterArea(name: "八戸へむかう道",
                          around: [Point(x: 49, y: 27), Point(x: 44, y: 26), Point(x: 37, y: 21), Point(x: 48, y: 11),
                                   Point(x: 44, y: 7), Point(x: 37, y: 33), Point(x: 27, y: 21)],
                          enemies: Balance.places[1].enemies, quizTown: .hachinohe),
        ],
        markerFloor: .grass
    )

    /// 青森。北は 陸奥湾。北西に ねぶたの家、南西の 森に 三内丸山遺跡。
    static let aomoriTown = GameMap(
        id: .aomori,
        name: "あおもり",
        kind: .town,
        region: .aomori,
        town: TownInfo(name: "青森", reading: "あおもり", tagline: "ねぶたと りんごの 港まち",
                       innBase: 2, innPerLevel: 3,
                       stock: [.apple, .senbeiJiru, .ringoBokuto, .nebutaHoko, .koginCoat, .nebutaHappi]),
        rows: [
            "############################",
            "#~~~~~~~~~~~~~~~~~~~~~~~~~~#",
            "#~~~~~~~~~~~~~~~~~~~~~~~~~~#",
            "#__P_______t_______P_____6_#",
            "#__________________________#",
            "#_HHHHH_____________HHH____#",
            "#_WWdWW__P____t_____WdW____#",
            "#__________________________#",
            "#_______III____SSS_______t_#",
            "#__t____III____SSS_________#",
            "#_______YdW____ZdW____3____#",
            "#__________________________#",
            "#_kk______e________________#",
            "#_kk_______________45______#",
            "#________t_______________2_#",
            "#ffff____________________f_#",
            "#f__f_P__________ff______f_#",
            "#f1_f____________ff______f_#",
            "#ff_ff______t______________#",
            "#fc_____________7__________#",
            "#ffff______________________#",
            "############EEEE############"
        ],
        outside: .grass,
        warps: [
            Point(x: 4, y: 6): Warp(to: .nebutaHouse, at: Point(x: 4, y: 4)),
            Point(x: 21, y: 6): Warp(to: .aomoriHouse, at: Point(x: 4, y: 4)),
            Point(x: 9, y: 10): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 16, y: 10): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(12...15, row: 21, to: .aomoriField, at: Point(x: 24, y: 17))) { first, _ in first },
        villagers: [
            ["ふなのり「むかしは 青函連絡船で 函館へ わたったもんさ。",
             "　いまは 海の 下の 青函トンネルを 新幹線が はしる。」"],
            ["おばさん「青森の 夏と いえば ねぶた祭！",
             "　紙の 大きな 人形の 中に あかりを ともすのよ。",
             "　でも ことしは 火が きえて しまって……」"],
            ["おとこ「この まちの 北に ひろがる 海は 陸奥湾。",
             "　ホタテの 養殖が さかんなんだ。」"],
            ["むすめ「青森は りんごの 生産量 日本一。",
             "　でも ねぶたが きえてから みんな げんきが ないの。」"],
            ["がくせい「まちの 南西に 縄文時代の 三内丸山遺跡が あるよ。",
             "　大きな 柱の あとが のこってるんだ。」"],
            ["おじいさん「ねぶたの かけごえは『ラッセラー』。",
             "　はねとが はねて おどるんじゃ。」"],
        ],
        residents: ["1": .lostJomonKid, "2": .aomoriGuide, "3": .aomoriExaminer, "4": .jomonMother,
                    "5": .jomonKidHome, "6": .aomoriDancer, "7": .itako],
        plaques: [
            Point(x: 3, y: 3): Plaque(title: "八甲田丸", lines: [
                "かんばんに こう かいてある。",
                "「青函連絡船 メモリアルシップ 八甲田丸」",
                "青森と 函館を むすんでいた 船。",
            ]),
            Point(x: 19, y: 3): Plaque(title: "大橋", lines: [
                "かんばんに こう かいてある。",
                "「青森ベイブリッジ」",
                "陸奥湾に かかる 白い 大きな 橋。",
            ]),
            Point(x: 9, y: 6): Plaque(title: "ねぶた", lines: [
                "かんばんに こう かいてある。",
                "「ねぶたの家 ワ・ラッセ」",
                "まつりに でた 本物の ねぶたが かざられている。",
            ]),
            Point(x: 6, y: 16): Plaque(title: "遺跡", lines: [
                "かんばんに こう かいてある。",
                "「特別史跡 三内丸山遺跡」",
                "やく 5900年前の 縄文時代の むらの あと。",
            ]),
        ],
        chestRewards: [.gold(20)]
    )

    /// 弘前。北に 弘前城（中は 天守）、まわりに さくらと りんご畑。
    static let hirosaki = GameMap(
        id: .hirosaki,
        name: "ひろさき",
        kind: .town,
        region: .aomori,
        town: TownInfo(name: "弘前", reading: "ひろさき", tagline: "城と さくらと りんごの まち",
                       innBase: 3, innPerLevel: 3,
                       stock: [.apple, .senbeiJiru, .nebutaHoko, .tsugaruKatana, .nebutaHappi, .hirosakiArmor]),
        rows: [
            "##########################",
            "#kk_____##########_____kk#",
            "#k______#__HHHHH_#______k#",
            "#___t___#__HHHHH_#__t____#",
            "#_______#__WWdWW_#_______#",
            "#__P____#______P_#____P__#",
            "#_______#####_####_______#",
            "#________________________#",
            "#_HHH_____III___SSS___HHH#",
            "#_WdW_____III___SSS___WdW#",
            "#_________YdW___ZdW______#",
            "#__t___________________t_#",
            "#___________e______1_____#",
            "#pppp_______________pppp_#",
            "#pppp___P______t____pppp_#",
            "#pppp_______________pppp_#",
            "#_______________2________#",
            "#____c___________________#",
            "###########EEEE###########"
        ],
        outside: .grass,
        warps: [
            Point(x: 13, y: 4): Warp(to: .hirosakiCastle, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 9): Warp(to: .ringoHouse, at: Point(x: 4, y: 4)),
            Point(x: 23, y: 9): Warp(to: .matagiHouse, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 10): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 17, y: 10): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(11...14, row: 18, to: .aomoriField, at: Point(x: 12, y: 25))) { first, _ in first },
        villagers: [
            ["おばあさん「弘前城の さくらは 日本一とも いわれるよ。",
             "　春には お堀が 花びらで ピンクに なるの。」"],
            ["おとこ「西に そびえるのが 岩木山。",
             "　『津軽富士』とも よばれてる。」"],
            ["むすめ「弘前の 夏は ねぷたまつり。",
             "　扇の かたちの ねぷたが ねりあるくの。」"],
            ["おばさん「この 服は こぎん刺し。",
             "　津軽の 布に 糸で 模様を さすのよ。」"],
            ["がくせい「弘前には 明治・大正の 洋館が",
             "　たくさん のこってるんだ。」"],
        ],
        residents: ["1": .shamisen, "2": .appleFarmer],
        plaques: [
            Point(x: 3, y: 5): Plaque(title: "弘前城", lines: [
                "かんばんに こう かいてある。",
                "「弘前城」",
                "津軽家の 城。 春は さくらの 名所。",
            ]),
            Point(x: 15, y: 5): Plaque(title: "天守", lines: [
                "かんばんに こう かいてある。",
                "「弘前城 天守」",
                "東北で ただ ひとつ 江戸時代から のこる 天守。",
            ]),
            Point(x: 22, y: 5): Plaque(title: "洋館", lines: [
                "かんばんに こう かいてある。",
                "「旧弘前市立図書館」",
                "明治に たてられた かわいい 洋館。",
            ]),
            Point(x: 8, y: 14): Plaque(title: "りんご", lines: [
                "かんばんに こう かいてある。",
                "「りんご公園」",
                "弘前は りんご畑に かこまれた まち。",
            ]),
        ],
        chestRewards: [.item(.apple)]
    )

    /// 八戸。太平洋に めんした みなとまち。南は 港。
    static let hachinohe = GameMap(
        id: .hachinohe,
        name: "はちのへ",
        kind: .town,
        region: .aomori,
        town: TownInfo(name: "八戸", reading: "はちのへ", tagline: "うみねこと イカの みなと",
                       innBase: 3, innPerLevel: 3,
                       stock: [.apple, .senbeiJiru, .ringoBokuto, .nebutaHoko, .koginCoat, .nebutaHappi]),
        rows: [
            "########################",
            "#______________________#",
            "#__HHH___III___SSS_____#",
            "#__WdW___YdW___ZdW__t__#",
            "#______________________#",
            "#_t______e_______P_____#",
            "#_____________________t#",
            "#__P_____1______t______#",
            "#______________________#",
            "#~~~~~____t_____~~P~~~~#",
            "#~~~~~~___c___~~~~~~~~~#",
            "#~~~~~~~______~~~~~~~~~#",
            "##########EEEE##########"
        ],
        outside: .grass,
        warps: [
            Point(x: 4, y: 3): Warp(to: .hachinoheHouse, at: Point(x: 4, y: 4)),
            Point(x: 10, y: 3): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 16, y: 3): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
        ].merging(exits(10...13, row: 12, to: .aomoriField, at: Point(x: 49, y: 27))) { first, _ in first },
        villagers: [
            ["りょうし「八戸港は イカの 水あげが 日本有数 なんだ。」"],
            ["おばさん「八戸の 名物は せんべい汁。",
             "　南部せんべいを なべに わって いれるのさ。」"],
            ["こども「蕪島には うみねこが いっぱい！",
             "　島の 上で ひなを そだてるんだよ。」"],
            ["おとこ「八戸は 太平洋に めんした みなとまち。",
             "　あさの 海が きもちいいぞ。」"],
            ["のうか「青森は にんにくの 生産量も 日本一だべ。」"],
            ["ふなのり「十和田湖へは 西の 山の ほうへ いくんだ。」"],
        ],
        residents: ["1": .hachinoheMarket],
        plaques: [
            Point(x: 17, y: 5): Plaque(title: "蕪島", lines: [
                "かんばんに こう かいてある。",
                "「蕪島」",
                "うみねこの はんしょく地。 国の 天然記念物。",
            ]),
            Point(x: 3, y: 7): Plaque(title: "八戸港", lines: [
                "かんばんに こう かいてある。",
                "「八戸港」",
                "イカつり船が ずらりと ならぶ みなと。",
            ]),
            Point(x: 18, y: 9): Plaque(title: "種差", lines: [
                "かんばんに こう かいてある。",
                "「種差海岸」",
                "しばふの 原っぱが 海まで つづく 海岸。",
            ]),
        ],
        chestRewards: [.gold(30)]
    )

    /// 十和田湖の ほこら。湖の 水が 入りこんだ ほらあな。いちばん奥に 八郎太郎。
    static let towadako = cave(
        .towadako, name: "十和田湖の ほこら", label: "十和田湖", region: .aomori,
        rows: [
            "#################",
            "#~~~~,,,,,,,~~~~#",
            "#~~~,,,,B,,,,~~~#",
            "#~~~~,,,,,,,~~~~#",
            "#~~~~~~,,,~~~~~~#",
            "#c,,,~~,,,~~,,,c#",
            "#,#,,,,,,#,,,,#,#",
            "#,#,~~~~,#,~~,#,#",
            "#,#,,,,~,#,~,,,,#",
            "#,###,,~,,,~,####",
            "#,,,,,,~~~~~,,,,#",
            "####,,,,,,,,,####",
            "#,,,,,,,U,,,,,,,#",
            "#################"
        ],
        warps: [Point(x: 8, y: 12): Warp(to: .aomoriField, at: Point(x: 44, y: 30))],
        chestRewards: [.gold(80), .item(.apple)],
        bossKind: .hachirotaro, enemies: Balance.places[2].enemies, quizTown: .hirosaki
    )

    static let hakkoda1 = cave(
        .hakkoda1, name: "八甲田山 B1", label: "八甲田山", region: .aomori,
        rows: [
            "#################",
            "#,,,,#,,,,,,,#,c#",
            "#,##,#,#####,#,,#",
            "#,#,,,,#,,,#,#,##",
            "#,#,####,#,#,,,,#",
            "#,,,,,,,,#,###,,#",
            "####,###,#,,,#,##",
            "#c,,,#,,,###,#,,#",
            "#,##,#,#,,,,,,,,#",
            "#,#D,,,#,#####,,#",
            "#,######,#,,,#,##",
            "#,,,,,,,,,,U,,,,#",
            "#################"
        ],
        warps: [
            Point(x: 11, y: 11): Warp(to: .aomoriField, at: Point(x: 27, y: 21)),
            Point(x: 3, y: 9): Warp(to: .hakkoda2, at: Point(x: 8, y: 9)),
        ],
        chestRewards: [.item(.hitomebore), .gold(120)],
        enemies: Balance.places[3].enemies, quizTown: .aomori
    )

    static let hakkoda2 = cave(
        .hakkoda2, name: "八甲田山 B2", region: .aomori,
        rows: [
            "###############",
            "#####,,B,,#####",
            "####,,,,,,,####",
            "####,,,,,,,####",
            "#,,,##,,,##,,,#",
            "#,#,,,,#,,,,#,#",
            "#,#,##,#,##,#c#",
            "#,,,#,,,,,#,,,#",
            "###,#,###,#,###",
            "#,,,,,#U,,,,,,#",
            "###############"
        ],
        warps: [Point(x: 7, y: 9): Warp(to: .hakkoda1, at: Point(x: 4, y: 9))],
        chestRewards: [.item(.hanabi)],
        bossKind: .yukioni, enemies: Balance.places[3].enemies, quizTown: .aomori
    )

    /// 恐山（クリア後）。宇曽利山湖の ほとり。下の階へは 6県の 検定に 合格してから。
    static let osorezan1 = cave(
        .osorezan1, name: "恐山 B1", label: "恐山", region: .aomori,
        rows: [
            "###################",
            "#,,,,~~~~~~~~~,,,,#",
            "#,##,~~~~~~~~~,##,#",
            "#,#,,,,~~~~~,,,,#,#",
            "#,#,##,,,,,,,##,#,#",
            "#,,,#,,,###,,,#,,,#",
            "###,#,#,,c,,#,#,###",
            "#D,,,,#,,,,,#,,,,,#",
            "#,###,###,###,###,#",
            "#,,,,,,,,,U,,,,,,,#",
            "###################"
        ],
        warps: [
            Point(x: 10, y: 9): Warp(to: .aomoriField, at: Point(x: 44, y: 7)),
            Point(x: 1, y: 7): Warp(to: .osorezan2, at: Point(x: 8, y: 8), needs: .allExams),
        ],
        chestRewards: [.item(.matsuriArmor)],
        enemies: Balance.places[24].enemies, quizTown: .aomori
    )

    static let osorezan2 = cave(
        .osorezan2, name: "恐山 B2", region: .aomori,
        rows: [
            "#############",
            "#,,,,,B,,,,,#",
            "#,~~,,,,,~~,#",
            "#,~~,,,,,~~,#",
            "##,,,#,#,,,##",
            "#c,#,#,#,#,c#",
            "#,,#,,,,,#,,#",
            "#,###,#,###,#",
            "#,,,,,#U,,,,#",
            "#############"
        ],
        warps: [Point(x: 7, y: 8): Warp(to: .osorezan1, at: Point(x: 2, y: 7))],
        chestRewards: [.item(.shakudama), .item(.imoni)],
        bossKind: .maouShadow, enemies: Balance.places[24].enemies, quizTown: .aomori
    )

    // MARK: 家の中

    static let nebutaHouse = house(
        .nebutaHouse, name: "ねぶたの家",
        rows: [
            "XXXXXXXXX",
            "XLL1oLLcX",
            "XoooooooX",
            "XtooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .aomori, region: .aomori, door: Point(x: 4, y: 6),
        villagers: [["はねと「ねぶたの はねとは ゆかたに 花笠を かぶって おどるんだ。",
                     "　すずを ならして ラッセラー！」"]],
        residents: ["1": .nebutashi], chestRewards: [.gold(30)]
    )

    static let aomoriHouse = house(
        .aomoriHouse, name: "みんか",
        rows: [
            "XXXXXXXXX",
            "XcLLoLLLX",
            "XoooooooX",
            "XooootooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .aomori, region: .aomori, door: Point(x: 21, y: 6),
        villagers: [["おじさん「青森は 冬に 雪が たくさん ふる まちなんだ。",
                     "　屋根の 雪おろしが たいへんでねえ。」"]],
        chestRewards: [.item(.apple)]
    )

    static let hirosakiCastle = house(
        .hirosakiCastle, name: "弘前城 天守",
        rows: [
            "XXXXXXXXX",
            "XLLLtLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .hirosaki, region: .aomori, door: Point(x: 13, y: 4),
        villagers: [["さむらい「弘前藩は 津軽家が おさめた 藩じゃ。",
                     "　この 天守は 江戸時代から のこっておる。」"]],
        chestRewards: [.gold(50)]
    )

    static let ringoHouse = house(
        .ringoHouse, name: "りんご農家",
        rows: [
            "XXXXXXXXX",
            "XLLoooLcX",
            "XoooooooX",
            "XotoooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .hirosaki, region: .aomori, door: Point(x: 3, y: 9),
        villagers: [["おばあさん「りんごの しゅるいは たくさん ある。",
                     "　『ふじ』も 青森で うまれたんじゃよ。」"]],
        chestRewards: [.item(.apple)]
    )

    static let matagiHouse = house(
        .matagiHouse, name: "マタギの 小屋",
        rows: [
            "XXXXXXXXX",
            "XLLo1oLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .hirosaki, region: .aomori, door: Point(x: 23, y: 9),
        villagers: [],
        residents: ["1": .matagi], chestRewards: [.gold(40)]
    )

    static let hachinoheHouse = house(
        .hachinoheHouse, name: "りょうしの 家",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLcX",
            "XoooooooX",
            "XoootoooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .hachinohe, region: .aomori, door: Point(x: 4, y: 3),
        villagers: [["りょうしの つま「イカは 夜に あかりで あつめて つるんだよ。",
                     "　沖に イカつり船の あかりが ならぶの。」"]],
        chestRewards: [.item(.senbeiJiru)]
    )
}
