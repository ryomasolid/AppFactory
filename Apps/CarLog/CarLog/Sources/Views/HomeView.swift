import SwiftData
import SwiftUI

/// ホーム。「燃費はどうか・今月いくら使ったか・近いメンテはあるか」と、
/// このアプリで一番押される「給油を記録」ボタンだけを置く。
struct HomeView: View {
    let onShowMaintenance: () -> Void

    @Environment(StoreManager.self) private var store
    @Query(sort: [SortDescriptor(\Vehicle.sortOrder), SortDescriptor(\Vehicle.createdAt)])
    private var vehicles: [Vehicle]
    @AppStorage(StorageKey.selectedVehicleID) private var selectedID = ""

    @State private var showFuelEntry = false

    private var vehicle: Vehicle? { Vehicle.resolve(vehicles, selectedID: selectedID) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let vehicle {
                    content(vehicle)
                } else {
                    NoVehicleView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(vehicle?.name ?? String(localized: "カーログ"))
            .vehicleSwitcher(vehicles, selectedID: $selectedID)
            .sheet(isPresented: $showFuelEntry) {
                if let vehicle {
                    FuelEntryView(vehicle: vehicle, record: nil)
                }
            }
        }
        .tint(Theme.accent)
    }

    private func content(_ vehicle: Vehicle) -> some View {
        let fuel = vehicle.fuelEntries
        let expenses = vehicle.expenseEntries
        let earliest = (fuel.map(\.date) + expenses.map(\.date)).min()

        return VStack(alignment: .leading, spacing: 18) {
            economyCard(vehicle, fuel: fuel)

            HStack(spacing: 12) {
                let month = CostSummary.breakdown(
                    fuel: fuel, expenses: expenses, in: CostPeriod.month.interval()
                )
                let all = CostSummary.breakdown(
                    fuel: fuel, expenses: expenses, in: CostPeriod.all.interval(earliest: earliest)
                )
                statCard("今月の出費", value: Formatting.yen(month.total), caption: month.isEmpty ? String(localized: "記録なし") : nil)
                statCard(
                    "1kmあたり",
                    value: all.costPerKilometer.map { Formatting.yen($0) } ?? "—",
                    caption: all.costPerKilometer == nil ? String(localized: "給油2回で出ます") : String(localized: "全期間")
                )
            }

            maintenanceSection(vehicle)

            Button {
                showFuelEntry = true
            } label: {
                PrimaryButtonLabel(
                    title: String(localized: "\(vehicle.fuelType.refuelLabel)を記録"),
                    systemImage: vehicle.fuelType == .electric ? "bolt.fill" : "fuelpump.fill"
                )
            }
            .buttonStyle(.plain)

            if let last = vehicle.sortedFuelRecords.first {
                Text("前回の\(vehicle.fuelType.refuelLabel)　\(last.date.formatted(.dateTime.month().day()))・\(Formatting.kilometers(last.odometer))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 28)
    }

    // MARK: - 燃費

    private func economyCard(_ vehicle: Vehicle, fuel: [FuelEntry]) -> some View {
        let unit = vehicle.fuelType.economyUnit
        let overall = FuelEconomy.overall(for: fuel)
        let latest = FuelEconomy.latest(for: fuel)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(vehicle.fuelType == .electric ? "平均電費" : "平均燃費")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(vehicle.fuelType.label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.2), in: Capsule())
            }

            if let overall {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(Formatting.economyNumber(overall))
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(unit)
                        .font(.title3.weight(.semibold))
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("—")
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                    Text(fuel.isEmpty ? "満タンで給油したら記録しましょう" : "次の満タン給油で燃費が出ます")
                        .font(.subheadline)
                        .opacity(0.9)
                }
            }

            HStack(spacing: 0) {
                heroStat(
                    "直近",
                    latest.map { Formatting.economy($0.kilometersPerLiter, unit: unit) } ?? "—"
                )
                Rectangle().fill(.white.opacity(0.3)).frame(width: 1, height: 30)
                heroStat("走行距離計", Formatting.kilometers(vehicle.currentOdometer))
                    .padding(.leading, 16)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Theme.accent, Theme.accent.opacity(0.78)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func heroStat(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).opacity(0.85)
            Text(value).font(.headline).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statCard(_ title: LocalizedStringKey, value: String, caption: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption ?? " ")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .card(padding: 16)
    }

    // MARK: - メンテ

    private func maintenanceSection(_ vehicle: Vehicle) -> some View {
        let statuses = vehicle.maintenanceStatuses()
        let urgent = vehicle.maintenanceItems
            .compactMap { item -> (MaintenanceItem, MaintenanceStatus)? in
                guard let status = statuses[item.id], status.state != .ok else { return nil }
                return (item, status)
            }
            .sorted { lhs, rhs in
                // 期限切れを先に、その中では残り日数の少ない順。
                if lhs.1.state != rhs.1.state { return lhs.1.state == .overdue }
                return (lhs.1.remainingDays ?? .max) < (rhs.1.remainingDays ?? .max)
            }
            .prefix(3)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle("期限が近いメンテ")
                Spacer()
                Button("すべて見る", action: onShowMaintenance)
                    .font(.subheadline)
            }

            VStack(spacing: 0) {
                if urgent.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.accent)
                        Text(vehicle.maintenanceItems.isEmpty ? "メンテ項目が未登録です" : "近いメンテはありません")
                            .font(.subheadline)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 14)
                } else {
                    ForEach(Array(urgent.enumerated()), id: \.element.0.id) { index, pair in
                        let (item, status) = pair
                        HStack(spacing: 12) {
                            IconTile(symbolName: item.symbolName, color: status.state.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.subheadline.weight(.semibold))
                                Text(MaintenanceText.next(status))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            DueBadge(state: status.state)
                        }
                        .padding(.vertical, 12)
                        if index < urgent.count - 1 {
                            Divider().padding(.leading, 46)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
    }
}
