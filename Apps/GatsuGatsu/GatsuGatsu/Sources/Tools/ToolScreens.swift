import SwiftUI
import UserNotifications

struct ToolsScreen: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(ToolKind.allCases) { kind in
                    NavigationLink(value: Route.tool(kind)) {
                        HStack(spacing: 12) {
                            Image(systemName: kind.icon).font(.title2).foregroundStyle(.tint).frame(width: 36)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(kind.title).font(.subheadline.weight(.black))
                                Text(kind.blurb).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .sticker()
                    }
                    .buttonStyle(.plain)
                }
                SponsoredCard(slot: "tools", path: "/tools")
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("ツール")
    }
}

/// ツール画面の共通の枠。
private struct ToolPage<Content: View>: View {
    let kind: ToolKind
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content() }
                .padding(16)
        }
        .paperBackground()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("閉じる") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

private struct GramField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(title).font(.subheadline.weight(.bold))
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.title3.weight(.black).monospacedDigit())
                .frame(width: 90)
                .textFieldStyle(.roundedBorder)
            Text("g").font(.subheadline.weight(.bold))
        }
    }
}

private struct ResultRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.footnote)
            Spacer()
            Text(value).font(.headline.weight(.black)).monospacedDigit()
        }
    }
}

// MARK: - 量の早見表

struct QuantityTool: View {
    @State private var noodleText = "300"
    @State private var isBoiledFigure = false
    @State private var riceText = "300"

    var body: some View {
        ToolPage(kind: .quantity) {
            let noodle = Portions.noodle(grams: Double(noodleText) ?? 0, isBoiledFigure: isBoiledFigure)
            let rice = Double(riceText) ?? 0

            VStack(alignment: .leading, spacing: 10) {
                Text("麺のグラム数を換算").font(.headline.weight(.black))
                GramField(title: "メニューの表記", text: $noodleText)
                Picker("表記", selection: $isBoiledFigure) {
                    Text("茹で前").tag(false)
                    Text("茹で後").tag(true)
                }
                .pickerStyle(.segmented)
                Divider()
                ResultRow(title: "茹で後の重さ", value: "約\(noodle.boiled.whole)g")
                ResultRow(title: "茹で前の重さ", value: "約\(noodle.raw.whole)g")
                ResultRow(title: "麺だけのカロリー", value: "約\(noodle.kcal.whole)kcal")
                ResultRow(title: "ラーメンにすると", value: "約\(noodle.ramenCount.oneDecimal)杯ぶん")
            }
            .padding(14)
            .sticker()

            VStack(alignment: .leading, spacing: 10) {
                Text("ご飯のグラム数を換算").font(.headline.weight(.black))
                GramField(title: "ご飯の量", text: $riceText)
                Divider()
                ResultRow(title: "茶碗にすると", value: "約\(Portions.riceBowls(grams: rice).oneDecimal)杯ぶん")
                ResultRow(title: "ご飯だけのカロリー", value: "約\(Portions.riceKcal(grams: rice).whole)kcal")
            }
            .padding(14)
            .sticker()

            BlocksView(blocks: Library.shared.quantityBlocks, adSlot: "quantity-mid", adPath: ToolKind.quantity.webPath)
        }
    }
}

// MARK: - カロリー＆PFC

struct CalorieTool: View {
    @Environment(BiteLog.self) private var log
    @Environment(Navigator.self) private var navigator
    @State private var chainID = Library.shared.chains.first?.id ?? ""
    @State private var picks: [Pick] = []
    @State private var saved = false
    private let library = Library.shared

    struct Pick: Identifiable, Equatable {
        let item: Chain.Item
        let place: String
        var count: Int
        var id: String { place + item.id }
    }

    private var chain: Chain? { library.chains.first { $0.id == chainID } }

    private var total: (kcal: Double, p: Double, f: Double, c: Double) {
        picks.reduce((0, 0, 0, 0)) { sum, pick in
            let n = Double(pick.count)
            return (sum.0 + pick.item.calories * n, sum.1 + pick.item.protein * n, sum.2 + pick.item.fat * n, sum.3 + pick.item.carbs * n)
        }
    }

