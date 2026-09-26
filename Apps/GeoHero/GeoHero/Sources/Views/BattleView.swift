import SwiftUI

struct BattleView: View {
    @Environment(GameState.self) private var game
    @State private var submenu: Submenu = .none

    private enum Submenu: Equatable { case none, spells, items, targets }
    /// 相手を選んだあとに出すコマンド（こうげき か 攻撃呪文）。
    @State private var pendingAttack: BattleCommand?

    var body: some View {
        if let session = game.battle {
            ZStack {
                Color.black.ignoresSafeArea()
                content(session)
                if let page = session.levelUp {
                    LevelUpBoard(page: page)
                        // 文字を流さず、ぱっと出す。
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                        .id(page)
                }
            }
            .animation(.spring(duration: 0.22), value: session.levelUp)
            // ダメージを受けた瞬間に画面全体を揺らし、一瞬赤く光らせる。
            .keyframeAnimator(initialValue: ScreenShake(), trigger: session.heroHit?.id ?? 0) { view, shake in
                view
                    .offset(x: shake.x, y: shake.y)
                    .overlay {
                        Color.red.opacity(shake.flash)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
            } keyframes: { _ in
                let power = quakePower(session)
                KeyframeTrack(\.x) {
                    LinearKeyframe(10 * power, duration: 0.04)
                    LinearKeyframe(-10 * power, duration: 0.05)
                    LinearKeyframe(8 * power, duration: 0.05)
                    LinearKeyframe(-6 * power, duration: 0.05)
                    LinearKeyframe(3 * power, duration: 0.05)
                    LinearKeyframe(0, duration: 0.05)
                }
                KeyframeTrack(\.y) {
                    LinearKeyframe(-6 * power, duration: 0.05)
                    LinearKeyframe(5 * power, duration: 0.05)
                    LinearKeyframe(-4 * power, duration: 0.05)
                    LinearKeyframe(2 * power, duration: 0.05)
                    LinearKeyframe(0, duration: 0.05)
                }
                KeyframeTrack(\.flash) {
                    LinearKeyframe(0.35, duration: 0.03)
                    LinearKeyframe(0, duration: 0.25)
                }
            }
            .onAppear {
                switch Launch.battleSubmenu {
                case "spells": submenu = .spells
                case "items": submenu = .items
                // 「ちしきの チャンス」を かならず出して 見る。
                case "quiz": game.offerQuizChance(target: session.battle.defaultTarget, force: true)
                default: break
                }
            }
            // 結果のページ（▼）は画面のどこをタップしても次へ進む。
            .contentShape(Rectangle())
            .onTapGesture { game.advanceBattleMessage() }
        }
    }

    /// 下の2枚の枠の高さ。行や選択肢が増えても変えない
    /// （伸び縮みすると敵の絵が上下にずれ、当たったときの揺れがわかりにくくなる）。
    /// 余った高さは枠の中の空白になるので、画面に黒いすきまは残らない。
    /// 中身がはみ出さないことは `LayoutTests` で見張っている。
    static let messageHeight: CGFloat = 175
    static let commandHeight: CGFloat = 150

    private func content(_ session: BattleSession) -> some View {
        VStack(spacing: 0) {
            // 状態の窓は戦いの絵に重ねる。行に並べると そのぶん絵が小さくなる。
            arena(session)
                .overlay(alignment: .topLeading) {
                    StatusPanel(hero: game.hero).padding(10)
                }

            MessageBox(
                lines: session.log,
                showsCursor: session.waitingForTap,
                fixedHeight: Self.messageHeight
            )

            commandSlot(session)
        }
    }

    /// コマンドの枠。文字が流れているあいだは 中身のない枠のまま置いておく。
    private func commandSlot(_ session: BattleSession) -> some View {
        RetroWindow {
            if session.end != nil {
                RetroChoice(title: "つぎへ") {
                    submenu = .none
                    Task { await game.finishBattle() }
                }
            } else if !session.isPlaying {
                commandChoices(session)
            }
            Spacer(minLength: 0)
        }
        .frame(height: Self.commandHeight)
    }

    /// 大ダメージ（ボスの炎など）は大きく揺らす。
    private func quakePower(_ session: BattleSession) -> CGFloat {
        session.heroHit?.isHeavy == true ? 1.8 : 1
    }

    // MARK: - 敵と勇者が向かい合う場所

    /// 敵を上、勇者を下に置き、そのあいだで呪文の演出を動かす。
    /// 空と地面はこの中だけに敷く（全画面に広げるとメッセージ枠の後ろまで明るくなって読みづらい）。
    private func arena(_ session: BattleSession) -> some View {
        GeometryReader { geometry in
            let size = geometry.size
            let enemyY = size.height * 0.38
            let heroY = size.height * 0.85
            ZStack {
                Backdrop(isBoss: session.battle.enemy.kind.isBoss, groundHeight: size.height * 0.34)

                // 敵を横に並べる。3体でも画面からはみ出さない幅にする。
                let alive = session.battle.enemies
                let spacing = min(size.width / CGFloat(alive.count + 1), 130)
                ForEach(Array(alive.enumerated()), id: \.element.id) { index, enemy in
                    enemySprite(session, enemy: enemy, count: alive.count)
                        .position(
                            x: size.width / 2 + spacing * (CGFloat(index) - CGFloat(alive.count - 1) / 2),
                            y: enemyY + (index % 2 == 1 ? 14 : 0)
                        )
                }

                SpriteCache.image(.heroUp1)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 76, height: 76)
                    .position(x: size.width / 2, y: heroY)

                if let cue = session.effect {
                    spellEffect(cue, size: size, enemyY: enemyY, heroY: heroY)
                        // 番号が変わるたびに作り直して、同じ演出でも出し直す。
                        .id(cue.id)
                        .allowsHitTesting(false)
                }
            }
            .clipped()
        }
        .frame(minHeight: 280)
    }

