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
    /// 敵に当たった最新の一撃。ダメージの数字は これに当たった敵だけに出す。
    var enemyHit: EnemyHit?
    /// 敵ごとの 最後に当たった一撃。画面は これが変わった敵だけを 揺らす。
    /// （最新の一撃だけを見ていると、別の敵に当たったとき「自分への一撃が なくなった」のも 変化になり、
    /// 当たっていない敵まで 揺れて 点滅していた。「ちしき」で 全員に当てた あとに 目立った）
    var lastHits: [Int: EnemyHit] = [:]
    /// 呪文・道具の最新の演出。画面はこれが変わるたびに粒や炎を出す。
    var effect: EffectCue?
    /// いま出しているレベルアップの画面。次の行が出たら消える。
    var levelUp: LevelUpPage?
}

/// ちしき検定の 進みぐあい。
struct ExamSession: Equatable {
    let region: Region
    let questions: [Quiz]
    var index = 0
    var correct = 0

    /// いま 出している 問題。おわったら nil。
    var current: Quiz? { questions.indices.contains(index) ? questions[index] : nil }
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

/// ウィンドウに出ている選択肢の一行。画面が並べた順に、十字キーの カーソルが たどる。
struct ChoiceSlot: Equatable {
    /// 行の見出し。ウィンドウの中では重ならないので、そのまま見分けに使う。
    let id: String
    let isEnabled: Bool
}

@MainActor
@Observable
final class GameState {
    enum Screen: Equatable { case title, naming, field, battle, ending }
    enum Overlay: Equatable {
        case none, menu, status, items, spells, shop, inn
        /// きろく（まつり・ずかん・てちょう・スタンプ・検定）。
        case records, book, notebook
        /// ちしき検定の 問題。
        case exam
        /// 新幹線の 行き先。
        case train
    }

    /// 1歩ごとの遭遇率（分母）と、戦闘後に遭遇しない歩数。
    static let encounterDenominator = 14
    static let safeSteps = 4

    var screen: Screen = .title
    var hero = Hero()
    var mapID: MapID = World.startMap
    var position = World.startPoint
    var facing: Direction = .down
    var openedChests: Set<String> = []
    var overlay: Overlay = .none {
        // ウィンドウが入れかわったら、前の選択肢は捨ててカーソルを頭に戻す。
        didSet { if overlay != oldValue { choices = []; cursor = 0 } }
    }
    var battle: BattleSession?
    var isWalking = false
    var walkFrame = 0
    /// 直前の位置変更がワープだったか。ワープではスクロールのアニメーションをしない。
    var lastMoveWasWarp = true
    /// 倒したボス。つぎの ほらあなに入れるかの判定に使う。
    var defeatedBosses: Set<EnemyKind> = []
    /// 宿屋・道具屋から出たときに戻る街。
    var lastTown: MapID = World.startMap
    /// 宿屋・道具屋から出たときに立つ場所（入った扉の前）。街ごとに扉の位置が ちがうため。
    var interiorReturn: Point?
    /// 物語の進みぐあい（人の頼みを片づけると立つ）。
    var storyFlags: Set<StoryFlag> = []
    /// 読んだ 名所の看板（めいしょ スタンプ）。
    var readPlaques: Set<PlaqueID> = []
    /// 県ごとの 押した スタンプの数。
    var stamps: [Region: Int] {
        Dictionary(grouping: readPlaques.intersection(World.stampPlaques), by: { $0.map.region ?? .aomori })
            .mapValues(\.count)
    }
    /// 倒した ことの ある 敵（まもの ずかん）。
    var seenEnemies: Set<EnemyKind> = []
    /// 正解した ことの ある 問題（ちしきの てちょう）。問題文で おぼえる。
    var learnedQuizzes: Set<String> = []
    /// つづけて 正解した 数（ちしき コンボ）。まちがえると 0。
    var quizStreak = 0
    var progress: StoryProgress {
        StoryProgress(flags: storyFlags, defeatedBosses: defeatedBosses, stamps: stamps, seen: seenEnemies.count)
    }
    /// いまの地図に 出ている人。
    var npcs: [NPC] { map.npcs(progress) }
    /// 街ごとの「ちしき」の問題の山。戦いをまたいで続きから出す（毎回 同じ問題から始まらないように）。
    @ObservationIgnored var quizDecks: [MapID: [Quiz]] = [:]
    /// いま出ている「ちしきの チャンス」。答えを選ぶと こうげきと いっしょに 出す。
    private(set) var quizChance: Quiz?
    /// チャンスが出たときに ねらっていた相手。
    @ObservationIgnored private var quizTarget: Int?
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
    /// 街に入ったときに しばらく出す 地名の札。フィールドから入ったときだけ（宿屋から出たときは出さない）。
    private(set) var arrivalBanner: PlaceBanner?
    @ObservationIgnored private var bannerTask: Task<Void, Never>?
    /// 地名の札を出しておく時間。
    @ObservationIgnored var bannerDuration: Duration = .milliseconds(2600)

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

