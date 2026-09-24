import Foundation
import Testing
@testable import GeoHero

/// 出入りの暗転と、宿屋の ねむり。
@MainActor
struct TransitionTests {

    private func makeGame(fade: Duration = .zero, sleep: Duration = .zero) -> GameState {
        let game = GameState()
        game.stepDuration = .zero
        game.messageInterval = .zero
        game.beatPause = .zero
        game.fadeDuration = fade
        game.sleepDuration = sleep
        game.waitsForTap = false
        game.rng = AnyRandomSource(SeededRandomSource(seed: 42))
        game.newGame()
        game.say([])
        return game
    }

    /// 最初は幕は下りていない。
    @Test func curtainStartsOpen() {
        let game = makeGame()
        #expect(game.curtain == 0)
        #expect(game.curtainCaption == nil)
        #expect(game.isTransitioning == false)
    }

    /// 村から出るときに幕を下ろし、着いたら上げる。
    @Test func walkingThroughAWarpDrawsTheCurtain() async {
        let game = makeGame()
        for _ in 0..<3 { await game.walk(.down) }
        #expect(game.mapID == .field, "フィールドへ 移っていない")
        // 行き着いたときには幕は上がっている。
        #expect(game.curtain == 0)
        #expect(game.isTransitioning == false)
        #expect(game.canWalk)
    }

    /// 幕を下ろしているあいだは歩けない。
    @Test func cannotWalkWhileTheCurtainIsMoving() async {
        // 幕の上げ下げに時間をかけて、途中の状態をつかまえる。
        let game = makeGame(fade: .milliseconds(200))
        let walking = Task { for _ in 0..<3 { await game.walk(.down) } }
        try? await Task.sleep(for: .milliseconds(260))
        #expect(game.isTransitioning, "暗転中のはずが そうなっていない")
        #expect(game.canWalk == false, "暗転中なのに 歩けてしまう")
        await walking.value
        #expect(game.isTransitioning == false)
    }

    // MARK: - 街の名前

    /// フィールドから街に入ると 地名の札が出て、しばらくすると消える。
    @Test func enteringATownShowsItsName() async {
        let game = makeGame()
        game.bannerDuration = .milliseconds(100)
        for _ in 0..<3 { await game.walk(.down) }
        #expect(game.mapID == .field)
        #expect(game.arrivalBanner == nil, "フィールドに出たのに 札が出ている")
        await game.walk(.up)
        #expect(game.mapID == .hakodate)
        #expect(game.arrivalBanner?.name == "函館")
        try? await Task.sleep(for: .milliseconds(300))
        #expect(game.arrivalBanner == nil, "札が 消えない")
    }

    /// 宿屋から 街へ戻ったときは 札を出さない（街の中を 行き来しただけなので）。
    @Test func leavingTheInnDoesNotShowTheName() async {
        let game = makeGame()
        game.position = Point(x: 3, y: 5)
        await game.walk(.up)
        #expect(game.mapID == .innInside)
        await game.walk(.down)
        #expect(game.mapID == .hakodate)
        #expect(game.arrivalBanner == nil)
    }

    /// 街の看板を しらべると 街の名前が読める。
    @Test func signpostTellsTheTownName() async {
        let game = makeGame()
        for id in [MapID.hakodate, .sapporo, .rausu] {
            #expect(World.map(id).tiles.joined().contains(.signpost), "\(id) に看板がない")
        }
        await game.walk(.left)
        await game.walk(.left)
        await game.walk(.down)
        #expect(game.position == Point(x: 5, y: 10))
        game.pressA()
        #expect(game.currentPage?.joined().contains("函館") == true)
    }

    // MARK: - 宿屋

    /// 泊まると、まず宿屋のあいさつが出る。この時点ではまだ回復しない。
    @Test func innGreetsBeforeSleeping() {
        let game = makeGame()
        game.hero.hp = 1
        game.hero.gold = 100
        game.stayAtInn()

        let page = game.currentPage ?? []
        #expect(page.contains { $0.contains("おやすみください") })
        #expect(game.hero.hp == 1, "あいさつの時点で 回復してしまっている")
    }

    /// あいさつを読み終えると まっくらになって眠り、朝に全快している。
    @Test func sleepingDarkensTheScreenAndHeals() async {
        let game = makeGame()
        game.hero.hp = 1
        game.hero.mp = 0
        game.hero.gold = 100
        game.stayAtInn()
        while game.currentPage != nil { game.advanceMessage() }

        // 眠りは Task で進むので、終わるまで待つ。
        for _ in 0..<50 where game.hero.hp != game.hero.maxHP {
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(game.hero.hp == game.hero.maxHP)
        #expect(game.hero.mp == game.hero.maxMP)
        #expect(game.hasSave, "宿屋で セーブされていない")

        // 朝のメッセージが出て、幕は上がっている。
        for _ in 0..<50 where game.currentPage == nil {
            try? await Task.sleep(for: .milliseconds(10))
        }
        let page = game.currentPage ?? []
        #expect(page.contains { $0.contains("おはよう") })
        #expect(game.curtain == 0)
        #expect(game.isTransitioning == false)
    }

    /// 眠っているあいだは まっくらで「Zzz」が出る。
    @Test func sleepShowsZzzWhileDark() async {
        let game = makeGame(fade: .zero, sleep: .milliseconds(300))
        game.hero.gold = 100
        game.stayAtInn()
        while game.currentPage != nil { game.advanceMessage() }

        try? await Task.sleep(for: .milliseconds(80))
        #expect(game.curtain == 1, "眠っているのに まっくらになっていない")
        #expect(game.curtainCaption?.contains("Zzz") == true)
    }

    /// おかねが足りなければ 眠らないし 暗くもしない。
    @Test func cannotSleepWithoutGold() {
        let game = makeGame()
        game.hero.hp = 1
        game.hero.gold = 0
        game.stayAtInn()
        #expect(game.hero.hp == 1)
        #expect(game.curtain == 0)
        let page = game.currentPage ?? []
        #expect(page.contains { $0.contains("たりない") })
    }
}
