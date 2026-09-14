import Charts
import SwiftData
import SwiftUI

/// 費用。期間ごとの総額・内訳・月別推移と、給油以外の費用の記録一覧。
///
/// ガソリン代は給油記録から自動で「ガソリン代」として合成する（二重入力させない）。
struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Query(sort: [SortDescriptor(\Vehicle.sortOrder), SortDescriptor(\Vehicle.createdAt)])
    private var vehicles: [Vehicle]
    @AppStorage(StorageKey.selectedVehicleID) private var selectedID = ""

    @State private var period: CostPeriod = .year
    @State private var showNewEntry = false
    @State private var editing: ExpenseRecord?

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
            .navigationTitle("費用")
            .toolbar {
                if vehicle != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showNewEntry = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(Text("費用を追加"))
                    }
                }
            }
            .vehicleSwitcher(vehicles, selectedID: $selectedID)
            .sheet(isPresented: $showNewEntry) {
                if let vehicle { ExpenseEntryView(vehicle: vehicle, record: nil) }
            }
            .sheet(item: $editing) { record in
                if let vehicle { ExpenseEntryView(vehicle: vehicle, record: record) }
            }
        }
        .tint(Theme.accent)
    }

    private func list(_ vehicle: Vehicle) -> some View {
        let fuel = vehicle.fuelEntries
        let expenses = vehicle.expenseEntries
        let earliest = (fuel.map(\.date) + expenses.map(\.date)).min()
        let interval = period.interval(earliest: earliest)
        let breakdown = CostSummary.breakdown(fuel: fuel, expenses: expenses, in: interval)
        let records = vehicle.expenses
            .filter { interval.contains(Calendar.current.startOfDay(for: $0.date)) }
            .sorted { $0.date > $1.date }

        return List {
            Section {
                Picker("期間", selection: $period) {
                    ForEach(CostPeriod.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Formatting.yen(breakdown.total))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    HStack(spacing: 0) {
                        stat("月平均", Formatting.yen(breakdown.monthlyAverage))
                        stat("1kmあたり", breakdown.costPerKilometer.map { Formatting.yen($0) } ?? "—")
                        stat("走行", breakdown.distance > 0 ? Formatting.kilometers(breakdown.distance) : "—")
                    }
                }
                .padding(.vertical, 6)
            }

            if !breakdown.isEmpty {
                Section("内訳") {
                    categoryChart(breakdown.categories, total: breakdown.total)
                        .padding(.vertical, 8)
                }
            }

            Section("月別の推移（直近12か月）") {
                monthlyChart(fuel: fuel, expenses: expenses)
                    .frame(height: 180)
                    .padding(.vertical, 8)
            }

            Section {
                if records.isEmpty {
                    Text("この期間の費用の記録はありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(records, id: \.id) { record in
                        Button {
                            editing = record
                        } label: {
                            row(record)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        for index in offsets { modelContext.delete(records[index]) }
                        try? modelContext.save()
                    }
                }
            } header: {
                Text("費用の記録")
            } footer: {
                Text("ガソリン代は給油の記録から自動で集計します。1kmあたりは、期間内の総額を期間内に走った距離で割った値です。")
            }
        }
    }

    private func stat(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categoryChart(_ categories: [CategoryTotal], total: Int) -> some View {
        VStack(spacing: 12) {
            ForEach(categories) { item in
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Image(systemName: item.category.symbolName)
                            .font(.caption)
                            .foregroundStyle(Color(hex: item.category.colorHex))
                            .frame(width: 18)
                        Text(item.category.label)
                            .font(.subheadline)
                        Spacer()
                        Text(Formatting.yen(item.amount))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                        Text(percent(item.amount, of: total))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: 38, alignment: .trailing)
                    }
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Color(hex: item.category.colorHex))
                            .frame(width: max(4, proxy.size.width * CGFloat(item.amount) / CGFloat(max(total, 1))))
                    }
                    .frame(height: 6)
                }
            }
        }
    }

    private func percent(_ amount: Int, of total: Int) -> String {
        guard total > 0 else { return "" }
        return (Double(amount) / Double(total)).formatted(.percent.precision(.fractionLength(0)))
    }

    private func monthlyChart(fuel: [FuelEntry], expenses: [ExpenseEntry]) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        let start = calendar.date(byAdding: .month, value: -11, to: thisMonth) ?? thisMonth
        let totals = CostSummary.monthlyTotals(
            fuel: fuel, expenses: expenses, in: DateInterval(start: start, end: today)
        )

        return Chart(totals) { item in
            BarMark(
                x: .value("月", item.month, unit: .month),
                y: .value("金額", item.amount)
            )
            .foregroundStyle(Theme.accent.gradient)
            .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                AxisValueLabel(format: .dateTime.month(.defaultDigits), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Int.self) {
                        Text(compactYen(amount))
                    }
                }
            }
        }
    }

    /// 軸ラベル用の短い金額（"12万" / "8,000"）。
    private func compactYen(_ amount: Int) -> String {
        amount >= 10000
            ? String(localized: "\((Double(amount) / 10000).formatted(.number.precision(.fractionLength(0...1))))万")
            : amount.formatted()
    }

    private func row(_ record: ExpenseRecord) -> some View {
        HStack(spacing: 12) {
            IconTile(symbolName: record.category.symbolName, color: Color(hex: record.category.colorHex), size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.category.label)
                    .font(.subheadline.weight(.semibold))
                Text(record.note.isEmpty
                     ? record.date.formatted(.dateTime.month().day())
                     : "\(record.date.formatted(.dateTime.month().day()))・\(record.note)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(Formatting.yen(record.amount))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .contentShape(Rectangle())
    }
}
