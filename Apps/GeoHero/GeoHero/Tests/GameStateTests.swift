import Foundation
import Testing
@testable import GeoHero

/// 画面から触る流れ（歩く・話す・買う・戦う・全滅）を GameState 単位で通す。
@MainActor
struct GameStateTests {

    private func makeGame() -> GameState {
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
        // 着地点は村の出口のワープ定義から引く（地図を広げても落ちないように）。
        let exit = World.map(.hakodate).warps.first { $0.value.to == .field }
        let landing = try! #require(exit?.value.at)
        game.position = World.revivePoint.point
        await game.walk(.down)
        #expect(game.mapID == .field)
        #expect(game.position == landing)
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
        // 函館の北、港と五稜郭の あいだの 通り。西の 湾の手前まで 何もない。
        game.position = Point(x: 10, y: 9)
        game.hold(.left)
        try await Task.sleep(for: .milliseconds(200))
        #expect(game.position == Point(x: 3, y: 9))
        game.hold(nil)
        #expect(game.heldDirection == nil)
    }

    /// 右を押したまま戦闘に入っても、戦闘後に勝手に右へ歩き出さない（不具合の再発防止）。
    @Test func battleReleasesHeldDirection() async throws {
        let game = makeGame()
        game.hero.receive(.steelSword)
        game.mapID = .field
        // 座標は直書きせず、左へ歩ける陸地を地図から探す（海岸線を変えても落ちないように）。
        let field = World.map(.field)
        let start = try #require(
            (0..<field.height).flatMap { y in (1..<field.width).map { Point(x: $0, y: y) } }
                .first { point in
                    let left = Point(x: point.x - 1, y: point.y)
                    return field.isWalkable(point) && field.isWalkable(left)
                        && field.warps[point] == nil && field.warps[left] == nil
                }
        )
        game.position = start
        game.hold(.right)
        game.startBattle(.potato)
        #expect(game.heldDirection == nil)
        for _ in 0..<10 where game.battle?.end == nil {
            await game.command(.attack)
        }
        await game.finishBattle()
        try await Task.sleep(for: .milliseconds(200))
        #expect(game.position == start)

