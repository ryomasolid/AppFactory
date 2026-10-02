import Foundation
import Testing
@testable import GeoHero2

/// 画面から 触る 流れを GameState 単位で 通す。
@MainActor
struct GameStateTests {

    static func makeGame() -> GameState {
        let game = GameState()
        game.stepDuration = .zero
        game.messageInterval = .zero
        game.beatPause = .zero
        game.fadeDuration = .zero
        game.sleepDuration = .zero
        game.waitsForTap = false
        game.rng = AnyRandomSource(SeededRandomSource(seed: 42))
        game.newGame()
        game.say([])
        return game
    }

    private func readAll(_ game: GameState) {
        while game.currentPage != nil { game.advanceMessage() }
    }

    @Test func newGameStartsInAomoriWithTheIntro() {
        let game = GameState()
        game.newGame()
        #expect(game.mapID == .aomori)
        #expect(game.currentPage != nil)
        #expect(!game.canWalk)
        readAll(game)
        #expect(game.canWalk)
        #expect(game.hero.weapon == .bunaStick)
    }

    @Test func walkOutOfTownToTheField() async {
        let game = Self.makeGame()
        game.position = World.revivePoint(in: .aomori).point
        await game.walk(.down)
        #expect(game.mapID == .aomoriField)
    }

    /// 駅に のると 行き先を えらべる。きっぷの ない 県へは 行けない。
    @Test func trainTravelsOnlyWithATicket() async {
        let game = Self.makeGame()
        game.mapID = .aomoriField
        let station = try! #require(game.map.station)
        game.position = station + Point(x: 0, y: 1)
        await game.walk(.up)
        #expect(game.overlay == .train)
        await game.travel(to: .akita)
        #expect(game.mapID == .aomoriField, "きっぷが ないのに 行けた")
        readAll(game)
        game.defeatedBosses.insert(.yukioni)
        await game.travel(to: .akita)
        #expect(game.mapID == .akitaField)
        #expect(game.position == World.map(.akitaField).station! + Point(x: 0, y: 1))
        #expect(game.arrivalBanner?.name == "秋田県")
    }

    /// 関所は 印が ないと とおれない。
    @Test func gatesStopUntilTheFlagIsSet() async {
        let game = Self.makeGame()
        game.mapID = .aomoriField
        game.position = Point(x: 44, y: 30)
        await game.walk(.up)
        #expect(game.mapID == .aomoriField)
        #expect(game.currentPage?.joined().contains("奥入瀬") == true)
        readAll(game)
        game.storyFlags.insert(.aomoriTowada)
        await game.walk(.down)
        await game.walk(.up)
        #expect(game.mapID == .towadako)
    }

    /// ちしき検定：ぜんぶ 正解で 合格し、かざりが もらえる。まちがえると そこで おわり。
    @Test func examPassesWithAllCorrect() {
        let game = Self.makeGame()
        game.startExam(.aomori)
        #expect(game.overlay == .exam)
        for _ in 0..<Story.examLength {
            let quiz = try! #require(game.exam?.current)
            game.answerExam(quiz.answer)
            readAll(game)
        }
        #expect(game.storyFlags.contains(.examPassed(.aomori)))
        #expect(game.hero.owns(.kingyoNebuta))
        #expect(game.learnedQuizzes.count == Story.examLength)
    }

    @Test func examFailsOnAMistake() {
        let game = Self.makeGame()
        game.startExam(.akita)
        let quiz = try! #require(game.exam?.current)
        game.answerExam((quiz.answer + 1) % 3)
        #expect(game.exam == nil)
        #expect(!game.storyFlags.contains(.examPassed(.akita)))
        #expect(game.currentPage?.joined().contains("ざんねん") == true)
    }

    /// 勝つと 倒した 敵が ずかんに のる。
    @Test func winningFillsTheBook() async {
        let game = Self.makeGame()
        game.hero.receive(.konjikiTachi)
        game.startBattle([.ringoSlime, .hotate])
        for _ in 0..<20 where game.battle?.end == nil { await game.command(.attack) }
        await game.finishBattle()
        #expect(game.seenEnemies == [.ringoSlime, .hotate])
    }

