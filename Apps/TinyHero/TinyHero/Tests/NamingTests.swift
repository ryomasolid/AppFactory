import Foundation
import Testing
@testable import TinyHero

/// 勇者の名前を決める流れ。
@MainActor
struct NamingTests {

    /// すべての語りを読み切って、1つの文字列にまとめる。
    private func readAll(_ game: GameState) -> String {
        var lines: [String] = []
        while let page = game.currentPage {
            lines += page
            game.advanceMessage()
        }
        return lines.joined(separator: "\n")
    }

    @Test func defaultNameIsSora() {
        #expect(Hero.defaultName == "そら")
        #expect(Hero().name == "そら")
    }

    @Test func titleGoesToNamingBeforeTheAdventure() {
        let game = GameState()
        #expect(game.screen == .title)
        game.beginNaming()
        #expect(game.screen == .naming)
    }

    @Test func chosenNameIsKept() {
        let game = GameState()
        game.newGame(name: "ひかり")
        #expect(game.hero.name == "ひかり")
    }

    @Test func emptyNameFallsBackToDefault() {
        let game = GameState()
        game.newGame(name: "   ")
        #expect(game.hero.name == Hero.defaultName)

        let another = GameState()
        another.newGame(name: nil)
        #expect(another.hero.name == Hero.defaultName)
    }

    @Test func nameIsTrimmedAndCapped() {
        let game = GameState()
        game.newGame(name: "  そらまめたろう  ")
        #expect(game.hero.name.count == Hero.maxNameLength)
        #expect(game.hero.name == "そらまめたろ")
    }

    /// 決めた名前が、はじまりの語りに出る。
    @Test func introCallsTheHeroByName() {
        let game = GameState()
        game.newGame(name: "ひかり")
        let intro = readAll(game)
        #expect(intro.contains("ひかり"))
    }

    /// 新しいストーリーの筋（まおう・5つの地方・守護神・いにしえの血）が語られる。
    @Test func introTellsTheNewStory() {
        let game = GameState()
        game.newGame()
        let intro = readAll(game)
        for word in ["まおう", "5つの地方", "守護神", "いにしえの ゆうしゃ"] {
            #expect(intro.contains(word), "はじまりの語りに「\(word)」がない")
        }
    }

    /// ボスは支配された守護神。倒す相手ではなく「解きはなつ」相手。
    @Test func bossIsThePossessedGuardian() {
        #expect(EnemyKind.guardian.stats.name == "知床の守護神")
        #expect(EnemyKind.guardian.isBoss)
    }

    /// 名前を決めているあいだも タイトルの曲が鳴る。
    @Test func namingKeepsTitleMusic() {
        let game = GameState()
        game.beginNaming()
        #expect(game.musicTrack == .title)
    }
}
