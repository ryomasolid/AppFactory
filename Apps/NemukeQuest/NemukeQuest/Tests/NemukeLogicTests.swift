import Foundation
import Testing
@testable import NemukeQuest

private let water = Catalog.quests[0] // 10 EXP / 5 G

struct LevelingTests {
    @Test func 必要EXPは1_5倍ずつ増える() {
        #expect(Leveling.expToNext(level: 1) == 100)
        #expect(Leveling.expToNext(level: 2) == 150)
        #expect(Leveling.expToNext(level: 3) == 225)
    }

    @Test func EXPがあふれるとレベルが上がる() {
        var s = PlayerState()
        s.currentExp = 95
        let next = Leveling.reward(s, exp: 10, gold: 3)
        #expect(next.level == 2)
        #expect(next.currentExp == 5)
        #expect(next.expToNextLevel == 150)
        #expect(next.gold == 3)
    }

    @Test func ブーストで1_5倍() {
        var s = PlayerState()
        s.inventory.expBoostMultiplier = 1.5
        #expect(Leveling.reward(s, exp: 15, gold: 0).currentExp == 22)
    }

    @Test func 同じ日に何回達成しても連続記録は1日ぶん() {
        var s = Leveling.completeQuest(PlayerState(), quest: water, today: "2026-11-13")
        s = Leveling.completeQuest(s, quest: water, today: "2026-11-13")
        #expect(s.streak == 1)
        #expect(s.questsCompleted == 2)
        s = Leveling.completeQuest(s, quest: water, today: "2026-11-14")
        #expect(s.streak == 2)
        #expect(s.bestStreak == 2)
    }

    @Test func 二日あくとフリーズを使って守る() {
        var s = PlayerState()
        s.streak = 5
        s.lastActiveDate = "2026-11-10"
        s.inventory.streakFreezes = 1
        let kept = Leveling.reconcile(s, today: "2026-11-13", yesterday: "2026-11-12")
        #expect(kept.streak == 5)
        #expect(kept.inventory.streakFreezes == 0)
        #expect(kept.lastActiveDate == "2026-11-12")

        s.inventory.streakFreezes = 0
        #expect(Leveling.reconcile(s, today: "2026-11-13", yesterday: "2026-11-12").streak == 0)
    }

    @Test func 昨日やっていれば連続記録はそのまま() {
        var s = PlayerState()
        s.streak = 3
        s.lastActiveDate = "2026-11-12"
        #expect(Leveling.reconcile(s, today: "2026-11-13", yesterday: "2026-11-12").streak == 3)
    }

    @Test func 実績は条件を満たしたぶんだけ解除() {
        var s = PlayerState()
        s.level = 5
        s.demonsDefeated = 1
        let (next, fresh) = Leveling.withAchievements(s)
        #expect(Set(fresh.map(\.id)) == ["LEVEL_5", "DEFEAT_1_DEMON"])
        #expect(Leveling.withAchievements(next).1.isEmpty)
    }

    @Test func ゴールドが足りないと買えない_ブーストは一度だけ() {
        var s = PlayerState()
        s.gold = 100
        #expect(Leveling.buy(.expBoost, state: s) == nil)
        s.gold = 500
        let boosted = Leveling.buy(.expBoost, state: s)
        #expect(boosted?.inventory.expBoostMultiplier == 1.5)
        #expect(boosted?.gold == 300)
        #expect(Leveling.buy(.expBoost, state: boosted!) == nil)
    }
}

@MainActor
struct GameTests {
    @Test func クエストでデーモンを倒すと討伐数が増える() {
        let game = Game(fileURL: nil)
        game.summonDemon()
        #expect(game.demon?.maxHp == 75)
        var defeated = false
        for _ in 0..<5 {
            if case .defeated? = game.complete(Catalog.quests[4])?.0 { defeated = true; break } // 25 EXP → 75 ダメージ
        }
        #expect(defeated)
        #expect(game.demon == nil)
        #expect(game.player.demonsDefeated == 1)
        #expect(game.player.unlockedAchievements.contains("DEFEAT_1_DEMON"))
    }

    @Test func デーモンがいなければクエストできない() {
        let game = Game(fileURL: nil)
        #expect(game.complete(water) == nil)
    }
}

struct LegacyStoreTests {
    @Test func 旧版v2の保存データを読む() throws {
        let inner = #"{"level":7,"currentExp":120,"expToNextLevel":1139,"gold":88,"questsCompleted":31,"unlockedAchievements":["LEVEL_5","STREAK_3"],"streak":4,"bestStreak":6,"lastActiveDate":"2026-11-12","demonsDefeated":5,"inventory":{"expBoostMultiplier":1.5,"streakFreezes":2}}"#
        let manifest = try JSONSerialization.data(withJSONObject: ["@player_state_v2": inner])
        let state = try #require(LegacyStore.parse(manifest: manifest) { _ in nil })
        #expect(state.level == 7)
        #expect(state.gold == 88)
        #expect(state.unlockedAchievements == ["LEVEL_5", "STREAK_3"])
        #expect(state.inventory.streakFreezes == 2)
        #expect(state.inventory.expBoostMultiplier == 1.5)
        #expect(state.lastActiveDate == "2026-11-12")
    }

    @Test func 古いv1の形でも足りない項目は初期値で読む() throws {
        let manifest = try JSONSerialization.data(withJSONObject: ["@player_state": #"{"level":3,"currentExp":40,"expToNextLevel":225}"#])
        let state = try #require(LegacyStore.parse(manifest: manifest) { _ in nil })
        #expect(state.level == 3)
        #expect(state.gold == 0)
        #expect(state.inventory.expBoostMultiplier == 1)
    }

    @Test func 大きな値は別ファイルから読む() {
        let manifest = Data(#"{"@player_state_v2":null}"#.utf8)
        let state = LegacyStore.parse(manifest: manifest) { key in
            key == "@player_state_v2" ? #"{"level":9}"# : nil
        }
        #expect(state?.level == 9)
    }
}
