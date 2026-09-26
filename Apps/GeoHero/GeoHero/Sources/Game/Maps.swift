import Foundation

/// ゲームの全マップ。
/// 地方ごとに フィールドが1枚ある。函館エリア（函館・松前・大沼、函館山・駒ヶ岳）から はじまり、
/// 駒ヶ岳のぬしを倒して もらう きっぷで 札幌・小樽へ、ヒグマのぬしを倒して もらう きっぷで 知床へ とぶ。
/// ワープの到着点はワープ床の隣に置く（到着した瞬間にまた飛ばないように）。
enum World {
    static let startMap: MapID = .hakodate
    /// 長老の すぐ下。
    static let startPoint = Point(x: 18, y: 18)

    static func map(_ id: MapID) -> GameMap {
        switch id {
        case .hakodateArea: hakodateArea
        case .sapporoArea: sapporoArea
        case .shiretokoArea: shiretokoArea
        case .hakodate: hakodate
        case .matsumae: matsumae
        case .onuma: onuma
        case .sapporo: sapporo
        case .otaru: otaru
        case .rausu: rausu
        case .hakodateyama: hakodateyama
        case .komagatake: komagatake
        case .moiwa1: moiwa1
        case .moiwa2: moiwa2
        case .rausudake1: rausudake1
        case .rausudake2: rausudake2
        case .innInside: innInside
        case .shopInside: shopInside
        case .bugyosho: bugyosho
        case .asaichiSouko: asaichiSouko
        case .motomachiHouse: motomachiHouse
        case .bukeyashiki: bukeyashiki
        case .tsukemonoya: tsukemonoya
        case .ryoshiHouse: ryoshiHouse
        case .noukaHouse: noukaHouse
        case .dangoya: dangoya
        case .yamagoya: yamagoya
        case .glassKobo: glassKobo
        case .tokeidaiHouse: tokeidaiHouse
        case .sapporoHouse: sapporoHouse
        }
    }

    /// 全滅したときに戻る場所。いちばん近い街ではなく、その地方の はじめの街の入口にそろえる。
    static let revivePoint = (map: MapID.hakodate, point: Point(x: 15, y: 24))

    static func revivePoint(in region: Region) -> (map: MapID, point: Point) {
        switch region {
        case .hakodate: revivePoint
        case .sapporo: (.sapporo, Point(x: 7, y: 11))
        case .shiretoko: (.rausu, Point(x: 7, y: 11))
        }
    }

    /// 名所の スタンプを押せる 看板（函館エリアの 街の 名所の看板 ぜんぶ）。
    static let stampPlaques: [PlaqueID] = [MapID.hakodate, .matsumae, .onuma].flatMap { id in
        map(id).plaques.keys.map { PlaqueID(map: id, point: $0) }
    }
    static var stampTotal: Int { stampPlaques.count }