    var body: some View {
        ToolPage(kind: .calorie) {
            totals
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(library.chains) { c in
                        Chip(label: "\(c.emoji) \(c.name)", selected: c.id == chainID) { chainID = c.id }
                    }
                }
                .padding(.vertical, 2).padding(.horizontal, 1)
            }
            if let chain {
                ForEach(chain.menu) { item in
                    menuRow(item, chain: chain)
                }
                if let url = URL(string: chain.source.url) {
                    Link("数値の出典: \(chain.source.label)（\(DateText.japanese(library.nutritionCheckedAt))確認）", destination: url)
                        .font(.caption)
                }
            }
            Text("メニューの改定や店舗によって変わることがあります。1日の目安は成人の一般的な値で、必要な量は人によって異なります。")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var totals: some View {
        let t = total
        return VStack(alignment: .leading, spacing: 8) {
            BigNumber(value: t.kcal.whole, unit: "kcal", size: 40)
            ProgressView(value: min(t.kcal / library.daily.calories, 1))
            Text("1日の目安 \(library.daily.calories.whole)kcal の \(Int((t.kcal / library.daily.calories * 100).rounded()))%").font(.caption)
            HStack(spacing: 14) {
                Text("P \(t.p.oneDecimal)g")
                Text("F \(t.f.oneDecimal)g")
                Text("C \(t.c.oneDecimal)g")
            }
            .font(.footnote.weight(.bold)).monospacedDigit()
            if !picks.isEmpty {
                HStack(spacing: 10) {
                    Button { saveToLog() } label: { PrimaryButtonLabel(text: "ガツログに記録", systemImage: "plus") }.buttonStyle(.plain)
                    Button("クリア") { picks = [] }.font(.footnote.weight(.bold))
                }
                .padding(.top, 4)
            }
            if saved {
                Button { navigator.tab = .log } label: {
                    Label("記録しました。ガツログを見る", systemImage: "checkmark.circle.fill").font(.footnote.weight(.bold)).foregroundStyle(.green)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sticker()
    }

    private func menuRow(_ item: Chain.Item, chain: Chain) -> some View {
        let count = picks.first { $0.id == chain.name + item.id }?.count ?? 0
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.footnote.weight(.semibold))
                Text("\(item.calories.whole)kcal ・ P\(item.protein.oneDecimal) F\(item.fat.oneDecimal) C\(item.carbs.oneDecimal)")
                    .font(.caption2).foregroundStyle(.secondary).monospacedDigit()
            }
            Spacer()
            if count > 0 {
                Button { change(item, chain: chain, by: -1) } label: { Image(systemName: "minus.circle.fill").font(.title2).foregroundStyle(.secondary) }
                    .buttonStyle(.plain).accessibilityLabel("\(item.name)を減らす")
                Text("\(count)").font(.subheadline.weight(.black)).monospacedDigit()
            }
            Button { change(item, chain: chain, by: 1) } label: { Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(.tint) }
                .buttonStyle(.plain).accessibilityLabel("\(item.name)を足す")
        }
        .padding(10)
        .background(Color.card, in: .rect(cornerRadius: 10))
    }

    private func change(_ item: Chain.Item, chain: Chain, by delta: Int) {
        saved = false
        let id = chain.name + item.id
        if let index = picks.firstIndex(where: { $0.id == id }) {
            picks[index].count += delta
            if picks[index].count <= 0 { picks.remove(at: index) }
        } else if delta > 0 {
            picks.append(Pick(item: item, place: chain.name, count: delta))
        }
    }

    private func saveToLog() {
        for pick in picks {
            for _ in 0..<pick.count {
                log.add(Bite(eatenAt: .now, name: pick.item.name, place: pick.place, kcal: pick.item.calories,
                             protein: pick.item.protein, fat: pick.item.fat, carbs: pick.item.carbs))
            }
        }
        picks = []
        saved = true
    }
}

