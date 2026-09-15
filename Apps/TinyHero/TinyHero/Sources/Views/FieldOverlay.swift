import SwiftUI

/// フィールドで開くウィンドウ（メニュー・つよさ・じゅもん・どうぐ・店・宿屋）。
struct FieldOverlay: View {
    @Environment(GameState.self) private var game

    var body: some View {
        let hero = game.hero
        switch game.overlay {
        case .none:
            EmptyView()

        case .menu:
            RetroWindow {
                RetroChoice(title: "つよさ") { game.overlay = .status }
                RetroChoice(title: "じゅもん", isEnabled: !hero.spells.isEmpty) { game.overlay = .spells }
                RetroChoice(title: "どうぐ") { game.overlay = .items }
                RetroChoice(title: "おと", detail: game.soundEnabled ? "ON" : "OFF") { game.soundEnabled.toggle() }
                RetroChoice(title: "セーブ") { game.saveFromMenu() }
                RetroChoice(title: "とじる") { game.closeOverlay() }
            }
            .frame(width: 220)

        case .status:
            RetroWindow {
                row("なまえ", hero.name)
                row("レベル", "\(hero.level)")
                row("HP", "\(hero.hp) / \(hero.maxHP)")
                row("MP", "\(hero.mp) / \(hero.maxMP)")
                row("こうげき", "\(hero.attack)")
                row("しゅび", "\(hero.defense)")
                row("すばやさ", "\(hero.agility)")
                row("けいけんち", "\(hero.exp)")
                if hero.level < LevelTable.maxLevel {
                    row("つぎのLVまで", "\(LevelTable.row(hero.level + 1).exp - hero.exp)")
                }
                row("ぶき", hero.weapon.name)
                row("よろい", hero.armor.name)
                RetroChoice(title: "もどる") { game.overlay = .menu }
            }

        case .spells:
            RetroWindow {
                ForEach(hero.spells) { spell in
                    RetroChoice(
                        title: spell.name,
                        detail: "MP \(spell.mpCost)",
                        isEnabled: spell.isHealing && hero.mp >= spell.mpCost
                    ) {
                        game.castInField(spell)
                    }
                }
                RetroChoice(title: "もどる") { game.overlay = .menu }
            }

        case .items:
            RetroWindow {
                RetroChoice(title: Item.herb.name, detail: "×\(hero.herbCount)", isEnabled: hero.herbCount > 0) {
                    game.useHerbInField()
                }
                row("そうび", "\(hero.weapon.name)・\(hero.armor.name)")
                RetroChoice(title: "もどる") { game.overlay = .menu }
            }

        case .shop:
            RetroWindow {
                Text("どうぐや「なにを かっていくかね？」")
                ForEach(GameState.shopStock) { item in
                    RetroChoice(title: item.name, detail: "\(item.price)G", isEnabled: hero.gold >= item.price) {
                        game.buy(item)
                    }
                }
                row("もちきん", "\(hero.gold)G")
                RetroChoice(title: "やめる") { game.closeOverlay() }
            }

        case .inn:
            RetroWindow {
                Text("やどや「ひとばん \(game.innPrice)ゴールドです。")
                Text("おとまりに なりますか？」")
                RetroChoice(title: "はい") { game.stayAtInn() }
                RetroChoice(title: "いいえ") { game.closeOverlay() }
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
    }
}