        game.hold(.left)
        try await Task.sleep(for: .milliseconds(50))
        game.hold(nil)
        #expect(game.position.x < start.x)
    }

    /// 宿屋の扉から中に入り、下の扉から村の家の前に戻る。
    @Test func enterInnAndLeave() async {
        let game = makeGame()
        game.position = Point(x: 14, y: 17)
        await game.walk(.up)
        #expect(game.mapID == .innInside)
        #expect(game.position == Point(x: 4, y: 4))
        #expect(game.musicTrack == .village)
        await game.walk(.down)
        #expect(game.mapID == .hakodate)
        #expect(game.position == Point(x: 14, y: 17))
    }

    /// 中の地図は 宿屋・道具屋で1つずつを使いまわすので、出る先は 入った扉の前にする
    /// （街ごとに 扉の位置が ちがう）。
    @Test func leavingTheShopReturnsToItsOwnDoor() async throws {
        for town in [MapID.hakodate, .sapporo] {
            let game = makeGame()
            let door = try #require(World.map(town).warps.first { $0.value.to == .shopInside }?.key)
            game.mapID = town
            game.position = door + Point(x: 0, y: 1)
            await game.walk(.up)
            #expect(game.mapID == .shopInside)
            await game.walk(.down)
            #expect(game.mapID == town)
            #expect(game.position == door + Point(x: 0, y: 1), "\(town) の道具屋の前に 戻っていない")
        }
    }

    /// 宿屋の主人にはカウンター越しに話しかける。
    @Test func innkeeperTalksAcrossCounter() {
        let game = makeGame()
        game.mapID = .innInside
        game.position = Point(x: 7, y: 3)
        game.facing = .up
        game.pressA()
        #expect(game.overlay == .inn)
    }

    @Test func shopkeeperSellsHerb() {
        let game = makeGame()
        game.mapID = .shopInside
        game.position = Point(x: 4, y: 3)
        game.facing = .up
        game.pressA()
        #expect(game.overlay == .shop)
        game.buy(.herb)
        #expect(game.hero.gold == 12)
        #expect(game.hero.herbCount == 3)
    }

    @Test func chestOpensOnlyOnce() throws {
        let game = makeGame()
        // 函館山の ほらあなの宝箱（ゴールド）。中身はマップから読む。
        let chest = try #require(World.map(.hakodateyama).chests.first)
        guard case .gold(let amount) = chest.reward else {
            Issue.record("この宝箱はゴールドではない")
            return
        }
        let before = game.hero.gold
        game.mapID = .hakodateyama
        game.position = chest.position + Point(x: 0, y: 1)
        game.facing = .up
        game.pressA()
        #expect(game.hero.gold == before + amount)
        while game.currentPage != nil { game.advanceMessage() }
        game.pressA()
        #expect(game.hero.gold == before + amount)
    }

    @Test func winningBattleReturnsToField() async {
        let game = makeGame()
        game.hero.receive(.steelSword)
        game.startBattle(.potato)
        #expect(game.screen == .battle)
        for _ in 0..<10 where game.battle?.end == nil {
            await game.command(.attack)
        }
        #expect(game.battle?.end == .won(exp: 2, gold: 3))
        await game.finishBattle()
        #expect(game.screen == .field)
        #expect(game.hero.gold == 23)
        #expect(game.hero.exp == 2)
    }

    /// 攻撃が当たるたびに「何発目か・ダメージ・会心か」が更新され、画面の動きのきっかけになる。
    @Test func enemyHitIsRecordedForEachDamagingLine() async {
        let game = makeGame()
        _ = game.hero.gainExp(LevelTable.row(5).exp)
        game.startBattle(.iceGolem)
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
        game.startBattle(.potato)
        let turn = Task { await game.command(.attack) }
        for _ in 0..<100 where game.battle?.waitingForTap != true {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(game.battle?.waitingForTap == true)
        #expect(game.battle?.isPlaying == true)
        #expect(game.battle?.defeatedIDs.isEmpty == false)
        game.advanceBattleMessage()
        await turn.value
        #expect(game.battle?.waitingForTap == false)
        #expect(game.battle?.end == .won(exp: 2, gold: 3))
    }

    /// 敵の攻撃が当たるたびに勇者の被ダメージが記録され、画面を揺らすきっかけになる。
    @Test func heroHitIsRecordedWhenDamaged() async {
        let game = makeGame()
        game.startBattle(.guardian)
        #expect(game.battle?.heroHit == nil)
        for _ in 0..<10 where game.battle?.heroHit == nil && game.battle?.end == nil {
            await game.command(.attack)
        }
        let hit = game.battle?.heroHit
        #expect((hit?.damage ?? 0) > 0)
        // レベル1（最大HP15）にボスの一撃は大ダメージ。
        #expect(hit?.isHeavy == true)
    }

    @Test func losingRevivesInVillageWithHalfGold() async {
        let game = makeGame()
        game.hero.gold = 100
        game.mapID = .rausudake2
        game.startBattle(.guardian)
        for _ in 0..<30 where game.battle?.end == nil {
            await game.command(.attack)
        }
        #expect(game.battle?.end == .lost)
        await game.finishBattle()
        #expect(game.screen == .field)
        #expect(game.mapID == .hakodate)
        #expect(game.hero.gold == 50)
        #expect(game.hero.hp == game.hero.maxHP)
    }

    /// 前のボスを倒すまで つぎの ほらあなに入れない。倒すと通れる。
    @Test func gatedCaveOpensAfterItsBoss() async throws {
        let field = World.map(.field)
        let (gate, warp) = try #require(field.warps.first { $0.value.requires != nil })
        let needed = try #require(warp.requires)

        let game = makeGame()
        game.mapID = .field
        game.position = gate + Point(x: 0, y: 1)
        game.facing = .up
        await game.walk(.up)
        #expect(game.mapID == .field, "ボスを倒す前なのに \(warp.to) へ入れてしまう")
        #expect(game.currentPage != nil, "通れない理由が出ていない")

        while game.currentPage != nil { game.advanceMessage() }
        game.defeatedBosses.insert(needed)
        game.position = gate + Point(x: 0, y: 1)
        game.facing = .up
        await game.walk(.up)
        #expect(game.mapID == warp.to, "ボスを倒したのに 道がひらかない")
    }

    /// 途中のボスを倒しても終わらない。ラスボスだけが エンディングにつながる。
    @Test func onlyTheFinalBossEndsTheAdventure() async {
        for kind in [EnemyKind.squidLord, .bearLord, .guardian] {
            let game = makeGame()
            game.mapID = .rausudake2
            // 確実に勝てるように、最高レベルで そうびも ととのえておく。
            _ = game.hero.gainExp(1_000_000)
            game.hero.receive(.steelSword)
            game.hero.receive(.chainMail)
            game.startBattle(kind)
            for _ in 0..<80 where game.battle?.end == nil {
                // 減ってきたら回復する（ラスボスは殴るだけでは倒せない）。
                let low = game.hero.hp < game.hero.maxHP * 3 / 5
                await game.command(low && game.hero.mp >= Spell.highHeal.mpCost ? .spell(.highHeal) : .attack)
            }
            await game.finishBattle()
            #expect(game.defeatedBosses.contains(kind))
            #expect((game.screen == .ending) == kind.isFinalBoss, "\(kind) で エンディングの出かたが おかしい")
        }
    }

    /// 倒したボスは ほらあなから いなくなる（居座って 何度でも戦えてしまう不具合の再発防止）。
    @Test func defeatedBossLeavesItsCave() async throws {
        let game = makeGame()
        game.mapID = .hakodateyama
        let boss = try #require(game.map.boss)
        let kind = try #require(game.map.bossKind)
        game.position = boss + Point(x: 0, y: 1)
        game.facing = .up

        // 倒す前。話しかけると 戦いになる。
        #expect(game.bossPoint == boss)
        game.pressA()
        while game.currentPage != nil { game.advanceMessage() }
        #expect(game.screen == .battle, "ボスに話しかけても 戦いにならない")

        // 倒したあと。絵も当たり判定も 消える。
        game.screen = .field
        game.battle = nil
        game.defeatedBosses.insert(kind)
        #expect(game.bossPoint == nil, "倒したのに ボスが 残っている")
        game.pressA()
        #expect(game.screen == .field, "倒したボスと また戦いになる")
        while game.currentPage != nil { game.advanceMessage() }
        await game.walk(.up)
        #expect(game.position == boss, "ボスが いたマスに 入れない")
    }

    // MARK: - ウィンドウの カーソル

    /// 十字キーは 選べない行をとばし、端まで来たら 反対の端へ回る。
    @Test func cursorSkipsRowsThatCannotBeChosen() {
        let game = makeGame()
        game.overlay = .shop
        game.setChoices([
            ChoiceSlot(id: "かう", isEnabled: true),
            ChoiceSlot(id: "うる", isEnabled: false),
            ChoiceSlot(id: "やめる", isEnabled: true),
        ])
        #expect(game.cursor == 0)
        game.moveCursor(.down)
        #expect(game.cursor == 2, "選べない行を とばしていない")
        game.moveCursor(.down)
        #expect(game.cursor == 0, "端で 反対の端へ 回らない")
        game.moveCursor(.up)
        #expect(game.cursor == 2)
    }

    /// ウィンドウの中身が入れかわったら いちばん上（選べる行）から。
    @Test func cursorStartsAtTheTopOfANewWindow() {
        let game = makeGame()
        game.overlay = .shop
        game.setChoices([
            ChoiceSlot(id: "かう", isEnabled: true),
            ChoiceSlot(id: "うる", isEnabled: true),
            ChoiceSlot(id: "やめる", isEnabled: true),
        ])
        game.moveCursor(.down)
        #expect(game.cursor == 1)
        // 同じ並びのままなら、選べるかどうかが変わっても 指したままにする。
        game.setChoices([
            ChoiceSlot(id: "かう", isEnabled: true),
            ChoiceSlot(id: "うる", isEnabled: false),
            ChoiceSlot(id: "やめる", isEnabled: true),
        ])
        #expect(game.cursor == 1)
        // 別のウィンドウに変わったら 頭に戻る。買えないときは 選べる行から。
        game.setChoices([
            ChoiceSlot(id: "はい", isEnabled: false),
            ChoiceSlot(id: "もどる", isEnabled: true),
        ])
        #expect(game.cursor == 1, "選べない行を 指したまま 開いている")
    }

    /// ウィンドウが出ているあいだ、十字キーは歩かずに カーソルを動かす。
    @Test func dPadMovesTheCursorInsteadOfWalking() {
        let game = makeGame()
        let start = game.position
        game.overlay = .menu
        game.setChoices([
            ChoiceSlot(id: "つよさ", isEnabled: true),
            ChoiceSlot(id: "どうぐ", isEnabled: true),
        ])
        game.hold(.down)
        #expect(game.cursor == 1)
        game.hold(nil)
        #expect(game.position == start, "ウィンドウが出ているのに 歩いてしまう")
    }

    /// A は 指している行を、B は「もどる」を画面に伝える。選べない行では A は空振りする。
    @Test func buttonsDecideAndGoBack() {
        let game = makeGame()
        game.overlay = .inn
        game.setChoices([
            ChoiceSlot(id: "はい", isEnabled: false),
            ChoiceSlot(id: "いいえ", isEnabled: true),
        ])
        game.moveCursor(.up)
        #expect(game.cursor == 1, "選べない行に カーソルが 乗ってしまう")
        game.pressA()
        #expect(game.confirmCount == 1)

        game.setChoices([ChoiceSlot(id: "はい", isEnabled: false)])
        game.pressA()
        #expect(game.confirmCount == 1, "選べない行なのに 決まってしまう")

        game.pressB()
        #expect(game.cancelCount == 1)
        #expect(game.overlay == .inn, "B を押しただけで ウィンドウが 変わってしまう")
    }

    /// ウィンドウを閉じれば 十字キーは また歩くのに戻る。
    @Test func closingTheWindowGivesTheDPadBackToWalking() async {
        let game = makeGame()
        game.overlay = .menu
        game.setChoices([ChoiceSlot(id: "とじる", isEnabled: true)])
        #expect(game.isChoosing)
        game.closeOverlay()
        #expect(!game.isChoosing)
        #expect(game.choices.isEmpty, "閉じたウィンドウの選択肢が 残っている")
        let start = game.position
        await game.walk(.left)
        #expect(game.position != start)
    }
}
