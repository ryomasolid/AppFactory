import Foundation

/// 起動引数で途中の場面から始める（シミュレータでの表示確認用）。
/// 例: `-startMap field -startX 5 -startY 8 -startFacing left` / `-startBattle darkDragon` / `-startLevel 10`
@MainActor
enum Launch {
    static func apply(to game: GameState, defaults: UserDefaults = .standard) {
        let mapName = defaults.string(forKey: "startMap")
        let battleName = defaults.string(forKey: "startBattle")
        let level = defaults.integer(forKey: "startLevel")
        guard mapName != nil || battleName != nil || level > 0 else { return }

        game.newGame()
        game.say([])
        if level > 1 {
            _ = game.hero.gainExp(LevelTable.row(level).exp)
            game.hero.restoreFully()
            game.hero.gold = 500
        }
        if let mapName, let map = MapID(rawValue: mapName) {
            game.mapID = map
            game.position = Point(x: defaults.integer(forKey: "startX"), y: defaults.integer(forKey: "startY"))
            game.lastMoveWasWarp = true
        }
        if let facing = defaults.string(forKey: "startFacing").flatMap(Direction.init(rawValue:)) {
            game.facing = facing
        }
        if let battleName, let kind = EnemyKind(rawValue: battleName) {
            game.startBattle(kind)
        }
    }
}
