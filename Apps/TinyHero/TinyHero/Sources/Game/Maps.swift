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
        }
    }

    /// 全滅したときに戻る場所（村の入口）。
    static let revivePoint = (map: MapID.village, point: Point(x: 7, y: 11))

    static let village = GameMap(
        id: .village,
        name: "はじまりの村",
        rows: [
            "###############",
            "#_____________#",
            "#_HHH_____HHH_#",
            "#_HHH_____HHH_#",
            "#__i_______s__#",
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
            Point(x: 6, y: 12): Warp(to: .field, at: Point(x: 4, y: 8)),
            Point(x: 7, y: 12): Warp(to: .field, at: Point(x: 4, y: 8)),
            Point(x: 8, y: 12): Warp(to: .field, at: Point(x: 4, y: 8)),
        ],
        villagers: [
            ["むすめ「どうくつは 川の むこう、", "きたの おかの おくに あるそうよ。", "はしを わたって すすんでね。」"],
            ["おとこ「レベルが ひくいうちは", "村の ちかくの くさはらで きたえるといい。", "もりや おかには つよい まものが でるぞ。」"],
        ]
    )

    static let field = GameMap(
        id: .field,
        name: "ひろの",
        rows: [
            "~~~~~~~~~~~~~~~~~~~~~~~~",
            "~MMMMMMMMMMMMMMMMMMMMMM~",
            "~M.......~~.hhhhhhhhhhM~",
            "~M..ff...~~.hhhhMMMhhhM~",
            "~M.fff...~~.hhhhMChhhhM~",
            "~M..f....~~..hhhhhhhhMM~",
            "~M.......~~...fff.hhhMM~",
            "~M..T====bb===ffff..MMM~",
            "~M.......~~...fff.....M~",
            "~M..ff...~~.....ffff..M~",
            "~M.ffff..~~....ffffff.M~",
            "~M..ff...~~.....fff...M~",
            "~MM......~~..........MM~",
            "~~MMMMMMMMMMMMMMMMMMMM~~",
        ],
        outside: .water,
        warps: [
            Point(x: 4, y: 7): Warp(to: .village, at: Point(x: 7, y: 11)),
            Point(x: 17, y: 4): Warp(to: .cave1, at: Point(x: 6, y: 11)),
        ],
        encounters: [
            .grass: [.bigRat, .mushroom, .bat],
            .forest: [.bat, .wolf, .mushroom],
            .hills: [.wolf, .goblin],
        ]
    )

    static let cave1 = GameMap(
        id: .cave1,
        name: "ヤミのどうくつ B1",
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
            Point(x: 7, y: 11): Warp(to: .field, at: Point(x: 17, y: 5)),
            Point(x: 3, y: 9): Warp(to: .cave2, at: Point(x: 6, y: 9)),
        ],
        chestRewards: [.gold(150)],
        encounters: [
            .caveFloor: [.goblin, .bat, .skeleton],
        ]
    )

    static let cave2 = GameMap(
        id: .cave2,
        name: "ヤミのどうくつ B2",
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
            .caveFloor: [.skeleton, .golem, .goblin],
        ]
    )
}
