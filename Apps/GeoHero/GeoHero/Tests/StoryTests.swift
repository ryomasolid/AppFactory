import Foundation
import Testing
@testable import GeoHero

/// 函館の物語（親方の話 → 奉行の てがた → 函館山）と 迷子さがし。
@MainActor
struct StoryTests {

    private func makeGame() -> GameState {
        let game = GameState()
        game.stepDuration = .zero
        game.messageInterval = .zero
        game.fadeDuration = .zero
        game.waitsForTap = false
        game.rng = AnyRandomSource(SeededRandomSource(seed: 7))
        game.newGame()
        game.say([])
        return game
    }

    /// その人の となりの 歩けるマスに立って 向きあい、話を 最後まで読む。読んだ せりふを返す。
    @discardableResult
    private func talk(to resident: Resident, in game: GameState) throws -> [String] {
        let map = World.map(.hakodate)
        let npc = try #require(map.npcs.first { $0.role == .resident(resident) }, "\(resident) が 函館にいない")
        let side = try #require(Direction.allCases.first { direction in
            map.isWalkable(npc.position + direction.delta, progress: game.progress)
        }, "\(resident) の となりに 立てない")
        game.mapID = .hakodate
        game.position = npc.position + side.delta
        game.facing = [.up: Direction.down, .down: .up, .left: .right, .right: .left][side]!
        game.pressA()
        var lines: [String] = []
        while let page = game.currentPage {
            lines += page
            game.advanceMessage()
        }
        return lines
    }

    /// 函館山の前に立って 1歩 入ろうとする。
    private func tryEnteringHakodateyama(_ game: GameState) async {
        let gate = World.field.warps.first { $0.value.to == .hakodateyama }!.key
        game.mapID = .field
        game.position = gate + Point(x: 0, y: 1)
        await game.walk(.up)
    }

    @Test func hakodateyamaIsClosedWithoutThePass() async {
        let game = makeGame()
        await tryEnteringHakodateyama(game)
        #expect(game.mapID == .field)
        #expect(game.currentPage?.joined().contains("てがた") == true)
    }

    /// 親方の話を聞かずに 奉行へ行っても てがたは もらえない。
    @Test func magistrateWantsProofFirst() throws {
        let game = makeGame()
        let lines = try talk(to: .magistrate, in: game)
        #expect(lines.joined().contains("親方"), "つぎに どこへ行けばいいか 言っていない")
        #expect(!game.storyFlags.contains(.hakodateyamaPass))
    }

    @Test func fisherThenMagistrateOpensTheMountain() async throws {
        let game = makeGame()
        try talk(to: .fisherBoss, in: game)
        #expect(game.storyFlags.contains(.heardFromFisher))
        try talk(to: .magistrate, in: game)
        #expect(game.storyFlags.contains(.hakodateyamaPass))
        await tryEnteringHakodateyama(game)
        #expect(game.mapID == .hakodateyama)
    }

    /// 長老は いまの つぎの ひと手を 教える。
    @Test func elderPointsToTheNextStep() throws {
        let game = makeGame()
        game.facing = .up
        game.pressA()
        #expect(game.currentPage?.joined().contains("奉行") == true)
    }

    /// 迷子は 見つけると 元町から消え、朝市の 母のとなりに 出る。お礼は 1度だけ。
    @Test func lostChildGoesHomeAndMotherThanksOnce() throws {
        let game = makeGame()
        let map = World.map(.hakodate)
        let lost = try #require(map.npcs.first { $0.role == .resident(.lostChild) }).position
        let home = try #require(map.npcs.first { $0.role == .resident(.childAtHome) }).position
        #expect(game.npcs.contains { $0.position == lost })
        #expect(!game.npcs.contains { $0.position == home })

        try talk(to: .mother, in: game)
        #expect(!game.storyFlags.contains(.childReturned), "見つける前に お礼が出た")

        try talk(to: .lostChild, in: game)
        #expect(!game.npcs.contains { $0.position == lost }, "迷子が 元町に残っている")
        #expect(game.npcs.contains { $0.position == home }, "迷子が 母のところに いない")

        let herbs = game.hero.inventory[.herb, default: 0]
        try talk(to: .mother, in: game)
        #expect(game.hero.inventory[.herb, default: 0] == herbs + 2)
        try talk(to: .mother, in: game)
        #expect(game.hero.inventory[.herb, default: 0] == herbs + 2, "お礼を 2度 もらえる")
    }

    /// ぬしを倒すと 親方が お礼をくれる。1度だけ。
    @Test func fisherRewardsAfterTheBossOnce() throws {
        let game = makeGame()
        game.defeatedBosses = [.squidLord]
        let gold = game.hero.gold
        try talk(to: .fisherBoss, in: game)
        #expect(game.hero.gold == gold + 100)
        try talk(to: .fisherBoss, in: game)
        #expect(game.hero.gold == gold + 100)
    }

    /// てがたの仕組みより前に ぬしを倒した人は、山の前で止めない。
    @Test func bossDefeatImpliesThePass() async {
        let game = makeGame()
        game.defeatedBosses = [.squidLord]
        await tryEnteringHakodateyama(game)
        #expect(game.mapID == .hakodateyama)
    }

    /// 物語の人は みな 函館の はじめの場所から 話しかけに行ける。
    @Test func everyoneInHakodateIsReachable() {
        let map = World.map(.hakodate)
        var seen: Set<Point> = [World.startPoint]
        var queue = [World.startPoint]
        while let point = queue.popLast() {
            for direction in Direction.allCases {
                let next = point + direction.delta
                guard map.isWalkable(next), seen.insert(next).inserted else { continue }
                queue.append(next)
            }
        }
        let targets = map.npcs.map(\.position) + map.chests.map(\.position) + Array(map.plaques.keys)
        for target in targets {
            let reachable = Direction.allCases.contains { seen.contains(target + $0.delta) }
            #expect(reachable, "\(target) に 話しかけられない")
        }
        for plaque in map.plaques.keys {
            #expect(map.tile(at: plaque) == .signpost, "\(plaque) に 看板のマスがない")
        }
    }

    /// 物語の前の セーブ（新しい項目がない）も 読める。
    @Test func oldSaveWithoutStoryStillLoads() throws {
        let old = """
        {"hero": \(String(data: try JSONEncoder().encode(Hero()), encoding: .utf8)!),
         "map": "sapporo", "position": {"x": 7, "y": 9}, "openedChests": [], "defeatedBosses": ["squidLord"]}
        """
        let save = try JSONDecoder().decode(SaveData.self, from: Data(old.utf8))
        #expect(save.storyFlags.isEmpty)
        #expect(save.defeatedBosses == [.squidLord])
        #expect(save.lastTown == .hakodate)
    }

    @Test func storyFlagsSurviveSaving() throws {
        var save = SaveData(hero: Hero(), map: .innInside, position: Point(x: 4, y: 4), openedChests: [])
        save.storyFlags = [.heardFromFisher, .childFound]
        save.lastTown = .sapporo
        save.interiorReturn = Point(x: 11, y: 5)
        let decoded = try JSONDecoder().decode(SaveData.self, from: JSONEncoder().encode(save))
        #expect(decoded == save)
    }
}
