import Foundation

/// ゲームの全マップ。
/// 函館 → 函館山 → 札幌 → 藻岩山 → 知床 → 羅臼岳 と、街とほらあなを3度くりかえす。
/// ワープの到着点はワープ床の隣に置く（到着した瞬間にまた飛ばないように）。
enum World {
    static let startMap: MapID = .hakodate
    /// 長老の すぐ下。
    static let startPoint = Point(x: 18, y: 18)

    static func map(_ id: MapID) -> GameMap {
        switch id {
        case .field: field
        case .hakodate: hakodate
        case .sapporo: sapporo
        case .rausu: rausu
        case .hakodateyama: hakodateyama
        case .moiwa1: moiwa1
        case .moiwa2: moiwa2
        case .rausudake1: rausudake1
        case .rausudake2: rausudake2
        case .innInside: innInside
        case .shopInside: shopInside
        }
    }

    /// 全滅したときに戻る場所。いちばん近い街ではなく、最初の街の入口にそろえる。
    static let revivePoint = (map: MapID.hakodate, point: Point(x: 15, y: 24))

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
            "#~~WWW_WWW_________~~~~___~~~~#",
            "#~~___P____26_______~_______~_#",
            "#~~__________________~_HHH_~__#",
            "#~~___t______________~_WdW_~__#",
            "#~~___________ff_____~__1__~__#",
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
            "#MMMMMMM_____P________________#",
            "##############EEE##############"
        ],
        // 壁の外は草原。出口のすきまの先に野原が見えて、外へ抜ける道だと分かる。
        outside: .grass,
        warps: [
            // 左の家（青い屋根・ベッドの看板）が宿屋、右の家（緑の屋根・お金のふくろ）が道具屋。
            Point(x: 14, y: 16): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 20, y: 16): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 14, y: 25): Warp(to: .field, at: Point(x: 16, y: 35)),
            Point(x: 15, y: 25): Warp(to: .field, at: Point(x: 16, y: 35)),
            Point(x: 16, y: 25): Warp(to: .field, at: Point(x: 16, y: 35)),
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
        residents: ["1": .magistrate, "2": .mother, "3": .fisherBoss, "4": .portKid, "5": .lostChild, "6": .childAtHome],
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
            "#WW_______e_WW#",
            "#_t_________t_#",
            "#___t______t__#",
            "#____P________#",
            "######EEE######"
        ],
        // 壁の外は草原。出口のすきまの先に野原が見えて、外へ抜ける道だと分かる。
        outside: .grass,
        warps: [
            // 左の家（青い屋根・ベッドの看板）が宿屋、右の家（緑の屋根・お金のふくろ）が道具屋。
            Point(x: 3, y: 4): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 4): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 6, y: 12): Warp(to: .field, at: Point(x: 14, y: 17)),
            Point(x: 7, y: 12): Warp(to: .field, at: Point(x: 14, y: 17)),
            Point(x: 8, y: 12): Warp(to: .field, at: Point(x: 14, y: 17)),
        ],
        // 戦闘の「ちしき」の答えは ここで聞ける（`QuizRegion.sapporo` と `QuizTests` を見る）。
        villagers: [
            ["むすめ「ここは いちばん 大きな街。",
             "　冬の 雪まつりには ひとで いっぱいよ。」"],
            ["しょうにん「はがねの剣は この街でしか 買えないよ。",
             "　帰りに 名物の みそラーメンも 食べていきな。」"],
            ["ろうじん「イカのぬしを たおさぬと 藻岩山へは 入れぬ。",
             "　むかし クラーク博士が いうたものじゃ。",
             "　『少年よ 大志を いだけ』とな。」"],
            ["おとこ「北の 藻岩山に ヒグマのぬしが すんでいるらしい。",
             "　あの山から 見る 札幌の 夜景は きれいなのにな。」"],
            ["こども「ひろばの ふん水、つめたくて きもちいいよ。",
             "　大通公園の ふん水は もっと 大きいんだって！」"],
            ["たびびと「白い 時計台の かねの音を きいたかい？",
             "　札幌の まちの しるしだよ。」"]
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
            Point(x: 6, y: 12): Warp(to: .field, at: Point(x: 46, y: 10)),
            Point(x: 7, y: 12): Warp(to: .field, at: Point(x: 46, y: 10)),
            Point(x: 8, y: 12): Warp(to: .field, at: Point(x: 46, y: 10)),
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
            Point(x: 7, y: 11): Warp(to: .field, at: Point(x: 33, y: 29)),
        ],
        chestRewards: [.gold(120)],
        bossKind: .squidLord,
        encounters: [
            .caveFloor: [.nightBat, .hairyCrab, .brickGolem],
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
            Point(x: 7, y: 11): Warp(to: .field, at: Point(x: 26, y: 9)),
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
            Point(x: 7, y: 11): Warp(to: .field, at: Point(x: 59, y: 3)),
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

    static let field = GameMap(
        id: .field,
        name: "ほっかいどう",
        // 北海道のかたち。65×40 マス。南西の渡島半島から入り、北東の知床半島へ向かう。
        // 街どうしは 20〜40歩 はなしてある（近いと すぐ着いてしまうため）。
        rows: [
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~hhhhC~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~h====~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~hhhhhhf=f~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~========f~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~hfff====hhhhh~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~hff==hhhhMfhh~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~hhhhff...C==========hchhhhhf=hhhhMMf~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~hhhf======ffffffffM==fhhhhfh=ThhhhMf~~~~~~~~~~~~",
            "~~~~~~~~~~~fffffffMff=~~.fffffffffMMM==========hhhhff~~~~~~~~~~~~",
            "~~~~~~~~~~fffffffMMMf=~~fffffffffffMfffMhhMMfhhhhhhhfhh~~~~~~~~~~",
            "~~~~~~~~~~ffffff..Mff=~~ffffffffffffffMMMhMMMhhhhhhhhhh~~~~~~~~~~",
            "~~~~~~~~fffffff...ff==~~ffffff.fffffhfMMMMhMMMhhhfhhhhhh~~~~~~~~~",
            "~~~~~~~~fffffff..====.~~fffff...fffhhhfMMMfhM.hhfffhhhhh~~~~~~~~~",
            "~~~~~~ffff.....f==....~~ffffff..fffhhhhfMfhh.hhhfffhhhhhhh~~~~~~~",
            "~~~~~~ff......Tf=.....~~ffffff.fffffhhhfffhhhfhhhfhhhhhhhc~~~~~~~",
            "~~~~~~f.......===.......ffffffffffffffhfffhhhffhhhhhhhhhhhhh~~~~~",
            "~~~~~~ffff..ff=......ffffffffffffffffffhhhffffffhfhhhhhhhhhh~~~~~",
            "~~~~~~~~f...ff=......f~~.ffffffffffffffMhhffffffffffh.hhhh~~~~~~~",
            "~~~~~~~~~~..f.=......f~~..fffffffffhffMMMhffffffMfff...h~~~~~~~~~",
            "~~~~~~~~~~ff..==......~~......ffffhhhffMfffhffhMMMhh...h~~~~~~~~~",
            "~~~~~~~~~~~....===....~~......ffffhhhfffffhhhfhhMhhhh~~~~~~~~~~~~",
            "~~~~~~~~~~~......=....~~......fhfffhffffffhhhfhfhhhhh~~~~~~~~~~~~",
            "~~~~~~~~~~~~~....=............hhhffffffffffhfhhhf~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~....=.M..........hhh.fffffffffffhhhf~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~..=MMM.........fhf..fffffffff~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~..=.M.............fffffffffff~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~=...............Cfff~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~=================fff~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~=...........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~=........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~=........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~..=....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~.T=....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~...=...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~.......~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~c.....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~......~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ],
        outside: .water,
        warps: [
            Point(x: 16, y: 34): Warp(to: .hakodate, at: Point(x: 15, y: 24)),
            Point(x: 14, y: 16): Warp(to: .sapporo, at: Point(x: 7, y: 11)),
            Point(x: 46, y: 9): Warp(to: .rausu, at: Point(x: 7, y: 11)),
            // ほらあなは順番に開く。前のボスを倒すまで入れない。
            // 函館山だけは ボスではなく、奉行の てがたで ひらく（`StoryFlag.hakodateyamaPass`）。
            Point(x: 33, y: 28): Warp(to: .hakodateyama, at: Point(x: 6, y: 11), needs: .hakodateyamaPass),
            Point(x: 26, y: 8): Warp(to: .moiwa1, at: Point(x: 6, y: 11), requires: .squidLord),
            Point(x: 59, y: 2): Warp(to: .rausudake1, at: Point(x: 6, y: 11), requires: .bearLord),
        ],
        chestRewards: [.item(.herb), .gold(120), .item(.leatherArmor)],
        // 目印ごとの区域。旅の順に ひとつずつ強くなり、出る敵は 場所ごとに ぜんぶ ちがう。
        // 入れる ほらあなより フィールドが強くならないようにそろえてある。
        encounterAreas: [
            EncounterArea(name: "函館のまわり", around: [Point(x: 16, y: 34)],
                          enemies: [.potato, .kelpSlime, .seagull]),
            EncounterArea(name: "函館山のふもと", around: [Point(x: 33, y: 28)],
                          enemies: [.squidKid, .scallop, .squidRice]),
            // 中の海でへだてられているので、渡れる陸つづき（27,18）にも中心を置く。
            // ここを 藻岩山の区域に取られると、札幌へ戻る道だけ 急に強くなってしまう。
            EncounterArea(name: "札幌へむかう道", around: [Point(x: 14, y: 16), Point(x: 27, y: 18)],
                          enemies: [.cornSoldier, .ramenGhost, .lambSheep]),
            EncounterArea(name: "藻岩山へむかう道", around: [Point(x: 26, y: 8)],
                          enemies: [.squirrel, .fox, .snowFestival]),
            EncounterArea(name: "知床へむかう道", around: [Point(x: 46, y: 9)],
                          enemies: [.deer, .cod, .salmon]),
            EncounterArea(name: "羅臼岳へむかう道", around: [Point(x: 59, y: 2)],
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
}
