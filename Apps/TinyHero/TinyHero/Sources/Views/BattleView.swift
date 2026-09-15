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

                MessageBox(lines: session.log, showsCursor: false)

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
        }
    }

    private func enemySprite(_ session: BattleSession) -> some View {
        let enemy = session.battle.enemy
        let size: CGFloat = enemy.kind.isBoss ? 280 : 200
        return SpriteCache.image(SpriteID(enemy: enemy.kind))
            .resizable()
            .interpolation(.none)
            .frame(width: size, height: size)
            // 倒した敵はメッセージが流れ終わったら消す。
            .opacity(enemy.isDead && !session.isPlaying ? 0 : 1)
            .animation(.easeOut(duration: 0.3), value: enemy.isDead && !session.isPlaying)
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
