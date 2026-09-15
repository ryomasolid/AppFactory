import SwiftUI

struct BattleView: View {
    @Environment(GameState.self) private var game
    @State private var submenu: Submenu = .none

    private enum Submenu { case none, spells, items }

    var body: some View {
        if let session = game.battle {
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    StatusPanel(hero: game.hero)
                    Spacer()
                }
                .padding(10)

                Spacer()
                enemySprite(session)
                Spacer()

                // 行が増えても枠の高さを変えない（伸びると敵の絵が上にずれ、揺れがわかりにくくなる）。
                MessageBox(lines: session.log, showsCursor: session.waitingForTap)
                    .frame(height: 190, alignment: .top)

                Group {
                    if session.end != nil {
                        RetroWindow {
                            RetroChoice(title: "つぎへ") {
                                submenu = .none
                                game.finishBattle()
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
            // ダメージを受けた瞬間に画面全体を揺らし、一瞬赤く光らせる。
            .keyframeAnimator(initialValue: ScreenShake(), trigger: session.heroHit?.id ?? 0) { content, shake in
                content
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
            // 結果のページ（▼）は画面のどこをタップしても次へ進む。
            .contentShape(Rectangle())
            .onTapGesture { game.advanceBattleMessage() }
        }
    }

    /// 大ダメージ（ボスの炎など）は大きく揺らす。
    private func quakePower(_ session: BattleSession) -> CGFloat {
        session.heroHit?.isHeavy == true ? 1.8 : 1
    }

    private func enemySprite(_ session: BattleSession) -> some View {
        let enemy = session.battle.enemy
        let size: CGFloat = enemy.kind.isBoss ? 280 : 200
        let hit = session.enemyHit
        // 会心の一撃は大きく揺らす。
        let strength: CGFloat = hit?.isCritical == true ? 2 : 1
        return ZStack {
            SpriteCache.image(SpriteID(enemy: enemy.kind))
                .resizable()
                .interpolation(.none)
                .frame(width: size, height: size)
                // 当たった瞬間に左右に揺れて、2回点滅する。
                .keyframeAnimator(initialValue: HitPose(), trigger: hit?.id ?? 0) { content, pose in
                    content
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

/// 敵の上に浮かび上がって消えるダメージの数字。
private struct DamagePopup: View {
    let hit: EnemyHit
    @State private var risen = false
    @State private var faded = false

    var body: some View {
        Text("\(hit.damage)")
            .font(Retro.font(hit.isCritical ? 46 : 36))
            .foregroundStyle(hit.isCritical ? .orange : .yellow)
            // ドット絵に合わせて、ぼかさない影で縁取る。
            .shadow(color: .black, radius: 0, x: 3, y: 3)
            .offset(y: risen ? -50 : 0)
            .opacity(faded ? 0 : 1)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { risen = true }
                withAnimation(.easeIn(duration: 0.3).delay(0.6)) { faded = true }
            }
    }
}