    @ViewBuilder
    private func spellEffect(_ cue: EffectCue, size: CGSize, enemyY: CGFloat, heroY: CGFloat) -> some View {
        switch cue.kind {
        case let .heal(amount):
            HealEffect(amount: amount)
                .position(x: size.width / 2, y: heroY)
        case let .flame(big):
            FlameEffect(big: big, travel: heroY - enemyY)
                .position(x: size.width / 2, y: enemyY)
        case .breath:
            BreathEffect(size: size)
        }
    }

    private func enemySprite(_ session: BattleSession, enemy: Enemy, count: Int) -> some View {
        // 数が増えるほど1体を小さくして、重ならないようにする。
        let base: CGFloat = enemy.kind.isBoss ? 176 : 132
        let size = count >= 3 ? base * 0.72 : (count == 2 ? base * 0.85 : base)
        // 自分に 最後に当たった一撃で 揺らし、それが いまの一撃なら ダメージの数字も出す。
        let lastHit = session.lastHits[enemy.id]
        let hit = session.enemyHit?.enemyID == enemy.id ? session.enemyHit : nil
        // 会心の一撃は大きく揺らす。
        let strength: CGFloat = lastHit?.isCritical == true ? 2 : 1
        return ZStack {
            SpriteCache.image(SpriteID(enemy: enemy.kind))
                .resizable()
                .interpolation(.none)
                .frame(width: size, height: size)
                // 当たった瞬間に左右に揺れて、2回点滅する。
                .keyframeAnimator(initialValue: HitPose(), trigger: lastHit?.id ?? 0) { view, pose in
                    view
                        .offset(x: pose.shake)
                        .opacity(pose.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.shake) {
                        LinearKeyframe(-12 * strength, duration: 0.04)
                        LinearKeyframe(12 * strength, duration: 0.06)
                        LinearKeyframe(-8 * strength, duration: 0.06)
                        LinearKeyframe(5 * strength, duration: 0.06)
                        LinearKeyframe(0, duration: 0.05)
                    }
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(0.1, duration: 0.01)
                        LinearKeyframe(0.1, duration: 0.07)
                        LinearKeyframe(1, duration: 0.01)
                        LinearKeyframe(1, duration: 0.07)
                        LinearKeyframe(0.1, duration: 0.01)
                        LinearKeyframe(0.1, duration: 0.07)
                        LinearKeyframe(1, duration: 0.01)
                    }
                }

            if let hit {
                DamagePopup(hit: hit)
                    .id(hit.id)
                    .offset(y: -size * 0.3)
            }
        }
        // 「たおした！」の行が出たら消す。
        .opacity(session.defeatedIDs.contains(enemy.id) ? 0 : 1)
        .animation(.easeOut(duration: 0.4), value: session.defeatedIDs)
    }

    /// 選べるものは2列に分ける。縦に積むと枠が高くなり、そのぶん戦いの絵が小さくなる。
    @ViewBuilder
    private func commandChoices(_ session: BattleSession) -> some View {
        if let quiz = game.quizChance {
            // 問題はメッセージの枠に出ている。ここは答えを選ぶだけ（もどれない。まちがえても こうげきは 当たる）。
            let choices = Array(quiz.choices.enumerated())
            let half = (choices.count + 1) / 2
            TwoColumns {
                ForEach(choices.prefix(half), id: \.offset) { answerChoice($0.offset, $0.element) }
            } right: {
                ForEach(choices.dropFirst(half), id: \.offset) { answerChoice($0.offset, $0.element) }
            }
        } else {
            regularChoices(session)
        }
    }

    @ViewBuilder
    private func regularChoices(_ session: BattleSession) -> some View {
        let hero = game.hero
        switch submenu {
        case .none:
            TwoColumns {
                RetroChoice(title: "こうげき") { aim(.attack, session) }
                RetroChoice(title: "まほう", isEnabled: !hero.spells.isEmpty) { submenu = .spells }
            } right: {
                RetroChoice(title: "どうぐ") { submenu = .items }
                RetroChoice(title: "にげる") { run(.run) }
            }
        case .spells:
            let half = (hero.spells.count + 1) / 2
            TwoColumns {
                ForEach(hero.spells.prefix(half)) { spellChoice($0, session) }
            } right: {
                ForEach(hero.spells.dropFirst(half)) { spellChoice($0, session) }
            }
            RetroChoice(title: "もどる") { submenu = .none }
        case .items:
            // 持っている 回復の道具を 2列に ならべる。なければ ハスカップを 0こで 出す（ないことが 分かるように）。
            let owned = hero.consumables.isEmpty ? [(item: Item.herb, count: 0)] : hero.consumables
            let half = (owned.count + 1) / 2
            TwoColumns {
                ForEach(owned.prefix(half), id: \.item) { itemChoice($0.item, $0.count) }
            } right: {
                ForEach(owned.dropFirst(half), id: \.item) { itemChoice($0.item, $0.count) }
            }
            RetroChoice(title: "もどる") { submenu = .none }
        case .targets:
            let living = session.battle.living
            let half = (living.count + 1) / 2
            TwoColumns {
                ForEach(living.prefix(half)) { targetChoice($0) }
            } right: {
                ForEach(living.dropFirst(half)) { targetChoice($0) }
            }
            RetroChoice(title: "もどる") {
                pendingAttack = nil
                submenu = .none
            }
        }
    }

    private func answerChoice(_ index: Int, _ title: String) -> some View {
        RetroChoice(title: title) {
            submenu = .none
            pendingAttack = nil
            Task { await game.answerQuiz(index) }
        }
    }

    private func itemChoice(_ item: Item, _ count: Int) -> some View {
        RetroChoice(title: item.name, detail: "×\(count)", isEnabled: count > 0) { run(.item(item)) }
    }

    private func spellChoice(_ spell: Spell, _ session: BattleSession) -> some View {
        RetroChoice(title: spell.name, detail: "MP \(spell.mpCost)", isEnabled: game.hero.mp >= spell.mpCost) {
            if spell.isHealing {
                run(.spell(spell))
            } else {
                aim(.spell(spell), session)
            }
        }
    }

    private func targetChoice(_ enemy: Enemy) -> some View {
        RetroChoice(title: enemy.name) { run(pendingAttack ?? .attack, target: enemy.id) }
    }

    /// 相手が2体以上いれば選ばせる。1体なら そのまま出す。
    private func aim(_ command: BattleCommand, _ session: BattleSession) {
        if session.battle.living.count <= 1 {
            run(command, target: session.battle.defaultTarget)
        } else {
            pendingAttack = command
            submenu = .targets
        }
    }

    private func run(_ command: BattleCommand, target: Int? = nil) {
        submenu = .none
        pendingAttack = nil
        // こうげきは ときどき「ちしきの チャンス」が 出るので GameState に まかせる。
        if command == .attack {
            Task { await game.attack(target: target) }
        } else {
            Task { await game.command(command, target: target) }
        }
    }
}