    /// 函館。3つの地区に分かれていて、歩きまわって 話を聞くと 函館山への道がひらける。
    /// - 北西: 港と朝市（西は函館湾）。赤レンガ倉庫・摩周丸の看板、港の親方、迷子をさがす母。
    /// - 北東: 五稜郭（星のかたちの堀）。橋をわたった奥に 奉行がいる。
    /// - 南西: 元町（函館山のふもと）。坂の看板と教会、迷子の子。
    /// 親方の話 → 奉行の てがた → 函館山、の順（`Story.swift`）。
    static let hakodate = GameMap(
        id: .hakodate,
        name: "はこだて",
        rows: [
            "###############################",
            "#~~_____________________~_____#",
            "#~~HHH_HHH______t______~_~____#",
            "#~~WdW_WWW_________~~~~___~~~~#",
            "#~~___P____26_______~_______~_#",
            "#~~__________________~_HHH_~__#",
            "#~~___t______________~_WdW_~__#",
            "#~~___________ff_____~1____~__#",
            "#~~___________ff____~__~b~__~_#",
            "#~~________________~~~~_b_~~~~#",
            "#~~_3_________________P_______#",
            "#~~_HHHHHHHH____t__________f__#",
            "#~~_WWWWWWWWP______________f__#",
            "#~~_____c__________________f__#",
            "#~~P_________III___SSS________#",
            "#~~__________III___SSS________#",
            "#~~__________YdW___ZdW________#",
            "#~~_______________e___________#",
            "#~~~__t_____________4_________#",
            "#~~~~_____________________t___#",
            "#MMM______HHH_________________#",
            "#MMMM_____WdW__P__t___________#",
            "#MMMMM_c_5__________ff________#",
            "#MMMMMM_____________ff________#",
            "#MMMMMMM_____P____7___________#",
            "##############EEE##############"
        ],
        // 壁の外は草原。出口のすきまの先に野原が見えて、外へ抜ける道だと分かる。
        outside: .grass,
        warps: [
            // 家の扉。
            Point(x: 24, y: 6): Warp(to: .bugyosho, at: Point(x: 4, y: 4)),
            Point(x: 4, y: 3): Warp(to: .asaichiSouko, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 21): Warp(to: .motomachiHouse, at: Point(x: 4, y: 4)),
            // 左の家（青い屋根・ベッドの看板）が宿屋、右の家（緑の屋根・お金のふくろ）が道具屋。
            Point(x: 14, y: 16): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 20, y: 16): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 14, y: 25): Warp(to: .hakodateArea, at: Point(x: 46, y: 28)),
            Point(x: 15, y: 25): Warp(to: .hakodateArea, at: Point(x: 46, y: 28)),
            Point(x: 16, y: 25): Warp(to: .hakodateArea, at: Point(x: 46, y: 28)),
        ],
        // 戦闘の「ちしき」の答えは ここで聞ける（`QuizRegion.hakodate` と `QuizTests` を見る）。
        // 人・看板・親方たちの せりふを あわせて、6つの問題の答えが ぜんぶ そろう。
        villagers: [
            ["おばさん「朝市は 朝 はやくから にぎやかだよ。",
             "　カニに ホタテに ウニ。 でも イカだけが",
             "　さっぱり とれなくなっちまってねえ。」"],
            ["ふなのり「この みなとは 津軽海峡に めんしてる。",
             "　むかしは 青函連絡船で 青森へ わたったもんさ。」"],
            ["おとこ「ここは 渡島半島の さきの みなとまち。",
             "　北の 五稜郭には 奉行所が あるぞ。」"],
            ["むすめ「函館山の ほらあなに イカのぬしが すみついたの。",
             "　山から 見る やけいが じまんだったのに……」"],
            ["たびびと「函館山には ロープウェイで のぼれるんだ。",
             "　でも いまは 奉行所が 山を とじてしまってね。」"],
            ["しんぷ「元町には 異国の 教会が ならんでいます。",
             "　むかし 外国の 船が 来た みなとだからですよ。」"],
        ],
        residents: ["1": .magistrate, "2": .mother, "3": .fisherBoss, "4": .portKid, "5": .lostChild, "6": .childAtHome,
                    "7": .guide],
        plaques: [
            Point(x: 6, y: 4): Plaque(title: "朝市", lines: [
                "かんばんに こう かいてある。",
                "「函館朝市」",
                "イカ・カニ・ホタテが ならぶ 朝の 市場。",
            ]),
            Point(x: 22, y: 10): Plaque(title: "五稜郭", lines: [
                "かんばんに こう かいてある。",
                "「特別史跡 五稜郭」",
                "星のかたちを した 西洋式の 城あと。",
                "いまは 奉行所が おかれている。",
            ]),
            Point(x: 12, y: 12): Plaque(title: "倉庫", lines: [
                "かんばんに こう かいてある。",
                "「金森赤レンガ倉庫」",
                "みなとに ならぶ 明治の 倉庫。",
                "船の 荷を しまっていた。",
            ]),
            Point(x: 3, y: 14): Plaque(title: "摩周丸", lines: [
                "かんばんに こう かいてある。",
                "「青函連絡船 記念館 摩周丸」",
                "函館と 青森を むすんでいた 船。",
            ]),
            Point(x: 15, y: 21): Plaque(title: "八幡坂", lines: [
                "かんばんに こう かいてある。",
                "「八幡坂」",
                "坂の 上から みなとと 海が まっすぐ 見える。",
            ]),
        ],
        chestRewards: [.item(.herb), .gold(40)]
    )

    /// 松前。北海道の いちばん南の 町。
    /// - 北: 石垣で かこんだ 松前城。本丸に 殿様がいて、火よけの おふだを さずける。
    /// - まんなか: 宿屋・道具屋・長老。城のまわりに さくら。
    /// - 南: 津軽海峡の みなと。北前船と 白神岬の 看板。
    static let matsumae = GameMap(
        id: .matsumae,
        name: "まつまえ",
        rows: [
            "###########################",
            "#_kk____#########______kk_#",
            "#_k_____#__HHH__#________k#",
            "#k______#__HHH__#____t___k#",
            "#_______#__WWW__#_________#",
            "#__P____#___1___#__HHH____#",
            "#_______#_P___c_#__WdW____#",
            "#___t___####_####_________#",
            "#_______________________k_#",
            "#kk____P_______________kkk#",
            "#kk__________e___________k#",
            "#___III___SSS_____HHH_____#",
            "#___III___SSS_____WdW__t__#",
            "#___YdW___ZdW_____________#",
            "#______________t__________#",
            "#~~~~~_____________k___k__#",
            "#~~~~~~__t____P___kkk_kkk_#",
            "#~~~~~~~___________k___k__#",
            "#~~~~~~~~_______HHH___t___#",
            "#~~~~~~~~~______WdW_____P_#",
            "#~~~~~~~~~~_________P_____#",
            "############EEE############"
        ],
        outside: .grass,
        warps: [
            // 家の扉。
            Point(x: 20, y: 6): Warp(to: .bukeyashiki, at: Point(x: 4, y: 4)),
            Point(x: 19, y: 12): Warp(to: .tsukemonoya, at: Point(x: 4, y: 4)),
            Point(x: 17, y: 19): Warp(to: .ryoshiHouse, at: Point(x: 4, y: 4)),
            Point(x: 5, y: 13): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 13): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 12, y: 21): Warp(to: .hakodateArea, at: Point(x: 13, y: 35)),
            Point(x: 13, y: 21): Warp(to: .hakodateArea, at: Point(x: 13, y: 35)),
            Point(x: 14, y: 21): Warp(to: .hakodateArea, at: Point(x: 13, y: 35)),
        ],
        // 戦闘の「ちしき」の答えは ここで聞ける（`QuizRegion.matsumae` と `QuizTests` を見る）。
        villagers: [
            ["さむらい「松前城は 江戸時代の おわりに たてられた。",
             "　北海道で ただ ひとつの 日本式の 城だ。」"],
            ["むすめ「松前は さくらの 名所なの。",
             "　春には 250しゅるいもの さくらが さくのよ。」"],
            ["おばあさん「松前漬けは スルメと こんぶを",
             "　しょうゆで つけた ものさ。 松前の 名物だよ。」"],
            ["たびびと「ここは 北海道の いちばん 南の 町。",
             "　白神岬からは 海の むこうに 本州が 見えるよ。」"],
            ["りょうし「むかしは 北前船が 日本海を 行き来して、",
             "　米や 着物を はこんできたんだ。」"],
            ["こども「とのさまは 松前藩の 話を たくさん してくれるよ。",
             "　でも つよい ひとにしか あって くれないんだ。」"],
        ],
        residents: ["1": .lord],
        plaques: [
            Point(x: 10, y: 6): Plaque(title: "松前城", lines: [
                "かんばんに こう かいてある。",
                "「松前城」",
                "北海道で ただ ひとつの 日本式の 城。",
                "松前藩の 殿様が おさめていた。",
            ]),
            Point(x: 3, y: 5): Plaque(title: "桜", lines: [
                "かんばんに こう かいてある。",
                "「血脈桜」",
                "松前の さくらの なかでも いちばんの 古木。",
                "春には 町じゅうが さくら色に なる。",
            ]),
            Point(x: 7, y: 9): Plaque(title: "藩邸", lines: [
                "かんばんに こう かいてある。",
                "「松前藩屋敷」",
                "江戸時代の 松前の 町なみを のこす やしき。",
            ]),
            Point(x: 14, y: 16): Plaque(title: "北前船", lines: [
                "かんばんに こう かいてある。",
                "「北前船の みなと」",
                "日本海を 行き来した 船が 荷を おろした みなと。",
            ]),
            Point(x: 24, y: 19): Plaque(title: "白神岬", lines: [
                "かんばんに こう かいてある。",
                "「白神岬」",
                "北海道の いちばん 南の みさき。",
                "津軽海峡の むこうに 本州が 見える。",
            ]),
        ],
        chestRewards: [.gold(90)]
    )

    /// 大沼。駒ヶ岳の ふもとの 湖の 町。
    /// - 北: 駒ヶ岳の すそと 山守。山守が 駒ヶ岳の ようすを 教える。
    /// - まんなか: 大沼。126の 島を はしで わたれる。いちばん奥の島に 白鳥の ひなが まいごに なっている。
    /// - 西: 七飯の りんご畑。 南: 宿屋・道具屋・だんご屋。
    static let onuma = GameMap(
        id: .onuma,
        name: "おおぬま",
        rows: [
            "###########################",
            "#MMMMMMMMMMMMMMMMMMMMMMMMM#",
            "#MMMMM_____MMMMMM_____MMMM#",
            "#____P___3________________#",
            "#_________~~~~~~~~~~~~~~~_#",
            "#___HHH___~~~~c~~~~~~~~~~_#",
            "#___WdW___~~~__~~~~~_~_f~_#",
            "#_______5_~~~~b~~~~__b_4~_#",
            "#__t____6_~_f~_~~~_b~~~~~_#",
            "#fff______b__b__bb__~~~~~_#",
            "#fff______~~_~~_~~f_~~~~~_#",
            "#fff______~~~~~~~~~b~~~~~_#",
            "#fff______~~~~~~~~~_P~~~~_#",
            "#_P_______~~~~~~~~~~~~~~~_#",
            "#_____e_____________t_____#",
            "#__III___SSS__t__HHH______#",
            "#__III___SSS_____WdW______#",
            "#__YdW___ZdW_________P____#",
            "#_____t____________HHH____#",
            "#__________________WdW_t__#",
            "#_______________P_________#",
            "############EEE############"
        ],
        outside: .grass,
        warps: [
            // 家の扉。
            Point(x: 5, y: 6): Warp(to: .noukaHouse, at: Point(x: 4, y: 4)),
            Point(x: 18, y: 16): Warp(to: .dangoya, at: Point(x: 4, y: 4)),
            Point(x: 20, y: 19): Warp(to: .yamagoya, at: Point(x: 4, y: 4)),
            Point(x: 4, y: 17): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 10, y: 17): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 12, y: 21): Warp(to: .hakodateArea, at: Point(x: 30, y: 18)),
            Point(x: 13, y: 21): Warp(to: .hakodateArea, at: Point(x: 30, y: 18)),
            Point(x: 14, y: 21): Warp(to: .hakodateArea, at: Point(x: 30, y: 18)),
        ],
        // 戦闘の「ちしき」の答えは ここで聞ける（`QuizRegion.onuma` と `QuizTests` を見る）。
        villagers: [
            ["のうか「この あたりは 七飯。 日本で はじめて",
             "　西洋りんごを そだてた 町なんだ。」"],
            ["ボートや「大沼には 126もの 島が うかんでる。",
             "　島どうしは はしで わたれるよ。」"],
            ["むすめ「大沼だんごは しょうゆと ごまと あんこ。",
             "　おみやげに どうぞ。」"],
            ["おとこ「冬の 大沼には ハクチョウが わたってくる。",
             "　氷の うえで ワカサギつりも できるぞ。」"],
            ["たびびと「駒ヶ岳が けむりを ふいて ひこうきが とばないんだ。",
             "　函館空港で まちぼうけさ。」"],
        ],
        residents: ["3": .ranger, "4": .lostCygnet, "5": .swanKeeper, "6": .cygnetHome],
        plaques: [
            Point(x: 5, y: 3): Plaque(title: "駒ヶ岳", lines: [
                "かんばんに こう かいてある。",
                "「北海道駒ヶ岳」",
                "うまの かたちに 見えるので 駒ヶ岳と いう 火山。",
            ]),
            Point(x: 20, y: 12): Plaque(title: "大沼", lines: [
                "かんばんに こう かいてある。",
                "「大沼国定公園」",
                "大小 126の 島が うかぶ 湖。",
                "島と 島は はしで つながっている。",
            ]),
            Point(x: 2, y: 13): Plaque(title: "りんご", lines: [
                "かんばんに こう かいてある。",
                "「西洋りんご 発祥の地 七飯」",
                "日本で はじめて 西洋りんごが そだてられた。",
            ]),
            Point(x: 21, y: 17): Plaque(title: "だんご", lines: [
                "かんばんに こう かいてある。",
                "「名物 大沼だんご」",
                "小さな だんごを はこに ぎっしり つめた おかし。",
            ]),
        ],
        chestRewards: [.gold(150)]
    )

    static let sapporo = GameMap(
        id: .sapporo,
        name: "さっぽろ",
        rows: [
            "###############",
            "#_____________#",
            "#_III_____SSS_#",
            "#_III_____SSS_#",
            "#_YdW_____ZdW_#",
            "#_____________#",
            "#__t__www__t__#",
            "#HH___www___HH#",
            "#dW_______e_Wd#",
            "#_t_________t_#",
            "#___t______t__#",
            "#____P________#",
            "######EEE######"
        ],
        // 壁の外は草原。出口のすきまの先に野原が見えて、外へ抜ける道だと分かる。
        outside: .grass,
        warps: [
            // 家の扉。
            Point(x: 1, y: 8): Warp(to: .tokeidaiHouse, at: Point(x: 4, y: 4)),
            Point(x: 13, y: 8): Warp(to: .sapporoHouse, at: Point(x: 4, y: 4)),
            // 左の家（青い屋根・ベッドの看板）が宿屋、右の家（緑の屋根・お金のふくろ）が道具屋。
            Point(x: 3, y: 4): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 4): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 6, y: 12): Warp(to: .sapporoArea, at: Point(x: 27, y: 18)),
            Point(x: 7, y: 12): Warp(to: .sapporoArea, at: Point(x: 27, y: 18)),
            Point(x: 8, y: 12): Warp(to: .sapporoArea, at: Point(x: 27, y: 18)),
        ],
        // 戦闘の「ちしき」の答えは ここで聞ける（`QuizRegion.sapporo` と `QuizTests` を見る）。
        villagers: [
            ["むすめ「ここは いちばん 大きな街。",
             "　冬の 雪まつりには ひとで いっぱいよ。」"],
            ["しょうにん「はがねの剣は この街でしか 買えないよ。",
             "　帰りに 名物の みそラーメンも 食べていきな。」"],
            ["ろうじん「むかし クラーク博士が いうたものじゃ。",
             "　『少年よ 大志を いだけ』とな。",
             "　藻岩山の ぬしにも おそれず いどむのじゃ。」"],
            ["おとこ「北の 藻岩山に ヒグマのぬしが すんでいるらしい。",
             "　あの山から 見る 札幌の 夜景は きれいなのにな。」"],
            ["こども「ひろばの ふん水、つめたくて きもちいいよ。",
             "　大通公園の ふん水は もっと 大きいんだって！」"],
            ["たびびと「白い 時計台の かねの音を きいたかい？",
             "　札幌の まちの しるしだよ。」"]
        ]
    )

    /// 小樽。札幌の 西の みなと町。運河と 石の倉庫、ガラス工房。
    static let otaru = GameMap(
        id: .otaru,
        name: "おたる",
        rows: [
            "#####################",
            "#~~~~~~~~~~~~~~~~~~~#",
            "#~~~~~~~~~~~~~~~~~~~#",
            "#__HHHH__~~_HHHH_t__#",
            "#__WWWW_P~~_WWWW____#",
            "#________bb_________#",
            "#___t____~~_________#",
            "#_____HHH~~____t____#",
            "#_____WdWbb_________#",
            "#_III_P__~~__SSS____#",
            "#_III_____e__SSS____#",
            "#_YdW________ZdW____#",
            "#_____t_____________#",
            "#____________P______#",
            "#########EEE#########"
        ],
        outside: .grass,
        warps: [
            // 家の扉。
            Point(x: 7, y: 8): Warp(to: .glassKobo, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 11): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 14, y: 11): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 9, y: 14): Warp(to: .sapporoArea, at: Point(x: 9, y: 16)),
            Point(x: 10, y: 14): Warp(to: .sapporoArea, at: Point(x: 9, y: 16)),
            Point(x: 11, y: 14): Warp(to: .sapporoArea, at: Point(x: 9, y: 16)),
        ],
        // 小樽の問題は 札幌の山に まぜてある（`QuizRegion.sapporo`）。
        villagers: [
            ["ふなのり「小樽は 石狩湾に めんした みなと町。",
             "　むかしは ニシンりょうで にぎわったんだ。」"],
            ["むすめ「運河ぞいの 石の 倉庫は むかしの みなとの なごり。",
             "　夜は ガスとうが ともって きれいよ。」"],
            ["しょくにん「小樽の ガラスは ニシンりょうの",
             "　うきだまを つくっていたのが はじまりさ。」"],
            ["たびびと「札幌から 小樽までは 海ぞいの 道で すぐだよ。",
             "　オルゴールの 店も あるんだ。」"],
        ],
        plaques: [
            Point(x: 8, y: 4): Plaque(title: "運河", lines: [
                "かんばんに こう かいてある。",
                "「小樽運河」",
                "船の 荷を 倉庫へ はこんだ 水の みち。",
            ]),
            Point(x: 6, y: 9): Plaque(title: "ガラス", lines: [
                "かんばんに こう かいてある。",
                "「ガラス工房」",
                "小樽の 名物の ガラスを つくる 店。",
            ]),
        ]
    )

    static let rausu = GameMap(
        id: .rausu,
        name: "らうす",
        rows: [
            "###############",
            "#MM_________MM#",
            "#_III_____SSS_#",
            "#_III_____SSS_#",
            "#_YdW_____ZdW_#",
            "#_____________#",
            "#MM_________MM#",
            "#MM____t____MM#",
            "#M_____e_____M#",
            "#M_t_______t_M#",
            "#MM_________MM#",
            "#MMM_P_____MMM#",
            "######EEE######"
        ],
        outside: .grass,
        warps: [
            // 左の家（青い屋根・ベッドの看板）が宿屋、右の家（緑の屋根・お金のふくろ）が道具屋。
            Point(x: 3, y: 4): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 4): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 6, y: 12): Warp(to: .shiretokoArea, at: Point(x: 18, y: 22)),
            Point(x: 7, y: 12): Warp(to: .shiretokoArea, at: Point(x: 18, y: 22)),
            Point(x: 8, y: 12): Warp(to: .shiretokoArea, at: Point(x: 18, y: 22)),
        ],
        // 戦闘の「ちしき」の答えは ここで聞ける（`QuizRegion.rausu` と `QuizTests` を見る）。
        villagers: [
            ["むすめ「ここは さいはての町。やども 品も 高いけど ゆるしてね。",
             "　知床は アイヌの ことばで 『ちの はて』って いみなの。」"],
            ["りょうし「羅臼の じまんは こんぶと シャチさ。",
             "　冬には りゅうひょうが 岸まで ながれつくぞ。」"],
            ["たびびと「知床は 世界自然遺産に えらばれた 土地。",
             "　北がわには オホーツク海が ひろがっている。」"]
        ]
    )

    static let hakodateyama = GameMap(
        id: .hakodateyama,
        name: "函館山の ほらあな",
        // 入口は下。細い通路をぬけた いちばん奥の広間に イカのぬしがいる。
        rows: [
            "###############",
            "#####,,,,,#####",
            "#####,,B,,#####",
            "#####,,,,,#####",
            "#######,#######",
            "#,,,,,,,,,,,,,#",
            "#,####,#,####,#",
            "#,,,,#,,,#,,,,#",
            "##,#,#,#,#,#,##",
            "#c,#,,,#,,,#,,#",
            "#,,#######,,,,#",
            "#,,,,,,U,,,,,,#",
            "###############"
        ],
        outside: .wall,
        warps: [
            Point(x: 7, y: 11): Warp(to: .hakodateArea, at: Point(x: 38, y: 34)),
        ],
        chestRewards: [.gold(120)],
        bossKind: .squidLord,
        encounters: [
            .caveFloor: [.nightBat, .hairyCrab, .brickGolem],
        ],
        markerFloor: .caveFloor
    )

    /// 駒ヶ岳の ほらあな。火よけの おふだが ないと 入れない。いちばん奥に 駒ヶ岳のぬしがいる。
    static let komagatake = GameMap(
        id: .komagatake,
        name: "駒ヶ岳の ほらあな",
        rows: [
            "###################",
            "#######,,,,,#######",
            "#######,,B,,#######",
            "#######,,,,,#######",
            "#########,#########",
            "#c,,,,#,,,,,,,#,,c#",
            "#,###,#,#####,#,#,#",
            "#,#,,,,,#,,,#,,,#,#",
            "#,#,###,#,#,#####,#",
            "#,,,#,,,,,#,,,,,,,#",
            "###,#,#######,###,#",
            "#,,,#,,,,#,,,,#,,,#",
            "#,#####,####,##,#,#",
            "#,,,,,,,,U,,,,,,#,#",
            "###################"
        ],
        outside: .wall,
        warps: [
            Point(x: 9, y: 13): Warp(to: .hakodateArea, at: Point(x: 40, y: 11)),
        ],
        chestRewards: [.gold(250), .item(.herb)],
        bossKind: .komaLord,
        encounters: [
            .caveFloor: [.lavaSlime, .pumiceGolem, .sulfurSmoke],
        ],
        markerFloor: .caveFloor
    )

    static let moiwa1 = GameMap(
        id: .moiwa1,
        name: "藻岩山の ほらあな B1",
        rows: [
            "###############",
            "#,,,,#,,,,,,,,#",
            "#,##,#,#####,,#",
            "#,#,,,,#c,,#,,#",
            "#,#,####,#,#,##",
            "#,,,,,,,,#,,,,#",
            "####,###,####,#",
            "#,,,,#,,,,,,#,#",
            "#,##,#,####,#,#",
            "#,#D,,,#,,,,,,#",
            "#,######,####,#",
            "#,,,,,,U,,,,,,#",
            "###############"
        ],
        outside: .wall,
        warps: [
            Point(x: 7, y: 11): Warp(to: .sapporoArea, at: Point(x: 17, y: 26)),
            Point(x: 3, y: 9): Warp(to: .moiwa2, at: Point(x: 6, y: 9)),
        ],
        chestRewards: [.item(.copperSword)],
        encounters: [
            .caveFloor: [.flyingSquirrel, .maitake, .salamander],
        ],
        markerFloor: .caveFloor
    )

    static let moiwa2 = GameMap(
        id: .moiwa2,
        name: "藻岩山の ほらあな B2",
        rows: [
            "#############",
            "#,,,,,B,,,,,#",
            "#,,,,,,,,,,,#",
            "####,,,,,####",
            "#,,#,###,#,,#",
            "#,,,,#c#,,,,#",
            "#,##,#,#,##,#",
            "#,#,,,,,,,#,#",
            "#,#,###,#,#,#",
            "#,,,#U,,#,,,#",
            "#############"
        ],
        outside: .wall,
        warps: [
            Point(x: 5, y: 9): Warp(to: .moiwa1, at: Point(x: 4, y: 9)),
        ],
        chestRewards: [.gold(300)],
        bossKind: .bearLord,
        encounters: [
            .caveFloor: [.bearCub, .fishOwl, .woodpecker],
        ],
        markerFloor: .caveFloor
    )

    static let rausudake1 = GameMap(
        id: .rausudake1,
        name: "羅臼岳の ほらあな B1",
        rows: [
            "###############",
            "#,,,,#,,,,,,,,#",
            "#,##,#,#####,,#",
            "#,#,,,,#c,,#,,#",
            "#,#,####,#,#,##",
            "#,,,,,,,,#,,,,#",
            "####,###,####,#",
            "#,,,,#,,,,,,#,#",
            "#,##,#,####,#,#",
            "#,#D,,,#,,,,,,#",
            "#,######,####,#",
            "#,,,,,,U,,,,,,#",
            "###############"
        ],
        outside: .wall,
        warps: [
            Point(x: 7, y: 11): Warp(to: .shiretokoArea, at: Point(x: 21, y: 8)),
            Point(x: 3, y: 9): Warp(to: .rausudake2, at: Point(x: 6, y: 9)),
        ],
        chestRewards: [.item(.steelSword)],
        encounters: [
            .caveFloor: [.hikarigoke, .icicleOgre, .iceBat],
        ],
        markerFloor: .caveFloor
    )

    static let rausudake2 = GameMap(
        id: .rausudake2,
        name: "羅臼岳の ほらあな B2",
        rows: [
            "#############",
            "#,,,,,B,,,,,#",
            "#,,,,,,,,,,,#",
            "####,,,,,####",
            "#,,#,###,#,,#",
            "#,,,,#c#,,,,#",
            "#,##,#,#,##,#",
            "#,#,,,,,,,#,#",
            "#,#,###,#,#,#",
            "#,,,#U,,#,,,#",
            "#############"
        ],
        outside: .wall,
        warps: [
            Point(x: 5, y: 9): Warp(to: .rausudake1, at: Point(x: 4, y: 9)),
        ],
        chestRewards: [.item(.chainMail)],
        bossKind: .guardian,
        encounters: [
            .caveFloor: [.phantomWolf, .iceGolem, .blizzardSpirit],
        ],
        markerFloor: .caveFloor
    )

    /// 函館エリア（道南）。65×40 マス。
    /// 南東の 函館（函館山は 砂州で つながった 島）、西の 松前半島の さきに 松前、北の 大沼と 駒ヶ岳。
    /// 函館の 東に 函館空港。駒ヶ岳のぬしを倒して きっぷを もらうと 札幌へ とべる。
    static let hakodateArea = GameMap(
        id: .hakodateArea,
        name: "函館エリア",
        rows: [
            "~~~~~~~~~~~~MMMMMMMMMMMMMMMMMMMMMMMMMMMM~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~MMMMMMMMMMMMMMMMMMMMMMMMMMMMM~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~cMMMMMMMMM.........hhhhhhhhh..~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~ffffffff......................~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~fffffffff.................hhhhh~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~fffffffffhhhhhh...........hMMMMMM~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~fffffffffhhMMMh...........hMMMMMM~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~fffffffffhhMMMh...........hMMMMMM~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~fffffffffhhMMMh...........hMMMMMMh~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~.fffffffffhhhhhh...........hMMMMMMh~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~.fffffffff...........~~~~..hhhhChhh.~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~.fffffffff..........~~~~~~.....=.....~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~....................~~f~~~.....=......~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~.................~~~~~~~f~fffff=.......~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~.....ffffffff....~~~~~~~~~fffff=.........~~~~~~~~~~~~~~~",
            "~~~~~~~~......ffffffff....~~~......fffff=..........~~~~~~~~~~~~~~",
            "~~~~~~~~......ffffffff............=======..............~~~~~~~~~~",
            "~~~~~~~~......ffffffff........T...=........................~~~~~~",
            "~~~~~~~~......ffffffff........=...=.........................~~~~~",
            "~~~~~~~.......ffffffff........=============.........hhhhhhh..~~~~",
            "~~~~~~~fffff..............................=...ffffffhhhhhhh...~~~",
            "~~~~~~~fffff..............................=...ffffffhhhhhhh...~~~",
            "~~~~~~.fffff..............=================...ffffffhhhhhhh...c~~",
            "~~~~~~.c..................=...~~~.........=...ffffffhhhhhhhMMM.~~",
            "~~~~~~..................===..~~~~~~~......=...ffffff.......MMM.~~",
            "~~~~~~....hhhhhh........=...~~~~~~~~~.....=...ffffff.......MMM.~~",
            "~~~~~~....hMMMMh........=...~~~~~~~~~~....=...................~~~",
            "~~~~~~....hMMMMh........=..~~~~~~~~~~~~...=...T........A......~~~",
            "~~~~~~....hMMMMh........=..~~~~~~~~~~~~~..==============.....~~~~",
            "~~~~~~....hMMMMh........=..~~~~~~~~~~~~~..=.................~~~~~",
            "~~~~~~....hhhhhhfffff...=..~~~~~~~~~~~~b===..............~~~~~~~~",
            "~~~~~~~.........fffff====.~~~~~~~~~~~~.=....c..........~~~~~~~~~~",
            "~~~~~~~.........fffff=....~~~~~~~~~....=..~~........~~~~~~~~~~~~~",
            "~~~~~~~......=========...~~~~~~~~MMMMMC.~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~.....T.........~~~~~~~~~.MMMMM..~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~c...=.......~~~~~~~~~~~.MMMMM..~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~........~~~~~~~~~~~~~~~MMMMM~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ],
        outside: .water,
        warps: [
            Point(x: 46, y: 27): Warp(to: .hakodate, at: Point(x: 15, y: 24)),
            Point(x: 13, y: 34): Warp(to: .matsumae, at: Point(x: 13, y: 20)),
            Point(x: 30, y: 17): Warp(to: .onuma, at: Point(x: 13, y: 20)),
            // 函館山は 奉行の てがた、駒ヶ岳は 松前の殿様の 火よけの おふだで ひらく（`Story.swift`）。
            Point(x: 38, y: 33): Warp(to: .hakodateyama, at: Point(x: 6, y: 11), needs: .hakodateyamaPass),
            Point(x: 40, y: 10): Warp(to: .komagatake, at: Point(x: 8, y: 13), needs: .fireCharm),
            // 函館空港 → 丘珠空港（札幌）。
            Point(x: 55, y: 27): Warp(to: .sapporoArea, at: Point(x: 34, y: 13), needs: .ticketToSapporo),
        ],
        chestRewards: [.gold(200), .gold(120), .item(.herb), .item(.leatherArmor), .gold(60)],
        // 目印ごとの区域。旅の順に ひとつずつ強くなり、出る敵は 場所ごとに ぜんぶ ちがう。
        // 函館 → 函館山 → 松前 → 大沼 の順に たずねる。
        encounterAreas: [
            EncounterArea(name: "函館のまわり", around: [Point(x: 46, y: 28), Point(x: 55, y: 28)],
                          enemies: [.potato, .kelpSlime, .seagull]),
            EncounterArea(name: "函館山のふもと", around: [Point(x: 38, y: 34)],
                          enemies: [.squidKid, .scallop, .squidRice]),
            // 函館湾を ぐるりと まわる 道にも 中心を置く。函館から 松前へ 歩いて 弱くならないように。
            EncounterArea(name: "松前へむかう道", around: [Point(x: 13, y: 35), Point(x: 24, y: 26), Point(x: 30, y: 22)],
                          enemies: [.sakuraSpirit, .matsumaeZuke, .kitamaeShip]),
            EncounterArea(name: "大沼のまわり", around: [Point(x: 30, y: 18), Point(x: 40, y: 11)],
                          enemies: [.apple, .dango, .junsai]),
        ],
        markerFloor: .grass
    )

    /// 札幌・小樽。48×34 マス。北西は 石狩湾、まんなかに 札幌、西の 海ぞいに 小樽、南西に 藻岩山。
    /// 丘珠空港（北東）は 函館と、新千歳空港（南東）は 知床の 中標津と むすぶ。
    static let sapporoArea = GameMap(
        id: .sapporoArea,
        name: "札幌・小樽",
        rows: [
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.........",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...........",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~......c......",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...............",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.................",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...................",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~......................",
            "~~~~~~~~~~~~~~~~~~~~~~~~........................",
            "~~~~~~~~~~~~~~~~~~~~~.........~.............ffff",
            "~~~~~~~~~~~~~~~~~~~...........~.............ffff",
            "~~~~~~~~~~~~~~~~~.............~.............ffff",
            "~~~~~~~~~~~~~~~...............~.............ffff",
            "~~~~~~~~~~~~~.................~...A.........ffff",
            "~~~~~~~~~.....................~...=.........ffff",
            "...c..........................~...=.........ffff",
            "MMMMMMhh.T....................~...=..fffffffffff",
            "MMMMMMhh.========.............~...=..fffffffffff",
            "MMMMMMhh..fffff.=..........T..~...=..fffffffffff",
            "MMMMMMhh..fffff.==============b====..fffffffffff",
            "MMMMMMhh..fffff............=..~...=..fffffffffff",
            "MMMMMMMMMMfffffhhhhhhh.....=..~...=..fffffffffff",
            "MMMMMMMMMMfffffMMMMMMh.....=..~...=..fffffffffff",
            "MMMMMMMMMMfffffMMMMMMh.....=..~...=.........ffff",
            "MMMMMMMMMM...hMMMMMMMh.....=..~...=======...ffff",
            "MMMMMMMMMM...hMMMMMMMh.....=............=...ffff",
            "MMMMMMMMMM...hMMMCMMMh.....=....fffffff.=...ffff",
            "MMMMMMMMMM.......===========....fffffff.=...ffff",
            "MMMMMMMMMMhhhhhhhhhhhhhhhhh.....fffffff.=...ffff",
            "MMMMMMMMMMMMMMMMMMMMMMMhhh~~~~..fffffff.=...ffff",
            "MMMMMMMMMMMMMMMMMMMMMMMhh~~~~~~.........A...ffff",
            "MMMMMMMMMMMMMMMMMMMMMMMhh~~~~~~.........=...ffff",
            "MMMMMMMMMMMMMMMMMMMMMMMhh~~~~~~.............ffff",
            "MMMMMMMMMMMMMMMMMMMMMMMhh~~~~~~.............ffff",
            "MMMMMMMMMMMMMMMMMMMMMMMhhhh.................ffff"
        ],
        outside: .water,
        warps: [
            Point(x: 27, y: 17): Warp(to: .sapporo, at: Point(x: 7, y: 11)),
            Point(x: 9, y: 15): Warp(to: .otaru, at: Point(x: 10, y: 13)),
            Point(x: 17, y: 25): Warp(to: .moiwa1, at: Point(x: 6, y: 11)),
            // 丘珠空港 → 函館空港（もどり）。
            Point(x: 34, y: 12): Warp(to: .hakodateArea, at: Point(x: 55, y: 28), needs: .ticketToSapporo),
            // 新千歳空港 → 中標津空港（知床）。
            Point(x: 40, y: 29): Warp(to: .shiretokoArea, at: Point(x: 6, y: 26), needs: .ticketToShiretoko),
        ],
        chestRewards: [.gold(300), .item(.herb)],
        encounterAreas: [
            EncounterArea(name: "札幌のまわり", around: [Point(x: 34, y: 13), Point(x: 27, y: 18), Point(x: 9, y: 16)],
                          enemies: [.cornSoldier, .ramenGhost, .lambSheep]),
            EncounterArea(name: "藻岩山のふもと", around: [Point(x: 17, y: 26), Point(x: 40, y: 30)],
                          enemies: [.squirrel, .fox, .snowFestival]),
        ],
        markerFloor: .grass
    )

    /// 知床。42×30 マス。南西の 中標津空港から、北東へ のびる 知床半島へ。
    /// 羅臼は 半島の 東がわ（海の むこうに 国後島）、羅臼岳は 半島の 背骨。
    static let shiretokoArea = GameMap(
        id: .shiretokoArea,
        name: "知床",
        rows: [
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.....~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~.....c...~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~........MMM.~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~........MMMMM.~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~.......MMMMMMM~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~.......MMMMMMM.~~~~~~~~~",
            "~~~~~~~~~~~~~~~~.~.....MMMMMMM..~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~...~.CMMMMMM...~~~~~~~~~~~",
            "~~~~~~~~~~~~~......MM=MMMM....~~~~~~~~~~~~",
            "~~~~~~~~~~~~.....MMMM=MM.....~~~~~~~~~~~~~",
            "~~~~~~~~~~.....MMMMMM=......~~~~~~~~~~~~~~",
            "~~~~~~~~~....hhMMMMMh===h..~~~~~~~~~~~~~~~",
            ".............hhMMMhhhhh=h.~~~~~~~~~~~~~~~~",
            ".c...........hhhhhhhhhh=h.~~~~~~~~~~~~~~~~",
            ".......................=.~~~~~~~~~~~~~~~~~",
            "..fffffff.........======.~~~~~~~~~~~~~~~~~",
            "..fffffff.........=.....~~~~~~~~~MMMMMMMM~",
            "..fffffff.........=.....~~~~~~~~~MMMMMMMM~",
            "..fffffff.........=....~~~~~~~~hhhhMMMMMM~",
            "..fffffff.........=...~~~~~~~~~hhhhMMMMMM~",
            "..................=..~~~~~~~~~~hhhhffffff~",
            "..................T.~~~~~~~~~~~hhhhffffff~",
            ".........fff=======~~~~~~~~~~~~hhhh~~~~~~~",
            ".........fff=ff....~~~~~~~~~~~~hhhh~~~~~~~",
            ".........fff=ff...~~~~~~~~~~~~~~~~~~~~~~~~",
            "......A..fff=ff...~~~~~~~~~~~~~~~~~~~~~~~~",
            "......=======ff..~~~~~~~~~~~~~~~~~~~~~~~~~",
            ".................~~~~~~~~~~~~~~~~~~~~~~~~~",
            ".................~~~~~~~~~~~~~~~~~~~~~~~~~",
            "................~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ],
        outside: .water,
        warps: [
            Point(x: 18, y: 21): Warp(to: .rausu, at: Point(x: 7, y: 11)),
            Point(x: 21, y: 7): Warp(to: .rausudake1, at: Point(x: 6, y: 11)),
            // 中標津空港 → 新千歳空港（もどり）。
            Point(x: 6, y: 25): Warp(to: .sapporoArea, at: Point(x: 40, y: 30), needs: .ticketToShiretoko),
        ],
        chestRewards: [.gold(500), .item(.herb)],
        encounterAreas: [
            EncounterArea(name: "知床へむかう道", around: [Point(x: 6, y: 26), Point(x: 18, y: 22)],
                          enemies: [.deer, .cod, .salmon]),
            EncounterArea(name: "羅臼岳へむかう道", around: [Point(x: 21, y: 8)],
                          enemies: [.seaEagle, .snowman, .orca]),
        ],
        markerFloor: .grass
    )

    static let innInside = GameMap(
        id: .innInside,
        name: "やどや",
        rows: [
            "XXXXXXXXX",
            "XQoQoooiX",
            "XoooooKKX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        outside: .darkness,
        warps: [
            // 出口の行き先は 入ってきた街の 扉の前に差し替わる（GameState が見る）。
            Point(x: 4, y: 5): Warp(to: .hakodate, at: Point(x: 3, y: 5)),
        ],
        markerFloor: .woodFloor
    )

    static let shopInside = GameMap(
        id: .shopInside,
        name: "どうぐや",
        rows: [
            "XXXXXXXXX",
            "XLLLsLLLX",
            "XooKKKooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        outside: .darkness,
        warps: [
            Point(x: 4, y: 5): Warp(to: .hakodate, at: Point(x: 11, y: 5)),
        ],
        markerFloor: .woodFloor
    )

    // MARK: - 家の中

    /// 家の中の地図（入れる順に）。
    static let houses: [MapID] = [.bugyosho, .asaichiSouko, .motomachiHouse, .bukeyashiki, .tsukemonoya, .ryoshiHouse, .noukaHouse, .dangoya, .yamagoya, .glassKobo, .tokeidaiHouse, .sapporoHouse]

    /// 家の中を作る。出口は 下の まんなか、入ると その上に立つ。
    /// 出口の行き先は 入った扉の前に差し替わる（GameState が見る）が、地図の上でも 同じ場所を書いておく。
    private static func house(_ id: MapID, name: String, rows: [String], town: MapID, door: Point,
                              villagers: [[String]], chestRewards: [ChestReward]) -> GameMap {
        GameMap(
            id: id, name: name, rows: rows, outside: .darkness,
            warps: [Point(x: 4, y: rows.count - 1): Warp(to: town, at: door + Point(x: 0, y: 1))],
            villagers: villagers, chestRewards: chestRewards, markerFloor: .woodFloor
        )
    }

    /// 五稜郭の 奉行所。奉行は 外の庭に いるので、中は 役人だけ。
    static let bugyosho = house(
        .bugyosho, name: "ぶぎょうしょ",
        rows: [
            "XXXXXXXXX",
            "XLLtoLLcX",
            "XoooooooX",
            "XtooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .hakodate, door: Point(x: 24, y: 6),
        villagers: [
            ["やくにん「奉行さまは 外の 庭で 函館山の ことを",
             "　かんがえて おられる。 あかしが あれば 話を きいてくださるぞ。」"],
            ["やくにん「五稜郭の 堀が 星の かたちなのは、",
             "　どこから 攻められても 大砲で ねらえる ように だそうだ。」"],
        ],
        chestRewards: [.gold(50)]
    )

    /// 朝市の 倉庫。
    static let asaichiSouko = house(
        .asaichiSouko, name: "あさいちの そうこ",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLLX",
            "XoooooooX",
            "XcootoooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .hakodate, door: Point(x: 4, y: 3),
        villagers: [
            ["りょうし「親方なら みなとの 西の はしに いるぞ。",
             "　イカのぬしを 見たって 大さわぎさ。」"],
        ],
        chestRewards: [.item(.herb)]
    )

    /// 元町の 家。
    static let motomachiHouse = house(
        .motomachiHouse, name: "もとまちの いえ",
        rows: [
            "XXXXXXXXX",
            "XQotoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .hakodate, door: Point(x: 11, y: 21),
        villagers: [
            ["おばあさん「さっき 坂の 下で 男の子が ないていたよ。",
             "　朝市の おかあさんの 子かねえ。」"],
        ],
        chestRewards: [.gold(60)]
    )

    /// 松前の 武家屋敷。
    static let bukeyashiki = house(
        .bukeyashiki, name: "ぶけやしき",
        rows: [
            "XXXXXXXXX",
            "XLLtoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .matsumae, door: Point(x: 20, y: 6),
        villagers: [
            ["さむらい「殿様は つよい ものにしか 会われぬ。",
             "　函館山の ぬしを たおしてから 城へ まいれ。」"],
        ],
        chestRewards: [.gold(120)]
    )

    /// 松前漬けの店。
    static let tsukemonoya = house(
        .tsukemonoya, name: "つけものや",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLLX",
            "XoooooooX",
            "XcootoooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .matsumae, door: Point(x: 19, y: 12),
        villagers: [
            ["おばあさん「松前漬けを たべると げんきが でるよ。",
             "　たなの はこに 薬草が あるから もっていきな。」"],
        ],
        chestRewards: [.item(.herb)]
    )

    /// 松前の 漁師の家。
    static let ryoshiHouse = house(
        .ryoshiHouse, name: "りょうしの いえ",
        rows: [
            "XXXXXXXXX",
            "XQotoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .matsumae, door: Point(x: 17, y: 19),
        villagers: [
            ["りょうし「白神岬の かんばんは 町の 南東の はしだ。",
             "　めいしょ スタンプを あつめてるなら わすれずにな。」"],
        ],
        chestRewards: [.gold(80)]
    )

    /// 大沼の 農家（七飯の りんご畑）。
    static let noukaHouse = house(
        .noukaHouse, name: "のうかの いえ",
        rows: [
            "XXXXXXXXX",
            "XQotoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .onuma, door: Point(x: 5, y: 6),
        villagers: [
            ["のうか「ハクチョウの ひななら 湖の いちばん 奥の 島で 見たぞ。",
             "　島は はしで 東へ 北へ つながってる。」"],
        ],
        chestRewards: [.item(.herb)]
    )

    /// 大沼だんごの店。
    static let dangoya = house(
        .dangoya, name: "だんごや",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLLX",
            "XoooooooX",
            "XcootoooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .onuma, door: Point(x: 18, y: 16),
        villagers: [
            ["だんごや「駒ヶ岳の ぬしは ほのおの たてがみで みを まもる。",
             "　大沼の ことを こたえると たてがみが きえるらしいよ。」"],
        ],
        chestRewards: [.gold(100)]
    )

    /// 大沼の 山小屋。
    static let yamagoya = house(
        .yamagoya, name: "やまごや",
        rows: [
            "XXXXXXXXX",
            "XcoQoQocX",
            "XoooooooX",
            "XoooootoX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .onuma, door: Point(x: 20, y: 19),
        villagers: [
            ["やまおとこ「駒ヶ岳の ほらあなは おくが ふかい。",
             "　薬草を たっぷり もっていけ。 はこの ぶんは やるよ。」"],
        ],
        chestRewards: [.item(.herb), .gold(40)]
    )

    /// 小樽の ガラス工房。
    static let glassKobo = house(
        .glassKobo, name: "ガラスこうぼう",
        rows: [
            "XXXXXXXXX",
            "XLLtoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .otaru, door: Point(x: 7, y: 8),
        villagers: [
            ["しょくにん「札幌で 鋼の剣は かったかい？",
             "　藻岩山の おくは てごわいぞ。」"],
        ],
        chestRewards: [.gold(200)]
    )

    /// 札幌の 家。
    static let tokeidaiHouse = house(
        .tokeidaiHouse, name: "とけいだいの いえ",
        rows: [
            "XXXXXXXXX",
            "XQotoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .sapporo, door: Point(x: 1, y: 8),
        villagers: [
            ["おとこ「藻岩山の ヒグマのぬしは 山の かごで みを まもる。",
             "　札幌と 小樽の 話を よく きいておけよ。」"],
        ],
        chestRewards: [.item(.herb)]
    )

    /// 札幌の 家。
    static let sapporoHouse = house(
        .sapporoHouse, name: "さっぽろの いえ",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLLX",
            "XoooooooX",
            "XcootoooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .sapporo, door: Point(x: 13, y: 8),
        villagers: [
            ["むすめ「新千歳空港は 札幌の 南東よ。",
             "　ヒグマのぬしを たおせば 知床へ とべる きっぷが もらえるわ。」"],
        ],
        chestRewards: [.gold(150)]
    )
}
