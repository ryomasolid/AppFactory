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
    private func talk(to resident: Resident, in game: GameState, town: MapID = .hakodate) throws -> [String] {
        let map = World.map(town)
        let npc = try #require(map.npcs.first { $0.role == .resident(resident) }, "\(resident) が \(town) にいない")
        let side = try #require(Direction.allCases.first { direction in
            map.isWalkable(npc.position + direction.delta, progress: game.progress)
        }, "\(resident) の となりに 立てない")
        game.mapID = town
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
        let gate = World.hakodateArea.warps.first { $0.value.to == .hakodateyama }!.key
        game.mapID = .hakodateArea
        game.position = gate + Point(x: 0, y: 1)
        await game.walk(.up)
    }

    @Test func hakodateyamaIsClosedWithoutThePass() async {
        let game = makeGame()
        await tryEnteringHakodateyama(game)
        #expect(game.mapID == .hakodateArea)
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

    /// 街の人・宝箱・看板には みな 街の入口から 話しかけに行ける（大沼の 島の ひなも）。
    @Test(arguments: MapID.allCases.filter(\.isTown))
    func everyoneInTownIsReachable(town: MapID) throws {
        let map = World.map(town)
        let entrance = try #require(map.warps.first { $0.value.to.isField }).key + Point(x: 0, y: -1)
        var seen: Set<Point> = [entrance]
        var queue = [entrance]
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
            #expect(reachable, "\(town) の \(target) に 話しかけられない")
        }
        for plaque in map.plaques.keys {
            #expect(map.tile(at: plaque) == .signpost, "\(plaque) に 看板のマスがない")
        }
    }

    // MARK: - 函館エリアの つづき（松前・大沼）

    /// 駒ヶ岳の前に立って 1歩 入ろうとする。
    private func tryEnteringKomagatake(_ game: GameState) async {
        let gate = World.hakodateArea.warps.first { $0.value.to == .komagatake }!.key
        game.mapID = .hakodateArea
        game.position = gate + Point(x: 0, y: 1)
        await game.walk(.up)
    }

    /// 殿様は イカのぬしを倒した ゆうしゃにだけ 火よけの おふだを さずける。
    @Test func lordGivesTheCharmAfterTheSquid() throws {
        let game = makeGame()
        try talk(to: .lord, in: game, town: .matsumae)
        #expect(!game.storyFlags.contains(.fireCharm), "ぬしを倒す前に おふだが もらえた")
        game.defeatedBosses = [.squidLord]
        let lines = try talk(to: .lord, in: game, town: .matsumae)
        #expect(lines.joined().contains("おふだ"))
        #expect(game.storyFlags.contains(.fireCharm))
    }

    @Test func komagatakeNeedsTheCharm() async {
        let game = makeGame()
        game.defeatedBosses = [.squidLord]
        await tryEnteringKomagatake(game)
        #expect(game.mapID == .hakodateArea)
        #expect(game.currentPage?.joined().contains("おふだ") == true)
        while game.currentPage != nil { game.advanceMessage() }
        game.storyFlags.insert(.fireCharm)
        await tryEnteringKomagatake(game)
        #expect(game.mapID == .komagatake)
    }

    /// ぬしを倒した 奉行は 松前へ 行くよう 教える（つぎに どこへ行けばいいか 分かるように）。
    @Test func magistratePointsToMatsumaeAfterTheSquid() throws {
        let game = makeGame()
        game.defeatedBosses = [.squidLord]
        let lines = try talk(to: .magistrate, in: game)
        #expect(lines.joined().contains("松前"))
    }

    /// 島の ひなを 見つけると 岸へ もどり、せわがかりが 1度だけ お礼をくれる。
    @Test func cygnetSwimsHomeAndKeeperThanksOnce() throws {
        let game = makeGame()
        let map = World.map(.onuma)
        let lost = try #require(map.npcs.first { $0.role == .resident(.lostCygnet) }).position
        #expect(map.tile(at: lost + Point(x: -1, y: 0)) == .townFloor, "ひなは 島の上に いるはず")

        let gold = game.hero.gold
        try talk(to: .swanKeeper, in: game, town: .onuma)
        #expect(game.hero.gold == gold, "見つける前に お礼が出た")
        try talk(to: .lostCygnet, in: game, town: .onuma)
        #expect(!game.npcs.contains { $0.position == lost })
        try talk(to: .swanKeeper, in: game, town: .onuma)
        #expect(game.hero.gold == gold + 120)
        try talk(to: .swanKeeper, in: game, town: .onuma)
        #expect(game.hero.gold == gold + 120, "お礼を 2度 もらえる")
    }

    // MARK: - めいしょ スタンプ

    /// 名所の看板を はじめて読むと スタンプが たまる。2度目は たまらない。
    @Test func readingAPlaqueStampsOnce() throws {
        let game = makeGame()
        let plaque = try #require(World.stampPlaques.first { $0.map == .hakodate })
        let map = World.map(.hakodate)
        let side = try #require(Direction.allCases.first { map.isWalkable(plaque.point + $0.delta) })
        game.position = plaque.point + side.delta
        game.facing = [.up: Direction.down, .down: .up, .left: .right, .right: .left][side]!
        game.pressA()
        var lines: [String] = []
        while let page = game.currentPage { lines += page; game.advanceMessage() }
        #expect(lines.joined().contains("スタンプ"))
        #expect(game.stamps[.hakodate] == 1)
        game.pressA()
        while game.currentPage != nil { game.advanceMessage() }
        #expect(game.stamps[.hakodate] == 1)
    }

    /// 案内所は 半分で 薬草、ぜんぶで ゴールドをくれる。それぞれ 1度だけ。
    @Test func guideRewardsHalfAndAllStamps() throws {
        #expect(World.stampTotal(in: .hakodate) >= 10, "名所が すくない: \(World.stampTotal(in: .hakodate))")
        let game = makeGame()
        let herbs = game.hero.inventory[.herb, default: 0]
        game.readPlaques = Set(World.stampPlaques(in: .hakodate).prefix((World.stampTotal(in: .hakodate) + 1) / 2))
        try talk(to: .guide, in: game)
        #expect(game.hero.inventory[.herb, default: 0] == herbs + 3)
        try talk(to: .guide, in: game)
        #expect(game.hero.inventory[.herb, default: 0] == herbs + 3, "薬草を 2度 もらえる")

        let gold = game.hero.gold
        game.readPlaques = Set(World.stampPlaques(in: .hakodate))
        try talk(to: .guide, in: game)
        #expect(game.hero.gold == gold + 300)
        try talk(to: .guide, in: game)
        #expect(game.hero.gold == gold + 300, "ゴールドを 2度 もらえる")
    }

    @Test func stampsSurviveSaving() throws {
        var save = SaveData(hero: Hero(), map: .onuma, position: Point(x: 13, y: 20), openedChests: [])
        save.readPlaques = [PlaqueID(map: .onuma, point: Point(x: 5, y: 3))]
        let decoded = try JSONDecoder().decode(SaveData.self, from: JSONEncoder().encode(save))
        #expect(decoded == save)
    }

    // MARK: - 札幌・小樽

    /// 藻岩山の前に立って 1歩 入ろうとする。
    private func tryEnteringMoiwa(_ game: GameState) async {
        let gate = World.sapporoArea.warps.first { $0.value.to == .moiwa1 }!.key
        game.mapID = .sapporoArea
        game.position = gate + Point(x: 0, y: 1)
        await game.walk(.up)
    }

    /// 長官の話 → 天狗を倒す → オルゴール職人から オルゴール → 藻岩山へ入れる。
    @Test func musicBoxOpensMoiwa() async throws {
        let game = makeGame()
        game.defeatedBosses = [.squidLord, .komaLord]
        let governor = try talk(to: .governor, in: game, town: .doucho)
        #expect(governor.joined().contains("小樽"), "長官が つぎの行き先を 言っていない")
        await tryEnteringMoiwa(game)
        #expect(game.mapID == .sapporoArea, "オルゴールが ないのに 藻岩山へ 入れる")
        while game.currentPage != nil { game.advanceMessage() }

        try talk(to: .musicBoxMaker, in: game, town: .otaru)
        #expect(!game.storyFlags.contains(.musicBox), "天狗を倒す前に オルゴールが もらえた")
        game.defeatedBosses.insert(.tengu)
        try talk(to: .musicBoxMaker, in: game, town: .otaru)
        #expect(game.storyFlags.contains(.musicBox))
        await tryEnteringMoiwa(game)
        #expect(game.mapID == .moiwa1)
    }

    /// ラーメンの 出前: 店で あずかり、北大の学生に とどけ、店で お礼を 1度だけ もらう。
    @Test func ramenDelivery() throws {
        let game = makeGame()
        try talk(to: .student, in: game, town: .sapporo)
        #expect(!game.storyFlags.contains(.ramenDelivered), "あずかる前に とどけられた")
        try talk(to: .ramenChef, in: game, town: .sapporo)
        #expect(game.storyFlags.contains(.ramenCarrying))
        try talk(to: .student, in: game, town: .sapporo)
        #expect(game.storyFlags.contains(.ramenDelivered))
        let gold = game.hero.gold
        try talk(to: .ramenChef, in: game, town: .sapporo)
        try talk(to: .ramenChef, in: game, town: .sapporo)
        #expect(game.hero.gold == gold + 150, "お礼が 1度で ない")
    }

    /// 倉庫の ネコを 見つけると かいぬしの となりに もどり、お礼は 1度だけ。
    @Test func lostCatGoesHome() throws {
        let game = makeGame()
        let herbs = game.hero.inventory[.herb, default: 0]
        try talk(to: .lostCat, in: game, town: .otaru)
        #expect(game.npcs.contains { $0.role == .resident(.catHome) } == false || game.mapID == .otaru)
        try talk(to: .catOwner, in: game, town: .otaru)
        try talk(to: .catOwner, in: game, town: .otaru)
        #expect(game.hero.inventory[.herb, default: 0] == herbs + 2)
        #expect(World.otaru.npcs(game.progress).contains { $0.role == .resident(.catHome) })
    }

    /// 定山渓の 足湯で HP・MPが ぜんぶ なおる。
    @Test func footBathHeals() throws {
        let game = makeGame()
        _ = game.hero.gainExp(LevelTable.row(5).exp)
        game.hero.hp = 1
        game.hero.mp = 0
        try talk(to: .yumori, in: game, town: .jozankei)
        #expect(game.hero.hp == game.hero.maxHP)
        #expect(game.hero.mp == game.hero.maxMP)
    }

    /// 札幌の案内所は 札幌・小樽・定山渓の スタンプを 数える（函館の スタンプは 数えない）。
    @Test func sapporoGuideCountsItsOwnStamps() throws {
        let total = World.stampTotal(in: .sapporo)
        #expect(total >= 10, "札幌・小樽の 名所が すくない: \(total)")
        let game = makeGame()
        game.readPlaques = Set(World.stampPlaques(in: .hakodate))
        let gold = game.hero.gold
        try talk(to: .sapporoGuide, in: game, town: .sapporo)
        #expect(game.hero.gold == gold, "函館の スタンプで 札幌の ごほうびが 出た")
        game.readPlaques.formUnion(World.stampPlaques(in: .sapporo))
        try talk(to: .sapporoGuide, in: game, town: .sapporo)
        #expect(game.hero.gold == gold + 300)
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
