import SwiftData
import SwiftUI

/// きょう：見守り → きょうの世話 → 温度 → 体のようす → さいきん。
struct TodayScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Turtle.order) private var turtles: [Turtle]
    @AppStorage(Selection.storageKey) private var selectedKey = ""
    @State private var feeding: Turtle?
    @State private var measuring: Turtle?
    @State private var checking: Turtle?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let turtle = Selection.pick(turtles, key: selectedKey) {
                    VStack(spacing: 14) {
                        TurtleSwitcher(turtles: turtles, selectedKey: $selectedKey)
                        ProfileCard(turtle: turtle)
                        ConcernCard(concerns: Concerns.list(for: turtle))
                        dueCard(turtle)
                        TemperatureCard(turtle: turtle)
                        Button {
                            checking = turtle
                        } label: {
                            Label("体のようすを記録", systemImage: "stethoscope")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("open-check")
                        RecentCard(turtle: turtle)
                    }
                    .padding()
                }
            }
            .background(Palette.sand.ignoresSafeArea())
            .navigationTitle("きょう")
            .sheet(item: $feeding) { FeedSheet(turtle: $0) }
            .sheet(item: $measuring) { MeasureSheet(turtle: $0) }
            .sheet(item: $checking) { CheckSheet(turtle: $0) }
        }
    }

    private func dueCard(_ turtle: Turtle) -> some View {
        let list = DueList.make(for: turtle)
        return Panel(title: turtle.currentRest == nil ? "きょうの世話" : "冬眠中の見守り", symbol: "checklist") {
            if turtle.currentRest != nil {
                Text("冬眠中はごはん・水換えの予定を止めています。1週間に1回は体重を計りましょう。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(list) { due in
                DueRow(due: due) { done(due.task, turtle: turtle) }
                if due.id != list.last?.id { Divider() }
            }
            if turtle.currentRest == nil {
                Text("日光浴はしたときに「した」を押すと、さいきんの記録に残ります。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    record(.sun, turtle: turtle)
                } label: {
                    Label("日光浴をした", systemImage: CareKind.sun.symbol)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("done-sun")
            }
        }
    }

    private func done(_ task: Due.Task, turtle: Turtle) {
        switch task {
        case .measure: measuring = turtle
        case .care(.feed): feeding = turtle
        case .care(let kind): record(kind, turtle: turtle)
        }
    }

    private func record(_ kind: CareKind, turtle: Turtle) {
        withAnimation {
            context.insert(Care(kind: kind, at: Date(), turtle: turtle))
        }
        Task { await Reminders.refresh(context) }
    }
}

private struct ProfileCard: View {
    let turtle: Turtle

    var body: some View {
        HStack(spacing: 14) {
            TurtleAvatar(turtle: turtle, size: 72)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(turtle.name).font(.title2.bold()).foregroundStyle(Palette.ink)
                    if turtle.currentRest != nil {
                        Label("冬眠中", systemImage: "moon.zzz.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Palette.pond.opacity(0.18), in: Capsule())
                            .foregroundStyle(Palette.pond)
                    }
                }
                Text("\(turtle.species.label)・\(turtle.sex.label)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let last = turtle.growth.last {
                    Text(summary(last)).font(.subheadline).foregroundStyle(Palette.moss)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func summary(_ m: Measure) -> String {
        var parts: [String] = []
        if turtle.hatchedOn != nil { parts.append(Fmt.age(from: turtle.ageBase)) }
        if let s = m.shellMM { parts.append("甲長 \(Fmt.number(s))mm") }
        if let g = m.grams { parts.append("\(Fmt.number(g))g") }
        return parts.joined(separator: "・")
    }
}

struct ConcernCard: View {
    let concerns: [Concern]

    var body: some View {
        if !concerns.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(concerns) { c in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: c.level == .note ? "info.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(Palette.level(c.level))
                        Text(c.text).font(.subheadline).foregroundStyle(Palette.ink)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Palette.level(concerns[0].level).opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct DueRow: View {
    let due: Due
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(due.isDue ? Palette.moss : .secondary)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(MorningNote.taskName(due.task)).font(.body.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(due.late > 0 ? Palette.amber : .secondary)
            }
            Spacer()
            Button(due.task == .measure ? "計る" : "した", action: action)
                .buttonStyle(.borderedProminent)
                .tint(due.isDue ? Palette.moss : .gray)
                .accessibilityIdentifier(identifier)
        }
    }

    private var symbol: String {
        switch due.task {
        case .care(let kind): kind.symbol
        case .measure: "ruler.fill"
        }
    }

    private var identifier: String {
        switch due.task {
        case .care(let kind): "done-\(kind.rawValue)"
        case .measure: "done-measure"
        }
    }

    private var detail: String {
        let last = due.last.map { "前回 \(Fmt.day($0))" } ?? "まだ記録なし"
        if due.late > 0 { return "\(last)・\(due.late)日すぎ" }
        if due.late == 0 { return "\(last)・きょう" }
        return "\(last)・次は \(Fmt.day(due.next))"
    }
}

private struct TemperatureCard: View {
    let turtle: Turtle
    @Environment(\.modelContext) private var context
    @State private var base = ""
    @State private var spot = ""
    @FocusState private var focused: Bool

    var body: some View {
        let habitat = turtle.species.habitat
        let band = Heat.band(for: turtle.species)
        Panel(title: "温度", symbol: "thermometer.sun.fill") {
            HStack(spacing: 10) {
                field(Heat.baseName(habitat), text: $base, id: "temp-base")
                field(Heat.spotName(habitat), text: $spot, id: "temp-spot")
                Button("記録") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(Fmt.parse(base) == nil && Fmt.parse(spot) == nil)
                    .accessibilityIdentifier("save-temp")
            }
            Text("目安：\(Heat.baseName(habitat)) \(Int(band.base.lowerBound))〜\(Int(band.base.upperBound))℃・\(Heat.spotName(habitat)) \(Int(band.spot.lowerBound))〜\(Int(band.spot.upperBound))℃")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let r = turtle.latestReading {
                HStack(spacing: 12) {
                    Text(r.at.formatted(.dateTime.month().day().hour().minute())).foregroundStyle(.secondary)
                    if let b = r.baseC { reading(Heat.baseName(habitat), b, Heat.judge(b, in: band.base)) }
                    if let s = r.spotC { reading(Heat.spotName(habitat), s, Heat.judge(s, in: band.spot)) }
                }
                .font(.footnote)
            }
        }
    }

    private func field(_ title: String, text: Binding<String>, id: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            HStack(spacing: 2) {
                TextField("--", text: text)
                    .keyboardType(.decimalPad)
                    .focused($focused)
                    .accessibilityIdentifier(id)
                Text("℃").foregroundStyle(.secondary)
            }
            .padding(8)
            .background(Palette.sand, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func reading(_ title: String, _ value: Double, _ verdict: Heat.Verdict) -> some View {
        Text("\(title) \(Fmt.number(value))℃")
            .foregroundStyle(verdict == .ok ? Palette.moss : Palette.amber)
            .fontWeight(.semibold)
    }

    private func save() {
        context.insert(Reading(at: Date(), baseC: Fmt.parse(base), spotC: Fmt.parse(spot), turtle: turtle))
        base = ""
        spot = ""
        focused = false
    }
}

/// さいきん7日の記録。長押しで消せる。
private struct RecentCard: View {
    let turtle: Turtle
    @Environment(\.modelContext) private var context

    private struct Item: Identifiable {
        let id: PersistentIdentifier
        let at: Date
        let symbol: String
        let text: String
        let photo: Data?
        let model: any PersistentModel
    }

    var body: some View {
        let items = recent
        Panel(title: "さいきんの記録", symbol: "clock.arrow.circlepath") {
            if items.isEmpty {
                Text("世話をしたら「した」を押すと、ここに並びます。").font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: item.symbol).foregroundStyle(Palette.moss).frame(width: 22)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.text).font(.subheadline)
                        if let data = item.photo, let ui = UIImage(data: data) {
                            Image(uiImage: ui).resizable().scaledToFill()
                                .frame(width: 120, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    Spacer()
                    Text(item.at.formatted(.dateTime.month().day().hour())).font(.caption).foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .contextMenu {
                    Button("この記録を削除", systemImage: "trash", role: .destructive) {
                        withAnimation { context.delete(item.model) }
                    }
                }
            }
        }
    }

    private var recent: [Item] {
        let since = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        var out: [Item] = []
        for c in turtle.cares ?? [] where c.at >= since {
            var text = c.kind.label
            let extra = [c.food?.label, c.appetite?.label].compactMap { $0 }
            if !extra.isEmpty { text += "（\(extra.joined(separator: "・"))）" }
            out.append(Item(id: c.persistentModelID, at: c.at, symbol: c.kind.symbol, text: text, photo: nil, model: c))
        }
        for m in turtle.measures ?? [] where m.on >= since {
            let parts = [m.shellMM.map { "甲長 \(Fmt.number($0))mm" }, m.grams.map { "\(Fmt.number($0))g" }].compactMap { $0 }
            out.append(Item(id: m.persistentModelID, at: m.on, symbol: "ruler.fill", text: parts.joined(separator: "・"), photo: nil, model: m))
        }
        for k in turtle.checkups ?? [] where k.on >= since {
            let signs = k.signs.sorted { $0.rawValue < $1.rawValue }.map(\.label)
            let text = ([signs.isEmpty ? "体のようす：気になるところなし" : "体のようす：" + signs.joined(separator: "、")] + (k.memo.isEmpty ? [] : [k.memo])).joined(separator: "\n")
            out.append(Item(id: k.persistentModelID, at: k.on, symbol: "stethoscope", text: text, photo: k.photo, model: k))
        }
        return out.sorted { $0.at > $1.at }.prefix(12).map { $0 }
    }
}