/// 枠の中の選択肢を2列に分けて並べる。
private struct TwoColumns<Left: View, Right: View>: View {
    @ViewBuilder let left: Left
    @ViewBuilder let right: Right

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) { left }
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 8) { right }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 背景

/// 戦闘の空と地面。ボス戦は暗くする。
private struct Backdrop: View {
    let isBoss: Bool
    let groundHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            (isBoss ? Retro.bossSky : Retro.sky)
            (isBoss ? Retro.bossGround : Retro.ground)
                .frame(height: groundHeight)
        }
    }
}

// MARK: - 揺れとダメージの数字

/// 勇者がダメージを受けたときの画面の揺れと赤いフラッシュ。
private struct ScreenShake {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var flash: Double = 0
}

/// 敵が当たったときの揺れと点滅の状態。
private struct HitPose {
    var shake: CGFloat = 0
    var opacity: Double = 1
}

/// 敵の上に出て、しばらくしてから消えるダメージの数字。
/// 上へ動かすと戦闘の枠の上端で見切れるので、その場に出して消えるだけにする。
private struct DamagePopup: View {
    let hit: EnemyHit
    @State private var faded = false

    var body: some View {
        Text("\(hit.damage)")
            .font(Retro.font(hit.isCritical ? 46 : 36))
            .foregroundStyle(hit.isCritical ? .orange : .yellow)
            // ドット絵に合わせて、ぼかさない影で縁取る。
            .shadow(color: .black, radius: 0, x: 3, y: 3)
            .opacity(faded ? 0 : 1)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeIn(duration: 0.3).delay(0.7)) { faded = true }
            }
    }
}

