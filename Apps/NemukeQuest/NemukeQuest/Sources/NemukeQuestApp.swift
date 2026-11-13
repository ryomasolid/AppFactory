import SwiftUI

@main
struct NemukeQuestApp: App {
    @State private var game: Game = Sample.isOn ? Sample.game() : Game.open()

    var body: some Scene {
        WindowGroup {
            DashboardScreen()
                .environment(game)
                .preferredColorScheme(.dark)
                .tint(Palette.primary)
        }
    }
}

/// デーモンを 3 体以上倒した人にだけ、討伐の OK を押したあとで App Store の評価をお願いする。
/// 一度お願いしたら 100 日はあける（OS 側にも回数制限がある）。
enum ReviewAsk {
    static let minDemons = 3
    static let interval: TimeInterval = 100 * 24 * 60 * 60
    private static let lastKey = "lastReviewRequest"

    static func shouldAsk(demonsDefeated: Int, now: Date = .now, defaults: UserDefaults = .standard) -> Bool {
        guard !Sample.isOn, demonsDefeated >= minDemons else { return false }
        let last = defaults.double(forKey: lastKey)
        return last == 0 || now.timeIntervalSince1970 - last >= interval
    }

    static func markAsked(now: Date = .now, defaults: UserDefaults = .standard) {
        defaults.set(now.timeIntervalSince1970, forKey: lastKey)
    }
}