// MARK: - 行列の待ち時間

struct QueueTool: View {
    @State private var genre = Library.shared.queueGenres.first
    @State private var people = 10.0
    @State private var seats = 20
    @State private var reminderAt: Date?
    @State private var reminderMessage: String?
    private let library = Library.shared
    private static let reminderID = "queue-reminder"

    private var minutes: Int { QueueEstimate.minutes(people: Int(people), seats: seats, stay: genre?.avgStayMin ?? 0) }
    private var arrival: Date { .now.addingTimeInterval(Double(minutes) * 60) }

    var body: some View {
        ToolPage(kind: .queue) {
            result
            VStack(alignment: .leading, spacing: 10) {
                Text("お店のジャンル").font(.subheadline.weight(.black))
                ForEach(library.queueGenres) { option in
                    Button { genre = option } label: {
                        HStack {
                            Text(option.emoji)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(option.label).font(.footnote.weight(.bold)).multilineTextAlignment(.leading)
                                Text("平均 \(option.avgStayMin)分 ・ \(option.examples)").font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                            }
                            Spacer()
                            if genre == option { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
                        }
                        .padding(10)
                        .background(genre == option ? Color.softOrange : Color.card, in: .rect(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                Text("並んでいる人数: \(Int(people))人").font(.subheadline.weight(.black)).padding(.top, 4)
                Slider(value: $people, in: 0...60, step: 1).accessibilityLabel("並んでいる人数")
                Text("お店の席数: \(seats)席").font(.subheadline.weight(.black))
                HStack(spacing: 8) {
                    ForEach(library.seatPresets) { preset in
                        Chip(label: "\(preset.label) \(preset.seats)", selected: seats == preset.seats) { seats = preset.seats }
                    }
                }
            }
            Text("待ち時間 ＝（並んでいる人数 ÷ 席数）× 業態の平均滞在時間。目安の計算で、実際の待ち時間は店の回転で変わります。")
                .font(.caption).foregroundStyle(.secondary)
            SponsoredCard(slot: "queue", path: ToolKind.queue.webPath)
        }
    }

    private var result: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("待ち時間の目安").font(.subheadline.weight(.black))
            BigNumber(value: "\(minutes)", unit: "分", size: 52)
            Text("入店予定 \(arrival.formatted(date: .omitted, time: .shortened))ごろ").font(.subheadline.weight(.heavy))
            Text(QueueEstimate.advice(minutes: minutes)).font(.footnote)
            if let reminderAt {
                HStack {
                    Label("\(reminderAt.formatted(date: .omitted, time: .shortened)) に通知します", systemImage: "bell.fill").font(.footnote.weight(.bold))
                    Spacer()
                    Button("やめる") { cancelReminder() }.font(.footnote.weight(.bold))
                }
            } else if QueueEstimate.reminderDate(minutes: minutes) != nil {
                Button { Task { await scheduleReminder() } } label: {
                    PrimaryButtonLabel(text: "入店の5分前に通知する", systemImage: "bell.fill")
                }
                .buttonStyle(.plain)
            }
            if let reminderMessage { Text(reminderMessage).font(.caption).foregroundStyle(.secondary) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sticker()
    }

    private func scheduleReminder() async {
        guard let date = QueueEstimate.reminderDate(minutes: minutes) else { return }
        let center = UNUserNotificationCenter.current()
        let allowed = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard allowed else {
            reminderMessage = "通知がオフです。端末の設定アプリから許可できます。"
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "そろそろ順番です"
        content.body = "入店予定の5分前になりました。頼むサイズは決まりましたか？"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(date.timeIntervalSinceNow, 1), repeats: false)
        do {
            try await center.add(UNNotificationRequest(identifier: Self.reminderID, content: content, trigger: trigger))
            reminderAt = date
            reminderMessage = nil
        } catch {
            reminderMessage = "通知を設定できませんでした。"
        }
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.reminderID])
        reminderAt = nil
    }
}

// MARK: - 食べ放題の元取り

struct BuffetTool: View {
    @State private var buffetID = Library.shared.buffets.first?.id ?? ""
    @State private var courseID: String?
    @State private var counts: [String: Int] = [:]
    private let library = Library.shared

    private var buffet: Buffet? { library.buffets.first { $0.id == buffetID } }
    private var course: Buffet.Course? { buffet?.courses.first { $0.id == courseID } ?? buffet?.courses.first }
    private var eaten: Int {
        buffet?.menu.reduce(0) { $0 + $1.unitPrice * (counts[$1.name] ?? 0) } ?? 0
    }

    private var categories: [String] {
        var seen: [String] = []
        for dish in buffet?.menu ?? [] where !seen.contains(dish.category) { seen.append(dish.category) }
        return seen
    }

    var body: some View {
        ToolPage(kind: .buffet) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(library.buffets) { b in
                        Chip(label: "\(b.emoji) \(b.name)", selected: b.id == buffetID) {
                            buffetID = b.id
                            courseID = nil
                            counts = [:]
                        }
                    }
                }
                .padding(.vertical, 2).padding(.horizontal, 1)
            }
            if let buffet { Text(buffet.catchcopy).font(.footnote).foregroundStyle(.secondary) }
            scoreboard
            if let buffet {
                Picker("コース", selection: Binding(get: { course?.id ?? "" }, set: { courseID = $0 })) {
                    ForEach(buffet.courses) { Text($0.name).tag($0.id) }
                }
                .pickerStyle(.menu)
                if let note = course?.note, !note.isEmpty { Text(note).font(.caption).foregroundStyle(.secondary) }
                ForEach(categories, id: \.self) { category in
                    SectionTitle(text: category)
                    ForEach(buffet.menu.filter { $0.category == category }) { dish in
                        dishRow(dish)
                    }
                }
            }
            Text("コース料金と単品価格は、よくある価格帯をもとにした目安で、実在のお店の価格ではありません。")
                .font(.caption).foregroundStyle(.secondary)
            SponsoredCard(slot: "buffet", path: ToolKind.buffet.webPath)
        }
    }

    private var scoreboard: some View {
        let price = course?.price ?? 0
        let left = price - eaten
        return VStack(alignment: .leading, spacing: 8) {
            Text(left <= 0 ? "元を取りました！" : "元取りまであと").font(.subheadline.weight(.black))
            BigNumber(value: abs(left).formatted(.number.locale(Locale(identifier: "ja_JP"))), unit: left <= 0 ? "円おトク" : "円", size: 44)
            ProgressView(value: price > 0 ? min(Double(eaten) / Double(price), 1) : 0)
            Text("食べた分 \(eaten.yen) ／ コース \(price.yen)").font(.caption)
            if eaten > 0 {
                Button("リセット") { counts = [:] }.font(.footnote.weight(.bold))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sticker()
    }

    private func dishRow(_ dish: Buffet.Dish) -> some View {
        let count = counts[dish.name] ?? 0
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(dish.name).font(.footnote.weight(.semibold))
                Text("単品の目安 \(dish.unitPrice.yen)").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if count > 0 {
                Button { counts[dish.name] = max(count - 1, 0) } label: { Image(systemName: "minus.circle.fill").font(.title2).foregroundStyle(.secondary) }
                    .buttonStyle(.plain).accessibilityLabel("\(dish.name)を減らす")
                Text("\(count)").font(.subheadline.weight(.black)).monospacedDigit()
            }
            Button { counts[dish.name] = count + 1 } label: { Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(.tint) }
                .buttonStyle(.plain).accessibilityLabel("\(dish.name)を足す")
        }
        .padding(10)
        .background(Color.card, in: .rect(cornerRadius: 10))
    }
}

