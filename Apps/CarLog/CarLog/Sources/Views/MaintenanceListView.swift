import SwiftData
import SwiftUI

/// メンテ項目の一覧。項目ごとに「次はいつ・あと何km」と状態を出し、実施をその場で記録できる。
struct MaintenanceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Query(sort: [SortDescriptor(\Vehicle.sortOrder), SortDescriptor(\Vehicle.createdAt)])
    private var vehicles: [Vehicle]
    @AppStorage(StorageKey.selectedVehicleID) private var selectedID = ""

    @State private var showNewItem = false
    @State private var editing: MaintenanceItem?
    @State private var recording: MaintenanceItem?
    @State private var showPaywall = false

    private var vehicle: Vehicle? { Vehicle.resolve(vehicles, selectedID: selectedID) }

    /// 無料版の上限は「全車両の合計」ではなく、クルマごとではなく**アプリ全体**で数える。
    /// （無料版はクルマ1台なので実質同じだが、Pro 解約後に2台持っていても抜け道にならないように）
    private var totalItemCount: Int { vehicles.reduce(0) { $0 + $1.maintenanceItems.count } }

    var body: some View {
        NavigationStack {
            Group {
                if let vehicle {
                    list(vehicle)
                } else {
                    ScrollView { NoVehicleView() }
                        .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("メンテ")
            .toolbar {
                if vehicle != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: addItem) {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(Text("項目を追加"))
                    }
                }
            }
            .vehicleSwitcher(vehicles, selectedID: $selectedID)
            .sheet(isPresented: $showNewItem) {
                if let vehicle { MaintenanceEditorView(vehicle: vehicle, item: nil) }
            }
            .sheet(item: $editing) { item in
                if let vehicle { MaintenanceEditorView(vehicle: vehicle, item: item) }
            }
            .sheet(item: $recording) { item in
                if let vehicle { MaintenanceDoneView(vehicle: vehicle, item: item) }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environment(store)
            }
        }
        .tint(Theme.accent)
    }

    private func addItem() {
        if ProLimits.canAddMaintenanceItem(currentCount: totalItemCount, isPro: store.isPro) {
            showNewItem = true
        } else {
            showPaywall = true
        }
    }

    private func list(_ vehicle: Vehicle) -> some View {
        let items = vehicle.sortedMaintenanceItems
        let statuses = vehicle.maintenanceStatuses()

        return List {
            if items.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("メンテ項目がありません")
                            .font(.headline)
                        Text("オイル交換・車検・自動車税などを登録すると、時期が近づいたら通知でお知らせします。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("項目を追加", action: addItem)
                            .font(.subheadline.weight(.semibold))
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
            } else {
                Section {
                    ForEach(items, id: \.id) { item in
                        row(item, status: statuses[item.id])
                            .contentShape(Rectangle())
                            .onTapGesture { editing = item }
                            .swipeActions(edge: .leading) {
                                Button {
                                    recording = item
                                } label: {
                                    Label("実施した", systemImage: "checkmark")
                                }
                                .tint(Theme.accent)
                            }
                    }
                    .onDelete { offsets in
                        for index in offsets { modelContext.delete(items[index]) }
                        try? modelContext.save()
                        let context = modelContext
                        Task { await NotificationScheduler.shared.rebuild(context: context) }
                    }
                } footer: {
                    footer
                }
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if let remaining = ProLimits.remainingMaintenanceItems(currentCount: totalItemCount, isPro: store.isPro) {
            Text(remaining == 0
                 ? "無料版で登録できる\(ProLimits.freeMaintenanceItems)件に達しています。間隔は一般的な目安なので、取扱説明書の指定に合わせて変更してください。"
                 : "無料版はあと\(remaining)件まで追加できます。間隔は一般的な目安なので、取扱説明書の指定に合わせて変更してください。")
        } else {
            Text("間隔は一般的な目安です。取扱説明書の指定に合わせて変更してください。")
        }
    }

    private func row(_ item: MaintenanceItem, status: MaintenanceStatus?) -> some View {
        let state = status?.state ?? .ok
        return HStack(spacing: 12) {
            IconTile(
                symbolName: item.symbolName,
                color: item.isEnabled ? state.color : Color(.systemGray3),
                size: 38
            )
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.body.weight(.semibold))
                    if state != .ok { DueBadge(state: state) }
                    if !item.isEnabled {
                        Image(systemName: "bell.slash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(Formatting.interval(months: item.intervalMonths, distance: item.intervalDistance))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let status {
                    Text("次回 \(MaintenanceText.next(status))")
                        .font(.subheadline)
                        .foregroundStyle(state == .ok ? Color.primary : state.color)
                        .monospacedDigit()
                }
            }
            Spacer(minLength: 8)
            Button {
                recording = item
            } label: {
                Text("実施")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.12), in: Capsule())
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("\(item.title)の実施を記録"))
        }
        .padding(.vertical, 4)
    }
}
