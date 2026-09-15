import Foundation
import Testing
@testable import TinyHero

/// 画面から触る流れ（歩く・話す・買う・戦う・全滅）を GameState 単位で通す。
@MainActor
struct GameStateTests {

    private func makeGame() -> GameState {
        let game = GameState()
        game.stepDuration = .zero
        game.messageInterval = .zero
        game.beatPause = .zero
        game.waitsForTap = false
        game.rng = AnyRandomSource(SeededRandomSource(seed: 42))
        game.newGame()
        game.say([])
        return game
    }

    @Test func newGameShowsIntroAndBlocksWalking() {
        let game = GameState()
        game.newGame()
        #expect(game.currentPage != nil)
        #expect(!game.canWalk)
        while game.currentPage != nil { game.advanceMessage() }
        #expect(game.canWalk)
    }

    @Test func walkOutOfVillageToField() async {
        let game = makeGame()
        for _ in 0..<3 { await game.walk(.down) }
        #expect(game.mapID == .field)
        #expect(game.position == Point(x: 4, y: 8))
    }

    @Test func wallsBlockButTurn() async {
        let game = makeGame()
        game.position = Point(x: 1, y: 1)
        await game.walk(.up)
        #expect(game.position == Point(x: 1, y: 1))
        #expect(game.facing == .up)
    }

    @Test func holdingWalksUntilWallAndReleaseStops() async throws {
        let game = makeGame()
        game.hold(.left)
        try await Task.sleep(for: .milliseconds(200))
        #expect(game.position == Point(x: 1, y: World.startPoint.y))
        game.hold(nil)
        #expect(game.heldDirection == nil)
    }

    /// 右を押したまま戦闘に入っても、戦闘後に勝手に右へ歩き出さない（不具合の再発防止）。
    @Test func battleReleasesHeldDirection() async throws {
        let game = makeGame()
        game.hero.receive(.steelSword)
        game.mapID = .field
        game.position = Point(x: 3, y: 8)
        game.hold(.right)
        game.startBattle(.bigRat)
        #expect(game.heldDirection == nil)
        for _ in 0..<10 where game.battle?.end == nil {
            await game.command(.attack)
        }
        game.finishBattle()
        try await Task.sleep(for: .milliseconds(200))
        #expect(game.position == Point(x: 3, y: 8))

        game.hold(.left)
        try await Task.sleep(for: .milliseconds(50))
        game.hold(nil)
        #expect(game.position.x < 3)
    }

    @Test func shopkeeperSellsHerb() {
        let game = makeGame()
        game.position = Point(x: 11, y: 5)
        game.facing = .up
        game.pressA()
        #expect(game.overlay == .shop)
        game.buy(.herb)
        #expect(game.hero.gold == 12)
        #expect(game.hero.herbCount == 3)
    }

    @Test func chestOpensOnlyOnce() {
        let game = makeGame()
        game.mapID = .cave1
        game.position = Point(x: 8, y: 4)
        game.facing = .up
        game.pressA()
        #expect(game.hero.gold == 170)
        while game.currentPage != nil { game.advanceMessage() }
        game.pressA()
        #expect(game.hero.gold == 170)
    }

    @Test func winningBattleReturnsToField() async {
        let game = makeGame()
        game.hero.receive(.steelSword)
        game.startBattle(.bigRat)
        #expect(game.screen == .battle)
        for _ in 0..<10 where game.battle?.end == nil {
            await game.command(.attack)
        }
        #expect(game.battle?.end == .won(exp: 2, gold: 3))
        game.finishBattle()
        #expect(game.screen == .field)
        #expect(game.hero.gold == 23)
        #expect(game.hero.exp == 2)
    }

    /// 攻撃が当たるたびに「何発目か・ダメージ・会心か」が更新され、画面の動きのきっかけになる。
    @Test func enemyHitIsRecordedForEachDamagingLine() async {
        let game = makeGame()
        _ = game.hero.gainExp(LevelTable.row(5).exp)
        game.startBattle(.golem)
        #expect(game.battle?.enemyHit == nil)
        var lastID = 0
        for _ in 0..<6 where game.battle?.end == nil {
            let hpBefore = game.battle?.battle.enemy.hp ?? 0
            await game.command(.attack)
            let hpAfter = game.battle?.battle.enemy.hp ?? 0
            if hpAfter < hpBefore {
                let hit = try? #require(game.battle?.enemyHit)
                #expect(hit?.damage == hpBefore - hpAfter)
                #expect((hit?.id ?? 0) > lastID)
                lastID = hit?.id ?? lastID
            }
        }
        #expect(lastID > 0)
    }

    /// 経験値のページでは ▼ を出してタップを待ち、タップすると先へ進む。
    @Test func rewardPageWaitsForTap() async throws {
        let game = makeGame()
        game.waitsForTap = true
        game.hero.receive(.steelSword)
        game.startBattle(.bigRat)
        let turn = Task { await game.command(.attack) }
        for _ in 0..<100 where game.battle?.waitingForTap != true {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(game.battle?.waitingForTap == true)
        #expect(game.battle?.isPlaying == true)
        #expect(game.battle?.enemyDefeated == true)
        game.advanceBattleMessage()
        await turn.value
        #expect(game.battle?.waitingForTap == false)
        #expect(game.battle?.end == .won(exp: 2, gold: 3))
    }

    @Test func losingRevivesInVillageWithHalfGold() async {
        let game = makeGame()
        game.hero.gold = 100
        game.mapID = .cave2
        game.startBattle(.darkDragon)
        for _ in 0..<30 where game.battle?.end == nil {
            await game.command(.attack)
        }
        #expect(game.battle?.end == .lost)
        game.finishBattle()
        #expect(game.screen == .field)
        #expect(game.mapID == .village)
        #expect(game.hero.gold == 50)
        #expect(game.hero.hp == game.hero.maxHP)
    }
}
