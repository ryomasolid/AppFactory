import Foundation
import Observation

/// 戦闘画面の進行。ロジックは `Battle`、ここはメッセージを1行ずつ流す表示の都合を持つ。
struct BattleSession {
    var battle: Battle
    /// 画面に出ている直近のメッセージ。
    var log: [String]
    var isPlaying = false
    var end: BattleEnd?
}

@MainActor
@Observable
final class GameState {
    enum Screen: Equatable { case title, field, battle, ending }
    enum Overlay: Equatable { case none, menu, status, items, spells, shop, inn }

    static let shopStock: [Item] = [.herb, .copperSword, .leatherArmor, .steelSword, .chainMail]
    /// 1歩ごとの遭遇率（分母）と、戦闘後に遭遇しない歩数。
    static let encounterDenominator = 14
    static let safeSteps = 4

    var screen: Screen = .title
    var hero = Hero()
    var mapID: MapID = World.startMap
    var position = World.startPoint
    var facing: Direction = .down
    var openedChests: Set<String> = []
    var overlay: Overlay = .none
    var battle: BattleSession?
    var isWalking = false
    var walkFrame = 0
    /// 直前の位置変更がワープだったか。ワープではスクロールのアニメーションをしない。
    var lastMoveWasWarp = true
    var hasSave = SaveStore.load() != nil

    /// 表示中の会話（1ページ最大3行）。
    private(set) var pages: [[String]] = []
    @ObservationIgnored private var afterMessages: (() -> Void)?
    @ObservationIgnored private var stepsSinceBattle = 0
    @ObservationIgnored var rng = AnyRandomSource(SystemRandomSource())
    /// 1歩の時間と戦闘メッセージの間隔。テストではゼロにする。
    @ObservationIgnored var stepDuration: Duration = .milliseconds(150)
    @ObservationIgnored var messageInterval: Duration = .milliseconds(420)

    var map: GameMap { World.map(mapID) }
    var currentPage: [String]? { pages.first }
    var innPrice: Int { 2 + hero.level * 3 }
    var canWalk: Bool { screen == .field && pages.isEmpty && overlay == .none && !isWalking }

    // MARK: - タイトル

    func newGame() {
        hero = Hero()
        mapID = World.startMap
        position = World.startPoint
        facing = .down
        openedChests = []
        enterField()
        say([
            "ちょうろう「おお ゆうしゃよ、よくぞ きてくれた。",
            "ひがしの どうくつに ヤミドラゴンが すみつき、",
            "村の まわりにも まものが ふえておる。",
            "どうか ドラゴンを たおしてくれ！」",
            "（十字キーで あるき、Aで はなす・しらべる、",
            "Bで メニューを ひらけます）",
        ])
    }

    func continueGame() {
        guard let save = SaveStore.load() else { return newGame() }
        hero = save.hero
        mapID = save.map
        position = save.position
        openedChests = save.openedChests
        facing = .down
        enterField()
    }

    private func enterField() {
        pages = []
        overlay = .none
        battle = nil
        lastMoveWasWarp = true
        stepsSinceBattle = 0
        screen = .field
    }

    // MARK: - 移動

    /// 十字キーで押している向き。戦闘などで場面が変わったら「離した」ことにする
    /// （画面が消えると指を離した通知が来ず、古い向きのまま歩き続けてしまうため）。
    private(set) var heldDirection: Direction?
    @ObservationIgnored private var walkLoop: Task<Void, Never>?

    /// 押している間は歩き続ける。歩く処理は常に1本だけ動かす。
    func hold(_ direction: Direction?) {
        guard heldDirection != direction else { return }
        heldDirection = direction
        guard direction != nil, walkLoop == nil else { return }
        walkLoop = Task { [weak self] in
            while let self, let current = self.heldDirection, self.screen == .field, !Task.isCancelled {
                let before = self.position
                await self.walk(current)
                // 壁や会話中で進めなかったときは空回りしないよう少し待つ。
                if self.position == before {
                    try? await Task.sleep(for: .milliseconds(80))
                }
            }
            self?.walkLoop = nil
        }
    }

    func walk(_ direction: Direction) async {
        guard canWalk else { return }
        facing = direction
        let next = position + direction.delta
        guard map.isWalkable(next) else { return }
        isWalking = true
        lastMoveWasWarp = false
        walkFrame += 1
        position = next
        try? await Task.sleep(for: stepDuration)
        isWalking = false
        arrived()
    }

    private func arrived() {
        if let warp = map.warps[position] {
            lastMoveWasWarp = true
            mapID = warp.to
            position = warp.at
            stepsSinceBattle = 0
            return
        }
        guard let table = map.encounters[map.tile(at: position)], !table.isEmpty else { return }
        stepsSinceBattle += 1
        if stepsSinceBattle > Self.safeSteps, rng.chance(Self.encounterDenominator) {
            startBattle(table[rng.next(in: 0...(table.count - 1))])
        }
    }

    // MARK: - ボタン

    func pressA() {
        if !pages.isEmpty { return advanceMessage() }
        guard screen == .field, overlay == .none, !isWalking else { return }
        interact()
    }

    func pressB() {
        if !pages.isEmpty { return advanceMessage() }
        guard screen == .field, !isWalking else { return }
        switch overlay {
        case .none: overlay = .menu
        case .menu: overlay = .none
        default: overlay = .menu
        }
    }

    func closeOverlay() {
        overlay = .none
    }

