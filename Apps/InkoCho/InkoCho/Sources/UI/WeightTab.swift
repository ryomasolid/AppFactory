import Charts
import SwiftData
import SwiftUI

/// 体重タブ：グラフ（ふだんの線つき）と記録の一覧。
struct WeightTab: View {
    @Query(sort: \Bird.sortIndex) private var birds: [Bird]
    @AppStorage(Picked.key) private var picked = ""
    @Environment(\.modelContext) private var context
    @State private var span = 30

    var body: some View {
        NavigationStack {
            List {
                if let bird = Picked.bird(in: birds, tag: picked) {
                    let points = bird.timeline.compactMap { l in l.grams.map { (log: l, grams: $0) } }
                    let reading = GramWatch.read(points.map { ($0.log.day, $0.grams) })
                    Section {
                        if let reading {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(GramWatch.text(reading.latest)).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(Hue.sky)
                                    Text(Say.day(reading.latestDay)).font(.subheadline).foregroundStyle(Hue.soft)
                                    Spacer()
                                    if let usual = reading.usual {
                                        VStack(alignment: .trailing) {
                                            Text("ふだん（7日平均）").font(.caption2).foregroundStyle(Hue.soft)
                                            Text(GramWatch.text(usual)).font(.headline)
                                        }
                                    }
                                }
                                Picker("期間", selection: $span) {
                                    Text("2週間").tag(14)
                                    Text("1か月").tag(30)
                                    Text("3か月").tag(90)
                                }
                                .pickerStyle(.segmented)
                                chart(points.map { ($0.log.day, $0.grams) }, usual: reading.usual)
                            }
                            .padding(.vertical, 4)
                        } else {
                            Text("「きょう」タブで体重を記録すると、ここにグラフが出ます。").font(.subheadline).foregroundStyle(Hue.soft)
                        }
                    } footer: {
                        Text("セキセイインコは30〜40gくらいの子が多く、大型の英セキセイは45〜60gほど。大事なのは、その子のふだんの体重からの変化です。")
                    }
                    if !points.isEmpty {
                        Section("記録") {
                            ForEach(points.reversed(), id: \.log.id) { p in
                                HStack {
                                    Text(Say.ymd(p.log.day))
                                    Spacer()
                                    Text(GramWatch.text(p.grams)).monospacedDigit().foregroundStyle(Hue.ink)
                                }
                            }
                            .onDelete { offsets in
                                let list = Array(points.reversed())
                                for i in offsets {
                                    let log = list[i].log
                                    log.grams = nil
                                    if log.isEmpty { context.delete(log) }
                                }
                                try? context.save()
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Hue.ground)
            .navigationTitle("体重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { BirdMenu(birds: birds, tag: $picked) } }
        }
    }

    private func chart(_ all: [(day: Date, grams: Double)], usual: Double?) -> some View {
        let from = Calendar.current.date(byAdding: .day, value: -span, to: Calendar.current.startOfDay(for: Date()))!
        let shown = all.filter { $0.day >= from }
        let values = shown.map(\.grams) + (usual.map { [$0] } ?? [])
        let low = (values.min() ?? 30) - 1, high = (values.max() ?? 40) + 1
        return Chart {
            if let usual {
                RuleMark(y: .value("ふだん", usual))
                    .foregroundStyle(Hue.lemon)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
            ForEach(shown, id: \.day) { p in
                LineMark(x: .value("日", p.day), y: .value("g", p.grams)).foregroundStyle(Hue.sky).interpolationMethod(.monotone)
                PointMark(x: .value("日", p.day), y: .value("g", p.grams)).foregroundStyle(Hue.sky).symbolSize(22)
            }
        }
        .chartYScale(domain: low...high)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisGridLine(); AxisValueLabel(format: .dateTime.month(.defaultDigits).day()) } }
        .frame(height: 190)
    }
}
