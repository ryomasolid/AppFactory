import SwiftData
import SwiftUI

/// 給油の一覧。各行に「その給油で確定した区間燃費」を大きく出す（＝入力の見返り）。
struct FuelListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Query(sort: [SortDescriptor(\Vehicle.sortOrder), SortDescriptor(\Vehicle.createdAt)])
    private var vehicles: [Vehicle]
    @AppStorage(StorageKey.selectedVehicleID) private var selectedID = ""

    @State private var showNewEntry = false
    @State private var editing: FuelRecord?

    private var vehicle: Vehicle? { Vehicle.resolve(vehicles, selectedID: selectedID) }

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
            .navigationTitle(vehicle?.fuelType.refuelLabel ?? String(localized: "給油"))
            .toolbar {
                if vehicle != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showNewEntry = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(Text("記録を追加"))
                    }
                }
            }
            .vehicleSwitcher(vehicles, selectedID: $selectedID)
            .sheet(isPresented: $showNewEntry) {
                if let vehicle { FuelEntryView(vehicle: vehicle, record: nil) }
            }
            .sheet(item: $editing) { record in
                if let vehicle { FuelEntryView(vehicle: vehicle, record: record) }
            }
        }
        .tint(Theme.accent)
    }

    private func list(_ vehicle: Vehicle) -> some View {
        let records = vehicle.sortedFuelRecords
        let entries = records.map(\.entry)
        let segments = FuelEconomy.segmentsByRecordID(for: entries)
        let unit = vehicle.fuelType.economyUnit
        let volumeUnit = vehicle.fuelType.volumeUnit

        return List {
            Section {
                HStack(spacing: 0) {
                    summary("通算", FuelEconomy.overall(for: entries).map { Formatting.economy($0, unit: unit) })
                    summary("直近", FuelEconomy.latest(for: entries).map { Formatting.economy($0.kilometersPerLiter, unit: unit) })
                    summary("平均単価", FuelEconomy.averagePricePerLiter(for: entries).map { Formatting.unitPrice($0, unit: volumeUnit) })
                }
                .padding(.vertical, 4)
            }

            Section {
                if records.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("まだ記録がありません")
                            .font(.headline)
                        Text("給油したら、日付・走行距離・給油量・金額の4つを入れるだけ。満タン給油を2回記録すると燃費が出ます。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("最初の記録を入れる") { showNewEntry = true }
                            .font(.subheadline.weight(.semibold))
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(records, id: \.id) { record in
                        Button {
                            editing = record
                        } label: {
                            row(record, segment: segments[record.id], unit: unit, volumeUnit: volumeUnit, isFirst: record.id == records.last?.id)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        for index in offsets { modelContext.delete(records[index]) }
                        try? modelContext.save()
                        let context = modelContext
                        Task { await NotificationScheduler.shared.rebuild(context: context) }
                    }
                }
            } header: {
                Text("記録")
            } footer: {
                if !records.isEmpty {
                    Text("燃費は満タン給油から次の満タン給油までの距離と、その間に入れた量から計算します（満タン法）。")
                }
            }
        }
    }

    private func summary(_ title: LocalizedStringKey, _ value: String?) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value ?? "—")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(
        _ record: FuelRecord, segment: FuelSegment?, unit: String, volumeUnit: String, isFirst: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date.formatted(.dateTime.year().month().day().weekday(.abbreviated)))
                    .font(.subheadline.weight(.semibold))
                Text("\(Formatting.kilometers(record.odometer))・\(Formatting.volume(record.liters, unit: volumeUnit))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                HStack(spacing: 6) {
                    Text(Formatting.yen(record.totalPrice))
                        .font(.caption)
                        .monospacedDigit()
                    if !record.isFullTank {
                        Text("継ぎ足し")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color(.tertiarySystemFill), in: Capsule())
                    }
                    if !record.stationName.isEmpty {
                        Text(record.stationName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 8)
            if let segment {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(Formatting.economyNumber(segment.kilometersPerLiter))
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accent)
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(isFirst && record.isFullTank ? "基準" : "—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
