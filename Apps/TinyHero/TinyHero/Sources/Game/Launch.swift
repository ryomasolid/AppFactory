import Foundation

/// 起動引数で途中の場面から始める（シミュレータでの表示確認用）。
/// 例: `-startMap field -startX 5 -startY 8 -startFacing left` / `-startBattle darkDragon -autoAttack YES` / `-startLevel 10`
/// / `-startOverlay shop`（menu・status・items・spells・shop・inn のウィンドウを開いた状態）
@MainActor
enum Launch {
    /// 戦闘で開いておくサブメニュー（`-battleSubmenu spells` / `items`）。表示確認用。
    static var battleSubmenu: String? {
        UserDefaults.standard.string(forKey: "battleSubmenu")
    }

    static func apply(to game: GameState, defaults: UserDefaults = .standard) {
        let mapName = defaults.string(forKey: "startMap")
        let battleName = defaults.string(forKey: "startBattle")
        let level = defaults.integer(forKey: "startLevel")
        let overlayName = defaults.string(forKey: "startOverlay")
        guard mapName != nil || battleName != nil || level > 0 || overlayName != nil else { return }

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
        switch overlayName {
        case "menu": game.overlay = .menu
        case "status": game.overlay = .status
        case "items": game.overlay = .items
        case "spells": game.overlay = .spells
        case "shop": game.overlay = .shop
        case "inn": game.overlay = .inn
        default: break
        }
        if let battleName, let kind = EnemyKind(rawValue: battleName) {
            game.startBattle(kind)
            // 攻撃の動きを撮るため、少し待ってから自動でこうげきする。
            if defaults.bool(forKey: "autoAttack") {
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    await game.command(.attack)
                }
            }
        }
    }
}