// MARK: - 呪文・道具の演出

/// 回復：白い湯気の粒に包まれ、緑の「+N」が浮かぶ。
private struct HealEffect: View {
    let amount: Int
    @State private var risen = false
    @State private var faded = false

    private let count = 18

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                let angle = Double(index) / Double(count) * .pi * 2
                Rectangle()
                    .fill(.white)
                    .frame(width: 7, height: 7)
                    .offset(
                        x: cos(angle) * 34,
                        y: sin(angle) * 26 + (risen ? -80 : 0)
                    )
                    .opacity(faded ? 0 : 0.95)
                    .animation(.easeOut(duration: 0.7).delay(Double(index) * 0.015), value: risen)
                    .animation(.easeIn(duration: 0.4).delay(0.35), value: faded)
            }

            Text("+\(amount)")
                .font(Retro.font(34))
                .foregroundStyle(Retro.heal)
                .shadow(color: .black, radius: 0, x: 3, y: 3)
                .offset(y: risen ? -60 : -10)
                .opacity(faded ? 0 : 1)
                .animation(.easeOut(duration: 0.6), value: risen)
                .animation(.easeIn(duration: 0.3).delay(0.5), value: faded)
        }
        .onAppear {
            risen = true
            faded = true
        }
    }
}

/// 攻撃呪文：勇者から敵へ火の玉が飛び、当たった場所で爆発する。
private struct FlameEffect: View {
    let big: Bool
    /// 勇者から敵までの距離。
    let travel: CGFloat

    @State private var arrived = false
    @State private var burst = false

    private var ballSize: CGFloat { big ? 40 : 28 }
    private var blastSize: CGFloat { big ? 230 : 150 }

    var body: some View {
        ZStack {
            // 飛んでいく火の玉。
            Fireball(size: ballSize)
                .offset(y: arrived ? 0 : travel)
                .opacity(arrived ? 0 : 1)
                .animation(.easeIn(duration: 0.26), value: arrived)

            // 当たった場所の爆発。
            Fireball(size: blastSize)
                .scaleEffect(burst ? 1 : 0.15)
                .opacity(burst ? 0 : 0.95)
                .animation(.easeOut(duration: 0.34).delay(0.26), value: burst)
        }
        .onAppear {
            arrived = true
            burst = true
        }
    }
}

