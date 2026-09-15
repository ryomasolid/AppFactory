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
                heading("どうぐ")
                if hero.herbCount > 0 {
                    RetroChoice(title: Item.herb.name, detail: "×\(hero.herbCount)") {
                        game.useHerbInField()
                    }
                    note("つかうと HPが \(Item.herbPower.lowerBound)〜\(Item.herbPower.upperBound) かいふく")
                } else {
                    note("なにも もっていない")
                }
                heading("そうび")
                row("ぶき", "\(hero.weapon.name)（こうげき+\(hero.weapon.power)）")
                row("よろい", "\(hero.armor.name)（しゅび+\(hero.armor.power)）")
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
        RetroRow(label: label, value: value)
    }

    /// まとまりの見出し（どうぐ・そうび）。
    private func heading(_ title: String) -> some View {
        Text(title)
            .font(Retro.font(14))
            .foregroundStyle(.yellow)
            .padding(.top, 2)
    }

    /// 選択肢の下に添える小さな説明。
    private func note(_ text: String) -> some View {
        HStack(spacing: 6) {
            Text("▶").hidden()
            Text(text)
                .font(Retro.font(13))
                .foregroundStyle(.gray)
        }
    }
}
