import SwiftData
import SwiftUI

/// メンテの実施を記録する。次回予定の起点が更新され、通知も組み直される。
struct MaintenanceDoneView: View {
    let vehicle: Vehicle
    let item: MaintenanceItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var date = Date()
    @State private var odometerText: String
    @State private var costText = ""
    @State private var note = ""
    /// 実施費用を「費用」タブの集計にも入れるか。二重に数えないよう、入れるのはここだけ。
    @State private var addToExpenses = true

    init(vehicle: Vehicle, item: MaintenanceItem) {
        self.vehicle = vehicle
        self.item = item
        _odometerText = State(initialValue: Formatting.editable(vehicle.currentOdometer))
    }

    private var cost: Int { NumberInput.int(costText).map { max(0, $0) } ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        IconTile(symbolName: item.symbolName, color: Theme.accent, size: 38)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.headline)
                            Text(Formatting.interval(months: item.intervalMonths, distance: item.intervalDistance))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    DatePicker("実施日", selection: $date, in: ...Date(), displayedComponents: .date)
                    HStack {
                        Text("走行距離")
                        Spacer()
                        TextField("任意", text: $odometerText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                        Text("km").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("費用")
                        Spacer()
                        TextField("0", text: $costText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                        Text("円").foregroundStyle(.secondary)
                    }
                    TextField("メモ", text: $note, axis: .vertical)
                } footer: {
                    if let next = nextPreview {
                        Text("次回は\(next)の予定になります。")
                    }
                }

                if cost > 0 {
                    Section {
                        Toggle("費用にも記録する", isOn: $addToExpenses)
                    } footer: {
                        Text("「\(item.expenseCategory.label)」として費用の集計に入ります。")
                    }
                }
            }
            .navigationTitle("実施を記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("記録", action: save).fontWeight(.semibold)
                }
            }
        }
        .tint(Theme.accent)
    }

    private var odometer: Double? { NumberInput.double(odometerText).flatMap { $0 > 0 ? $0 : nil } }

    /// 保存後の次回予定のプレビュー。
    private var nextPreview: String? {
        var plan = item.plan
        plan.lastDoneDate = date
        if let odometer { plan.lastDoneOdometer = odometer }
        let status = MaintenanceDue.evaluate(
            plan: plan,
            currentOdometer: max(vehicle.currentOdometer, odometer ?? 0),
            pace: vehicle.pace,
            fallbackDate: vehicle.firstRegistrationDate,
            fallbackOdometer: vehicle.purchaseOdometer
        )
        var parts: [String] = []
        if let dueDate = status.dueDate {
            parts.append(dueDate.formatted(.dateTime.year().month().day()))
        }
        if let dueOdometer = status.dueOdometer {
            parts.append(Formatting.kilometers(dueOdometer))
        }
        return parts.isEmpty ? nil : parts.joined(separator: String(localized: " または "))
    }

    private func save() {
        let log = item.markDone(date: date, odometer: odometer, cost: cost, note: note)
        modelContext.insert(log)
        if addToExpenses, cost > 0 {
            let expense = ExpenseRecord(
                date: date, category: item.expenseCategory, amount: cost,
                odometer: odometer, note: note.isEmpty ? item.title : "\(item.title)・\(note)"
            )
            expense.vehicle = vehicle
            modelContext.insert(expense)
        }
        try? modelContext.save()
        let context = modelContext
        Task { await NotificationScheduler.shared.rebuild(context: context) }
        dismiss()
    }
}
