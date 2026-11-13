import Foundation

/// EXP・レベル・連続記録・実績の計算（旧版の usePlayerState と同じ規則）。
enum Leveling {
    static let baseExp = 100

    /// そのレベルから次のレベルまでに要る EXP。
    static func expToNext(level: Int) -> Int {
        Int(Double(baseExp) * pow(1.5, Double(level - 1)))
    }

    /// EXP とゴールドを足してレベルアップを計算する（EXP はブースト倍率がかかる）。
    static func reward(_ state: PlayerState, exp: Int, gold: Int) -> PlayerState {
        var s = state
        var newExp = Double(s.currentExp) + Double(exp) * s.inventory.expBoostMultiplier
        while newExp >= Double(s.expToNextLevel) {
            newExp -= Double(s.expToNextLevel)
            s.level += 1
            s.expToNextLevel = expToNext(level: s.level)
        }
        s.currentExp = Int(newExp)
        s.gold += gold
        return s
    }

    /// 新しく条件を満たした実績を足す。
    static func withAchievements(_ state: PlayerState) -> (PlayerState, [Achievement]) {
        var s = state
        let fresh = Catalog.achievements.filter { !s.unlockedAchievements.contains($0.id) && $0.isMet(s) }
        s.unlockedAchievements += fresh.map(\.id)
        return (s, fresh)
    }

    /// クエスト達成。今日はじめての達成なら連続記録をのばす。
    static func completeQuest(_ state: PlayerState, quest: Quest, today: String) -> PlayerState {
        var s = reward(state, exp: quest.exp, gold: quest.gold)
        s.questsCompleted += 1
        if state.lastActiveDate != today {
            s.streak = state.streak + 1
            s.bestStreak = max(s.streak, state.bestStreak)
            s.lastActiveDate = today
        }
        return s
    }

    /// デーモンの最大 HP（レベルで強くなる）。
    static func demonHp(level: Int) -> Int { 60 + level * 15 }

    /// クエストでデーモンに与えるダメージ。
    static func damage(of quest: Quest) -> Int { quest.exp * 3 }

    /// 討伐ボーナス。
    static func defeatBonus(level: Int) -> (exp: Int, gold: Int) {
        (30 + level * 5, 20 + level * 3)
    }

    static func defeat(_ state: PlayerState) -> PlayerState {
        let bonus = defeatBonus(level: state.level)
        var s = reward(state, exp: bonus.exp, gold: bonus.gold)
        s.demonsDefeated += 1
        return s
    }

    /// 起動時の連続記録の判定。昨日も今日もクエストをしていなければ、フリーズを1つ使って守るか、0 に戻す。
    static func reconcile(_ state: PlayerState, today: String, yesterday: String) -> PlayerState {
        var s = state
        guard let last = s.lastActiveDate, last != today, last != yesterday else { return s }
        if s.inventory.streakFreezes > 0 && s.streak > 0 {
            s.inventory.streakFreezes -= 1
            s.lastActiveDate = yesterday
        } else {
            s.streak = 0
        }
        return s
    }

    /// 買えたら新しい状態、ゴールドが足りなければ nil。
    static func buy(_ item: ShopItem, state: PlayerState) -> PlayerState? {
        guard state.gold >= item.cost else { return nil }
        if item == .expBoost && state.inventory.expBoostMultiplier > 1 { return nil }
        var s = state
        s.gold -= item.cost
        switch item {
        case .expBoost: s.inventory.expBoostMultiplier = 1.5
        case .streakFreeze: s.inventory.streakFreezes += 1
        }
        return s
    }
}

/// 日付のキー（yyyy-MM-dd・端末の暦）。旧版と同じ形。
enum DayString {
    static func of(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func yesterday(of date: Date, calendar: Calendar = .current) -> String {
        of(calendar.date(byAdding: .day, value: -1, to: date) ?? date, calendar: calendar)
    }
}
