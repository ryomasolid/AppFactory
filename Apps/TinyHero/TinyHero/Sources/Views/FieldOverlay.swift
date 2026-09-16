import SwiftUI

/// フィールドで開くウィンドウ（メニュー・つよさ・じゅもん・どうぐ・店・宿屋）。
struct FieldOverlay: View {
    @Environment(GameState.self) private var game
    /// 道具屋でいま開いている画面。
    @State private var shopPanel: ShopPanel = .menu

    /// 道具屋の流れ。かう／うる を選んでから、一覧 → 確認と進む。
    private enum ShopPanel: Equatable {
        case menu
        case buying
        case confirmBuy(Item)
        case selling
        case confirmSell(Item)
    }
    /// どうぐ画面で選んでいる持ちもの。nil なら一覧。
    @State private var selectedItem: Item?

    var body: some View {
        content
            // 店を離れたら、確認の途中状態を残さない。
            .onChange(of: game.overlay) { _, screen in
                if screen != .shop { shopPanel = .menu }
                if screen != .items { selectedItem = nil }
            }
    }

    @ViewBuilder
    private var content: some View {
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
                row("ぶき", hero.weaponName)
                row("よろい", hero.armorName)
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
                if let item = selectedItem {
                    itemActions(item, hero: hero)
                } else {
                    belongings(hero: hero)
                }
            }
            .onAppear {
                // 表示確認用の起動引数。ふだんは nil。
                if selectedItem == nil { selectedItem = Launch.selectItem }
            }

        case .shop:
            RetroWindow {
                switch shopPanel {
                case .menu: shopMenu(hero: hero)
                case .buying: shopStock(hero: hero)
                case let .confirmBuy(item): purchaseConfirm(item, hero: hero)
                case .selling: sellList(hero: hero)
                case let .confirmSell(item): sellConfirm(item, hero: hero)
                }
            }
            .onAppear {
                // 表示確認用の起動引数。ふだんは .menu のまま。
                guard shopPanel == .menu else { return }
                if let item = Launch.shopConfirm { shopPanel = .confirmBuy(item) }
                else if Launch.shopSell { shopPanel = .selling }
            }