    /// ほらあなで だっしゅつ すると フィールドの 入口へ。
    @Test func escapeSpellLeavesTheCave() async throws {
        let game = Self.makeGame()
        _ = game.hero.gainExp(LevelTable.row(8).exp)
        game.hero.restoreFully()
        game.mapID = .hakkoda2
        game.position = Point(x: 7, y: 8)
        game.castInField(.escape)
        try await Task.sleep(for: .milliseconds(100))
        #expect(game.mapID == .aomoriField)
        #expect(game.position == Point(x: 27, y: 21))
    }

    /// 守護神を 倒すと エンディング。そのあと 冒険を つづけられる。
    @Test func endingCanContinue() async {
        let game = Self.makeGame()
        game.startBattle(.guardian)
        game.battle?.end = .won(exp: 0, gold: 0)
        await game.finishBattle()
        #expect(game.screen == .ending)
        #expect(game.defeatedBosses.contains(.guardian))
        game.continueAfterEnding()
        #expect(game.screen == .field)
        #expect(game.mapID == .yamagata)
        #expect(game.progress.has(.cleared))
    }

    /// かざりを つけかえると 能力が かわる。
    @Test func charmsChangeStats() {
        var hero = Hero()
        let before = hero.maxHP
        hero.receive(.akabeko)
        #expect(hero.charm == .akabeko)
        #expect(hero.maxHP == before + 30)
        hero.receive(.oushou)
        #expect(hero.charm == .akabeko, "2つめの かざりは 自分で つけかえる")
        hero.equip(.oushou)
        #expect(hero.maxHP == before)
        #expect(hero.isEquipped(.oushou))
    }

    /// 起き上がり小法師は 1戦に 1回 おきあがらせる。
    @Test func okiagariRevivesOnce() {
        var rng = SeededRandomSource(seed: 5)
        var hero = Hero()
        hero.receive(.okiagari)
        var battle = Battle(hero: hero, enemies: [Enemy(.guardian)])
        var revived = 0
        for _ in 0..<20 where battle.end == nil {
            let result = battle.take(.attack, rng: &rng)
            revived += result.messages.filter { $0.contains("起き上がり小法師") }.count
        }
        #expect(revived == 1)
        #expect(battle.end == .lost)
    }

    /// セーブして 読みなおすと 図鑑・てちょう・コンボも もどる。
    @Test func saveKeepsTheRecords() throws {
        let defaults = UserDefaults(suiteName: "geohero2.test.\(UUID())")!
        let save = SaveData(hero: Hero(), map: .sendai, position: Point(x: 3, y: 3), openedChests: ["a"],
                            defeatedBosses: [.yukioni], storyFlags: [.aomoriHeard], readPlaques: [],
                            lastTown: .sendai, interiorReturn: nil, seenEnemies: [.hotate],
                            learnedQuizzes: ["q"], quizStreak: 4)
        SaveStore.save(save, to: defaults)
        #expect(SaveStore.load(from: defaults) == save)
    }

    /// 戦いの まほうは 4つずつ ならべても ぜんぶ えらべる（11こ）。
    @Test func everyBattleSpellIsListed() {
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(30).exp)
        #expect(hero.spells.count == Spell.allCases.count)
        #expect(hero.spells.filter(\.isBattleUsable).count == Spell.allCases.count - 1)
    }

    /// 全体の まほうは 生きている 敵 みんなに 当たる。
    @Test func thunderHitsEveryone() {
        var rng = SeededRandomSource(seed: 2)
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(8).exp)
        var battle = Battle(hero: hero, enemies: EnemyGroup.numbered([.kiritanpoSoldier, .hatahata, .komachiRice]))
        let result = battle.take(.spell(.thunder), rng: &rng)
        #expect(Set(result.lines.compactMap(\.enemyID)).count == 3)
    }
}
