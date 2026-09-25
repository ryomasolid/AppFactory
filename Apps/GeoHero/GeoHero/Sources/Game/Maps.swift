import Foundation

/// ゲームの全マップ。
/// 函館 → 函館山 → 札幌 → 藻岩山 → 知床 → 羅臼岳 と、街とほらあなを3度くりかえす。
/// ワープの到着点はワープ床の隣に置く（到着した瞬間にまた飛ばないように）。
enum World {
    static let startMap: MapID = .hakodate
    static let startPoint = Point(x: 7, y: 9)

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
    static let revivePoint = (map: MapID.hakodate, point: Point(x: 7, y: 11))

    static let hakodate = GameMap(
        id: .hakodate,
        name: "はこだて",
        rows: [
            "###############",
            "#____________~#",
            "#_III_____SSS~#",
            "#_III_____SSS~#",
            "#_YdW_____ZdW~#",
            "#___________~~#",
            "#__t______t_~~#",
            "#_____e_____~~#",
            "#__________t~~#",
            "#_____________#",
            "#________t____#",
            "#____P________#",
            "######EEE######"
        ],
        // 壁の外は草原。出口のすきまの先に野原が見えて、外へ抜ける道だと分かる。
        outside: .grass,
        warps: [
            // 左の家（青い屋根・ベッドの看板）が宿屋、右の家（緑の屋根・お金のふくろ）が道具屋。
            Point(x: 3, y: 4): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 4): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 6, y: 12): Warp(to: .field, at: Point(x: 16, y: 35)),
            Point(x: 7, y: 12): Warp(to: .field, at: Point(x: 16, y: 35)),
            Point(x: 8, y: 12): Warp(to: .field, at: Point(x: 16, y: 35)),
        ],
        // 戦闘の「ちしき」の答えは ここで聞ける（`QuizRegion.hakodate` と `QuizTests` を見る）。
        villagers: [
            ["むすめ「函館山の ほらあなに イカのぬしが すみついたの。",
             "　山から 見る やけいが じまんだったのに……」"],
            ["おとこ「ここは 渡島半島の さきの みなとまち。",
             "　星のかたちの 城あと 五稜郭も 見ていきな。」"],
            ["ふなのり「この みなとは 津軽海峡に めんしてる。",
             "　むかしは 青函連絡船で 青森へ わたったもんさ。」"],
            ["こども「みなとに イカが よりつかなくなっちゃった。",
             "　イカは 函館の 市の さかな なのに！」"]
        ]
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
            Point(x: 16, y: 34): Warp(to: .hakodate, at: Point(x: 7, y: 11)),
            Point(x: 14, y: 16): Warp(to: .sapporo, at: Point(x: 7, y: 11)),
            Point(x: 46, y: 9): Warp(to: .rausu, at: Point(x: 7, y: 11)),
            // ほらあなは順番に開く。前のボスを倒すまで入れない。
            Point(x: 33, y: 28): Warp(to: .hakodateyama, at: Point(x: 6, y: 11)),
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
            // 出口の行き先は 入ってきた街に差し替わる（GameState が見る）。
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
