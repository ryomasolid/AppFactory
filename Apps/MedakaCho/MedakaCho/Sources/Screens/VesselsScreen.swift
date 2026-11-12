import SwiftData
import SwiftUI

/// 容器の一覧。上に「今日の見まわり」、下に容器のカード。
struct VesselsScreen: View {
    @Query(sort: \Vessel.order) private var vessels: [Vessel]
    @Query(filter: #Predicate<EggBatch> { $0.hatched == nil }) private var openBatches: [EggBatch]
    @State private var addingVessel = false
    @State private var path: [PersistentIdentifier] = []

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if vessels.isEmpty {
                        emptyState
                    } else {
                        RoundsPanel(vessels: vessels, batches: openBatches)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(vessels) { vessel in
                                NavigationLink(value: vessel.persistentModelID) {
                                    VesselCard(vessel: vessel)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Palette.water)
            .navigationTitle("めだか帳")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                if let vessel = vessels.first(where: { $0.persistentModelID == id }) {
                    VesselScreen(vessel: vessel)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("容器を追加", systemImage: "plus") { addingVessel = true }
                }
            }
            .sheet(isPresented: $addingVessel) {
                VesselEditor(vessel: nil, nextOrder: (vessels.map(\.order).max() ?? -1) + 1)
            }
            .onAppear {
                if Sample.opensFirstVessel, path.isEmpty, let first = vessels.first {
                    path = [first.persistentModelID]
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            BowlGlyph(style: .bowl, headcount: 3, mood: .lively, size: 96)
            Text("はじめに、めだかの入っている容器を登録しましょう")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("睡蓮鉢・発泡スチロール・水槽など、入れものごとに水換えやえさ、卵を記録します。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                addingVessel = true
            } label: {
                Label("容器を登録する", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

/// 今日やること：水換えの目安が来た容器、孵りそうな卵、全体の数。
private struct RoundsPanel: View {
    let vessels: [Vessel]
    let batches: [EggBatch]

    var body: some View {
        let now = Date()
        let dueWater = vessels.filter { $0.headcount > 0 && VesselState(vessel: $0, now: now).daysUntilWater(now: now) <= 0 }
        let hatching = batches.filter { HatchClock.progress(collectedOn: $0.collectedOn, celsius: $0.celsius, now: now) >= 0.9 }
        let total = vessels.reduce(0) { $0 + $1.headcount }

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("今日の見まわり").font(.headline)
                Spacer()
                Text("ぜんぶで \(total) 匹・\(vessels.count) 容器")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if dueWater.isEmpty && hatching.isEmpty {
                Label("今日の水換えはありません。様子を見てあげてください", systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(Palette.duckweed)
            }
            if !dueWater.isEmpty {
                Label {
                    Text("水換えの目安: ") + Text(dueWater.map(\.name).joined(separator: "・")).bold()
                } icon: {
                    Image(systemName: LogKind.waterChange.symbol).foregroundStyle(Palette.deep)
                }
                .font(.subheadline)
            }
            if !hatching.isEmpty {
                Label {
                    Text("孵化が近い卵: ") + Text("\(hatching.count)組").bold()
                } icon: {
                    Image(systemName: "sparkle").foregroundStyle(Palette.koi)
                }
                .font(.subheadline)
            }
        }
        .panel()
    }
}

private struct VesselCard: View {
    let vessel: Vessel

    var body: some View {
        let state = VesselState(vessel: vessel)
        let days = state.daysUntilWater()
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                BowlGlyph(style: vessel.style, headcount: vessel.headcount, mood: state.mood, size: 44)
                Spacer()
                if let c = state.celsius {
                    Text(String(format: "%.0f℃", c))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Text(vessel.name).font(.headline).lineLimit(1)
            Text("\(vessel.breedLabel)・\(vessel.stage.label) \(vessel.headcount)匹")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(spacing: 4) {
                if vessel.headcount > 0 {
                    Pill(text: "水換え \(DayText.relative(days: days))", tint: days <= 0 ? Palette.koi : Palette.deep)
                }
                if state.crowded { Pill(text: "過密", tint: Palette.warn) }
            }
        }
        .panel()
    }
}
