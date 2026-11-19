import Charts
import SwiftData
import SwiftUI

/// 成長：甲長・体重のグラフと、冬眠の見守り。
struct GrowthScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Turtle.order) private var turtles: [Turtle]
    @AppStorage(Selection.storageKey) private var selectedKey = ""
    @State private var metric = Metric.shell
    @State private var span = Span.year
    @State private var measuring: Turtle?
    @State private var starting: Turtle?

    enum Metric: String, CaseIterable, Identifiable {
        case shell, weight
        var id: Self { self }
        var label: String { self == .shell ? "甲長" : "体重" }
        var unit: String { self == .shell ? "mm" : "g" }
    }

    enum Span: Int, CaseIterable, Identifiable {
        case half = 182, year = 365, all = 0
        var id: Self { self }
        var label: String {
            switch self {
            case .half: "半年"
            case .year: "1年"
            case .all: "すべて"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let turtle = Selection.pick(turtles, key: selectedKey) {
                    VStack(spacing: 14) {
                        TurtleSwitcher(turtles: turtles, selectedKey: $selectedKey)
                        // 冬眠中は体重の減りがいちばん大事なので、上に出す。
                        if turtle.currentRest != nil {
                            RestCard(turtle: turtle) { starting = turtle }
                            chartCard(turtle)
                        } else {
                            chartCard(turtle)
                            RestCard(turtle: turtle) { starting = turtle }
                        }
                        historyCard(turtle)
                    }
                    .padding()
                }
            }
            .background(Palette.sand.ignoresSafeArea())
            .navigationTitle("成長")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        measuring = Selection.pick(turtles, key: selectedKey)
                    } label: {
                        Label("計る", systemImage: "plus")
                    }
                    .accessibilityIdentifier("add-measure")
                }
            }
            .sheet(item: $measuring) { MeasureSheet(turtle: $0) }
            .sheet(item: $starting) { RestStartSheet(turtle: $0) }
        }
    }

    private func points(_ turtle: Turtle) -> [GrowthMath.Point] {
        metric == .shell ? GrowthMath.shell(turtle.growth) : GrowthMath.weight(turtle.growth)
    }

    private func chartCard(_ turtle: Turtle) -> some View {
        let all = points(turtle)
        let from = span == .all ? Date.distantPast : Calendar.current.date(byAdding: .day, value: -span.rawValue, to: Date())!
        let shown = all.filter { $0.on >= from }
        let rests = (turtle.rests ?? []).filter { ($0.endedOn ?? Date()) >= from }
        return Panel {
            Picker("項目", selection: $metric) {
                ForEach(Metric.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .firstTextBaseline, spacing: 18) {
                stat("いま", all.last.map { "\(Fmt.number($0.value))\(metric.unit)" } ?? "—")
                stat("前回から", GrowthMath.change(all).map { "\(Fmt.signed($0))\(metric.unit)" } ?? "—")
                stat("1年で", GrowthMath.perYear(all, now: Date()).map { "\(Fmt.signed($0, digits: 0))\(metric.unit)" } ?? "—")
            }

            if shown.count < 2 {
                Text("2回以上計ると、ここにグラフが出ます。2週間に1回くらいが目安です。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart {
                    ForEach(rests, id: \.startedOn) { r in
                        RectangleMark(xStart: .value("冬眠", max(r.startedOn, shown.first!.on)), xEnd: .value("冬眠", r.endedOn ?? Date()))
                            .foregroundStyle(Palette.pond.opacity(0.12))
                    }
                    ForEach(shown, id: \.on) { p in
                        LineMark(x: .value("日", p.on), y: .value(metric.label, p.value))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(Palette.moss)
                        PointMark(x: .value("日", p.on), y: .value(metric.label, p.value))
                            .foregroundStyle(Palette.moss)
                            .symbolSize(24)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 210)
                if !rests.isEmpty {
                    Label("青い帯は冬眠していた期間", systemImage: "moon.zzz").font(.caption).foregroundStyle(Palette.pond)
                }
            }

            Picker("期間", selection: $span) {
                ForEach(Span.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold().monospacedDigit()).foregroundStyle(Palette.ink)
        }
    }

    private func historyCard(_ turtle: Turtle) -> some View {
        Panel(title: "計った記録", symbol: "ruler") {
            let rows = Array(turtle.growth.reversed())
            if rows.isEmpty {
                Text("右上の＋から記録できます。").font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(rows.prefix(30)) { m in
                HStack {
                    Text(m.on.formatted(.dateTime.year().month().day())).foregroundStyle(.secondary)
                    Spacer()
                    Text(m.shellMM.map { "\(Fmt.number($0))mm" } ?? "—").monospacedDigit().frame(width: 80, alignment: .trailing)
                    Text(m.grams.map { "\(Fmt.number($0))g" } ?? "—").monospacedDigit().frame(width: 80, alignment: .trailing)
                }
                .font(.subheadline)
                .contentShape(Rectangle())
                .contextMenu {
                    Button("この記録を削除", systemImage: "trash", role: .destructive) {
                        withAnimation { context.delete(m) }
                    }
                }
            }
            if !rows.isEmpty {
                Text("長押しで削除できます。").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

/// 冬眠の見守り。
private struct RestCard: View {
    let turtle: Turtle
    let start: () -> Void
    @Environment(\.modelContext) private var context
    @State private var confirmEnd = false

    var body: some View {
        Panel(title: "冬眠", symbol: "moon.zzz.fill") {
            if let rest = turtle.currentRest {
                Text("\(Fmt.day(rest.startedOn)) から冬眠中（\(days(since: rest.startedOn))日目）")
                    .font(.subheadline.weight(.semibold))
                if let start = rest.startGrams {
                    if let r = HibernationWatch.check(rest, measures: turtle.measures ?? []) {
                        HStack(spacing: 18) {
                            figure("始めたとき", "\(Fmt.number(start))g")
                            figure("減った分", "\(Fmt.number(r.lostPercent))%")
                            figure("ひと月あたり", "\(Fmt.number(r.perMonth))%")
                        }
                        Gauge(value: min(r.perMonth, 3), in: 0...3) { EmptyView() }
                            .tint(Gradient(colors: [Palette.moss, Palette.amber, Palette.rust]))
                    } else {
                        Text("始めたときは \(Fmt.number(start))g。1週間に1回、体重を計って減り方を見ます。")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Text("体重はひと月に1%までの減りが目安。それより早く減るときや、10%減ったときは起こして温めます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("冬眠を終える") { confirmEnd = true }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("end-rest")
            } else if turtle.species.canHibernate {
                Text("冬眠させるときは、始めた日の体重を残しておくと、減りすぎに気づけます。冬眠させずに保温して冬を越すこともできます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("冬眠を始める", action: start)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("start-rest")
            } else {
                Text("\(turtle.species.label)は暖かい地域のカメなので、冬眠させずに一年じゅう保温します。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            let past = (turtle.rests ?? []).filter { $0.endedOn != nil }.sorted { $0.startedOn > $1.startedOn }
            ForEach(past, id: \.startedOn) { r in
                Text("これまで：\(Fmt.day(r.startedOn))〜\(Fmt.day(r.endedOn!))（\(days(since: r.startedOn, to: r.endedOn!))日）")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .confirmationDialog("冬眠を終えて、ふだんの世話の予定に戻します。", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("冬眠を終える") { turtle.currentRest?.endedOn = Date() }
        }
    }

    private func days(since: Date, to: Date = Date()) -> Int {
        (Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: since), to: Calendar.current.startOfDay(for: to)).day ?? 0) + 1
    }

    private func figure(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit())
        }
    }
}

/// 冬眠を始める。始めたときの体重を残す。
private struct RestStartSheet: View {
    let turtle: Turtle
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var on = Date()
    @State private var grams = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("始めた日", selection: $on, in: ...Date(), displayedComponents: .date)
                    HStack {
                        Text("体重")
                        TextField("0", text: $grams)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("rest-grams")
                        Text("g").foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("冬眠の前は数週間ごはんを止めて、おなかを空にしておきます。体の弱っている子・1歳未満の子は、冬眠させずに保温するのが安心です。")
                }
            }
            .navigationTitle("冬眠を始める")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("始める") {
                        let g = Fmt.parse(grams)
                        context.insert(Rest(startedOn: on, startGrams: g, turtle: turtle))
                        if let g { context.insert(Measure(on: on, shellMM: nil, grams: g, turtle: turtle)) }
                        Task { await Reminders.refresh(context) }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let g = turtle.growth.last(where: { $0.grams != nil })?.grams { grams = Fmt.number(g) }
            }
        }
        .presentationDetents([.medium])
    }
}