    static let soundKey = "geohero2.soundEnabled"
    /// 音のオン・オフ（メニューで切り替え、端末に保存する）。
    var soundEnabled = UserDefaults.standard.object(forKey: GameState.soundKey) as? Bool ?? true {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Self.soundKey) }
    }

    var map: GameMap { World.map(mapID) }
    /// いまの県。宿屋・道具屋の中では 入ってきた街の県。
    var region: Region { mapID.region ?? lastTown.region ?? .aomori }
    var currentPage: [String]? { pages.first }
    /// いま使っている街。宿屋・道具屋の中では 入ってきた街を見る。
    var town: TownInfo { mapID.townInfo ?? lastTown.townInfo ?? World.startMap.townInfo! }
    /// 宿代。奥の街ほど 高い。
    var innPrice: Int { town.innBase + hero.level * town.innPerLevel }
    /// 道具屋の品ぞろえ。街ごとに変える。
    var shopStock: [Item] { town.stock }
    var canWalk: Bool { screen == .field && pages.isEmpty && overlay == .none && !isWalking && !isTransitioning }

    /// いまの地図に まだ立っているボス。倒したボスは 二度と出さない（居座って何度も戦えてしまうため）。
    var bossPoint: Point? {
        guard let kind = map.bossKind, !defeatedBosses.contains(kind) else { return nil }
        return map.boss
    }

    /// いま流す BGM。場面から決まる。
    var musicTrack: MusicTrack? {
        switch screen {
        // 名前を決めているあいだも タイトルの曲を流し続ける。
        case .title, .naming: .title
        case .field:
            if mapID.isField { .field(region) } else if mapID.isCave { .cave(region) } else { .village(region) }
        case .battle:
            if let battle, !battle.musicStopped {
                if battle.battle.enemies.contains(where: { $0.kind.isFinalBoss || $0.kind.isSecretBoss }) {
                    .finalBoss
                } else {
                    battle.battle.isBoss ? .boss : .battle(region)
                }
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
        defeatedBosses = []
        storyFlags = []
        readPlaques = []
        seenEnemies = []
        learnedQuizzes = []
        quizStreak = 0
        quizDecks = [:]
        lastTown = World.startMap
        interiorReturn = nil
        enterField()
        say([
            "北海道の 守護神を 解きはなった \(hero.name)は、",
            "青函トンネルを ぬけて 本州の 青森に たどりついた。",
            "しかし 東北でも まおうが 守護神を あやつり、",
            "6つの 県の まつりの 火を けしてしまった。",
            "まつりの きえた 街は げんきを なくし、まものが ふえている。",
            "ちょうろう「おお \(hero.name)よ、よくぞ きてくれた。",
            "　6つの 県の ぬしを たおして まつりを とりもどせば",
            "　蔵王の 守護神も 正気に もどるはずじゃ。",
            "　まずは この 青森の ねぶたじゃ。",
            "　ねぶたの家の ねぶた師に 話を きくのじゃ。」",
            "（十字キーで あるき、Aで はなす・しらべる、",
            "Bで メニューを ひらけます）",
            "（たたかいで こうげきすると ときどき",
            "「ちしきの チャンス」が でます。",
            "つづけて せいかいすると コンボで 強く なります）",
        ])
    }

    func continueGame() {
        guard let save = SaveStore.load() else { return newGame() }
        hero = save.hero
        mapID = save.map
        position = save.position
        openedChests = save.openedChests
        defeatedBosses = save.defeatedBosses
        storyFlags = save.storyFlags
        readPlaques = save.readPlaques
        seenEnemies = save.seenEnemies
        learnedQuizzes = save.learnedQuizzes
        quizStreak = save.quizStreak
        lastTown = save.lastTown
        interiorReturn = save.interiorReturn
        if mapID.isTown { lastTown = mapID }
        // 地図を描きなおした街で 古いセーブの位置が 建物や海の中に なっていたら、街の入口へ。
        if !map.contains(position) || !map.tile(at: position).isPassable {
            (mapID, position) = World.revivePoint(in: region)
        }
        facing = .down
        enterField()
    }

    private func enterField() {
        hideBanner()
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
    /// 歩いている途中に ちょんと押して離した向き。次の一歩で 使う。
    @ObservationIgnored private var tappedDirection: Direction?

    /// 押している間は歩き続ける。歩く処理は常に1本だけ動かす。
    /// ちょんと押してすぐ離しても 一歩は歩く（歩く処理が 動き出す前に「離した」が
    /// 届くことがあり、端末によっては タップで まったく歩かなかったため）。
    func hold(_ direction: Direction?) {
        guard heldDirection != direction else { return }
        heldDirection = direction
        // ウィンドウが出ているあいだは、同じ十字キーで カーソルを動かす。
        if isChoosing {
            if let direction { moveCursor(direction) }
            return
        }
        guard let direction else { return }
        guard walkLoop == nil else {
            tappedDirection = direction
            return
        }
        tappedDirection = nil
        walkLoop = Task { [weak self] in
            var next: Direction? = direction
            while let self, let current = next, self.screen == .field, !Task.isCancelled {
                let before = self.position
                await self.walk(current)
                // 壁や会話中で進めなかったときは空回りしないよう少し待つ。
                if self.position == before {
                    try? await Task.sleep(for: .milliseconds(80))
                }
                next = self.heldDirection ?? self.tappedDirection
                self.tappedDirection = nil
            }
            self?.tappedDirection = nil
            self?.walkLoop = nil
        }
    }

    func walk(_ direction: Direction) async {
        guard canWalk else { return }
        facing = direction
        let next = position + direction.delta
        guard map.isWalkable(next, bossRemains: bossPoint != nil, progress: progress) else { return playSound(.bump) }
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
        // 駅に のったら 行き先を えらぶ。
        if map.tile(at: position) == .station {
            playSound(.confirm)
            overlay = .train
            return
        }
        if let warp = map.warps[position] {
            // まだ前のボスを倒していない ほらあなには入れない。
            if let needed = warp.requires, !defeatedBosses.contains(needed) {
                playSound(.bump)
                say(["つよい かぜが ふきつけて さきへ すすめない。",
                     "（\(needed.stats.name)を たおすと 道がひらける）"])
                return
            }
            // 頼まれごとを片づけていないと 入れない場所。
            if let flag = warp.needs, !progress.has(flag) {
                playSound(.bump)
                say(flag.gateLines)
                return
            }
            // 出入りは 暗転をはさんで「移った」と分かるようにする。
            playSound(.stairs)
            await drawCurtain()
            lastMoveWasWarp = true
            if mapID.isTown { lastTown = mapID }
            let from = mapID
            if warp.to.isInterior { interiorReturn = position + Point(x: 0, y: 1) }
            // 宿屋・道具屋から出るときは 入ってきた街の 扉の前へ戻す。
            if from.isInterior {
                mapID = lastTown
                position = interiorReturn ?? warp.at
            } else {
                mapID = warp.to
                position = warp.at
            }
            stepsSinceBattle = 0
            hideBanner()
            await openCurtain()
            if from.isField, let town = mapID.townInfo {
                showBanner(town.banner)
            }
            return
        }
        guard let table = map.encounterTable(at: position), !table.isEmpty else { return }
        stepsSinceBattle += 1
        if stepsSinceBattle > Self.safeSteps, rng.chance(Self.encounterDenominator) {
            startBattle(EnemyGroup.random(from: table, rng: &rng).map(\.kind))
        }
    }

    /// 街の名前の札を出し、しばらくしたら消す。
    private func showBanner(_ banner: PlaceBanner) {
        bannerTask?.cancel()
        arrivalBanner = banner
        let duration = bannerDuration
        bannerTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.arrivalBanner = nil
        }
    }

    private func hideBanner() {
        bannerTask?.cancel()
        bannerTask = nil
        arrivalBanner = nil
    }

    // MARK: - 新幹線

    /// 新幹線で 県を うつる。駅の 下に おりる。
    func travel(to destination: Region) async {
        overlay = .none
        guard destination != region else { return }
        guard progress.canTravel(to: destination) else {
            playSound(.bump)
            return say(["かかりいん「\(destination.shortName)ゆきの きっぷを おもちですか？",
                        "　……きっぷが ないと おのせ できません。」"])
        }
        playSound(.stairs)
        await drawCurtain(caption: "しんかんせんで はしっている……")
        try? await Task.sleep(for: sleepDuration)
        let field = World.map(destination.field)
        mapID = destination.field
        position = (field.station ?? Point(x: 1, y: 1)) + Point(x: 0, y: 1)
        facing = .down
        lastMoveWasWarp = true
        stepsSinceBattle = 0
        hideBanner()
        await openCurtain()
        showBanner(destination.banner)
    }

    /// 駅から おりずに 引きかえす（いまの 県に いる）。
    func stayOnPlatform() {
        overlay = .none
    }

    // MARK: - ちしき検定

    /// いま うけている ちしき検定。
    private(set) var exam: ExamSession?

    /// 県の 問題から \(Story.examLength)もん 出す。ぜんぶ 正解で 合格。
    func startExam(_ region: Region) {
        let questions = Array(QuizBank.quizzes(in: region).shuffled().prefix(Story.examLength))
        guard !questions.isEmpty else { return }
        exam = ExamSession(region: region, questions: questions)
        overlay = .exam
    }

    /// 検定の 答え。まちがえたら そこで おわり（また いつでも うけられる）。
    func answerExam(_ choice: Int) {
        guard var session = exam, let quiz = session.current else { return }
        overlay = .none
        session.index += 1
        guard choice == quiz.answer else {
            playSound(.miss)
            exam = nil
            return say(["ざんねん！ こたえは「\(quiz.correctChoice)」。",
                        "けんていいん「\(session.index - 1)もん せいかい でした。",
                        "　\(session.region.shortName)の 人の 話を よく きいて また どうぞ。」"])
        }
        playSound(.critical)
        learnedQuizzes.insert(quiz.question)
        session.correct += 1
        exam = session
        if session.current != nil {
            say(["せいかい！（\(session.correct)／\(session.questions.count)）"]) { [weak self] in
                self?.overlay = .exam
            }
            return
        }
        exam = nil
        let reward = Story.examReward(session.region)
        storyFlags.insert(.examPassed(session.region))
        hero.receive(reward)
        playSound(.levelUp)
        say(["せいかい！（\(session.correct)／\(session.questions.count)）",
             "けんていいん「おみごと！ \(session.region.name)の ちしき検定 合格です！",
             "　ごほうびに \(reward.name)を どうぞ。」",
             "\(reward.name)を てにいれた！",
             "（\(reward.effectNote)）"])
    }

    /// 検定を とちゅうで やめる。
    func quitExam() {
        exam = nil
        overlay = .none
        say(["けんていいん「また いつでも どうぞ。」"])
    }

    // MARK: - ウィンドウの カーソル

    /// いま指している行。十字キーで動かし、A で決める。
    private(set) var cursor = 0
    /// 出ている選択肢。画面が `setChoices` で知らせる。
    @ObservationIgnored private(set) var choices: [ChoiceSlot] = []
    /// A で決めた回数。画面はこれが増えたら 指している行を実行する。
    private(set) var confirmCount = 0
    /// B で戻した回数。画面はこれが増えたら「もどる」の行を実行する。
    private(set) var cancelCount = 0

    /// 十字キーが 歩くのではなく カーソルを動かすとき（ウィンドウが出ていて 会話は出ていない）。
    var isChoosing: Bool { screen == .field && pages.isEmpty && overlay != .none && !isTransitioning }

    /// 画面が いま出している選択肢を知らせる。並びが変わったら カーソルを頭に戻す。
    /// **どのウィンドウにも「もどる」にあたる行をひとつ入れる**。B ボタンの行き先がなくなるため。
    func setChoices(_ next: [ChoiceSlot]) {
        let sameList = next.map(\.id) == choices.map(\.id)
        choices = next
        if !sameList {
            cursor = next.firstIndex(where: \.isEnabled) ?? 0
        } else if cursor >= next.count {
            cursor = max(0, next.count - 1)
        }
    }

    /// 十字キーで となりの行へ。選べない行は とばし、端まで来たら 反対の端へ回る。
    func moveCursor(_ direction: Direction) {
        let step = (direction == .up || direction == .left) ? -1 : 1
        guard let next = selectable(from: cursor, step: step), next != cursor else { return }
        cursor = next
        playSound(.cursor)
    }

    /// タップで選ばれた行に カーソルを合わせる（十字キーの続きが そこから始まるように）。
    func moveCursor(to index: Int) {
        guard choices.indices.contains(index) else { return }
        cursor = index
    }

    /// `index` から `step` の向きへ、次に選べる行をさがす。ひと回りして なければ nil。
    private func selectable(from index: Int, step: Int) -> Int? {
        guard !choices.isEmpty else { return nil }
        var candidate = index
        for _ in choices.indices {
            candidate = (candidate + step + choices.count) % choices.count
            if choices[candidate].isEnabled { return candidate }
        }
        return nil
    }

    /// A で いま指している行を決める。選べない行なら 音だけ返す。
    func confirmChoice() {
        guard choices.indices.contains(cursor), choices[cursor].isEnabled else { return playSound(.bump) }
        playSound(.cursor)
        confirmCount += 1
    }

    // MARK: - ボタン

    func pressA() {
        if !pages.isEmpty { return advanceMessage() }
        if isChoosing { return confirmChoice() }
        guard screen == .field, overlay == .none, !isWalking, !isTransitioning else { return }
        interact()
    }

    func pressB() {
        if !pages.isEmpty { return advanceMessage() }
        guard screen == .field, !isWalking, !isTransitioning else { return }
        playSound(.cursor)
        // ウィンドウが出ていれば「もどる」を押したことにして、どこへ戻すかは画面にまかせる。
        if overlay == .none { overlay = .menu } else { cancelCount += 1 }
    }

    func closeOverlay() {
        overlay = .none
    }

    private func interact() {
        let map = map
        var target = position + facing.delta
        // カウンター越しに、奥にいる人と話せる。
        if map.tile(at: target) == .counter { target = target + facing.delta }
        if let npc = map.npc(at: target, progress) {
            playSound(.confirm)
            talk(to: npc)
        } else if let chest = map.chest(at: target) {
            open(chest)
        } else if map.tile(at: target) == .signpost, let plaque = map.plaques[target] {
            playSound(.confirm)
            say(plaque.lines + stamp(PlaqueID(map: mapID, point: target)))
        } else if map.tile(at: target) == .signpost, let town = mapID.townInfo {
            playSound(.confirm)
            say(["かんばんに こう かいてある。", "「ここは \(town.name)（\(town.reading)）。", "\(town.tagline)」"])
        } else if bossPoint == target, let kind = map.bossKind {
            playSound(.confirm)
            say(Story.bossGreeting(kind)) { [weak self] in
                self?.startBattle(kind)
            }
        } else {
            playSound(.cursor)
            say(["\(hero.name)は あしもとを しらべた。", "しかし なにも みつからなかった。"])
        }
    }

    /// 名所の看板を はじめて読んだら スタンプを押す。押したときの せりふを返す。
    private func stamp(_ plaque: PlaqueID) -> [String] {
        guard World.stampPlaques.contains(plaque), readPlaques.insert(plaque).inserted else { return [] }
        playSound(.chest)
        let region = plaque.map.region ?? .aomori
        return ["めいしょ スタンプを おした！（\(stamps[region, default: 0])／\(World.stampTotal(in: region))）"]
    }

    private func talk(to npc: NPC) {
        switch npc.role {
        case .elder:
            say(Story.elderHint(progress))
        case .villager(let lines):
            say(lines)
        case .resident(let resident):
            play(resident.scene(progress))
        case .innkeeper:
            overlay = .inn
        case .shopkeeper:
            overlay = .shop
        }
    }

    /// 物語の場面を出す。ごほうびは すぐ渡し（左上の所持金が せりふと そろうように）、
    /// 印は 読み終えてから立てる（迷子が 話の途中で 消えないように）。
    private func play(_ scene: StoryScene) {
        if scene.gold > 0 || !scene.items.isEmpty || !scene.sets.isEmpty { playSound(.chest) }
        hero.gold += scene.gold
        for item in scene.items { hero.receive(item) }
        if scene.heals {
            hero.restoreFully()
            playSound(.heal)
        }
        say(scene.lines) { [weak self] in
            self?.storyFlags.formUnion(scene.sets)
            if let region = scene.startsExam { self?.startExam(region) }
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
            // めずらしい 道具は 何に 使うかも 見せる。
            let note: String = switch item.kind {
            case .consumable: item.isTreasure ? "（\(item.effectNote)）" : ""
            case .charm: hero.charm == item ? "さっそく みにつけた。" : "（\(item.effectNote)）"
            default: "さっそく そうびした。"
            }
            say(["たからばこを あけた！", "\(item.name)を てにいれた！", note].filter { !$0.isEmpty })
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

    /// その品を買うのに あと いくら足りないか。0 なら買える。
    func shortfall(for item: Item) -> Int { max(0, item.price - hero.gold) }

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
        guard spell.isFieldUsable, hero.spells.contains(spell), hero.mp >= spell.mpCost else {
            return say(["MPが たりない！"])
        }
        if spell.effect == .escape {
            guard let exit = World.caveExit(from: mapID) else {
                overlay = .none
                return say(["\(hero.name)は \(spell.name)を となえた！", "しかし ここでは つかえない。"])
            }
            hero.mp -= spell.mpCost
            overlay = .none
            Task { await escape(to: exit) }
            return
        }
        hero.mp -= spell.mpCost
        let healed = hero.heal(rng.next(in: spell.power))
        playSound(.heal)
        overlay = .none
        say(["\(hero.name)は \(spell.name)を となえた！", "HPが \(healed) かいふくした！"])
    }

    /// だっしゅつ：ほらあなの 入口の 前へ もどる。
    private func escape(to exit: (map: MapID, point: Point)) async {
        playSound(.spell)
        await drawCurtain()
        mapID = exit.map
        position = exit.point
        facing = .down
        lastMoveWasWarp = true
        stepsSinceBattle = 0
        await openCurtain()
        say(["\(hero.name)は \(Spell.escape.name)を となえた！", "ほらあなの いりぐちに もどってきた。"])
    }

    func useHerbInField() { useInField(.apple) }

    /// 回復の道具を フィールドで つかう。
    func useInField(_ item: Item) {
        guard let effect = item.effect, hero.consume(item) else { return say(["どうぐが ない！"]) }
        let (amount, isMP) = hero.apply(effect, rng: &rng)
        playSound(.heal)
        overlay = .none
        if case let .grow(growth, _) = effect {
            return say(["\(hero.name)は \(item.name)を たべた！", "\(growth.label)が \(amount) あがった！"])
        }
        say(["\(hero.name)は \(item.name)を つかった！", "\(isMP ? "MP" : "HP")が \(amount) かいふくした！"])
    }

    func save() {
        SaveStore.save(SaveData(
            hero: hero, map: mapID, position: position,
            openedChests: openedChests, defeatedBosses: defeatedBosses,
            storyFlags: storyFlags, readPlaques: readPlaques, lastTown: lastTown, interiorReturn: interiorReturn,
            seenEnemies: seenEnemies, learnedQuizzes: learnedQuizzes, quizStreak: quizStreak
        ))
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

    // MARK: - きろく・評価

    /// シェアする きろくカードの 中身。
    var adventureSummary: AdventureSummary {
        let bosses = EnemyKind.allCases.filter(\.isBoss)
        return AdventureSummary(
            name: hero.name, level: hero.level, regionName: region.name,
            festivals: Region.allCases.filter(progress.festivalRestored).count,
            bosses: bosses.filter { defeatedBosses.contains($0) }.count, bossTotal: bosses.count,
            stamps: stamps.values.reduce(0, +), stampTotal: World.stampPlaques.count,
            book: seenEnemies.count, bookTotal: EnemyKind.allCases.count,
            lastBoss: bosses.last { defeatedBosses.contains($0) },
            cleared: defeatedBosses.contains(.guardian),
            mastered: defeatedBosses.contains(.maouShadow)
        )
    }

    static let reviewKey = "geohero2.reviewAskedVersion"
    /// 評価を たのんだ 回数。画面は これが 増えたら iOS の 評価の ダイアログを 出す。
    private(set) var reviewRequests = 0
    /// アプリの バージョン（評価を たのむのは バージョンごとに 1回だけ）。
    @ObservationIgnored var appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

    /// 中ぐらいの ぬしを たおして 気分の いいときに、評価を たのむ（バージョンごとに 1回）。
    private func askForReviewIfFitting(after kind: EnemyKind) {
        guard [.namahageKing, .datemaru, .tenagaAshinaga].contains(kind),
              UserDefaults.standard.string(forKey: Self.reviewKey) != appVersion else { return }
        UserDefaults.standard.set(appVersion, forKey: Self.reviewKey)
        reviewRequests += 1
    }

    // MARK: - そうびと 売り買い

    func equip(_ item: Item) {
        hero.equip(item)
        playSound(.confirm)
        overlay = .none
        say([item.isCharm ? "\(item.name)を みにつけた。" : "\(item.name)を そうびした。"])
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

    /// 戦闘の枠に出しておく行数。枠の高さ（`BattleView.messageHeight`）と対で決めている。
    static let battleLogLines = 3

    func startBattle(_ kind: EnemyKind) {
        startBattle([kind])
    }

    func startBattle(_ kinds: [EnemyKind]) {
        let group = EnemyGroup.numbered(kinds)
        guard !group.isEmpty else { return }
        heldDirection = nil
        tappedDirection = nil
        playSound(.encounter)
        var quizzes: [Quiz] = []
        if let town = QuizBank.town(at: mapID, position) {
            quizzes = quizDecks[town] ?? (QuizBank.byTown[town] ?? []).shuffled()
        }
        battle = BattleSession(
            battle: Battle(hero: hero, enemies: group, quizzes: quizzes, streak: quizStreak),
            log: [EnemyGroup.encounterText(group)]
        )
        overlay = .none
        screen = .battle
    }

    func command(_ command: BattleCommand, target: Int? = nil) async {
        guard var session = battle, !session.isPlaying, session.end == nil else { return }
        quizChance = nil
        let result = session.battle.take(command, target: target, rng: &rng)
        if let town = QuizBank.town(at: mapID, position), !session.battle.quizzes.isEmpty {
            quizDecks[town] = session.battle.quizzes
        }
        // コンボと てちょうは 答えた その場で のこす（にげても 消えないように）。
        quizStreak = session.battle.streak
        learnedQuizzes.formUnion(session.battle.solved.map(\.question))
        session.log = []
        session.isPlaying = true
        battle = session
        for line in result.lines {
            await pace(before: line)
            show(line)
        }
        // レベルアップの板は最後の行で出ることがある。そのままだと閉じる契機がなく、
        // 画面をタップしても進めなくなるので、ここでタップを待ってから閉じる。
        if battle?.levelUp != nil {
            await waitForTap()
            battle?.levelUp = nil
        }
        // 最後の行を読む間を置いてからコマンドに戻す。
        try? await Task.sleep(for: messageInterval)
        hero = session.battle.hero
        battle?.isPlaying = false
        battle?.end = result.end
    }

    /// 「こうげき」を選んだ。ときどき「ちしきの チャンス」が出て、答えを選ぶまで 待つ。
    /// 出なければ そのまま こうげきする。
    func attack(target: Int?) async {
        if offerQuizChance(target: target) { return }
        await command(.attack, target: target)
    }

    /// 「ちしきの チャンス」を くじで出す。出たら メッセージの枠に 問題を出して true。
    /// `force` は 表示確認用（かならず出す）。
    @discardableResult
    func offerQuizChance(target: Int?, force: Bool = false) -> Bool {
        guard let session = battle, !session.isPlaying, session.end == nil, quizChance == nil,
              let quiz = session.battle.nextQuiz,
              force || rng.chance(session.battle.quizChanceDenominator) else { return false }
        quizChance = quiz
        quizTarget = target
        playSound(.critical)
        battle?.log = ["ちしきの チャンス！", quiz.question]
        return true
    }

    /// 「ちしきの チャンス」に 答える。こうげきして、正解なら 追い打ち。
    func answerQuiz(_ choice: Int) async {
        guard quizChance != nil else { return }
        await command(.quizAttack(answer: choice), target: quizTarget)
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
        // 枠に収まる行数だけ残す。あふれると下の行が切れる。
        if let count = battle?.log.count, count > GameState.battleLogLines {
            battle?.log.removeFirst(count - GameState.battleLogLines)
        }
        // HP・MP・レベルの表示は、その行が出たときに合わせて変える。
        if let snapshot = line.hero { hero = snapshot }
        if let damage = line.enemyDamage {
            // 書き換えの最中に battle を読むと排他アクセス違反で落ちるので、次の番号は先に取り出す。
            let nextID = (battle?.enemyHit?.id ?? 0) + 1
            let hit = EnemyHit(id: nextID, enemyID: line.enemyID ?? 0, damage: damage, isCritical: line.isCritical)
            battle?.enemyHit = hit
            battle?.lastHits[hit.enemyID] = hit
        }
        // レベルアップの画面は、その行のあいだだけ出す。
        battle?.levelUp = line.levelUp
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
        if case .won = end {
            // 倒した 敵を ずかんに のせる。
            let fresh = Set(session.battle.enemies.map(\.kind)).subtracting(seenEnemies)
            seenEnemies.formUnion(fresh)
        }
        switch end {
        case .won where session.battle.isBoss:
            let kind = session.battle.enemies.first?.kind
            if let kind { defeatedBosses.insert(kind) }
            battle = nil
            if kind?.isFinalBoss == true || kind?.isSecretBoss == true {
                endingKind = kind?.isSecretBoss == true ? .secret : .main
                screen = .ending
            } else {
                screen = .field
                if let kind {
                    say(Story.bossDefeated(kind)) { [weak self] in self?.askForReviewIfFitting(after: kind) }
                }
            }
        case .won, .fled:
            battle = nil
            screen = .field
        case .lost:
            // 気を失って村で目を覚ますので、暗転をはさむ。
            await drawCurtain()
            hero.gold /= 2
            hero.restoreFully()
            (mapID, position) = World.revivePoint(in: region)
            facing = .up
            enterField()
            await openCurtain()
            say(["\(hero.name)は 村の いりぐちで めを さました。", "もっていた ゴールドが はんぶんに なった……"])
        }
    }

    // MARK: - エンディングの あと

    enum EndingKind: Equatable { case main, secret }
    /// いま 出している エンディング。
    private(set) var endingKind: EndingKind = .main

    /// エンディングの あとも 冒険を つづける（恐山や ずかん うめの ため）。
    /// 守護神を 倒した 蔵王の ふもとの 山形の 街に もどして、きろくを かきとめる。
    func continueAfterEnding() {
        let (map, point) = endingKind == .secret ? World.revivePoint(in: .aomori) : World.revivePoint(in: .yamagata)
        mapID = map
        position = point
        lastTown = map
        interiorReturn = nil
        facing = .down
        hero.restoreFully()
        enterField()
        save()
        say(endingKind == .secret
            ? ["\(hero.name)は 恐山から 青森の 街に もどってきた。", "ぼうけんの きろくを かきとめました。"]
            : ["\(hero.name)は 山形の 街に もどってきた。",
               "東北の 守護神「下北の 恐山に まだ やみが のこっている。",
               "　6県の ちしきを きわめ、うちはらって おくれ。」",
               "ぼうけんの きろくを かきとめました。"])
    }

    func backToTitle() {
        hasSave = SaveStore.load() != nil
        battle = nil
        pages = []
        overlay = .none
        screen = .title
    }
}
