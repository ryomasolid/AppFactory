import SwiftData
import SwiftUI

/// 容器1つの詳細。いまの様子 → ワンタップ記録 → 履歴。
struct VesselScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var close
    @Bindable var vessel: Vessel
    @State private var sheetKind: LogKind?
    @State private var editing = false
    @State private var justLogged: String?

    var body: some View {
        let state = VesselState(vessel: vessel)
        List {
            Section {
                header
                statusRows(state)
            }
            .listRowBackground(Palette.surface)

            Section {
                QuickGrid { kind in tap(kind) }
                    .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            } header: {
                Text("記録する")
            } footer: {
                Text("えさ・足し水・底掃除はワンタップで。ほかは数や水温を入れて保存します。")
            }
            .listRowBackground(Palette.surface)

            Section("これまで") {
                if vessel.history.isEmpty {
                    Text("まだ記録がありません").foregroundStyle(.secondary)
                }
                ForEach(vessel.history) { log in
                    LogRow(log: log)
                }
                .onDelete { offsets in
                    let shown = vessel.history
                    for index in offsets { remove(shown[index]) }
                }
            }
            .listRowBackground(Palette.surface)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.water)
        .navigationTitle(vessel.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("編集") { editing = true }
        }
        .sheet(item: $sheetKind) { kind in
            LogSheet(vessel: vessel, kind: kind)
        }
        .sheet(isPresented: $editing) {
            VesselEditor(vessel: vessel, nextOrder: vessel.order) {
                close()
                let context = context
                let doomed = vessel
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    context.delete(doomed)
                    try? context.save()
                    await MorningDigest.refresh(context: context)
                }
            }
        }
        .overlay(alignment: .top) {
            if let justLogged {
                Text(justLogged)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 6)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            BowlGlyph(style: vessel.style, headcount: vessel.headcount, mood: VesselState(vessel: vessel).mood, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(vessel.breedLabel).font(.title3.bold())
                Text("\(vessel.style.label)・\(vessel.outdoors ? "屋外" : "屋内")・\(Self.liters(vessel.liters))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(vessel.stage.label) \(vessel.headcount)匹")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.koi)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusRows(_ state: VesselState) -> some View {
        let days = state.daysUntilWater()
        LabeledContent {
            Text("\(DayText.short(state.waterDue))（\(DayText.relative(days: days))）")
                .foregroundStyle(days <= 0 ? Palette.koi : .primary)
        } label: {
            Label("次の水換え", systemImage: LogKind.waterChange.symbol)
        }
        LabeledContent {
            Text(state.lastWaterChange.map { "\(DayText.short($0))・\(state.waterInterval)日おき目安" } ?? "\(state.waterInterval)日おき目安")
        } label: {
            Label("前の水換え", systemImage: "clock.arrow.circlepath")
        }
        if let c = state.celsius {
            VStack(alignment: .leading, spacing: 4) {
                LabeledContent {
                    Text(String(format: "%.1f℃", c) + (state.mood.map { "・\($0.title)" } ?? ""))
                } label: {
                    Label("水温", systemImage: LogKind.temperature.symbol)
                }
                if let mood = state.mood {
                    Text("えさ: \(mood.feedingAdvice)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("1週間以上前の水温です。測りなおすと、えさと水換えの目安が季節に合います。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Label("水温を記録すると、季節に合ったえさの目安が出ます", systemImage: LogKind.temperature.symbol)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        if let perFish = WaterSense.litersPerFish(liters: vessel.liters, headcount: vessel.headcount) {
            LabeledContent {
                Text(String(format: "%.1f L", perFish))
                    .foregroundStyle(state.crowded ? Palette.warn : .primary)
            } label: {
                Label(state.crowded ? "1匹あたりの水（過密ぎみ）" : "1匹あたりの水", systemImage: "drop")
            }
        }
        if state.recentLosses > 0 {
            LabeledContent {
                Text("\(state.recentLosses)匹").foregroundStyle(Palette.warn)
            } label: {
                Label("30日で★になった数", systemImage: "star")
            }
        }
    }

    private func tap(_ kind: LogKind) {
        switch kind {
        case .feed, .topUp, .clean:
            let log = PondLog(kind: kind, vessel: vessel)
            context.insert(log)
            try? context.save()
            withAnimation { justLogged = "\(kind.label)を記録しました" }
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation { justLogged = nil }
            }
            refreshDigest()
        default:
            sheetKind = kind
        }
    }

    /// 消した記録が数を動かしていたら、もとに戻す。
    private func remove(_ log: PondLog) {
        if let count = log.count, log.kind.headcountSign != 0 {
            vessel.headcount = max(0, vessel.headcount - log.kind.headcountSign * count)
        }
        context.delete(log)
        try? context.save()
        refreshDigest()
    }

    private func refreshDigest() {
        let context = context
        Task { await MorningDigest.refresh(context: context) }
    }

    static func liters(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))L" : String(format: "%.1fL", value)
    }
}

private struct QuickGrid: View {
    let action: (LogKind) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(LogKind.quick) { kind in
                Button {
                    action(kind)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: kind.symbol).font(.title3)
                        Text(kind.label).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .foregroundStyle(kind == .loss ? Palette.mute : Palette.deep)
                    .background(Palette.water, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("quick-\(kind.rawValue)")
            }
        }
    }
}

struct LogRow: View {
    let log: PondLog
    var showsVessel = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.kind.symbol)
                .frame(width: 26)
                .foregroundStyle(log.kind == .loss ? Palette.mute : Palette.deep)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(log.kind.label).font(.subheadline.weight(.semibold))
                    if showsVessel, let name = log.vessel?.name {
                        Text(name).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if !log.summary.isEmpty {
                    Text(log.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer()
            Text(DayText.short(log.at))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
