import Charts
import SwiftData
import SwiftUI

/// 日記タブ。体重グラフと、記録の一覧（新しい順）。
struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\DiaryRecord.date, order: .reverse), SortDescriptor(\DiaryRecord.createdAt, order: .reverse)])
    private var records: [DiaryRecord]
    @Query(sort: \CleaningOption.sortOrder) private var cleaningOptions: [CleaningOption]

    @State private var editing: DiaryRecord?
    @State private var sharing: DiaryRecord?
    @State private var showNew = false
    @State private var deleting: DiaryRecord?

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            WeightChartCard(records: records)
                            ForEach(records) { record in
                                RecordCard(record: record, cleaningOptions: cleaningOptions, onShare: { sharing = record })
                                    .contentShape(Rectangle())
                                    .onTapGesture { editing = record }
                                    .contextMenu {
                                        Button("編集", systemImage: "pencil") { editing = record }
                                        Button("シェア", systemImage: "square.and.arrow.up") { sharing = record }
                                        Button("削除", systemImage: "trash", role: .destructive) { deleting = record }
                                    }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .creamBackground()
            .navigationTitle("日記")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("記録する", systemImage: "plus") { showNew = true }
                }
            }
        }
        .sheet(isPresented: $showNew) { RecordEditorView(record: nil) }
        .sheet(item: $editing) { RecordEditorView(record: $0) }
        .sheet(item: $sharing) { ShareCardView(record: $0) }
        .confirmationDialog("この記録を削除しますか？", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                if let record = deleting {
                    PhotoStore.delete(record.photoPath)
                    modelContext.delete(record)
                    try? modelContext.save()
                }
                deleting = nil
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("📔").font(.system(size: 56))
            Text("まだ記録がありません").font(.title3.bold())
            Text("体重やごはん、掃除の記録を残しましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("最初の記録を追加") { showNew = true }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 体重の推移（Swift Charts）。体重の記録が2件以上あるときだけ出す。
struct WeightChartCard: View {
    let records: [DiaryRecord]
    @State private var range: WeightRange = .month

    var body: some View {
        let all = WeightSeries.points(records.map { ($0.date, $0.weight, $0.createdAt) })
        if all.count >= 2, let latest = all.last {
            let points = WeightSeries.filter(all, range: range)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("体重の推移", systemImage: "chart.xyaxis.line")
                            .font(.subheadline.weight(.semibold))
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            WeightText(weight: latest.weight, size: 26)
                            if let change = WeightSeries.change(points) {
                                Text(Formatting.signedWeight(change))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Picker("期間", selection: $range) {
                        ForEach(WeightRange.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }

                if points.count >= 2 {
                    Chart(points) { point in
                        AreaMark(x: .value("日付", point.date, unit: .day), yStart: .value("", WeightSeries.yDomain(points).lowerBound), yEnd: .value("体重", point.weight))
                            .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.28), Theme.accent.opacity(0)], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.monotone)
                        LineMark(x: .value("日付", point.date, unit: .day), y: .value("体重", point.weight))
                            .foregroundStyle(Theme.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.monotone)
                        if points.count <= 40 || point == points.last {
                            PointMark(x: .value("日付", point.date, unit: .day), y: .value("体重", point.weight))
                                .foregroundStyle(Theme.accent)
                                .symbolSize(point == points.last ? 60 : 18)
                        }
                    }
                    .chartYScale(domain: WeightSeries.yDomain(points))
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                        }
                    }
                    .frame(height: 170)
                } else {
                    Text("この期間の体重記録が2件以上たまるとグラフが表示されます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 170)
                        .multilineTextAlignment(.center)
                }
            }
            .card()
        }
    }
}

/// 日記の1件。
struct RecordCard: View {
    let record: DiaryRecord
    let cleaningOptions: [CleaningOption]
    var onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Formatting.day(record.date))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let weight = record.weight {
                    Text("体重").font(.caption).foregroundStyle(.secondary)
                    WeightText(weight: weight)
                }
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .padding(7)
                        .background(Theme.softFill, in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)
                .accessibilityLabel("この記録をシェア")
            }

            if record.photoPath != nil {
                PhotoView(path: record.photoPath)
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            if !record.food.isEmpty {
                row("🌾 ごはん") { Text(record.food).font(.subheadline) }
            }
            let cleanings = record.cleaningKeys.compactMap { key in cleaningOptions.first { $0.key == key } }
            if !cleanings.isEmpty {
                row("🧹 お掃除") {
                    FlowLayout(spacing: 6) {
                        ForEach(cleanings, id: \.key) { ChipLabel(text: "\($0.emoji) \($0.name)") }
                    }
                }
            }
            if !record.memo.isEmpty {
                row("📝 メモ") { Text(record.memo).font(.subheadline).foregroundStyle(.secondary) }
            }
        }
        .card()
    }

    private func row<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text(title).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }
}

/// 横に並べて、はみ出したら折り返す。
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let extra = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if extra > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let last = rows.count - 1
            rows[last].width = rows[last].indices.isEmpty ? size.width : rows[last].width + spacing + size.width
            rows[last].height = max(rows[last].height, size.height)
            rows[last].indices.append(index)
        }
        return rows
    }
}
