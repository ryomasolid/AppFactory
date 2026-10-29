import SwiftData
import SwiftUI

/// 多頭飼いの「ごはんの時間」を1画面で。同じエサを順に配って、食べなかった子だけ外す。
struct FeedRoundSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Gecko.position) private var geckos: [Gecko]

    @State private var feeder: Feeder = .cricket
    @State private var count = 3
    @State private var dusted = true
    /// 記録する子。開いた時点でごはんの日の子を入れておく。
    @State private var selected: Set<UUID> = []
    /// 選んだうち、食べなかった子。
    @State private var refused: Set<UUID> = []
    @State private var prepared = false

    var body: some View {
        NavigationStack {
            Form {
                Section("エサ") {
                    FeederPicker(feeder: $feeder)
                    Stepper("1匹あたり \(count)\(feeder.counter)", value: $count, in: 0...30)
                    Toggle("カルシウム・ビタミンをまぶした", isOn: $dusted)
                }
                Section {
                    ForEach(geckos) { gecko in
                        row(for: gecko)
                    }
                } header: {
                    Text("あげた子")
                } footer: {
                    Text("食べなかった子は右の「食べた」を押して「拒食」に切り替えてください。次のごはんの日はそのまま進みます。")
                }
            }
            .navigationTitle("ごはんの時間")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("記録する（\(selected.count)匹）", action: save).disabled(selected.isEmpty)
                }
            }
            .onAppear(perform: prepare)
        }
    }

    private func row(for gecko: Gecko) -> some View {
        let isOn = selected.contains(gecko.uid)
        let ate = !refused.contains(gecko.uid)
        let status = gecko.status()
        return HStack(spacing: 12) {
            Button {
                if isOn { selected.remove(gecko.uid) } else { selected.insert(gecko.uid) }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isOn ? Terrarium.moss : .secondary)
                    GeckoAvatar(name: gecko.name, portrait: gecko.portrait, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gecko.name).foregroundStyle(.primary)
                        Text(status.isFeedingDue ? "ごはんの日" : "あと\(status.daysUntilFeeding)日")
                            .font(.caption)
                            .foregroundStyle(status.isFeedingDue ? Terrarium.moss : .secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            if isOn {
                Button(ate ? "食べた" : "拒食") {
                    if ate { refused.insert(gecko.uid) } else { refused.remove(gecko.uid) }
                }
                .buttonStyle(.bordered)
                .tint(ate ? Terrarium.moss : Terrarium.alert)
                .font(.subheadline.weight(.semibold))
            }
        }
    }

    private func prepare() {
        guard !prepared else { return }
        prepared = true
        selected = Set(geckos.filter { $0.status().isFeedingDue }.map(\.uid))
        // 前回と同じエサから始める（たいてい毎回同じものをあげるので）。
        let lastFeed = geckos.flatMap(\.allEntries)
            .filter { $0.kind == .feeding && $0.accepted && $0.feeder != nil }
            .max { $0.occurredAt < $1.occurredAt }
        if let lastFeed, let lastFeeder = lastFeed.feeder {
            feeder = lastFeeder
            if lastFeed.feederCount > 0 { count = lastFeed.feederCount }
        }
    }

    private func save() {
        let now = Date()
        for gecko in geckos where selected.contains(gecko.uid) {
            let entry = CareEntry(kind: .feeding, occurredAt: now, gecko: gecko)
            entry.accepted = !refused.contains(gecko.uid)
            if entry.accepted {
                entry.feederCode = feeder.rawValue
                entry.feederCount = count
                entry.dusted = dusted
            }
            context.insert(entry)
        }
        try? context.save()
        Task { await FeedingAlarm.reschedule(context: context) }
        dismiss()
    }
}

/// エサの種類を横に並べたチップで選ぶ。
struct FeederPicker: View {
    @Binding var feeder: Feeder

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Feeder.allCases) { item in
                    Button(item.label) { feeder = item }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .foregroundStyle(feeder == item ? Color.white : Color.primary)
                        .background(feeder == item ? Terrarium.moss : Terrarium.sand, in: Capsule())
                        .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
