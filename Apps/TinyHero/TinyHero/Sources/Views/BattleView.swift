import SwiftUI

struct BattleView: View {
    @Environment(GameState.self) private var game
    @State private var submenu: Submenu = .none

    private enum Submenu { case none, spells, items }

    var body: some View {
        if let session = game.battle {
            ZStack {
                Color.black.ignoresSafeArea()
                content(session)
            }
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
                default: break
                }
            }
            // 結果のページ（▼）は画面のどこをタップしても次へ進む。
            .contentShape(Rectangle())
            .onTapGesture { game.advanceBattleMessage() }
        }
    }

    private func content(_ session: BattleSession) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                StatusPanel(hero: game.hero)
                Spacer()
            }
            .padding(10)

            arena(session)

            // 行が増えても枠の高さを変えない（伸びると敵の絵が上にずれ、揺れがわかりにくくなる）。
            MessageBox(lines: session.log, showsCursor: session.waitingForTap)
                .frame(height: 190, alignment: .top)

            Group {
                if session.end != nil {
                    RetroWindow {
                        RetroChoice(title: "つぎへ") {
                            submenu = .none
                            Task { await game.finishBattle() }
                        }
                    }
                } else if !session.isPlaying {
                    commandWindow(session)
                } else {
                    Color.clear
                }
            }
            .frame(height: 210, alignment: .top)
        }
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
            let enemyY = size.height * 0.33
            let heroY = size.height * 0.86
            ZStack {
                Backdrop(isBoss: session.battle.enemy.kind.isBoss, groundHeight: size.height * 0.30)

                enemySprite(session)
                    .position(x: size.width / 2, y: enemyY)

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
        .frame(minHeight: 300)
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

    private func enemySprite(_ session: BattleSession) -> some View {
        let enemy = session.battle.enemy
        let size: CGFloat = enemy.kind.isBoss ? 210 : 168
        let hit = session.enemyHit
        // 会心の一撃は大きく揺らす。
        let strength: CGFloat = hit?.isCritical == true ? 2 : 1
        return ZStack {
            SpriteCache.image(SpriteID(enemy: enemy.kind))
                .resizable()
                .interpolation(.none)
                .frame(width: size, height: size)
                // 当たった瞬間に左右に揺れて、2回点滅する。
                .keyframeAnimator(initialValue: HitPose(), trigger: hit?.id ?? 0) { view, pose in
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
        .opacity(session.enemyDefeated ? 0 : 1)
        .animation(.easeOut(duration: 0.4), value: session.enemyDefeated)
    }

    @ViewBuilder
    private func commandWindow(_ session: BattleSession) -> some View {
        let hero = game.hero
        RetroWindow {
            switch submenu {
            case .none:
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading) {
                        RetroChoice(title: "こうげき") { run(.attack) }
                        RetroChoice(title: "まほう", isEnabled: !hero.spells.isEmpty) { submenu = .spells }
                    }
                    VStack(alignment: .leading) {
                        RetroChoice(title: "どうぐ") { submenu = .items }
                        RetroChoice(title: "にげる") { run(.run) }
                    }
                }
            case .spells:
                ForEach(hero.spells) { spell in
                    RetroChoice(title: spell.name, detail: "MP \(spell.mpCost)", isEnabled: hero.mp >= spell.mpCost) {
                        run(.spell(spell))
                    }
                }
                RetroChoice(title: "もどる") { submenu = .none }
            case .items:
                RetroChoice(title: Item.herb.name, detail: "×\(hero.herbCount)", isEnabled: hero.herbCount > 0) {
                    run(.item(.herb))
                }
                RetroChoice(title: "もどる") { submenu = .none }
            }
        }
    }

    private func run(_ command: BattleCommand) {
        submenu = .none
        Task { await game.command(command) }
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
private struct Fireball: View {
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