        case .inn:
            RetroWindow {
                speech("やどや", ["ひとばん \(game.innPrice)ゴールドです。", "おとまりに なりますか？"])
                divider()
                RetroChoice(title: "はい") { game.stayAtInn() }
                RetroChoice(title: "いいえ") { game.closeOverlay() }
            }
        }
    }

    // MARK: - どうぐ

    /// 持ちもの一覧。そうび中のものには印を付ける。
    @ViewBuilder
    private func belongings(hero: Hero) -> some View {
        heading("もちもの")
        purse(hero.gold)
        divider()
        if hero.belongings.isEmpty {
            note("なにも もっていない")
        } else {
            ForEach(hero.belongings, id: \.item) { entry in
                RetroChoice(title: entry.item.name, detail: detail(for: entry, hero: hero)) {
                    selectedItem = entry.item
                }
            }
        }
        divider()
        RetroChoice(title: "もどる") { game.overlay = .menu }
    }

    /// 一覧の右側。そうび中か、持っている数。
    private func detail(for entry: (item: Item, count: Int), hero: Hero) -> String {
        if hero.isEquipped(entry.item) { return "そうび中" }
        if entry.item.kind == .consumable { return "×\(entry.count)" }
        return entry.count > 1 ? "×\(entry.count)" : ""
    }

    /// 選んだ持ちものに対してできること。
    @ViewBuilder
    private func itemActions(_ item: Item, hero: Hero) -> some View {
        heading(item.name)
        // 説明は1行だけにする。品物の素の強さと 差し引きの伸びを並べると食い違って見える。
        if case .consumable = item.kind {
            note(effectNote(item))
            RetroChoice(title: "つかう", isEnabled: hero.hp < hero.maxHP) {
                selectedItem = nil
                game.useHerbInField()
            }
        } else if hero.isEquipped(item) {
            note(equippedNote(item))
            RetroChoice(title: "はずす") {
                selectedItem = nil
                game.unequip(item)
            }
        } else {
            note(equipPreview(item, hero: hero))
            RetroChoice(title: "そうびする") {
                selectedItem = nil
                game.equip(item)
            }
        }
        divider()
        note("うるのは どうぐやで")
        RetroChoice(title: "やめる") { selectedItem = nil }
    }

    /// いま そうびしているものが どれだけ足してくれているか。
    private func equippedNote(_ item: Item) -> String {
        switch item.kind {
        case .consumable: return ""
        case .weapon(let power): return "いま こうげきを +\(power) している"
        case .armor(let power): return "いま しゅびを +\(power) している"
        }
    }

    /// 買ったら能力値がどう変わるか。ひと目で分かるよう大きく、あがった値は青で出す。
    @ViewBuilder
    private func statPreview(_ item: Item, hero: Hero) -> some View {
        let change: (label: String, now: Int, next: Int)? = {
            switch item.kind {
            case .consumable: nil
            case .weapon(let power): ("こうげき", hero.attack, hero.base.attack + power)
            case .armor(let power): ("しゅび", hero.defense, hero.base.defense + power)
            }
        }()
        if let change {
            let rises = change.next > change.now
            HStack(spacing: 10) {
                Text(change.label)
                    .font(Retro.font(17))
                Spacer()
                Text("\(change.now)")
                    .font(Retro.font(20))
                    .foregroundStyle(Retro.dim)
                Text("→")
                    .font(Retro.font(17))
                    .foregroundStyle(Retro.dim)
                Text("\(change.next)")
                    .font(Retro.font(26))
                    // あがるなら青、さがるなら赤で警告する。
                    .foregroundStyle(rises ? Retro.fresh : Retro.hpLow)
            }
            .padding(.vertical, 2)
        }
    }

    /// そうびしたら どれだけ変わるか。
    private func equipPreview(_ item: Item, hero: Hero) -> String {
        switch item.kind {
        case .consumable: return ""
        case .weapon(let power):
            let now = hero.attack
            return "そうびすると こうげき \(now)→\(hero.base.attack + power)"
        case .armor(let power):
            let now = hero.defense
            return "そうびすると しゅび \(now)→\(hero.base.defense + power)"
        }
    }

    // MARK: - 道具屋

    /// 話し手の名前と せりふを 行で分ける（「どうぐや「〜」」だと読みにくいため）。
    @ViewBuilder
    private func speech(_ name: String, _ lines: [String]) -> some View {
        Text(name)
            .font(Retro.font(14))
            .foregroundStyle(Retro.accent)
        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            let head = index == 0 ? "「" : "　"
            let tail = index == lines.count - 1 ? "」" : ""
            Text(head + line + tail)
        }
    }

    /// 店に入って最初に出る選択。
    @ViewBuilder
    private func shopMenu(hero: Hero) -> some View {
        speech("どうぐや", ["いらっしゃい。", "かうかい？ それとも うるのかい？"])
        divider()
        RetroChoice(title: "かう") { shopPanel = .buying }
        RetroChoice(title: "うる", isEnabled: hero.belongings.isEmpty == false) { shopPanel = .selling }
        divider()
        RetroChoice(title: "やめる") { game.closeOverlay() }
    }

    /// 売れるもの一覧。そうび中のものは 外さないと売れない。
    @ViewBuilder
    private func sellList(hero: Hero) -> some View {
        speech("どうぐや", ["どれを うるんだい？"])
        divider()
        ForEach(hero.belongings, id: \.item) { entry in
            let equipped = hero.isEquipped(entry.item)
            RetroChoice(
                title: entry.item.name,
                detail: equipped ? "そうび中" : "\(Hero.sellPrice(of: entry.item))G",
                isEnabled: !equipped
            ) {
                shopPanel = .confirmSell(entry.item)
            }
        }
        divider()
        RetroChoice(title: "もどる") { shopPanel = .menu }
    }

    /// 売るまえの確認。
    @ViewBuilder
    private func sellConfirm(_ item: Item, hero: Hero) -> some View {
        let paid = Hero.sellPrice(of: item)
        speech("どうぐや", ["\(item.name)なら", "\(paid)ゴールドで ひきとるよ。いいかい？"])
        if case .consumable = item.kind {
            note("のこり ×\(hero.inventory[item, default: 0])")
        }
        divider()
        RetroChoice(title: "はい") {
            game.sell(item)
            shopPanel = .selling
        }
        RetroChoice(title: "いいえ") {
            shopPanel = .selling
        }
    }

    /// 商品一覧。もちきんは商品と混ざらないよう、上に出して線で区切る。
    @ViewBuilder
    private func shopStock(hero: Hero) -> some View {
        speech("どうぐや", ["なにが ほしいんだい？"])
        divider()
        ForEach(GameState.shopStock) { item in
            // もう持っている装備は、はいを押しても断られるので最初から選ばせない。
            let owned = item.kind != .consumable && hero.owns(item)
            RetroChoice(
                title: item.name,
                detail: owned ? "もっている" : "\(item.price)G",
                isEnabled: !owned && hero.gold >= item.price
            ) {
                shopPanel = .confirmBuy(item)
            }
        }
        divider()
        RetroChoice(title: "もどる") { shopPanel = .menu }
    }

    /// 買うまえの確認。いきなり買わずに はい／いいえ を選ばせる。
    @ViewBuilder
    private func purchaseConfirm(_ item: Item, hero: Hero) -> some View {
        speech("どうぐや", ["\(item.name)だね。", "\(item.price)ゴールドに なるが、かうかい？"])
        // 装備は「いまの値 → 買ったあとの値」だけを大きく出す。
        // 品物の素の強さ（+16 など）も並べると、買い替えの本当の伸び（+8）と食い違って紛らわしい。
        if case .consumable = item.kind {
            note(effectNote(item))
        } else {
            statPreview(item, hero: hero)
        }
        divider()
        RetroChoice(title: "はい") {
            game.buy(item)
            shopPanel = .buying
        }
        RetroChoice(title: "いいえ") {
            shopPanel = .buying
        }
    }

    /// もちきん。買ったあとの残りも出すと、いくら減るかが分かる。
    private func purse(_ gold: Int, after: Int? = nil) -> some View {
        HStack(spacing: 6) {
            Text("▶").hidden()
            Text("もちきん")
            Spacer()
            if let after {
                Text("\(gold)G → \(after)G").foregroundStyle(.yellow)
            } else {
                Text("\(gold)G").foregroundStyle(.yellow)
            }
        }
    }

    /// 商品の効きめ。装備は上がり幅、薬草は回復量。
    private func effectNote(_ item: Item) -> String {
        switch item.kind {
        case .consumable:
            "つかうと HPが \(Item.herbPower.lowerBound)〜\(Item.herbPower.upperBound) かいふく"
        case .weapon(let power):
            "そうびすると こうげき +\(power)"
        case .armor(let power):
            "そうびすると しゅび +\(power)"
        }
    }

    /// まとまりを区切る細い線。
    private func divider() -> some View {
        Rectangle()
            .fill(.white.opacity(0.35))
            .frame(height: 2)
            .padding(.vertical, 2)
    }

    // MARK: - 共通

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
