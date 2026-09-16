import Foundation

/// ゲームの全マップ。村 → 野原 → 洞窟B1 → 洞窟B2（ボス）の1本道。
/// ワープの到着点はワープ床の隣に置く（到着した瞬間にまた飛ばないように）。
enum World {
    static let startMap: MapID = .village
    static let startPoint = Point(x: 7, y: 9)

    static func map(_ id: MapID) -> GameMap {
        switch id {
        case .village: village
        case .field: field
        case .cave1: cave1
        case .cave2: cave2
        case .innInside: innInside
        case .shopInside: shopInside
        }
    }

    /// 全滅したときに戻る場所（村の入口）。
    static let revivePoint = (map: MapID.village, point: Point(x: 7, y: 11))

    static let village = GameMap(
        id: .village,
        name: "さっぽろの村",
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
            "######EEE######",
        ],
        outside: .wall,
        warps: [
            // 左の家（青い屋根・ベッドの看板）が宿屋、右の家（緑の屋根・お金のふくろ）が道具屋。
            Point(x: 3, y: 4): Warp(to: .innInside, at: Point(x: 4, y: 4)),
            Point(x: 11, y: 4): Warp(to: .shopInside, at: Point(x: 4, y: 4)),
            Point(x: 6, y: 12): Warp(to: .field, at: Point(x: 5, y: 12)),
            Point(x: 7, y: 12): Warp(to: .field, at: Point(x: 5, y: 12)),
            Point(x: 8, y: 12): Warp(to: .field, at: Point(x: 5, y: 12)),
        ],
        villagers: [
            ["むすめ「守護神の ほらあなは 川の むこう、", "きたの おかの おくに あるそうよ。", "はしを わたって すすんでね。」"],
            ["おとこ「レベルが ひくいうちは", "村の ちかくの くさはらで きたえるといい。", "もりや おかには つよい まものが でるぞ。」"],
        ]
    )

    /// 宿屋の中。主人はカウンターの奥にいて、カウンターの前から話しかける。
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
            Point(x: 4, y: 5): Warp(to: .village, at: Point(x: 3, y: 5)),
        ],
        markerFloor: .woodFloor
    )

    /// 道具屋の中。商品棚の前に主人が立ち、カウンター越しに買い物をする。
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
            Point(x: 4, y: 5): Warp(to: .village, at: Point(x: 11, y: 5)),
        ],
        markerFloor: .woodFloor
    )

    static let field = GameMap(
        id: .field,
        name: "いしかりの野",
        rows: [
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
            "~MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM~",
            "~M...........~~....hhhhhhhhhhhhhhhM~",
            "~M...........~~....hhhhhhMMMhhhhhhM~",
            "~M..ffff.....~~....hhhhhhMCMhhhhhhM~",
            "~M..ffff.....~~....hhhhhhhhhhhMMhhM~",
            "~M..ffff.....~~....hhhhhhhhhhhMMhhM~",
            "~M...........~~....hhhhhhhhhhhhhhhM~",
            "~M......ff...~~.......hhhhhhhhhhhhM~",
            "~M......ff...~~.......hhhhhhhhhhhhM~",
            "~M...........~~...................M~",
            "~M...T=======bb======.....fffff...M~",
            "~M...........~~...........fffff...M~",
            "~M...........~~...fffffff.fffff...M~",
            "~M.ffff......~~...fffffff.fffff...M~",
            "~M.ffff......~~...fffffff.........M~",
            "~M.ffff......~~...fffffff.........M~",
            "~M.ffff...MMM~~...fffffff......MMMM~",
            "~M........MMM~~................MMMM~",
            "~M...........~~...................M~",
            "~MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM~",
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
        ],
        outside: .water,
        warps: [
            Point(x: 5, y: 11): Warp(to: .village, at: Point(x: 7, y: 11)),
            Point(x: 26, y: 4): Warp(to: .cave1, at: Point(x: 6, y: 11)),
        ],
        // 1つのエリアに強さの違う敵を混ぜすぎない。
        // 経験値のはしご: くさち 2〜4 → もり 4〜9 → おか 9〜14 → ほらあな1 14〜22 → ほらあな2 22〜35。
        // となりのエリアと1種だけ重ねて、進んだ実感と地続き感を両立させる。
        encounters: [
            .grass: [.potato, .kelpSlime, .scallop],
            .forest: [.scallop, .fox],
            .hills: [.fox, .cod],
        ]
    )

    static let cave1 = GameMap(
        id: .cave1,
        name: "知床のほらあな B1",
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
            "###############",
        ],
        outside: .wall,
        warps: [
            Point(x: 7, y: 11): Warp(to: .field, at: Point(x: 26, y: 5)),
            Point(x: 3, y: 9): Warp(to: .cave2, at: Point(x: 6, y: 9)),
        ],
        chestRewards: [.gold(150)],
        encounters: [
            .caveFloor: [.cod, .snowman],
        ]
    )

    static let cave2 = GameMap(
        id: .cave2,
        name: "知床のほらあな B2",
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
            "#############",
        ],
        outside: .wall,
        warps: [
            Point(x: 5, y: 9): Warp(to: .cave1, at: Point(x: 4, y: 9)),
        ],
        chestRewards: [.item(.steelSword)],
        encounters: [
            .caveFloor: [.snowman, .iceGolem],
        ]
    )
}
