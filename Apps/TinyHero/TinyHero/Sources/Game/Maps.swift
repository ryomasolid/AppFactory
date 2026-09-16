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
            "#__t________~~#",
            "#_____e_____~~#",
            "#___________~~#",
            "#_____________#",
            "#________t____#",
            "#_____________#",
            "######EEE######"
        ],
        outside: .wall,
        warps: [
            // 左の家（青い屋根・ベッドの看板）が宿屋、右の家（緑の屋根・お金のふくろ）が道具屋。
            Point(x: 3, y: 4): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 4): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 6, y: 12): Warp(to: .field, at: Point(x: 8, y: 19)),
            Point(x: 7, y: 12): Warp(to: .field, at: Point(x: 8, y: 19)),
            Point(x: 8, y: 12): Warp(to: .field, at: Point(x: 8, y: 19)),
        ],
        villagers: [
            ["むすめ「まおうの てさきが 函館山に すみついて、", "みなとに イカが よりつかなくなったの。」"],
            ["おとこ「まずは 村の まわりの くさはらで", "レベルを あげるといい。」"]
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
            "#_____www_____#",
            "#_____www__t__#",
            "#_____www_____#",
            "#__e__________#",
            "#_____________#",
            "#___t_________#",
            "#_____________#",
            "######EEE######"
        ],
        outside: .wall,
        warps: [
            // 左の家（青い屋根・ベッドの看板）が宿屋、右の家（緑の屋根・お金のふくろ）が道具屋。
            Point(x: 3, y: 4): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 4): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 6, y: 12): Warp(to: .field, at: Point(x: 8, y: 10)),
            Point(x: 7, y: 12): Warp(to: .field, at: Point(x: 8, y: 10)),
            Point(x: 8, y: 12): Warp(to: .field, at: Point(x: 8, y: 10)),
        ],
        villagers: [
            ["むすめ「藻岩山の ほらあなから", "うなり声が きこえるのよ。」"],
            ["おとこ「北東の 知床まで 街道が つづいている。", "おかには つよい まものが でるぞ。」"]
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
            "#M___t_______M#",
            "#M___________M#",
            "#______e_____M#",
            "#_____________#",
            "#MM______t___M#",
            "#M___________M#",
            "######EEE######"
        ],
        outside: .wall,
        warps: [
            // 左の家（青い屋根・ベッドの看板）が宿屋、右の家（緑の屋根・お金のふくろ）が道具屋。
            Point(x: 3, y: 4): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 4): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 6, y: 12): Warp(to: .field, at: Point(x: 26, y: 6)),
            Point(x: 7, y: 12): Warp(to: .field, at: Point(x: 26, y: 6)),
            Point(x: 8, y: 12): Warp(to: .field, at: Point(x: 26, y: 6)),
        ],
        villagers: [
            ["むすめ「羅臼岳の おくに 守護神さまが……", "でも いまは まおうの ものなの。」"],
            ["おとこ「ここが さいごの街だ。", "そうびを ととのえて いくといい。」"]
        ]
    )

    static let hakodateyama = GameMap(
        id: .hakodateyama,
        name: "函館山の ほらあな",
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
            "#,#B,,,#,,,,,,#",
            "#,######,####,#",
            "#,,,,,,U,,,,,,#",
            "###############"
        ],
        outside: .wall,
        warps: [
            Point(x: 7, y: 11): Warp(to: .field, at: Point(x: 11, y: 18)),
        ],
        chestRewards: [.gold(120)],
        bossKind: .squidLord,
        encounters: [
            .caveFloor: [.potato, .kelpSlime, .scallop],
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
            Point(x: 7, y: 11): Warp(to: .field, at: Point(x: 6, y: 12)),
            Point(x: 3, y: 9): Warp(to: .moiwa2, at: Point(x: 6, y: 9)),
        ],
        chestRewards: [.item(.copperSword)],
        encounters: [
            .caveFloor: [.scallop, .fox],
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
            .caveFloor: [.fox, .cod],
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
            Point(x: 7, y: 11): Warp(to: .field, at: Point(x: 29, y: 3)),
            Point(x: 3, y: 9): Warp(to: .rausudake2, at: Point(x: 6, y: 9)),
        ],
        chestRewards: [.item(.steelSword)],
        encounters: [
            .caveFloor: [.cod, .snowman],
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
            .caveFloor: [.snowman, .iceGolem],
        ],
        markerFloor: .caveFloor
    )

    static let field = GameMap(
        id: .field,
        name: "ほっかいどう",
        // 北海道のかたち。南西の渡島半島から入り、北東の知床半島へ向かう。
        rows: [
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~hh.~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~==Chh~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~.hh==hh~~~~~~",
            "~~~~~~~~~...........chhhhh=hh~~~~~~~",
            "~~~~~~..====~=============Thh~~~~~~~",
            "~~~~~..f=ff.~...MMMM.hhhhhhhhh~~~~~~",
            "~~~~...f=ff.~...MMMM.hhhhhhhhh.~~~~~",
            "~~~....f=ff.~.MM.....hhhhhhhhh..~~~~",
            "~~~.....T=....MM....MM.........c.~~~",
            "~~~~....==..~.......MM..........~~~~",
            "~~~~~.C===..~..................~~~~~",
            "~~~~~~...=ff~....fffff.......~~~~~~~",
            "~~~~~~~..=fff....fffff.....~~~~~~~~~",
            "~~~~~~~~.=fff....fffff..~~~~~~~~~~~~",
            "~~~~~~~~~=.fff......~~~~~~~~~~~~~~~~",
            "~~~~~~~~~=.fff..~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~==C..~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~.=..~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~..T.~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~.c.~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ],
        outside: .water,
        warps: [
            Point(x: 9, y: 19): Warp(to: .hakodate, at: Point(x: 7, y: 11)),
            Point(x: 8, y: 9): Warp(to: .sapporo, at: Point(x: 7, y: 11)),
            Point(x: 26, y: 5): Warp(to: .rausu, at: Point(x: 7, y: 11)),
            // ほらあなは順番に開く。前のボスを倒すまで入れない。
            Point(x: 11, y: 17): Warp(to: .hakodateyama, at: Point(x: 6, y: 11)),
            Point(x: 6, y: 11): Warp(to: .moiwa1, at: Point(x: 6, y: 11), requires: .squidLord),
            Point(x: 29, y: 2): Warp(to: .rausudake1, at: Point(x: 6, y: 11), requires: .bearLord),
        ],
        chestRewards: [.item(.herb), .gold(120), .item(.leatherArmor)],
        encounters: [
            .grass: [.potato, .kelpSlime, .scallop],
            .forest: [.scallop, .fox],
            .hills: [.fox, .cod],
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
