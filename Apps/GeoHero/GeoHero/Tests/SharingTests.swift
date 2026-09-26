import Foundation
import Testing
@testable import GeoHero

/// 評価の お願いと、シェアする きろくカード。
@MainActor
struct SharingTests {

    private func makeGame(version: String) -> GameState {
        UserDefaults.standard.removeObject(forKey: GameState.reviewKey)
        let game = GameState()
        game.appVersion = version
        game.messageInterval = .zero
        game.beatPause = .zero
        game.waitsForTap = false
        game.newGame()
        game.say([])
        return game
    }

    private func defeat(_ kind: EnemyKind, in game: GameState) async {
        game.startBattle(kind)
        game.battle?.end = .won(exp: 0, gold: 0)
        await game.finishBattle()
        while game.currentPage != nil { game.advanceMessage() }
    }

    /// 駒ヶ岳の ぬしを たおした 話を 読みおえたら 評価を たのむ。同じ バージョンでは 2度 たのまない。
    @Test func asksForReviewOncePerVersion() async {
        let game = makeGame(version: "9.9-test")
        await defeat(.squidLord, in: game)
        #expect(game.reviewRequests == 0, "さいしょの ぬしで たのんでいる（まだ 早い）")
        await defeat(.komaLord, in: game)
        #expect(game.reviewRequests == 1)
        await defeat(.bearLord, in: game)
        #expect(game.reviewRequests == 1, "同じ バージョンで 2度 たのんだ")
        UserDefaults.standard.removeObject(forKey: GameState.reviewKey)
    }

    /// きろくカードは たおした ぬし・スタンプ・いまの地方を 数える。
    @Test func summaryCountsProgress() {
        let game = makeGame(version: "9.9-test")
        game.defeatedBosses = [.squidLord, .komaLord]
        game.readPlaques = Set(World.stampPlaques.prefix(3))
        let summary = game.adventureSummary
        #expect(summary.bosses == 2)
        #expect(summary.bossTotal == 6)
        #expect(summary.stamps == 3)
        #expect(summary.lastBoss == .komaLord)
        #expect(summary.regionName == Region.hakodate.banner.name)
        #expect(summary.message.contains("#地理の勇者"))
        #expect(summary.message.contains(AdventureSummary.storeURL))
        UserDefaults.standard.removeObject(forKey: GameState.reviewKey)
    }
}

/// App Store の アプリ内イベントからの リンク。
@MainActor
struct EventLinkTests {
    @Test func stampRallyLinkShowsNotice() {
        let game = GameState()
        game.open(URL(string: "geohero://stamp-rally")!)
        #expect(game.eventNotice?.joined().contains("スタンプラリー") == true)
        game.dismissEventNotice()
        #expect(game.eventNotice == nil)
    }

    @Test func unknownLinksAreIgnored() {
        let game = GameState()
        game.open(URL(string: "https://example.com/stamp-rally")!)
        #expect(game.eventNotice == nil)
        game.open(URL(string: "geohero://unknown")!)
        #expect(game.eventNotice == nil)
    }
}