/// 炎のかたまり。真ん中が白く、外へいくほど赤くなる。
struct Fireball: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.85, green: 0.15, blue: 0.05)).frame(width: size, height: size)
            Circle().fill(Retro.ember).frame(width: size * 0.7, height: size * 0.7)
            Circle().fill(Color(red: 1, green: 0.92, blue: 0.5)).frame(width: size * 0.38, height: size * 0.38)
        }
    }
}

/// ボスのほのお：画面の上から火の粉が降りそそぐ。
private struct BreathEffect: View {
    let size: CGSize
    @State private var fallen = false
    @State private var faded = false

    private let count = 40

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(0..<count, id: \.self) { index in
                // 位置と速さは番号から決めて、毎回同じ降り方にする。
                var seed = SeededRandomSource(seed: UInt64(index) &+ 77)
                let x = CGFloat(seed.next(in: 0...max(1, Int(size.width))))
                let width = CGFloat(seed.next(in: 6...13))
                let duration = 0.55 + Double(seed.next(in: 0...5)) / 10
                let delay = Double(seed.next(in: 0...6)) / 20

                Rectangle()
                    .fill(index % 3 == 0 ? Color(red: 1, green: 0.85, blue: 0.4) : Retro.ember)
                    .frame(width: width, height: width * 1.6)
                    .position(x: x, y: fallen ? size.height + 30 : -30)
                    .opacity(faded ? 0 : 0.9)
                    .animation(.easeIn(duration: duration).delay(delay), value: fallen)
                    .animation(.easeOut(duration: 0.3).delay(0.6), value: faded)
            }
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            fallen = true
            faded = true
        }
    }
}


// MARK: - レベルアップ

/// レベルアップで出す板。伸びた能力値を まとめて ぱっと出し、
/// タップすると 覚えた わざを アイコンつきで出す。
private struct LevelUpBoard: View {
    let page: LevelUpPage

    var body: some View {
        ZStack {
            // 後ろのメッセージ枠が脇から覗かないよう、暗く敷く。
            Color.black.opacity(0.7).ignoresSafeArea()
            RetroWindow {
                switch page {
                case let .stats(levelUp):
                    stats(levelUp)
                case let .spells(spells):
                    learned(spells)
                }
            }
            .frame(maxWidth: 340)
            .padding(.horizontal, 24)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func stats(_ levelUp: Hero.LevelUp) -> some View {
        Text(levelUp.headline)
            .font(Retro.font(18))
            .foregroundStyle(Retro.accent)
        Rectangle().fill(.white.opacity(0.35)).frame(height: 2).padding(.vertical, 2)
        ForEach(levelUp.gains, id: \.label) { gain in
            HStack(spacing: 6) {
                Text(gain.label)
                Spacer()
                Text("\(gain.before)")
                    .foregroundStyle(Retro.dim)
                Text("→")
                    .foregroundStyle(Retro.dim)
                // あがったあとの値だけ青くして目立たせる。
                Text("\(gain.after)")
                    .foregroundStyle(Retro.fresh)
            }
            .font(Retro.font(16))
        }
    }

    @ViewBuilder
    private func learned(_ spells: [Spell]) -> some View {
        Text("あたらしい わざを おぼえた！")
            .font(Retro.font(16))
            .foregroundStyle(Retro.accent)
        Rectangle().fill(.white.opacity(0.35)).frame(height: 2).padding(.vertical, 2)
        ForEach(spells) { spell in
            HStack(spacing: 10) {
                SpellIcon(spell: spell)
                VStack(alignment: .leading, spacing: 2) {
                    Text(spell.name).font(Retro.font(17))
                    Text(spell.isHealing ? "かいふくの まほう" : "こうげきの まほう")
                        .font(Retro.font(11))
                        .foregroundStyle(Retro.dim)
                }
                Spacer()
                Text("MP \(spell.mpCost)")
                    .font(Retro.font(12))
                    .foregroundStyle(Retro.dim)
            }
        }
    }
}

/// 呪文の種類がひと目で分かる印。攻撃は炎、回復は緑の十字。
private struct SpellIcon: View {
    let spell: Spell

    var body: some View {
        ZStack {
            if spell.isHealing {
                Rectangle().frame(width: 22, height: 8)
                Rectangle().frame(width: 8, height: 22)
            } else {
                Fireball(size: 24)
            }
        }
        .foregroundStyle(Retro.heal)
        .frame(width: 26, height: 26)
    }
}
