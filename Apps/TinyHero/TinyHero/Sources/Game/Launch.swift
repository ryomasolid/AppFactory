import Foundation

/// 起動引数で途中の場面から始める（シミュレータでの表示確認用）。
/// 例: `-startMap field -startX 5 -startY 8 -startFacing left` / `-startBattle guardian -autoAttack YES` / `-startLevel 10`
/// / `-startBattle potato,potato,kelpSlime`（複数体と戦う）
/// / `-startBattle cod -autoCommand fire`（1.5秒後に自動で呪文・道具を使う。attack / heal / fire / highHeal / flame / herb）
/// / `-startHP 20`（HP を減らした状態から。回復の演出や瀕死の表示の確認用）
/// / `-startNaming YES`（名前を決める画面から）
/// / `-grantExp 120`（けいけんちを渡して、レベルアップの表示をすぐ見る）
/// / `-autoInn YES`（宿屋に泊まって、暗転とねむりの演出を見る）
/// / `-startOverlay shop`（menu・status・items・spells・shop・inn のウィンドウを開いた状態）
/// / `-startOverlay shop -shopConfirm herb`（道具屋の「かうかい？」を出した状態）
/// / `-startOverlay items -selectItem copperSword`（どうぐ画面で1つ選んだ状態）
/// / `-startOverlay shop -shopSell YES`（道具屋の「うる」一覧を出した状態）
/// / `-openedChests cave1-0,cave2-0`（開けた宝箱）
@MainActor
enum Launch {
    /// 戦闘で開いておくサブメニュー（`-battleSubmenu spells` / `items`）。表示確認用。
    static var battleSubmenu: String? {
        UserDefaults.standard.string(forKey: "battleSubmenu")
    }

    /// 道具屋で「かうかい？」を出しておく商品（`-shopConfirm herb`）。表示確認用。
    static var shopConfirm: Item? {
        UserDefaults.standard.string(forKey: "shopConfirm").flatMap(Item.init(rawValue:))
    }

    /// 道具屋の「うる」一覧を開いておく（`-shopSell YES`）。表示確認用。
    static var shopSell: Bool {
        UserDefaults.standard.bool(forKey: "shopSell")
    }

    /// どうぐ画面で選んでおく持ちもの（`-selectItem copperSword`）。表示確認用。
    static var selectItem: Item? {
        UserDefaults.standard.string(forKey: "selectItem").flatMap(Item.init(rawValue:))
    }

    static func apply(to game: GameState, defaults: UserDefaults = .standard) {
        // 名前を決める画面は、ほかの指定より先に見る（冒険を始めてしまうと戻れないため）。
        if defaults.bool(forKey: "startNaming") {
            game.beginNaming()
            return
        }
        let mapName = defaults.string(forKey: "startMap")
        let battleName = defaults.string(forKey: "startBattle")
        let level = defaults.integer(forKey: "startLevel")
        let overlayName = defaults.string(forKey: "startOverlay")
        let startHP = defaults.integer(forKey: "startHP")
        let grantExp = defaults.integer(forKey: "grantExp")
        let openedChests = defaults.string(forKey: "openedChests")
        guard mapName != nil || battleName != nil || level > 0 || overlayName != nil
            || openedChests != nil || startHP > 0 || grantExp > 0 else { return }

        game.newGame()
        game.say([])
        if level > 1 {
            _ = game.hero.gainExp(LevelTable.row(level).exp)
            game.hero.restoreFully()
            game.hero.gold = 500
            // 表示確認がしやすいよう、ひととおりの装備を持たせる。
            game.hero.receive(.copperSword)
            game.hero.receive(.leatherArmor)
        }
        if startHP > 0 {
            game.hero.hp = min(startHP, game.hero.maxHP)
        }
        if grantExp > 0 {
            // レベルアップの見た目の確認用。上がったぶんのメッセージをそのまま出す。
            game.say(game.hero.gainExp(grantExp))
            return
        }
        if let mapName, let map = MapID(rawValue: mapName) {
            game.mapID = map
            game.position = Point(x: defaults.integer(forKey: "startX"), y: defaults.integer(forKey: "startY"))
            game.lastMoveWasWarp = true
        }
        if let facing = defaults.string(forKey: "startFacing").flatMap(Direction.init(rawValue:)) {
            game.facing = facing
        }
        if let openedChests {
            game.openedChests = Set(openedChests.split(separator: ",").map(String.init))
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
        if defaults.bool(forKey: "autoInn") {
            // 暗転とねむりの演出の確認用。あいさつを読み飛ばして眠りに入る。
            Task {
                try? await Task.sleep(for: .seconds(1))
                game.stayAtInn()
                try? await Task.sleep(for: .seconds(0.4))
                while game.currentPage != nil { game.advanceMessage() }
            }
        }
        if let battleName {
            // カンマ区切りで複数体（`-startBattle potato,potato,kelpSlime`）。
            let kinds = battleName.split(separator: ",").compactMap { EnemyKind(rawValue: String($0)) }
            guard !kinds.isEmpty else { return }
            game.startBattle(kinds)
            // 動きを撮るため、少し待ってから自動でコマンドを出す。
            let auto = defaults.bool(forKey: "autoAttack")
                ? BattleCommand.attack
                : autoCommand(defaults.string(forKey: "autoCommand"))
            if let auto {
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    await game.command(auto)
                }
            }
        }
    }

    /// `-autoCommand` の文字列を戦闘コマンドに直す。
    static func autoCommand(_ name: String?) -> BattleCommand? {
        guard let name else { return nil }
        if name == "attack" { return .attack }
        if name == "herb" { return .item(.herb) }
        return Spell(rawValue: name).map { .spell($0) }
    }
}
