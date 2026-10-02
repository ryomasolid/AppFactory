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
    /// ずかん・てちょうの ページ。
    @State private var page = 0
    /// ずかんで 見ている 敵。
    @State private var selectedEnemy: EnemyKind?
    /// てちょうで 見ている 県。
    @State private var notebookRegion: Region?

    var body: some View {
        content
            // 店を離れたら、確認の途中状態を残さない。
            .onChange(of: game.overlay) { _, screen in
                if screen != .shop { shopPanel = .menu }
                if screen != .items { selectedItem = nil }
                if screen != .book { selectedEnemy = nil }
                if screen != .notebook { notebookRegion = nil }
                page = 0
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
                ChoiceList([
                    Choice(title: "つよさ") { game.overlay = .status },
                    Choice(title: "じゅもん", isEnabled: !hero.spells.isEmpty) { game.overlay = .spells },
                    Choice(title: "どうぐ") { game.overlay = .items },
                    Choice(title: "きろく") { game.overlay = .records },
                    Choice(title: "おと", detail: game.soundEnabled ? "ON" : "OFF") { game.soundEnabled.toggle() },
                    Choice(title: "セーブ") { game.saveFromMenu() },
                    Choice(title: "とじる", isCancel: true) { game.closeOverlay() },
                ])
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
                row("かざり", hero.charmName)
                ChoiceList([
                    Choice(title: "きろくを シェア") { ShareSheet.present(game.adventureSummary) },
                    Choice(title: "もどる", isCancel: true) { game.overlay = .menu },
                ])
            }

        case .spells:
            RetroWindow {
                ChoiceList(hero.spells.map { spell in
                    Choice(
                        title: spell.name,
                        detail: "MP \(spell.mpCost)",
                        isEnabled: spell.isFieldUsable && hero.mp >= spell.mpCost
                    ) {
                        game.castInField(spell)
                    }
                } + [Choice(title: "もどる", isCancel: true) { game.overlay = .menu }])
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
                else if Launch.shopBuy { shopPanel = .buying }
            }

        case .records:
            records(hero: hero)

        case .book:
            RetroWindow {
                if let kind = selectedEnemy {
                    bookEntry(kind)
                } else {
                    bookList()
                }
            }

        case .notebook:
            RetroWindow {
                if let region = notebookRegion {
                    notebookPage(region)
                } else {
                    notebookList()
                }
            }

        case .exam:
            RetroWindow {
                if let exam = game.exam, let quiz = exam.current {
                    heading("\(exam.region.name) ちしき検定 \(exam.index + 1)／\(exam.questions.count)")
                    PhraseLine(text: quiz.question)
                    divider()
                    ChoiceList(quiz.choices.enumerated().map { index, choice in
                        Choice(title: choice) { game.answerExam(index) }
                    } + [Choice(title: "やめる", separated: true, isCancel: true) { game.quitExam() }])
                }
            }

        case .train:
            RetroWindow {
                speech("えきいん", "どちらへ まいりますか？")
                divider()
                ChoiceList(Region.allCases.map { region in
                    let here = region == game.region
                    let open = game.progress.canTravel(to: region)
                    return Choice(
                        title: region.stationName,
                        detail: here ? "いま ここ" : (open ? region.shortName : "きっぷ なし"),
                        detailStyle: here ? Retro.dim : (open ? Retro.accent : Retro.hpLow),
                        isEnabled: open && !here
                    ) {
                        Task { await game.travel(to: region) }
                    }
                } + [Choice(title: "やめる", separated: true, isCancel: true) { game.stayOnPlatform() }])
            }

        case .inn:
            RetroWindow {
                speech("やどや", "ひとばん \(game.innPrice)ゴールドです。")
                divider()
                ChoiceList([
                    Choice(title: "はい") { game.stayAtInn() },
                    Choice(title: "いいえ", isCancel: true) { game.closeOverlay() },
                ])
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
        }
        ChoiceList(hero.belongings.map { entry in
            Choice(title: entry.item.name, detail: detail(for: entry, hero: hero)) {
                selectedItem = entry.item
            }
        } + [Choice(title: "もどる", separated: true, isCancel: true) { game.overlay = .menu }])
    }

    /// 一覧の右側。そうび中か、持っている数。
    private func detail(for entry: (item: Item, count: Int), hero: Hero) -> String {
        if hero.isEquipped(entry.item) { return "そうび中" }
        if entry.item.kind == .consumable { return "×\(entry.count)" }
        return entry.count > 1 ? "×\(entry.count)" : ""
    }

    /// 選んだ持ちものに対してできること。
    /// 説明は1行だけにする。品物の素の強さと 差し引きの伸びを並べると食い違って見える。
    /// 説明を先にまとめ、選択肢は下にそろえる（あいだに挟むと カーソルが とびとびになる）。
    @ViewBuilder
    private func itemActions(_ item: Item, hero: Hero) -> some View {
        let available = itemAction(item, hero: hero)
        heading(item.name)
        note(available.note)
        note("うるのは どうぐやで")
        divider()
        ChoiceList([available.choice, Choice(title: "やめる", isCancel: true) { selectedItem = nil }])
    }

    /// 持ちものに対してできること ひとつと、その説明。
    private func itemAction(_ item: Item, hero: Hero) -> (note: String, choice: Choice) {
        if case .consumable = item.kind {
            return (item.effectNote, Choice(title: "つかう", isEnabled: hero.canUse(item)) {
                selectedItem = nil
                game.useInField(item)
            })
        }
        if case .charm = item.kind {
            if hero.isEquipped(item) {
                return (item.effectNote, Choice(title: "はずす") {
                    selectedItem = nil
                    game.unequip(item)
                })
            }
            return (item.effectNote, Choice(title: "みにつける") {
                selectedItem = nil
                game.equip(item)
            })
        }
        if hero.isEquipped(item) {
            return (equippedNote(item), Choice(title: "はずす") {
                selectedItem = nil
                game.unequip(item)
            })
        }
        return (equipPreview(item, hero: hero), Choice(title: "そうびする") {
            selectedItem = nil
            game.equip(item)
        })
    }

    /// いま そうびしているものが どれだけ足してくれているか。
    private func equippedNote(_ item: Item) -> String {
        switch item.kind {
        case .consumable, .charm: return ""
        case .weapon(let power): return "いま こうげきを +\(power) している"
        case .armor(let power): return "いま しゅびを +\(power) している"
        }
    }

    /// 買ったら能力値がどう変わるか。ひと目で分かるよう大きく、あがった値は青で出す。
    @ViewBuilder
    private func statPreview(_ item: Item, hero: Hero) -> some View {
        let change: (label: String, now: Int, next: Int)? = {
            switch item.kind {
            case .consumable, .charm: nil
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
        case .consumable, .charm: return ""
        case .weapon(let power):
            let now = hero.attack
            return "そうびすると こうげき \(now)→\(hero.base.attack + power)"
        case .armor(let power):
            let now = hero.defense
            return "そうびすると しゅび \(now)→\(hero.base.defense + power)"
        }
    }

    // MARK: - きろく

    /// きろくの 一覧。まつり・スタンプ・検定は ここで 見て、ずかん・てちょうへ すすむ。
    private func records(hero: Hero) -> some View {
        let progress = game.progress
        let festivals = Region.allCases.filter(progress.festivalRestored).count
        let exams = Region.allCases.filter { progress.has(.examPassed($0)) }.count
        let stamps = game.stamps.values.reduce(0, +)
        return RetroWindow {
            heading("ぼうけんの きろく")
            row("まつり", "\(festivals) / \(Region.allCases.count)")
            row("めいしょ スタンプ", "\(stamps) / \(World.stampPlaques.count)")
            row("ちしき検定", "\(exams) / \(Region.allCases.count)")
            row("ちしき コンボ", "×\(game.quizStreak)")
            divider()
            ChoiceList([
                Choice(title: "まもの ずかん", detail: "\(game.seenEnemies.count)/\(EnemyKind.allCases.count)") {
                    game.overlay = .book
                },
                Choice(title: "ちしきの てちょう", detail: "\(game.learnedQuizzes.count)/\(QuizBank.total)") {
                    game.overlay = .notebook
                },
                Choice(title: "もどる", separated: true, isCancel: true) { game.overlay = .menu },
            ])
        }
    }

    /// ずかんの 1ページに ならべる 数。
    private static let bookPageSize = 8

    /// まもの ずかんの 一覧（旅の順）。倒していない 敵は「？？？」。
    @ViewBuilder
    private func bookList() -> some View {
        let all = EnemyKind.allCases
        let pages = (all.count + Self.bookPageSize - 1) / Self.bookPageSize
        let current = min(page, pages - 1)
        let shown = Array(all.dropFirst(current * Self.bookPageSize).prefix(Self.bookPageSize))
        heading("まもの ずかん \(game.seenEnemies.count)/\(all.count)　\(current + 1)/\(pages)")
        ChoiceList(shown.map { kind in
            let seen = game.seenEnemies.contains(kind)
            return Choice(title: seen ? kind.name : "？？？", detail: Self.placeLabel(kind), isEnabled: seen) {
                selectedEnemy = kind
            }
        } + [
            Choice(title: "つぎの ページ", separated: true) { page = (current + 1) % pages },
            Choice(title: "もどる", isCancel: true) { game.overlay = .records },
        ])
    }

    /// ずかんの 右に 出す 県（恐山は 恐山）。
    private static func placeLabel(_ kind: EnemyKind) -> String {
        Balance.place(of: kind) > 24 ? "恐山" : kind.region.shortName
    }

    /// ずかんの 1体。絵と その土地の ひとこと。
    @ViewBuilder
    private func bookEntry(_ kind: EnemyKind) -> some View {
        HStack(spacing: 12) {
            SpriteCache.image(SpriteID(enemy: kind)).resizable().interpolation(.none).frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.name).foregroundStyle(Retro.accent)
                Text(Self.placeLabel(kind)).font(Retro.font(13)).foregroundStyle(Retro.dim)
            }
        }
        PhraseLine(text: kind.lore, fontSize: 15)
            .font(Retro.font(15))
        divider()
        ChoiceList([Choice(title: "もどる", isCancel: true) { selectedEnemy = nil }])
    }

    /// てちょうの 県の 一覧。
    @ViewBuilder
    private func notebookList() -> some View {
        heading("ちしきの てちょう")
        note("せいかいした もんだいが のる")
        divider()
        ChoiceList(Region.allCases.map { region in
            let quizzes = QuizBank.quizzes(in: region)
            let learned = quizzes.filter { game.learnedQuizzes.contains($0.question) }.count
            return Choice(title: region.name, detail: "\(learned)/\(quizzes.count)", isEnabled: !quizzes.isEmpty) {
                notebookRegion = region
                page = 0
            }
        } + [Choice(title: "もどる", separated: true, isCancel: true) { game.overlay = .records }])
    }

    /// てちょうの 1ページに ならべる 数（問題は 2行に なるので 少なめ）。
    private static let notebookPageSize = 4

    /// 県の 問題と 答え。まだ せいかいしていない 問題は かくす。
    @ViewBuilder
    private func notebookPage(_ region: Region) -> some View {
        let quizzes = QuizBank.quizzes(in: region)
        let pages = max(1, (quizzes.count + Self.notebookPageSize - 1) / Self.notebookPageSize)
        let current = min(page, pages - 1)
        let shown = Array(quizzes.dropFirst(current * Self.notebookPageSize).prefix(Self.notebookPageSize))
        heading("\(region.name)　\(current + 1)/\(pages)")
        ForEach(shown, id: \.question) { quiz in
            if game.learnedQuizzes.contains(quiz.question) {
                VStack(alignment: .leading, spacing: 2) {
                    PhraseLine(text: quiz.question, fontSize: 13).font(Retro.font(13))
                    Text("→ \(quiz.correctChoice)").font(Retro.font(14)).foregroundStyle(Retro.accent)
                }
            } else {
                Text("？？？").font(Retro.font(13)).foregroundStyle(Retro.dim)
            }
        }
        divider()
        ChoiceList([
            Choice(title: "つぎの ページ", isEnabled: pages > 1) { page = (current + 1) % pages },
            Choice(title: "もどる", isCancel: true) { notebookRegion = nil },
        ])
    }

    // MARK: - 道具屋

    /// 話し手の名前と せりふ。せりふは折り返さないよう、1行で収まる短さにする。
    @ViewBuilder
    private func speech(_ name: String, _ line: String) -> some View {
        Text(name)
            .font(Retro.font(14))
            .foregroundStyle(Retro.accent)
        Text("「\(line)」")
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 店に入って最初に出る選択。
    @ViewBuilder
    private func shopMenu(hero: Hero) -> some View {
        speech("どうぐや", "いらっしゃい！")
        divider()
        ChoiceList([
            Choice(title: "かう") { shopPanel = .buying },
            Choice(title: "うる", isEnabled: hero.belongings.isEmpty == false) { shopPanel = .selling },
            Choice(title: "やめる", separated: true, isCancel: true) { game.closeOverlay() },
        ])
    }

    /// 売れるもの一覧。そうび中のものは 外さないと売れない。
    @ViewBuilder
    private func sellList(hero: Hero) -> some View {
        speech("どうぐや", "どれを うるんだい？")
        divider()
        ChoiceList(hero.belongings.map { entry in
            let equipped = hero.isEquipped(entry.item)
            return Choice(
                title: entry.item.name,
                detail: equipped ? "そうび中" : "\(Hero.sellPrice(of: entry.item))G",
                isEnabled: !equipped
            ) {
                shopPanel = .confirmSell(entry.item)
            }
        } + [Choice(title: "もどる", separated: true, isCancel: true) { shopPanel = .menu }])
    }

    /// 売るまえの確認。
    @ViewBuilder
    private func sellConfirm(_ item: Item, hero: Hero) -> some View {
        let paid = Hero.sellPrice(of: item)
        speech("どうぐや", "\(item.name)なら \(paid)ゴールドだね。")
        if case .consumable = item.kind {
            note("のこり ×\(hero.inventory[item, default: 0])")
        }
        divider()
        ChoiceList([
            Choice(title: "はい") {
                game.sell(item)
                shopPanel = .selling
            },
            Choice(title: "いいえ", isCancel: true) {
                shopPanel = .selling
            },
        ])
    }

    /// 商品一覧。もちきんは商品と混ざらないよう、上に出して線で区切る。
    @ViewBuilder
    private func shopStock(hero: Hero) -> some View {
        speech("どうぐや", "なにが ほしいんだい？")
        divider()
        ChoiceList(game.shopStock.map { item in
            // もう持っている装備は、はいを押しても断られるので最初から選ばせない。
            let owned = item.kind != .consumable && hero.owns(item)
            // **おかねが足りなくても選べる。** どれだけ強くなるかを先に見て、
            // 貯める目標にできるようにするため（買えるかどうかは値段の色で伝える）。
            let short = game.shortfall(for: item) > 0
            return Choice(
                title: item.name,
                detail: owned ? "もっている" : "\(item.price)G",
                detailStyle: owned ? nil : (short ? Retro.hpLow : Retro.accent),
                isEnabled: !owned
            ) {
                shopPanel = .confirmBuy(item)
            }
        } + [Choice(title: "もどる", separated: true, isCancel: true) { shopPanel = .menu }])
    }

    /// 買うまえの確認。いきなり買わずに はい／いいえ を選ばせる。
    /// おかねが足りなくても ここまで来られる。伸びしろを見てから 貯めに行けるように。
    @ViewBuilder
    private func purchaseConfirm(_ item: Item, hero: Hero) -> some View {
        let short = game.shortfall(for: item)
        speech("どうぐや", "\(item.name)は \(item.price)ゴールドだよ。")
        // 装備は「いまの値 → 買ったあとの値」だけを大きく出す。
        // 品物の素の強さ（+16 など）も並べると、買い替えの本当の伸び（+8）と食い違って紛らわしい。
        if case .consumable = item.kind {
            note(item.effectNote)
        } else {
            statPreview(item, hero: hero)
        }
        if short > 0 {
            note("あと \(short)ゴールド たりない。", color: Retro.hpLow)
        }
        divider()
        ChoiceList([
            Choice(title: "はい", isEnabled: short == 0) {
                game.buy(item)
                shopPanel = .buying
            },
            Choice(title: short > 0 ? "もどる" : "いいえ", isCancel: true) {
                shopPanel = .buying
            },
        ])
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
    private func note(_ text: String, color: Color = .gray) -> some View {
        HStack(spacing: 6) {
            Text("▶").hidden()
            Text(text)
                .font(Retro.font(13))
                .foregroundStyle(color)
        }
    }
}
