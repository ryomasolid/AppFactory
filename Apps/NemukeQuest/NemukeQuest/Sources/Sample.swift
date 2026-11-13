import Foundation

/// ストアのスクショ用の見本（起動引数 `-sample`）。端末のデータには触らない。
/// `-tab 1` で実績、`-tab 2` でショップ、`-demon` でデーモン戦の途中から開く。
enum Sample {
    static var isOn: Bool { ProcessInfo.processInfo.arguments.contains("-sample") }

    static var firstTab: DashboardScreen.Tab {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-tab"), i + 1 < args.count else { return .quest }
        return DashboardScreen.Tab(rawValue: Int(args[i + 1]) ?? 0) ?? .quest
    }

    @MainActor
    static func game() -> Game {
        var player = PlayerState()
        player.level = 12
        player.expToNextLevel = Leveling.expToNext(level: 12)
        player.currentExp = Int(Double(player.expToNextLevel) * 0.62)
        player.gold = 340
        player.questsCompleted = 58
        player.streak = 9
        player.bestStreak = 14
        player.lastActiveDate = DayString.of(.now)
        player.demonsDefeated = 7
        player.inventory.streakFreezes = 1
        player = Leveling.withAchievements(player).0
        let game = Game(fileURL: nil, seed: player)
        if ProcessInfo.processInfo.arguments.contains("-demon") {
            game.summonDemon()
            if let demon = game.demon {
                game.demon = Demon(hp: Int(Double(demon.maxHp) * 0.45), maxHp: demon.maxHp)
            }
        }
        return game
    }
}
