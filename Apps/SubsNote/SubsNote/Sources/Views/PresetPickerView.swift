import SwiftUI

/// 追加のシート。プリセットを選んで編集へ（プリセットが決まっていれば編集から始める）。
struct AddSubscriptionSheet: View {
    var preset: ServicePreset?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let preset {
                SubscriptionEditorView(subscription: nil, preset: preset) { _ in dismiss() }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("キャンセル") { dismiss() }
                        }
                    }
            } else {
                PresetPickerView { dismiss() }
            }
        }
        .tint(Theme.accent)
    }
}

/// サービスの検索と、カテゴリ別の一覧。
struct PresetPickerView: View {
    var onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [ServicePreset] { ServicePreset.search(query) }
    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    editor(preset: nil, name: trimmedQuery)
                } label: {
                    Label(
                        trimmedQuery.isEmpty ? String(localized: "リストにないサービスを追加") : String(localized: "「\(trimmedQuery)」を追加"),
                        systemImage: "square.and.pencil"
                    )
                    .foregroundStyle(Theme.accent)
                }
            }

            if trimmedQuery.isEmpty {
                ForEach(SubCategory.allCases) { category in
                    let presets = ServicePreset.all.filter { $0.category == category }
                    if !presets.isEmpty {
                        Section(category.label) {
                            ForEach(presets) { row($0) }
                        }
                    }
                }
            } else if !results.isEmpty {
                Section {
                    ForEach(results) { row($0) }
                }
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("サービス名で検索"))
        .navigationTitle("サブスクを追加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
        }
    }

    private func row(_ preset: ServicePreset) -> some View {
        NavigationLink {
            editor(preset: preset, name: "")
        } label: {
            HStack(spacing: 12) {
                ServiceIcon(name: preset.name, category: preset.category, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name).font(.body)
                    if let plan = preset.plans.first {
                        let price = Formatting.cyclePrice(price: plan.price, cycle: plan.cycle, interval: plan.interval)
                        Text(preset.plans.count > 1 ? String(localized: "\(price) ほか") : price)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func editor(preset: ServicePreset?, name: String) -> some View {
        SubscriptionEditorView(subscription: nil, preset: preset, initialName: name) { _ in onFinish() }
    }
}
