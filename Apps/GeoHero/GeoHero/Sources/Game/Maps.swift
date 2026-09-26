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
        case .jozankei: jozankei
        case .rausu: rausu
        case .nakashibetsu: nakashibetsu
        case .utoro: utoro
        case .shiretokoMisaki: shiretokoMisaki
        case .hakodateyama: hakodateyama
        case .komagatake: komagatake
        case .tenguyama: tenguyama
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
        case .doucho: doucho
        case .susukinoHouse: susukinoHouse
        case .orgelDo: orgelDo
        case .otaruSouko: otaruSouko
        case .onsenHouse: onsenHouse
        case .bokujoHouse: bokujoHouse
        case .nakaHouse: nakaHouse
        case .utoroCenter: utoroCenter
        case .utoroHouse: utoroHouse
        case .banya: banya
        case .ekashiHouse: ekashiHouse
        case .rausuHouse: rausuHouse
        }
    }

    /// 全滅したときに戻る場所。いちばん近い街ではなく、その地方の はじめの街の入口にそろえる。
    static let revivePoint = (map: MapID.hakodate, point: Point(x: 15, y: 24))

    static func revivePoint(in region: Region) -> (map: MapID, point: Point) {
        switch region {
        case .hakodate: revivePoint
        case .sapporo: (.sapporo, Point(x: 15, y: 24))
        case .shiretoko: (.nakashibetsu, Point(x: 12, y: 16))
        }
    }

    /// 名所の スタンプを押せる 看板（街の 名所の看板 ぜんぶ）。地方ごとに 案内所で ごほうびが もらえる。
    static let stampPlaques: [PlaqueID] = MapID.allCases.filter(\.isTown).flatMap { id in
        map(id).plaques.keys.map { PlaqueID(map: id, point: $0) }
    }
    static func stampPlaques(in region: Region) -> [PlaqueID] { stampPlaques.filter { $0.map.region == region } }
    static func stampTotal(in region: Region) -> Int { stampPlaques(in: region).count }

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
        chestRewards: [.item(.herb), .gold(20)]
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
        chestRewards: [.gold(40)]
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
        chestRewards: [.gold(80)]
    )

    /// 札幌。北海道で いちばん大きな街。
    /// - 北: 北海道大学（ポプラ並木・クラーク像）。出前を まつ学生。
    /// - 北東: 赤れんが庁舎（中に 長官）と 時計台。
    /// - まんなか: 東西に のびる 大通公園と テレビ塔。
    /// - 南: すすきの（ラーメン横丁）、宿屋・道具屋、観光案内所。
    /// 長官の話 → 小樽の オルゴール職人 → 天狗山 → オルゴールで 藻岩山、の順（`Story.swift`）。
    static let sapporo = GameMap(
        id: .sapporo,
        name: "さっぽろ",
        rows: [
            "###############################",
            "#_f_f__HHHHH_____HHHHHHH______#",
            "#_f_f__WWWWW_____HHHHHHH__HHH_#",
            "#_f_f______3_____WWWdWWW__WdW_#",
            "#_f_f___P_____________P__P____#",
            "#_f_f_t_______________________#",
            "#__________________t__________#",
            "#_____________________________#",
            "#__________________________HH_#",
            "#_f___f___f___f___f___f___fWW_#",
            "#_____ww__P___ww__t___ww__P___#",
            "#___f___f___f___f___f___f___f_#",
            "#___t_________________________#",
            "#_____________________________#",
            "#_III___SSS____e____HHHHHHH___#",
            "#_III___SSS_________WWWWWWW___#",
            "#_YdW___ZdW___________P_______#",
            "#_______________________2_____#",
            "#_________________t___________#",
            "#____________4__________HHH___#",
            "#___HHH_________________WdW___#",
            "#___WdW____________________t__#",
            "#_________t___________________#",
            "#___________________c_________#",
            "#____________P________________#",
            "##############EEE##############"
        ],
        outside: .grass,
        warps: [
            // 家の扉。
            Point(x: 20, y: 3): Warp(to: .doucho, at: Point(x: 4, y: 4)),
            Point(x: 27, y: 3): Warp(to: .tokeidaiHouse, at: Point(x: 4, y: 4)),
            Point(x: 25, y: 20): Warp(to: .sapporoHouse, at: Point(x: 4, y: 4)),
            Point(x: 5, y: 21): Warp(to: .susukinoHouse, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 16): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 9, y: 16): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 14, y: 25): Warp(to: .sapporoArea, at: Point(x: 36, y: 21)),
            Point(x: 15, y: 25): Warp(to: .sapporoArea, at: Point(x: 36, y: 21)),
            Point(x: 16, y: 25): Warp(to: .sapporoArea, at: Point(x: 36, y: 21)),
        ],
        // 戦闘の「ちしき」の答えは ここと 定山渓で 聞ける（`QuizRegion.sapporo` と `QuizTests` を見る）。
        villagers: [
            ["がくせい「ポプラ並木は 北大の じまん。",
             "　クラーク博士の 像も あるよ。」"],
            ["やくにん「赤れんが庁舎は 明治に たてられた 北海道の 役所。",
             "　長官は 中に おられるぞ。」"],
            ["こども「冬の 大通公園では 雪まつりが あるんだ！",
             "　大きな 雪の 像が ずらっと ならぶよ。」"],
            ["むすめ「大通公園は 札幌の まんなかを",
             "　東西に のびる 公園よ。」"],
            ["たびびと「札幌で 生まれた みそラーメン、",
             "　すすきので 食べなきゃ そんだよ！」"],
            ["おとこ「南西の 藻岩山から 見る 夜景は きれいなんだ。",
             "　いまは ヒグマのぬしで 近づけないけどな。」"],
            ["しょうにん「鋼の剣は 札幌で 買えるよ。",
             "　藻岩山へ 行くなら そろえておきな。」"],
        ],
        residents: ["2": .ramenChef, "3": .student, "4": .sapporoGuide],
        plaques: [
            Point(x: 8, y: 4): Plaque(title: "クラーク", lines: [
                "かんばんに こう かいてある。",
                "「クラーク博士の 像」",
                "北大の はじめの 先生。",
                "『少年よ 大志を いだけ』の ことばを のこした。",
            ]),
            Point(x: 22, y: 4): Plaque(title: "道庁", lines: [
                "かんばんに こう かいてある。",
                "「北海道庁 旧本庁舎（赤れんが庁舎）」",
                "明治に たてられた 北海道の 役所。",
            ]),
            Point(x: 25, y: 4): Plaque(title: "時計台", lines: [
                "かんばんに こう かいてある。",
                "「札幌市時計台」",
                "白い 木の たてもの。 いまも かねが 時を つげる。",
            ]),
            Point(x: 10, y: 10): Plaque(title: "大通", lines: [
                "かんばんに こう かいてある。",
                "「大通公園」",
                "札幌の まんなかを 東西に のびる 公園。",
                "冬には 雪まつりの 会場に なる。",
            ]),
            Point(x: 26, y: 10): Plaque(title: "テレビ塔", lines: [
                "かんばんに こう かいてある。",
                "「さっぽろテレビ塔」",
                "大通公園の 東の はしに たつ 塔。",
            ]),
            Point(x: 22, y: 16): Plaque(title: "横丁", lines: [
                "かんばんに こう かいてある。",
                "「ラーメン横丁」",
                "札幌 名物の みそラーメンの 店が ならぶ。",
            ]),
        ],
        chestRewards: [.gold(40)]
    )

    /// 小樽。石狩湾の みなと町。
    /// - 北: 小樽港と 石の倉庫（まいごの ネコ）。
    /// - まんなか: 東西に ながれる 小樽運河。
    /// - 南: 堺町通りの ガラス工房・オルゴール堂（天狗に オルゴールを うばわれた 職人）、宿屋・道具屋。
    static let otaru = GameMap(
        id: .otaru,
        name: "おたる",
        rows: [
            "###########################",
            "#~~~~~~~~~~~~~~~~~~~~~~~~~#",
            "#~~~~~_~~~~~~~~~~~_~~~~~~~#",
            "#_HHHH___HHHH____c__HHHH__#",
            "#_WWWW___WdWW__2____WWWW__#",
            "#_______P_________________#",
            "#~~~~b~~~~~~~b~~~~~~~b~~~~#",
            "#_______________P_________#",
            "#__________34_____________#",
            "#__HHH___________HHHHH__t_#",
            "#__WdW___________WWdWW____#",
            "#_____P_________P____1____#",
            "#_________t_______________#",
            "#________HHH______________#",
            "#________WWW______________#",
            "#_III______P_______SSS____#",
            "#_III_________e____SSS____#",
            "#_YdW______________ZdW____#",
            "#_______t_________________#",
            "#_____________________t___#",
            "#_________P______P________#",
            "############EEE############"
        ],
        outside: .grass,
        warps: [
            // 家の扉。
            Point(x: 10, y: 4): Warp(to: .otaruSouko, at: Point(x: 4, y: 4)),
            Point(x: 4, y: 10): Warp(to: .glassKobo, at: Point(x: 4, y: 4)),
            Point(x: 19, y: 10): Warp(to: .orgelDo, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 17): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 20, y: 17): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 12, y: 21): Warp(to: .sapporoArea, at: Point(x: 10, y: 22)),
            Point(x: 13, y: 21): Warp(to: .sapporoArea, at: Point(x: 10, y: 22)),
            Point(x: 14, y: 21): Warp(to: .sapporoArea, at: Point(x: 10, y: 22)),
        ],
        // 戦闘の「ちしき」の答えは ここで聞ける（`QuizRegion.otaru` と `QuizTests` を見る）。
        villagers: [
            ["ふなのり「むかし 小樽は ニシンりょうで にぎわったんだ。",
             "　運河は その 荷を はこぶ 水の みちさ。」"],
            ["むすめ「小樽の ガラスは ニシンりょうの",
             "　うきだまづくりが はじまりなの。」"],
            ["おとこ「街の 南の 天狗山には 天狗が すむって いうぜ。",
             "　ロープウェイで のぼると 石狩湾が 見わたせるんだ。」"],
            ["たびびと「銀行が ならんで『北の ウォール街』って",
             "　よばれたのが この 小樽さ。」"],
        ],
        residents: ["1": .musicBoxMaker, "2": .lostCat, "3": .catOwner, "4": .catHome],
        plaques: [
            Point(x: 8, y: 5): Plaque(title: "運河", lines: [
                "かんばんに こう かいてある。",
                "「小樽運河」",
                "船の 荷を 倉庫へ はこんだ 水の みち。",
            ]),
            Point(x: 16, y: 7): Plaque(title: "倉庫", lines: [
                "かんばんに こう かいてある。",
                "「運河の 石造倉庫」",
                "ニシンや 米を しまった 石の 倉庫。",
            ]),
            Point(x: 6, y: 11): Plaque(title: "ガラス", lines: [
                "かんばんに こう かいてある。",
                "「ガラス工房」",
                "小樽の 名物の ガラスを つくる 店。",
            ]),
            Point(x: 16, y: 11): Plaque(title: "オルゴ", lines: [
                "かんばんに こう かいてある。",
                "「小樽オルゴール堂」",
                "たくさんの オルゴールが ならぶ 店。",
            ]),
            Point(x: 11, y: 15): Plaque(title: "銀行", lines: [
                "かんばんに こう かいてある。",
                "「北の ウォール街」",
                "むかし 銀行が たちならんだ 通り。",
            ]),
            Point(x: 17, y: 20): Plaque(title: "天狗山", lines: [
                "かんばんに こう かいてある。",
                "「天狗山」",
                "小樽の 南に そびえる 山。 天狗の 伝説が のこる。",
            ]),
        ],
        chestRewards: [.gold(40)]
    )

    /// 定山渓。札幌の 南西の 山あいの 温泉街。豊平川の 谷に かかる 吊橋と、かっぱの 伝説。
    /// 湯守に 話しかけると 足湯で HP・MPが ぜんぶ なおる（藻岩山の 前の ひとやすみ）。
    static let jozankei = GameMap(
        id: .jozankei,
        name: "じょうざんけい",
        rows: [
            "#######################",
            "#MMMMMMMMMMMMMMMMMMMMM#",
            "#MMMM_______MMMMMMMMMM#",
            "#__________~~_P_______#",
            "#__www_P___bb_________#",
            "#__www_____~~____1____#",
            "#___2______~~__P______#",
            "#__________~~_________#",
            "#_HHH______~~__III_SSS#",
            "#_WdW______~~__III_SSS#",
            "#______t___~~__YdW_ZdW#",
            "#__________~~_________#",
            "#____e_____bb_________#",
            "#__________~~____t____#",
            "#__________~~_t_______#",
            "#__c_____P____________#",
            "#_____________________#",
            "##########EEE##########"
        ],
        outside: .grass,
        warps: [
            Point(x: 3, y: 9): Warp(to: .onsenHouse, at: Point(x: 4, y: 4)),
            Point(x: 16, y: 10): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 20, y: 10): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 10, y: 17): Warp(to: .sapporoArea, at: Point(x: 20, y: 34)),
            Point(x: 11, y: 17): Warp(to: .sapporoArea, at: Point(x: 20, y: 34)),
            Point(x: 12, y: 17): Warp(to: .sapporoArea, at: Point(x: 20, y: 34)),
        ],
        villagers: [
            ["おばあさん「定山渓は 札幌の 奥座敷と よばれる",
             "　温泉の 町さ。 ゆっくり していきな。」"],
            ["こども「川に かっぱが すむって ほんとかなあ？",
             "　町には かっぱの 像が いっぱい あるよ。」"],
            ["たびびと「藻岩山の ぬしに いどむ まえに",
             "　足湯で やすんで いくと いい。」"],
        ],
        residents: ["1": .kappa, "2": .yumori],
        plaques: [
            Point(x: 14, y: 3): Plaque(title: "吊橋", lines: [
                "かんばんに こう かいてある。",
                "「二見吊橋」",
                "豊平川の 谷に かかる 赤い 吊橋。",
            ]),
            Point(x: 7, y: 4): Plaque(title: "温泉", lines: [
                "かんばんに こう かいてある。",
                "「定山渓温泉」",
                "山あいに わく 札幌の 温泉。",
            ]),
            Point(x: 15, y: 6): Plaque(title: "かっぱ", lines: [
                "かんばんに こう かいてある。",
                "「かっぱ淵」",
                "かっぱが すむと いわれる 川の ふち。",
            ]),
        ],
        chestRewards: [.gold(60)]
    )

    /// 羅臼。知床半島の 東がわ、根室海峡に めんした 町。
    /// - 北: 羅臼岳の すそ。 西: 間欠泉と エカシ（長老）の家。
    /// - まんなか: 番屋と 昆布ほし場（牛乳を まつ おやじ）。 東: 漁港と 国後島の 見える 展望。
    /// - 南: 宿屋・道具屋・観光案内所。
    /// エカシの話 → 知床岬の トドのぬし → カムイの はね → 羅臼岳、の順（`Story.swift`）。
    static let rausu = GameMap(
        id: .rausu,
        name: "らうす",
        rows: [
            "#############################",
            "#MMMMMMMMMMMMMMMMMMMMM~~~~~~#",
            "#MMMM______MMMMM___MMM~~~~~~#",
            "#______P______________~~~~~~#",
            "#_____________________~~~~~~#",
            "#__www________HHHHH___~~~~~~#",
            "#_____P_______WWdWW___~~~~~~#",
            "#__________________3__~~~~~~#",
            "#_________t_______________P~#",
            "#_HHH________f_f_f_f__~~~~~~#",
            "#_WdW__________P______~~~~~~#",
            "#____1________________~~~~~~#",
            "#____________________P~~~~~~#",
            "#_____________2_______~~~~~~#",
            "#_III___SSS___________~~~~~~#",
            "#_III___SSS______e____~~~~~~#",
            "#_YdW___ZdW___________~~~~~~#",
            "#________________HHH__~~~~~~#",
            "#____________t___WdW__~~~~~~#",
            "#____t________________~~~~~~#",
            "#________P__________c_~~~~~~#",
            "############EEE##############"
        ],
        outside: .grass,
        warps: [
            // 家の扉。
            Point(x: 16, y: 6): Warp(to: .banya, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 10): Warp(to: .ekashiHouse, at: Point(x: 4, y: 4)),
            Point(x: 18, y: 18): Warp(to: .rausuHouse, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 16): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 9, y: 16): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 12, y: 21): Warp(to: .shiretokoArea, at: Point(x: 41, y: 25)),
            Point(x: 13, y: 21): Warp(to: .shiretokoArea, at: Point(x: 41, y: 25)),
            Point(x: 14, y: 21): Warp(to: .shiretokoArea, at: Point(x: 41, y: 25)),
        ],
        // 戦闘の「ちしき」の答えは ここと 中標津で 聞ける（`QuizRegion.rausu` と `QuizTests` を見る）。
        villagers: [
            ["りょうし「羅臼の 海には シャチが やってくる。",
             "　船で 見に いけるんだぜ。」"],
            ["むすめ「羅臼は 知床の 東がわ、",
             "　根室海峡に めんした 町なの。」"],
            ["こども「エカシの おじいちゃんは",
             "　知床の ことを なんでも しってるんだよ。」"],
        ],
        residents: ["1": .ekashi, "2": .shiretokoGuide, "3": .banyaOyaji],
        plaques: [
            Point(x: 7, y: 3): Plaque(title: "羅臼岳", lines: [
                "かんばんに こう かいてある。",
                "「羅臼岳」",
                "知床連山の 山。 いまは ふぶきに とざされている。",
            ]),
            Point(x: 6, y: 6): Plaque(title: "間欠泉", lines: [
                "かんばんに こう かいてある。",
                "「羅臼間欠泉」",
                "ときどき 高く ゆが ふきあがる。",
            ]),
            Point(x: 26, y: 8): Plaque(title: "国後島", lines: [
                "かんばんに こう かいてある。",
                "「国後島 展望」",
                "根室海峡の むこうに 国後島が 見える。",
            ]),
            Point(x: 15, y: 10): Plaque(title: "昆布", lines: [
                "かんばんに こう かいてある。",
                "「羅臼昆布」",
                "だしの 王さまと よばれる 羅臼の こんぶ。",
            ]),
            Point(x: 21, y: 12): Plaque(title: "シャチ", lines: [
                "かんばんに こう かいてある。",
                "「シャチ ウォッチング」",
                "羅臼の 海には シャチや クジラが くる。",
            ]),
        ],
        chestRewards: [.gold(150)]
    )

    /// 中標津。知床への 空の入口の 酪農の町。牧場主が 羅臼の番屋へ 牛乳を たのむ。
    static let nakashibetsu = GameMap(
        id: .nakashibetsu,
        name: "なかしべつ",
        rows: [
            "#########################",
            "#__HHH___HH_____________#",
            "#__WdW___WW_____P_______#",
            "#____________1______t___#",
            "#__f__f__f__f__f__f__f__#",
            "#_______________________#",
            "#_______________________#",
            "#_III___SSS_______HHH___#",
            "#_III___SSS___e___WdW___#",
            "#_YdW___ZdW_____________#",
            "#_______________________#",
            "#____t__________________#",
            "#__________________t____#",
            "#___________P___________#",
            "#_______________________#",
            "#__c_____________P______#",
            "#_______________________#",
            "###########EEE###########"
        ],
        outside: .grass,
        warps: [
            Point(x: 4, y: 2): Warp(to: .bokujoHouse, at: Point(x: 4, y: 4)),
            Point(x: 19, y: 8): Warp(to: .nakaHouse, at: Point(x: 4, y: 4)),
            Point(x: 3, y: 9): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 9, y: 9): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 17): Warp(to: .shiretokoArea, at: Point(x: 16, y: 32)),
            Point(x: 12, y: 17): Warp(to: .shiretokoArea, at: Point(x: 16, y: 32)),
            Point(x: 13, y: 17): Warp(to: .shiretokoArea, at: Point(x: 16, y: 32)),
        ],
        villagers: [
            ["むすめ「牛さんたちの ごはんは 牧草。",
             "　夏は いちめん みどりよ。」"],
            ["たびびと「中標津空港から 知床までは",
             "　まだまだ 歩くぜ。」"],
            ["おじさん「羅臼へは 東へ、ウトロへは 北へ。",
             "　どっちも 知床の 入口さ。」"],
        ],
        residents: ["1": .rancher],
        plaques: [
            Point(x: 16, y: 2): Plaque(title: "開陽台", lines: [
                "かんばんに こう かいてある。",
                "「開陽台」",
                "360度 見わたせる 丘。",
                "地球の まるみが 見えると いわれる。",
            ]),
            Point(x: 12, y: 13): Plaque(title: "酪農", lines: [
                "かんばんに こう かいてある。",
                "「酪農の 町 中標津」",
                "牛の かずが 人より おおい 町。",
            ]),
        ],
        chestRewards: [.gold(120)]
    )

    /// ウトロ。知床半島の 西がわ、オホーツク海に めんした 町。
    /// 北に 港と オロンコ岩、東に 知床五湖（まいごの キツネの子）、西に オシンコシンの滝。
    static let utoro = GameMap(
        id: .utoro,
        name: "うとろ",
        rows: [
            "###########################",
            "#~~~~~~~~~~~~~~~~~MMM~~~~~#",
            "#~~~~~~~~~~~~~~~~~MMM~~~~~#",
            "#~~~~~~~~~~~~~~~~MMMMM~~~~#",
            "#_____P_________P_________#",
            "#________t________________#",
            "#___________________ffffff#",
            "#MM_________________f~2fff#",
            "#Mw_____HHHHH_______ff_~ff#",
            "#MwP____WWdWW_____P______f#",
            "#MM__________34_____f~ffff#",
            "#___________________ffff~f#",
            "#___________________ff~fff#",
            "#__III___SSS______________#",
            "#__III___SSS_____e________#",
            "#__YdW___ZdW________HHH___#",
            "#___________________WdW___#",
            "#_________________________#",
            "#_____t_______________t___#",
            "#_________________________#",
            "#________P________c_______#",
            "############EEE############"
        ],
        outside: .grass,
        warps: [
            Point(x: 10, y: 9): Warp(to: .utoroCenter, at: Point(x: 4, y: 4)),
            Point(x: 21, y: 16): Warp(to: .utoroHouse, at: Point(x: 4, y: 4)),
            Point(x: 4, y: 15): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 10, y: 15): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 12, y: 21): Warp(to: .shiretokoArea, at: Point(x: 30, y: 12)),
            Point(x: 13, y: 21): Warp(to: .shiretokoArea, at: Point(x: 30, y: 12)),
            Point(x: 14, y: 21): Warp(to: .shiretokoArea, at: Point(x: 30, y: 12)),
        ],
        // 戦闘の「ちしき」の答えは ここで聞ける（`QuizRegion.utoro` と `QuizTests` を見る）。
        villagers: [
            ["りょうし「冬の ウトロの 海は りゅうひょうで",
             "　まっしろに なるんだ。」"],
            ["むすめ「知床は 世界自然遺産に",
             "　えらばれた 土地なのよ。」"],
            ["たびびと「知床岬へは この町から 海ぞいの 道を 北へ。",
             "　けわしい 道だから ハスカップを わすれずにな。」"],
        ],
        residents: ["2": .lostFox, "3": .foxRanger, "4": .foxHome],
        plaques: [
            Point(x: 6, y: 4): Plaque(title: "港", lines: [
                "かんばんに こう かいてある。",
                "「ウトロ漁港」",
                "オホーツク海に めんした 港。",
            ]),
            Point(x: 16, y: 4): Plaque(title: "オロンコ", lines: [
                "かんばんに こう かいてある。",
                "「オロンコ岩」",
                "港に そびえる 大きな 岩。",
            ]),
            Point(x: 18, y: 9): Plaque(title: "五湖", lines: [
                "かんばんに こう かいてある。",
                "「知床五湖」",
                "原生林の なかに ならぶ 5つの 湖。",
            ]),
            Point(x: 3, y: 9): Plaque(title: "滝", lines: [
                "かんばんに こう かいてある。",
                "「オシンコシンの滝」",
                "海ぞいに おちる 知床の 滝。",
            ]),
            Point(x: 9, y: 20): Plaque(title: "夕日", lines: [
                "かんばんに こう かいてある。",
                "「夕陽台」",
                "オホーツク海に しずむ 夕日が 見える。",
            ]),
        ],
        chestRewards: [.gold(180)]
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
        chestRewards: [.gold(60)],
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
        chestRewards: [.gold(120), .item(.herb)],
        bossKind: .komaLord,
        encounters: [
            .caveFloor: [.lavaSlime, .pumiceGolem, .sulfurSmoke],
        ],
        markerFloor: .caveFloor
    )

    /// 天狗山の ほらあな。小樽の 南。いちばん奥に オルゴールを うばった 天狗がいる。
    static let tenguyama = GameMap(
        id: .tenguyama,
        name: "天狗山の ほらあな",
        rows: [
            "###################",
            "######,,,,,,,######",
            "######,,,B,,,######",
            "######,,,,,,,######",
            "########,,,########",
            "#c,,,,#,,,,,#,,,,,#",
            "#,###,#,###,#,###,#",
            "#,#,,,,,#,,,,,#,#,#",
            "#,#,#####,###,#,#,#",
            "#,,,#,,,,,,,#,,,#,#",
            "###,#,#####,#####,#",
            "#,,,,,#,,,,,,,,#,c#",
            "#,#####,####,#,#,,#",
            "#,,,,,,,,U,,,#,,,,#",
            "###################"
        ],
        outside: .wall,
        warps: [
            Point(x: 9, y: 13): Warp(to: .sapporoArea, at: Point(x: 9, y: 29)),
        ],
        chestRewards: [.gold(150), .item(.herb)],
        bossKind: .tengu,
        encounters: [
            .caveFloor: [.flyingSquirrel, .maitake, .salamander],
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
            Point(x: 7, y: 11): Warp(to: .sapporoArea, at: Point(x: 29, y: 28)),
            Point(x: 3, y: 9): Warp(to: .moiwa2, at: Point(x: 6, y: 9)),
        ],
        chestRewards: [.item(.herb)],
        encounters: [
            .caveFloor: [.bearCub, .fishOwl, .woodpecker],
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
        chestRewards: [.gold(150)],
        bossKind: .bearLord,
        encounters: [
            .caveFloor: [.bearCub, .fishOwl, .woodpecker],
        ],
        markerFloor: .caveFloor
    )

    /// 知床岬の 海の ほらあな。いちばん奥に カムイの はねを うばった トドのぬしがいる。
    static let shiretokoMisaki = GameMap(
        id: .shiretokoMisaki,
        name: "知床岬の ほらあな",
        rows: [
            "###################",
            "#~~~~~,,,,,,,~~~~~#",
            "#~~~~,,,,B,,,,~~~~#",
            "#~~~~~,,,,,,,~~~~~#",
            "#~~~~~~~,,,~~~~~~~#",
            "#c,,,~~~,,,~~~,,,c#",
            "#,#,,,,,,#,,,,,,#,#",
            "#,#,~~~~,#,~~~~,#,#",
            "#,#,,,,~,#,~,,,,#,#",
            "#,####,~,,,~,####,#",
            "#,,,,#,~~~~~,#,,,,#",
            "####,#,,,,,,,#,####",
            "#,,,,###,#,#####,,#",
            "#,,,,,,,,U,,,,,,,,#",
            "###################"
        ],
        outside: .wall,
        warps: [
            Point(x: 9, y: 13): Warp(to: .shiretokoArea, at: Point(x: 57, y: 3)),
        ],
        chestRewards: [.gold(250), .item(.herb)],
        bossKind: .todoLord,
        encounters: [
            .caveFloor: [.hikarigoke, .icicleOgre, .iceBat],
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
            Point(x: 7, y: 11): Warp(to: .shiretokoArea, at: Point(x: 38, y: 17)),
            Point(x: 3, y: 9): Warp(to: .rausudake2, at: Point(x: 6, y: 9)),
        ],
        chestRewards: [.item(.steelSword)],
        encounters: [
            .caveFloor: [.phantomWolf, .iceGolem, .blizzardSpirit],
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
            Point(x: 55, y: 27): Warp(to: .sapporoArea, at: Point(x: 42, y: 15), needs: .ticketToSapporo),
        ],
        chestRewards: [.gold(100), .gold(60), .item(.herb), .item(.leatherArmor), .gold(30)],
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

    /// 札幌・小樽。65×40 マス。北西は 石狩湾、まんなかに 札幌（豊平川が ながれる）、西の 海ぞいに 小樽と 天狗山、
    /// 南西に 藻岩山と 山あいの 定山渓、南に 支笏湖。
    /// 丘珠空港（北東）は 函館と、新千歳空港（南東）は 知床の 中標津と むすぶ。
    static let sapporoArea = GameMap(
        id: .sapporoArea,
        name: "札幌・小樽",
        rows: [
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~....................",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...c.................",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~....=..................",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.....=..................",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...=..................",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...~~~~~~=..................",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~........~~~b~~................",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.............b~~~~~.............",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...............=..~~~~~~..........",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.................=.....~~~~~~.......",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~...................=........~~~~~~....",
            "~~~~~~~~~~~~~~~~~~~~~~~~~.....................=...........~~~~~~.",
            "~~~~~~~~~~~~~~~~~~~~~~~..............~........=..............~~~~",
            "~~~~~~~~~~~~~~~~~~~~~................~........=.................~",
            "~~~~~~~~~~~~~~~~~~~..................~....A...=................c.",
            "~~~~~~~~~~~~~~~~~....................~....=====..................",
            "~~~~~~~~~~~~~~~.....................~.....=...............fffffff",
            "~~~~~~~~~~~~~.......................~.....=...............fffffff",
            "~~~~~~~~~~~.........................~.....=...............fffffff",
            "~~~~~~~~~...........===========.....~.....=...fffffff.....fffffff",
            "~~~~~~..............=.........=.....T.....=...fffffff.....fffffff",
            "..........T.....ffff=ffff.....======b================.....fffffff",
            "MMMMMc....===========ffff..........~=.........ffffff=.....fffffff",
            "MMMMMhh......=..fffffffffhhhhhhhh..~=.........ffffff=.....fffffff",
            "MMMMMhhhhhhhh=h.fffffffffhMMMMMMh..~=.........ffffff=.....fffffff",
            "MMMMMhhhMMMMM=h.fffffffffhMMMMMMh..~=.........ffffff=.....fffffff",
            "MMMMMhhhMMMMM=h.fffffffffhMMMMMMh..~=.........ffffff=...fffffffff",
            "MMMMMhhhMMMMM=h.fffffffffhMMMCMMh..~=...............=...fffffffff",
            "MMMMMhhhMCMMM=h..........hhhh=hhh.~.=...............=...fffffffff",
            "MMMMMhhhh=hhh=h..........hhhh=hhh.~.=...............=...fffffffff",
            "MMMMMMMhh=====h.........==========b==...............=...fffffffff",
            "MMMMMMMMhhhhhhhhhhffffff=hhhhhhhhh~.................=...fffffffff",
            "MMMMMMMMhhhhMMMMhhffffff=hhMMMMMhh~....~~~~~~.......=.A.fffffffff",
            "MMMMMMMMhhhhMMMMhhffTfff=hhMMMMMhh~...~~~~~~~~......===.fffffffff",
            "MMMMMMMMhhhhMMMMhhff=====hhMMMMMhhh...~~~~~~~~..........fffffffff",
            "MMMMMMMMMMMMMMMMMMffffffMMMMMMMMMMM...~~~~~~~~..........fffffffff",
            "MMMMMMMMMMMMMMMMMMffffffMMMMMMMMMMM...~~~~~~~~..........fffffffff",
            "MMMMMMMMMMMMMMMMMMhhhhhhMMMMMMMMMMM...~~~~~~~~..........fffffffff",
            "MMMMMMMMMMMMMMMMMMhhhhhhMMMMMMMMMMMc...~~~~~~...........fffffffff",
            "MMMMMMMMMMMMMMMMMMhhhhhhMMMMMMMMMMM.....................fffffffff"
        ],
        outside: .water,
        warps: [
            Point(x: 36, y: 20): Warp(to: .sapporo, at: Point(x: 15, y: 24)),
            Point(x: 10, y: 21): Warp(to: .otaru, at: Point(x: 13, y: 20)),
            Point(x: 20, y: 33): Warp(to: .jozankei, at: Point(x: 11, y: 16)),
            // 天狗山は いつでも 入れる。藻岩山は ヒグマの こどもたちを オルゴールで しずめてから。
            Point(x: 9, y: 28): Warp(to: .tenguyama, at: Point(x: 8, y: 13)),
            Point(x: 29, y: 27): Warp(to: .moiwa1, at: Point(x: 6, y: 11), needs: .musicBox),
            // 丘珠空港 → 函館空港（もどり）。
            Point(x: 42, y: 14): Warp(to: .hakodateArea, at: Point(x: 55, y: 28), needs: .ticketToSapporo),
            // 新千歳空港 → 中標津空港（知床）。
            Point(x: 54, y: 32): Warp(to: .shiretokoArea, at: Point(x: 10, y: 30), needs: .ticketToShiretoko),
        ],
        chestRewards: [.gold(120), .item(.herb), .gold(200), .item(.herb)],
        // 札幌の まわりは やさしく、小樽・天狗山・定山渓の ほうは 手ごわい。
        encounterAreas: [
            EncounterArea(name: "札幌のまわり",
                          around: [Point(x: 42, y: 15), Point(x: 36, y: 21), Point(x: 54, y: 33), Point(x: 29, y: 28)],
                          enemies: [.cornSoldier, .ramenGhost, .lambSheep]),
            // 札幌から 小樽への 海ぞいの道にも 中心を置く（歩いて 弱いほうへ 戻らないように）。
            EncounterArea(name: "小樽へむかう道",
                          around: [Point(x: 10, y: 22), Point(x: 9, y: 29), Point(x: 20, y: 34), Point(x: 22, y: 19)],
                          enemies: [.squirrel, .fox, .snowFestival]),
        ],
        markerFloor: .grass
    )

    /// 知床。65×40 マス。南西の 中標津空港・中標津から、北東へ のびる 知床半島へ。
    /// 北西の オホーツク海がわに ウトロ、南東の 根室海峡がわに 羅臼（海の むこうに 国後島）、
    /// 半島の 背骨に 羅臼岳（知床峠で ウトロと 羅臼を むすぶ）、いちばん さきに 知床岬。
    static let shiretokoArea = GameMap(
        id: .shiretokoArea,
        name: "知床",
        rows: [
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.........~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.............c.~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.........MMMM.C...~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...........MMMM==...~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...........MMMMMM....~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.......====MMMMMM.....~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...~..~..=...MMMMMM....~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~......~....=.MMMMMM.....~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~....~.......MMMMMM......~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...======b===MMMMMM.....~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.....=.......MMMMMM......~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~..T...=.....MMMMMM.......~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~...=====.....MMMMMM......~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~......=...=...MMMMMM.......~~~~~~~~~~~~~~",
            "................~~~~~.=========...=.MMMMMM........~~~~~~~~~~~~~~~",
            ".c....................=...hhhhhhhh=.MMMMMM.......~~~~~~~~~~~~~~~~",
            "............hhhhhh....=...hhhhhhhhMMMMCM........~~~~MMMMMMMMMMMM~",
            "............hhhhhh....=...hhhhhhMMMMMM=.........~~~~MMMMMMMMMMMM~",
            "............hhhhhh....=...hhhhhhMMMMMM=........~~~~~MMMMMMMMMMMM~",
            "............hhhhhh....=...hhhhMMMMMM..=.......~~~~~~MMMMMMMMMMMM~",
            "..fffffffff.....=======.......MMMM....=......c~~hhhhhhhhhhh~~~~~~",
            "..fffffffff.....=.............MMMM....=......~~~hhhhhhMMMMh~~~~~~",
            "..fffffffff.....=.....................====...~~~hhhhhhMMMMh~~~~~~",
            "..fffffffff.....=........................=...~~~hhhhhhMMMMh~~~~~~",
            "..fffffffff.....=........................T..~~~~hhhhhhMMMMh~~~~~~",
            "..fffffffff.....=...................======..~~~~hhhhhhhhhhh~~~~~~",
            "..fffffffff.....=...................=......~~~~~hhhhhhhhhhh~~~~~~",
            "................=...................=.....~~~~hhhhhhh~~~~~~~~~~~~",
            "................=.......=============....~~~~~hhhhhhh~~~~~~~~~~~~",
            "..........A.....=.......=...............~~~~~~hhhhhhh~~~~~~~~~~~~",
            "....ffffff=======.......=..............~~~~~~~hhhhhhh~~~~~~~~~~~~",
            "....ffffff......T.......=.............~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "....ffffff......=========............~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "....ffffff........fffffffff.........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "....ffffff........fffffffff.........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "....ffffff........fffffffff........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "....ffffff........fffffffff........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "..................fffffffff........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "..................fffffffff......c~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "..................................~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ],
        outside: .water,
        warps: [
            Point(x: 16, y: 31): Warp(to: .nakashibetsu, at: Point(x: 12, y: 16)),
            Point(x: 30, y: 11): Warp(to: .utoro, at: Point(x: 13, y: 20)),
            Point(x: 41, y: 24): Warp(to: .rausu, at: Point(x: 13, y: 20)),
            // 知床岬は いつでも 入れる。羅臼岳は カムイの はねで ふぶきを はらってから。
            Point(x: 57, y: 2): Warp(to: .shiretokoMisaki, at: Point(x: 8, y: 13)),
            Point(x: 38, y: 16): Warp(to: .rausudake1, at: Point(x: 6, y: 11), needs: .kamuiFeather),
            // 中標津空港 → 新千歳空港（もどり）。
            Point(x: 10, y: 29): Warp(to: .sapporoArea, at: Point(x: 54, y: 33), needs: .ticketToShiretoko),
        ],
        chestRewards: [.gold(250), .item(.herb), .item(.herb), .gold(300)],
        // 中標津の まわりは やさしく、ウトロ・羅臼・知床岬の ほうは 手ごわい。
        encounterAreas: [
            EncounterArea(name: "中標津のまわり", around: [Point(x: 10, y: 30), Point(x: 16, y: 32), Point(x: 24, y: 31)],
                          enemies: [.deer, .cod, .salmon]),
            // 斜里を まわる 道にも 中心を置く（中標津から ウトロ・羅臼へ 歩いて 弱いほうへ 戻らないように）。
            EncounterArea(name: "ウトロへむかう道",
                          around: [Point(x: 30, y: 12), Point(x: 41, y: 25), Point(x: 38, y: 17),
                                   Point(x: 57, y: 3), Point(x: 16, y: 18)],
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
    static let houses: [MapID] = [.bokujoHouse, .nakaHouse, .utoroCenter, .utoroHouse, .banya, .ekashiHouse, .rausuHouse, .doucho, .susukinoHouse, .orgelDo, .otaruSouko, .onsenHouse, .bugyosho, .asaichiSouko, .motomachiHouse, .bukeyashiki, .tsukemonoya, .ryoshiHouse, .noukaHouse, .dangoya, .yamagoya, .glassKobo, .tokeidaiHouse, .sapporoHouse]

    /// 家の中を作る。出口は 下の まんなか、入ると その上に立つ。
    /// 出口の行き先は 入った扉の前に差し替わる（GameState が見る）が、地図の上でも 同じ場所を書いておく。
    private static func house(_ id: MapID, name: String, rows: [String], town: MapID, door: Point,
                              villagers: [[String]], residents: [Character: Resident] = [:],
                              chestRewards: [ChestReward]) -> GameMap {
        GameMap(
            id: id, name: name, rows: rows, outside: .darkness,
            warps: [Point(x: 4, y: rows.count - 1): Warp(to: town, at: door + Point(x: 0, y: 1))],
            villagers: villagers, residents: residents, chestRewards: chestRewards, markerFloor: .woodFloor
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
        chestRewards: [.gold(20)]
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
        chestRewards: [.gold(30)]
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
        chestRewards: [.gold(60)]
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
             "　たなの はこに ハスカップが あるから もっていきな。」"],
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
        chestRewards: [.gold(40)]
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
            ["だんごや「駒ヶ岳の ぬしは 火を ふく うまの ばけもの。",
             "　大沼の ことを よく しってると たたかいで やくに たつらしいよ。」"],
        ],
        chestRewards: [.gold(50)]
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
             "　ハスカップを たっぷり もっていけ。 はこの ぶんは やるよ。」"],
        ],
        chestRewards: [.item(.herb), .gold(20)]
    )







    /// 赤れんが庁舎（北海道庁 旧本庁舎）。奥に 長官がいる。
    static let doucho = house(
        .doucho, name: "あかれんがちょうしゃ",
        rows: [
            "XXXXXXXXX",
            "XLLL1LLLX",
            "XoooooooX",
            "XtooooocX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .sapporo, door: Point(x: 20, y: 3),
        villagers: [
            ["やくにん「長官は 小樽の オルゴールの ことを",
             "　たいそう 気にかけて おられる。」"],
        ],
        residents: ["1": .governor],
        chestRewards: [.gold(50)]
    )

    /// 札幌の 時計台。
    static let tokeidaiHouse = house(
        .tokeidaiHouse, name: "とけいだい",
        rows: [
            "XXXXXXXXX",
            "XQotoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .sapporo, door: Point(x: 27, y: 3),
        villagers: [
            ["かねもり「この 時計台は もとは 札幌農学校の 演武場。",
             "　いまも かねが 時を つげて いるんだよ。」"],
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
        town: .sapporo, door: Point(x: 25, y: 20),
        villagers: [
            ["むすめ「新千歳空港は 札幌の 南東よ。",
             "　ヒグマのぬしを たおせば 知床へ とべる きっぷが もらえるわ。」"],
        ],
        chestRewards: [.gold(80)]
    )

    /// すすきのの 家。
    static let susukinoHouse = house(
        .susukinoHouse, name: "すすきのの いえ",
        rows: [
            "XXXXXXXXX",
            "XLLtoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .sapporo, door: Point(x: 5, y: 21),
        villagers: [
            ["おじさん「ラーメンの おやじは 出前の 手が",
             "　たりないって ぼやいてたよ。」"],
        ],
        chestRewards: [.gold(30)]
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
        town: .otaru, door: Point(x: 4, y: 10),
        villagers: [
            ["しょくにん「札幌で 鋼の剣は かったかい？",
             "　天狗山の おくは てごわいぞ。」"],
        ],
        chestRewards: [.gold(100)]
    )

    /// 小樽の オルゴール堂。
    static let orgelDo = house(
        .orgelDo, name: "オルゴールどう",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLLX",
            "XoooooooX",
            "XcootoooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .otaru, door: Point(x: 19, y: 10),
        villagers: [
            ["てんいん「天狗山の 天狗は うちわで つむじかぜを おこすの。",
             "　小樽の ことを よく しってると たたかいで やくに たつそうよ。」"],
        ],
        chestRewards: [.item(.herb)]
    )

    /// 小樽の 石の倉庫。
    static let otaruSouko = house(
        .otaruSouko, name: "おたるの そうこ",
        rows: [
            "XXXXXXXXX",
            "XQotoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .otaru, door: Point(x: 10, y: 4),
        villagers: [
            ["にんぷ「ネコなら さっき 倉庫の 東の かげに いたぞ。",
             "　ニシンの においでも したのかな。」"],
        ],
        chestRewards: [.gold(60)]
    )

    /// 定山渓の 湯宿。
    static let onsenHouse = house(
        .onsenHouse, name: "ゆやど",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLLX",
            "XoooooooX",
            "XcootoooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .jozankei, door: Point(x: 3, y: 9),
        villagers: [
            ["おかみ「藻岩山の ほらあなは 2かいだて。",
             "　ぬしは いちばん 奥に いるそうだよ。」"],
        ],
        chestRewards: [.item(.herb)]
    )

    /// 中標津の 牧場の家。
    static let bokujoHouse = house(
        .bokujoHouse, name: "ぼくじょうの いえ",
        rows: [
            "XXXXXXXXX",
            "XQotoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .nakashibetsu, door: Point(x: 4, y: 2),
        villagers: [
            ["むすこ「開陽台に のぼると 地球が まるく 見えるんだ。",
             "　とうさんの 牛乳は 羅臼でも 大人気さ。」"],
        ],
        chestRewards: [.item(.herb)]
    )

    /// 中標津の 家。
    static let nakaHouse = house(
        .nakaHouse, name: "なかしべつの いえ",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLLX",
            "XoooooooX",
            "XcootoooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .nakashibetsu, door: Point(x: 19, y: 8),
        villagers: [
            ["おばあさん「知床の まものは つよいよ。",
             "　宿屋で しっかり やすんで おいき。」"],
        ],
        chestRewards: [.gold(150)]
    )

    /// ウトロの 自然センター。
    static let utoroCenter = house(
        .utoroCenter, name: "しぜんセンター",
        rows: [
            "XXXXXXXXX",
            "XLLtoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .utoro, door: Point(x: 10, y: 9),
        villagers: [
            ["しょくいん「知床岬の ほらあなの トドのぬしは とても 大きいの。",
             "　ウトロの ことを よく しってると たたかいで やくに たつそうよ。」"],
        ],
        chestRewards: [.item(.herb)]
    )

    /// ウトロの 漁師の家。
    static let utoroHouse = house(
        .utoroHouse, name: "うとろの いえ",
        rows: [
            "XXXXXXXXX",
            "XQotoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .utoro, door: Point(x: 21, y: 16),
        villagers: [
            ["りょうし「オシンコシンの 滝は 2すじに わかれて おちるから",
             "　双美の滝とも いうんだ。」"],
        ],
        chestRewards: [.gold(180)]
    )

    /// 羅臼の 番屋（漁師の 作業小屋）。
    static let banya = house(
        .banya, name: "ばんや",
        rows: [
            "XXXXXXXXX",
            "XLLLoLLLX",
            "XoooooooX",
            "XcootoooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .rausu, door: Point(x: 16, y: 6),
        villagers: [
            ["わかい りょうし「羅臼の こんぶは 夏に ほすんだ。",
             "　おやじは 牛乳に 目が ないんだよ。」"],
        ],
        chestRewards: [.item(.herb)]
    )

    /// 羅臼の エカシの家。
    static let ekashiHouse = house(
        .ekashiHouse, name: "エカシの いえ",
        rows: [
            "XXXXXXXXX",
            "XLLtoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .rausu, door: Point(x: 3, y: 10),
        villagers: [
            ["むすめ「父は コタンコロカムイの はねの 話を",
             "　だれかに たくせる ひを まっていたの。」"],
        ],
        chestRewards: [.gold(200)]
    )

    /// 羅臼の 家。
    static let rausuHouse = house(
        .rausuHouse, name: "らうすの いえ",
        rows: [
            "XXXXXXXXX",
            "XQotoLLcX",
            "XoooooooX",
            "XoooooooX",
            "XoooooooX",
            "XXXXdXXXX",
        ],
        town: .rausu, door: Point(x: 18, y: 18),
        villagers: [
            ["おとこ「羅臼岳の ほらあなは 2かいだて。",
             "　守護神の ふぶきは つよい。 HPに よゆうを もて。」"],
        ],
        chestRewards: [.item(.herb)]
    )
}
