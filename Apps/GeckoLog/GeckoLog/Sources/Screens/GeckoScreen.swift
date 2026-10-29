import Charts
import SwiftData
import SwiftUI

/// 1匹の詳細。いまの様子 → ワンタップ記録 → 体重グラフ → これまでの記録。
struct GeckoScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let gecko: Gecko

    @State private var newKind: CareKind?
    @State private var editingEntry: CareEntry?
    @State private var editingProfile = false
    @State private var removalRequested = false

    var body: some View {
        let status = gecko.status()
        let entries = gecko.allEntries.sorted { $0.occurredAt > $1.occurredAt }

        ScrollView {
            VStack(spacing: 14) {
                header(status: status)
                watchNotes(status: status)
                statusGrid(status: status)
                quickRecord
                WeightChart(entries: gecko.allEntries)
                history(entries)
            }
            .padding(16)
        }
        .background(Terrarium.sand)
        .navigationTitle(gecko.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("編集") { editingProfile = true }
            }
        }
        .sheet(item: $newKind) { kind in
            EntrySheet(gecko: gecko, kind: kind, existing: nil)
        }
        .sheet(item: $editingEntry) { entry in
            EntrySheet(gecko: gecko, kind: entry.kind, existing: entry)
        }
        .sheet(isPresented: $editingProfile, onDismiss: removeIfRequested) {
            GeckoForm(gecko: gecko) { removalRequested = true }
        }
    }

    /// 編集シートで「消す」が押されたら、一覧へ戻ってから消す。
    private func removeIfRequested() {
        guard removalRequested else { return }
        removalRequested = false
        let target = gecko
        dismiss()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            context.delete(target)
            try? context.save()
            await FeedingAlarm.reschedule(context: context)
        }
    }

    private func header(status: GeckoStatus) -> some View {
        HStack(spacing: 14) {
            GeckoAvatar(name: gecko.name, portrait: gecko.portrait, size: 76)
            VStack(alignment: .leading, spacing: 4) {
                Text(gecko.name).font(.title2.weight(.bold))
                if !gecko.morph.isEmpty {
                    Text(gecko.morph).font(.subheadline).foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Tag(text: gecko.sex.label, color: Terrarium.spot)
                    Tag(text: status.stage.label, color: Terrarium.moss)
                    if let age = gecko.ageText() { Tag(text: age, color: .secondary) }
                }
                if let arrived = gecko.arrivedOn {
                    Text("お迎えから \(CareRhythm.days(from: arrived, to: Date()))日")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .cardSurface()
    }

    /// 気にかけたいことがあるときだけ出す。
    @ViewBuilder private func watchNotes(status: GeckoStatus) -> some View {
        let notes = watchMessages(status)
        if !notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(notes, id: \.self) { note in
                    Label(note, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Terrarium.alert)
                }
                Text("温度が低い・脱皮前・繁殖期・冬場は食欲が落ちることがあります。しっぽが細くなる・ぐったりしているときは爬虫類を診られる動物病院へ。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface()
        }
    }

    private func watchMessages(_ status: GeckoStatus) -> [String] {
        var notes: [String] = []
        if status.refusalStreak >= 2 { notes.append("\(status.refusalStreak)回つづけて食べていません") }
        if let since = status.daysSinceAte, since >= 14 { notes.append("最後に食べてから\(since)日たちました") }
        if status.isLosingWeight, let change = status.monthlyWeightChange {
            notes.append(String(format: "この1か月で体重が %.0f%% 減っています", -change))
        }
        return notes
    }

    private func statusGrid(status: GeckoStatus) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            statusTile(
                title: "次のごはん",
                value: status.daysUntilFeeding < 0 ? "\(-status.daysUntilFeeding)日すぎ" : status.nextFeeding.shortDayText,
                detail: "\(status.feedInterval)日おき",
                color: status.isFeedingDue ? Terrarium.moss : .primary
            )
            statusTile(
                title: "最後に食べた",
                value: status.daysSinceAte.map { $0 == 0 ? "今日" : "\($0)日前" } ?? "—",
                detail: status.refusalStreak > 0 ? "そのあと拒食\(status.refusalStreak)回" : " ",
                color: status.needsAppetiteWatch ? Terrarium.alert : .primary
            )
            statusTile(
                title: "次の脱皮（予想）",
                value: status.nextShed.map { status.daysUntilShed! < 0 ? "そろそろ" : $0.shortDayText } ?? "—",
                detail: status.nextShed == nil ? "脱皮を記録すると予想します" : "これまでの間隔から",
                color: status.isShedNear ? Terrarium.shed : .primary
            )
            statusTile(
                title: "体重",
                value: status.latestGrams.map(CareEntry.gramText) ?? "—",
                detail: status.monthlyWeightChange.map { String(format: "1か月で %+.0f%%", $0) } ?? " ",
                color: status.isLosingWeight ? Terrarium.alert : .primary
            )
        }
    }

    private func statusTile(title: String, value: String, detail: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.bold)).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)
            Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var quickRecord: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("記録する").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(CareKind.allCases) { kind in
                    Button { newKind = kind } label: {
                        VStack(spacing: 6) {
                            Image(systemName: kind.symbol).font(.title3)
                            Text(kind.label).font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Terrarium.sand, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(kind == .feeding ? Terrarium.moss : kind == .shed ? Terrarium.shed : .primary)
                }
            }
        }
        .cardSurface()
    }

    private func history(_ entries: [CareEntry]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("これまでの記録").font(.headline).padding(.bottom, 8)
            if entries.isEmpty {
                Text("まだ記録がありません").font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 8)
            }
            ForEach(entries.prefix(60)) { entry in
                Button { editingEntry = entry } label: { EntryRow(entry: entry, showsName: false) }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("削除", systemImage: "trash", role: .destructive) {
                            context.delete(entry)
                            try? context.save()
                        }
                    }
                if entry.id != entries.prefix(60).last?.id { Divider() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

/// 記録1件の行。きろくタブと詳細画面で共通。
struct EntryRow: View {
    let entry: CareEntry
    let showsName: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.kind.symbol)
                .frame(width: 30, height: 30)
                .foregroundStyle(tint)
                .background(tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if showsName, let name = entry.gecko?.name { Text(name).font(.subheadline.weight(.bold)) }
                    Text(entry.kind.label).font(.subheadline.weight(showsName ? .regular : .semibold))
                }
                Text(entry.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            // きろくタブは日ごとの見出しがあるので時刻だけ。
            Text(showsName ? entry.occurredAt.formatted(date: .omitted, time: .shortened) : entry.occurredAt.shortDayText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var tint: Color {
        switch entry.kind {
        case .feeding: entry.accepted ? Terrarium.moss : Terrarium.alert
        case .shed: Terrarium.shed
        case .weight: Terrarium.yolk
        default: .secondary
        }
    }
}

/// 体重の折れ線。2回以上はかったら出す。
struct WeightChart: View {
    let entries: [CareEntry]

    var body: some View {
        let points = entries
            .compactMap { entry in entry.kind == .weight ? entry.grams.map { (at: entry.occurredAt, grams: $0) } : nil }
            .sorted { $0.at < $1.at }
        if points.count >= 2 {
            VStack(alignment: .leading, spacing: 10) {
                Text("体重の変化").font(.headline)
                Chart(points, id: \.at) { point in
                    LineMark(x: .value("日付", point.at), y: .value("体重", point.grams))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Terrarium.yolk)
                    PointMark(x: .value("日付", point.at), y: .value("体重", point.grams))
                        .foregroundStyle(Terrarium.yolk)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxis { AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel { if let grams = value.as(Double.self) { Text("\(Int(grams))g") } }
                } }
                .frame(height: 170)
            }
            .cardSurface()
        }
    }
}
