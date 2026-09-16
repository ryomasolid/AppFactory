import Foundation
import Observation

/// 戦闘画面の進行。ロジックは `Battle`、ここはメッセージを1行ずつ流す表示の都合を持つ。
struct BattleSession {
    var battle: Battle
    /// 画面に出ている直近のメッセージ。
    var log: [String]
    var isPlaying = false
    var end: BattleEnd?
    /// 勝利・全滅のジングルが鳴ったら戦闘の BGM を止める。
    var musicStopped = false
    /// 結果のページで ▼ を出してタップを待っている。
    var waitingForTap = false
    /// たおれた敵。画面から消す。
    var defeatedIDs: Set<Int> = []
    /// 勇者が受けた最新の一撃。画面はこれが変わるたびに揺れる。
    var heroHit: HeroHit?
    /// 敵に当たった最新の一撃。画面はこれが変わるたびに敵を揺らし、ダメージの数字を出す。
    var enemyHit: EnemyHit?
    /// 呪文・道具の最新の演出。画面はこれが変わるたびに粒や炎を出す。
    var effect: EffectCue?
}

/// 呪文・道具の演出と、その通し番号（同じ演出が続いても出し直すため）。
struct EffectCue: Equatable {
    let id: Int
    let kind: BattleEffect
}

struct HeroHit: Equatable {
    let id: Int
    let damage: Int
    /// 最大HPの3分の1以上の大ダメージ（大きく揺らす）。
    let isHeavy: Bool
}

struct EnemyHit: Equatable {
    /// 何発目か（同じダメージが続いても動きを出し直すため）。
    let id: Int
    /// だれに当たったか。
    let enemyID: Int
    let damage: Int
    let isCritical: Bool
}

@MainActor
@Observable
final class GameState {
    enum Screen: Equatable { case title, naming, field, battle, ending }
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
    /// 画面をおおう黒幕の濃さ（0＝見えない、1＝まっくら）。濃さを変えるのは画面側のアニメーション。
    private(set) var curtain: Double = 0
    /// 黒幕の上に出す文字（宿屋の「Zzz」など）。
    private(set) var curtainCaption: String?
    /// 黒幕を上げ下げしているあいだは操作を受け付けない。
    private(set) var isTransitioning = false

    /// 黒幕の濃さが変わるのにかかる時間。画面側のアニメーションと同じ値にする。
    @ObservationIgnored var fadeDuration: Duration = .milliseconds(280)
    /// 画面側のアニメーションに渡す秒数。
    var fadeSeconds: Double {
        let parts = fadeDuration.components
        return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
    }
    /// 宿屋でまっくらなまま眠っている時間（ジングルを聴かせる）。
    @ObservationIgnored var sleepDuration: Duration = .milliseconds(1600)

    @ObservationIgnored var stepDuration: Duration = .milliseconds(150)
    @ObservationIgnored var messageInterval: Duration = .milliseconds(450)
    /// 行動が変わるときの間（読んでから枠を空ける）。
    @ObservationIgnored var beatPause: Duration = .milliseconds(900)
    /// 戦いの結果のページでタップを待つか（テストでは待たない）。
    @ObservationIgnored var waitsForTap = true
    @ObservationIgnored private var tapContinuation: CheckedContinuation<Void, Never>?
    /// 効果音を鳴らす先。アプリでは AudioManager につなぎ、テストでは記録に使う。
    @ObservationIgnored var playSound: (SoundCue) -> Void = { _ in }