// MARK: - 割り勘

struct SplitTool: View {
    @State private var billText = ""
    @State private var peopleText = ""
    @State private var tiers = [SplitBill.Tier(name: "上司・多め出し", count: 1, adjustment: 2000)]
    @State private var outcome: Swift.Result<SplitBill.Result, SplitBill.Failure>?
    @State private var copied = false

    private var bill: Int { Int(billText.replacingOccurrences(of: ",", with: "")) ?? 0 }
    private var people: Int { Int(peopleText) ?? 0 }

    var body: some View {
        ToolPage(kind: .split) {
            VStack(alignment: .leading, spacing: 10) {
                labeledField("お会計", text: $billText, suffix: "円")
                labeledField("参加人数", text: $peopleText, suffix: "人")
                Text("通常メンバー \(SplitBill.regularCount(people: people, tiers: tiers))人（自動）").font(.caption).foregroundStyle(.secondary)
            }
            .padding(14)
            .sticker()

            SectionTitle(text: "金額に差をつけるグループ")
            ForEach($tiers) { $tier in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("グループ名", text: $tier.name).font(.subheadline.weight(.bold))
                        Button { tiers.removeAll { $0.id == tier.id } } label: { Image(systemName: "trash") }
                            .accessibilityLabel("\(tier.name)を消す")
                    }
                    Stepper("人数 \(tier.count)人", value: $tier.count, in: 1...99).font(.footnote.weight(.bold))
                    Stepper("通常より \(tier.adjustment >= 0 ? "+" : "")\(tier.adjustment.yen)", value: $tier.adjustment, in: -20000...20000, step: 500)
                        .font(.footnote.weight(.bold))
                }
                .padding(12)
                .background(Color.card, in: .rect(cornerRadius: 10))
            }
            Button {
                tiers.append(.init(name: "新しいグループ", count: 1, adjustment: -1000))
            } label: {
                Label("グループを足す", systemImage: "plus.circle.fill").font(.footnote.weight(.bold))
            }