    private func interact() {
        let target = position + facing.delta
        let map = map
        if let npc = map.npc(at: target) {
            talk(to: npc)
        } else if let chest = map.chest(at: target) {
            open(chest)
        } else if map.boss == target {
            say(["グルルル……", "ヤミドラゴン「ちいさき ゆうしゃよ、", "よくぞ ここまで きた。", "わが ほのおで もえつきるがよい！」"]) { [weak self] in
                self?.startBattle(.darkDragon)
            }
        } else {
            say(["\(hero.name)は あしもとを しらべた。", "しかし なにも みつからなかった。"])
        }
    }

    private func talk(to npc: NPC) {
        switch npc.role {
        case .elder:
            say(["ちょうろう「ヤミドラゴンは ほのおを はく。", "HPに よゆうを もって いどむのじゃ。", "ヒールを おぼえたら わすれずに つかうのじゃぞ。」"])
        case .villager(let lines):
            say(lines)
        case .innkeeper:
            overlay = .inn
        case .shopkeeper:
            overlay = .shop
        }
    }

    private func open(_ chest: Chest) {
        guard !openedChests.contains(chest.id) else {
            return say(["たからばこは からっぽだ。"])
        }
        openedChests.insert(chest.id)
        switch chest.reward {
        case .gold(let amount):
            hero.gold += amount
            say(["たからばこを あけた！", "\(amount)ゴールドを てにいれた！"])
        case .item(let item):
            hero.receive(item)
            say(["たからばこを あけた！", "\(item.name)を てにいれた！", item.kind == .consumable ? "" : "さっそく そうびした。"].filter { !$0.isEmpty })
        }
    }

    // MARK: - 会話

    func say(_ lines: [String], then: (() -> Void)? = nil) {
        pages = stride(from: 0, to: lines.count, by: 3).map { Array(lines[$0..<min($0 + 3, lines.count)]) }
        afterMessages = then
        if pages.isEmpty { finishMessages() }
    }

    func advanceMessage() {
        guard !pages.isEmpty else { return }
        pages.removeFirst()
        if pages.isEmpty { finishMessages() }
    }

    private func finishMessages() {
        let next = afterMessages
        afterMessages = nil
        next?()
    }

    // MARK: - 宿屋・店・メニュー

    func stayAtInn() {
        overlay = .none
        guard hero.gold >= innPrice else {
            return say(["やどや「おかねが たりない ようですね。」"])
        }
        hero.gold -= innPrice
        hero.restoreFully()
        save()
        say(["やどや「ゆっくり おやすみください。」", "……", "おはようございます。 ぼうけんの きろくを かきとめました。"])
    }

    func buy(_ item: Item) {
        guard hero.gold >= item.price else {
            return say(["どうぐや「おかねが たりないよ。」"])
        }
        if item == hero.weapon || item == hero.armor {
            return say(["どうぐや「それは もう そうびしているよ。」"])
        }
        hero.gold -= item.price
        hero.receive(item)
        if item.kind == .consumable {
            say(["どうぐや「まいどあり！」", "\(item.name)を てにいれた。"])
        } else {
            say(["どうぐや「まいどあり！」", "\(item.name)を そうびした。"])
        }
    }

    func castInField(_ spell: Spell) {
        guard spell.isHealing, hero.spells.contains(spell), hero.mp >= spell.mpCost else {
            return say(["MPが たりない！"])
        }
        hero.mp -= spell.mpCost
        let healed = hero.heal(rng.next(in: spell.power))
        overlay = .none
        say(["\(hero.name)は \(spell.name)を となえた！", "HPが \(healed) かいふくした！"])
    }

    func useHerbInField() {
        guard hero.consume(.herb) else { return say(["どうぐが ない！"]) }
        let healed = hero.heal(rng.next(in: Item.herbPower))
        overlay = .none
        say(["\(hero.name)は 薬草を つかった！", "HPが \(healed) かいふくした！"])
    }

    func save() {
        SaveStore.save(SaveData(hero: hero, map: mapID, position: position, openedChests: openedChests))
        hasSave = true
    }

    func saveFromMenu() {
        save()
        overlay = .none
        say(["ぼうけんの きろくを かきとめました。"])
    }

    // MARK: - 戦闘

    func startBattle(_ kind: EnemyKind) {
        let enemy = Enemy(kind)
        heldDirection = nil
        battle = BattleSession(battle: Battle(hero: hero, enemy: enemy), log: ["\(enemy.name)が あらわれた！"])
        overlay = .none
        screen = .battle
    }

    func command(_ command: BattleCommand) async {
        guard var session = battle, !session.isPlaying, session.end == nil else { return }
        let result = session.battle.take(command, rng: &rng)
        session.log = []
        session.isPlaying = true
        battle = session
        for message in result.messages {
            battle?.log.append(message)
            if let count = battle?.log.count, count > 4 { battle?.log.removeFirst(count - 4) }
            // HPの表示はメッセージが流れ終わってから反映する（先にバーだけ減るのを避ける）。
            try? await Task.sleep(for: messageInterval)
        }
        hero = session.battle.hero
        battle?.isPlaying = false
        battle?.end = result.end
    }

    func finishBattle() {
        guard let session = battle, let end = session.end else { return }
        hero = session.battle.hero
        stepsSinceBattle = 0
        switch end {
        case .won where session.battle.enemy.kind.isBoss:
            battle = nil
            screen = .ending
        case .won, .fled:
            battle = nil
            screen = .field
        case .lost:
            hero.gold /= 2
            hero.restoreFully()
            mapID = World.revivePoint.map
            position = World.revivePoint.point
            facing = .up
            enterField()
            say(["\(hero.name)は 村の いりぐちで めを さました。", "もっていた ゴールドが はんぶんに なった……"])
        }
    }

    func backToTitle() {
        hasSave = SaveStore.load() != nil
        battle = nil
        pages = []
        overlay = .none
        screen = .title
    }
}