    static let soundKey = "tinyhero.soundEnabled"
    /// 音のオン・オフ（メニューで切り替え、端末に保存する）。
    var soundEnabled = UserDefaults.standard.object(forKey: GameState.soundKey) as? Bool ?? true {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Self.soundKey) }
    }

    var map: GameMap { World.map(mapID) }
    var currentPage: [String]? { pages.first }
    var innPrice: Int { 2 + hero.level * 3 }
    var canWalk: Bool { screen == .field && pages.isEmpty && overlay == .none && !isWalking && !isTransitioning }

    /// いま流す BGM。場面から決まる。
    var musicTrack: MusicTrack? {
        switch screen {
        // 名前を決めているあいだも タイトルの曲を流し続ける。
        case .title, .naming: .title
        case .field:
            switch mapID {
            case .village, .innInside, .shopInside: .village
            case .field: .overworld
            case .cave1, .cave2: .cave
            }
        case .battle:
            if let battle, !battle.musicStopped {
                battle.battle.isBoss ? .boss : .battle
            } else {
                nil
            }
        case .ending: .ending
        }
    }

    // MARK: - タイトル

    /// タイトルの「はじめから」。まず名前を決める。
    func beginNaming() {
        playSound(.confirm)
        screen = .naming
    }

    /// 名前を決めて冒険を始める。空なら既定の名前。
    func newGame(name: String? = nil) {
        hero = Hero()
        if let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            hero.name = String(trimmed.prefix(Hero.maxNameLength))
        }
        mapID = World.startMap
        position = World.startPoint
        facing = .down
        openedChests = []
        enterField()
        say([
            "まおうが この国の 5つの地方の",
            "守護神を すべて あやつって しまった。",
            "まものは ふえ、地は あれはてた。",
            "ちょうろう「おお \(hero.name)よ。",
            "そなたには いにしえの ゆうしゃの ちが ながれておる。",
            "まずは この北海道の 守護神を 解きはなつのじゃ。",
            "きたの ほらあなの おくに おわす。」",
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
        guard map.isWalkable(next) else { return playSound(.bump) }
        isWalking = true
        lastMoveWasWarp = false
        walkFrame += 1
        position = next
        try? await Task.sleep(for: stepDuration)
        isWalking = false
        await arrived()
    }

    /// 黒幕を下ろす（まっくらにする）。
    private func drawCurtain(caption: String? = nil) async {
        isTransitioning = true
        curtainCaption = caption
        curtain = 1
        try? await Task.sleep(for: fadeDuration)
    }

    /// 黒幕を上げる（明るくもどす）。
    private func openCurtain() async {
        curtainCaption = nil
        curtain = 0
        try? await Task.sleep(for: fadeDuration)
        isTransitioning = false
    }

    private func arrived() async {
        if let warp = map.warps[position] {
            // 出入りは 暗転をはさんで「移った」と分かるようにする。
            playSound(.stairs)
            await drawCurtain()
            lastMoveWasWarp = true
            mapID = warp.to
            position = warp.at
            stepsSinceBattle = 0
            await openCurtain()
            return
        }
        guard let table = map.encounters[map.tile(at: position)], !table.isEmpty else { return }
        stepsSinceBattle += 1
        if stepsSinceBattle > Self.safeSteps, rng.chance(Self.encounterDenominator) {
            startBattle(EnemyGroup.random(from: table, rng: &rng).map(\.kind))
        }
    }

    // MARK: - ボタン

    func pressA() {
        if !pages.isEmpty { return advanceMessage() }
        guard screen == .field, overlay == .none, !isWalking, !isTransitioning else { return }
        interact()
    }

    func pressB() {
        if !pages.isEmpty { return advanceMessage() }
        guard screen == .field, !isWalking, !isTransitioning else { return }
        playSound(.cursor)
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
        let map = map
        var target = position + facing.delta
        // カウンター越しに、奥にいる人と話せる。
        if map.tile(at: target) == .counter { target = target + facing.delta }
        if let npc = map.npc(at: target) {
            playSound(.confirm)
            talk(to: npc)
        } else if let chest = map.chest(at: target) {
            open(chest)
        } else if map.boss == target {
            playSound(.confirm)
            say([
                "ゴゴゴ……",
                "知床の守護神「……ちが、ながれて いる な。",
                "だが われは まおうの もの。",
                "ふぶきの なかで ねむるが よい！」",
                "（あやつられた 守護神が おそいかかってきた！）",
            ]) { [weak self] in
                self?.startBattle(.guardian)
            }
        } else {
            playSound(.cursor)
            say(["\(hero.name)は あしもとを しらべた。", "しかし なにも みつからなかった。"])
        }
    }

    private func talk(to npc: NPC) {
        switch npc.role {
        case .elder:
            say(["ちょうろう「守護神は ふぶきを おこす。", "HPに よゆうを もって いどむのじゃ。", "ヒールを おぼえたら わすれずに つかうのじゃぞ。」"])
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
        playSound(.chest)
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
        playSound(.cursor)
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
        say(["やどや「ゆっくり おやすみください。」"]) { [weak self] in
            Task { await self?.sleepAtInn() }
        }
    }

    func buy(_ item: Item) {
        guard hero.gold >= item.price else {
            return say(["どうぐや「おかねが たりないよ。」"])
        }
        if hero.owns(item), item.kind != .consumable {
            return say(["どうぐや「それは もう もっているよ。」"])
        }
        hero.gold -= item.price
        hero.receive(item)
        playSound(.coin)
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
        playSound(.heal)
        overlay = .none
        say(["\(hero.name)は \(spell.name)を となえた！", "HPが \(healed) かいふくした！"])
    }

    func useHerbInField() {
        guard hero.consume(.herb) else { return say(["どうぐが ない！"]) }
        let healed = hero.heal(rng.next(in: Item.herbPower))
        playSound(.heal)
        overlay = .none
        say(["\(hero.name)は 薬草を つかった！", "HPが \(healed) かいふくした！"])
    }

    func save() {
        SaveStore.save(SaveData(hero: hero, map: mapID, position: position, openedChests: openedChests))
        hasSave = true
    }

    /// 宿屋で眠る。画面をまっくらにして、ジングルのあいだ寝かせてから朝にする。
    private func sleepAtInn() async {
        await drawCurtain(caption: "……Zzz……")
        playSound(.inn)
        hero.restoreFully()
        save()
        try? await Task.sleep(for: sleepDuration)
        await openCurtain()
        say(["おはようございます。", "HPと MPが かいふくした！", "ぼうけんの きろくを かきとめました。"])
    }

    // MARK: - そうびと 売り買い

    func equip(_ item: Item) {
        hero.equip(item)
        playSound(.confirm)
        overlay = .none
        say(["\(item.name)を そうびした。"])
    }

    func unequip(_ item: Item) {
        hero.unequip(item)
        playSound(.cursor)
        overlay = .none
        say(["\(item.name)を はずした。"])
    }

    /// 売れるのは どうぐやの中だけ。
    func sell(_ item: Item) {
        guard overlay == .shop else { return }
        guard let paid = hero.sell(item) else {
            return say(["どうぐや「それは そうびしたままだよ。」"])
        }
        playSound(.coin)
        // 続けて売れるよう、店は開けたままにする（買うときと同じ）。
        say(["どうぐや「まいどあり！」", "\(item.name)を うって \(paid)ゴールドに なった。"])
    }

    func saveFromMenu() {
        save()
        playSound(.confirm)
        overlay = .none
        say(["ぼうけんの きろくを かきとめました。"])
    }

    // MARK: - 戦闘

    func startBattle(_ kind: EnemyKind) {
        startBattle([kind])
    }

    func startBattle(_ kinds: [EnemyKind]) {
        let group = EnemyGroup.numbered(kinds)
        guard !group.isEmpty else { return }
        heldDirection = nil
        playSound(.encounter)
        battle = BattleSession(
            battle: Battle(hero: hero, enemies: group),
            log: [EnemyGroup.encounterText(group)]
        )
        overlay = .none
        screen = .battle
    }

    func command(_ command: BattleCommand, target: Int? = nil) async {
        guard var session = battle, !session.isPlaying, session.end == nil else { return }
        let result = session.battle.take(command, target: target, rng: &rng)
        session.log = []
        session.isPlaying = true
        battle = session
        for line in result.lines {
            await pace(before: line)
            show(line)
        }
        // 最後の行を読む間を置いてからコマンドに戻す。
        try? await Task.sleep(for: messageInterval)
        hero = session.battle.hero
        battle?.isPlaying = false
        battle?.end = result.end
    }

    /// 行の前の間。同じ場面の続きは少し待って下に足し、行動が変わるときは長めに待って枠を空ける。
    /// 戦いの結果（経験値・レベルアップ）は ▼ を出してタップを待ってから次のページへ。
    private func pace(before line: BattleLine) async {
        guard let log = battle?.log, !log.isEmpty else { return }
        switch line.pause {
        case .none:
            try? await Task.sleep(for: messageInterval)
        case .beat:
            try? await Task.sleep(for: beatPause)
            battle?.log = []
        case .page:
            try? await Task.sleep(for: messageInterval)
            await waitForTap()
            battle?.log = []
        }
    }

    private func show(_ line: BattleLine) {
        battle?.log.append(line.text)
        if let count = battle?.log.count, count > 4 { battle?.log.removeFirst(count - 4) }
        // HP・MP・レベルの表示は、その行が出たときに合わせて変える。
        if let snapshot = line.hero { hero = snapshot }
        if let damage = line.enemyDamage {
            // 書き換えの最中に battle を読むと排他アクセス違反で落ちるので、次の番号は先に取り出す。
            let nextID = (battle?.enemyHit?.id ?? 0) + 1
            battle?.enemyHit = EnemyHit(
                id: nextID, enemyID: line.enemyID ?? 0, damage: damage, isCritical: line.isCritical
            )
        }
        if let defeated = line.defeatedID {
            battle?.defeatedIDs.insert(defeated)
        }
        if let damage = line.heroDamage {
            let nextID = (battle?.heroHit?.id ?? 0) + 1
            let isHeavy = damage * 3 >= (line.hero?.maxHP ?? .max)
            battle?.heroHit = HeroHit(id: nextID, damage: damage, isHeavy: isHeavy)
        }
        if let kind = line.effect {
            // 書き換えの最中に battle を読むと排他アクセス違反で落ちるので、次の番号は先に取り出す。
            let nextID = (battle?.effect?.id ?? 0) + 1
            battle?.effect = EffectCue(id: nextID, kind: kind)
        }
        if let cue = line.cue {
            if cue == .victory || cue == .gameOver { battle?.musicStopped = true }
            playSound(cue)
        }
    }

    private func waitForTap() async {
        guard waitsForTap else { return }
        battle?.waitingForTap = true
        await withCheckedContinuation { continuation in
            tapContinuation = continuation
        }
        battle?.waitingForTap = false
    }

    /// 戦闘メッセージの ▼ でタップされたら次のページへ。
    func advanceBattleMessage() {
        let continuation = tapContinuation
        tapContinuation = nil
        continuation?.resume()
    }

    func finishBattle() async {
        guard let session = battle, let end = session.end else { return }
        hero = session.battle.hero
        stepsSinceBattle = 0
        switch end {
        case .won where session.battle.isBoss:
            battle = nil
            screen = .ending
        case .won, .fled:
            battle = nil
            screen = .field
        case .lost:
            // 気を失って村で目を覚ますので、暗転をはさむ。
            await drawCurtain()
            hero.gold /= 2
            hero.restoreFully()
            mapID = World.revivePoint.map
            position = World.revivePoint.point
            facing = .up
            enterField()
            await openCurtain()
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