            Button {
                dismissKeyboard()
                outcome = SplitBill.calculate(bill: bill, people: people, tiers: tiers)
                copied = false
            } label: { PrimaryButtonLabel(text: "計算する") }
                .buttonStyle(.plain)

            switch outcome {
            case .success(let result): resultCard(result)
            case .failure(let failure):
                Text(failure.message).font(.footnote.weight(.bold)).foregroundStyle(.red)
            case nil: EmptyView()
            }
            // 計算ボタンの押しまちがいで広告に触れないよう、少し離す。
            SponsoredCard(slot: "split", path: ToolKind.split.webPath).padding(.top, 16)
        }
        .onChange(of: tiers) { outcome = nil }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func labeledField(_ title: String, text: Binding<String>, suffix: String) -> some View {
        HStack {
            Text(title).font(.subheadline.weight(.bold))
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.title3.weight(.black).monospacedDigit())
                .textFieldStyle(.roundedBorder)
                .frame(width: 130)
            Text(suffix).font(.subheadline.weight(.bold))
        }
    }

    private func resultCard(_ result: SplitBill.Result) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("お一人あたり").font(.subheadline.weight(.black))
            ForEach(result.lines) { line in
                HStack(alignment: .firstTextBaseline) {
                    Text("\(line.name)（\(line.count)人）").font(.footnote.weight(.semibold))
                    Spacer()
                    BigNumber(value: line.perPerson.formatted(.number.locale(Locale(identifier: "ja_JP"))), unit: "円", size: 24)
                }
            }
            Divider()
            Text("集める合計 \(result.collected.yen)").font(.footnote.weight(.bold))
            if result.surplus > 0 {
                Text("100円単位で切り上げたので、幹事の預かりが \(result.surplus.yen) 出ます").font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                ShareLink(item: result.shareText) { PrimaryButtonLabel(text: "LINEなどで送る", systemImage: "square.and.arrow.up") }.buttonStyle(.plain)
                Button {
                    UIPasteboard.general.string = result.shareText
                    copied = true
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc").font(.headline).padding(12).sticker(radius: 10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copied ? "コピーしました" : "結果をコピー")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sticker()
    }
}
