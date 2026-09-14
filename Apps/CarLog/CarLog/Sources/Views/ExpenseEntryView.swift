import SwiftData
import SwiftUI

/// 給油以外の費用の入力。カテゴリと金額だけで保存できる。
struct ExpenseEntryView: View {
    let vehicle: Vehicle
    let record: ExpenseRecord?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var category: ExpenseCategory
    @State private var amountText: String
    @State private var date: Date
    @State private var odometerText: String
    @State private var note: String
    @State private var confirmDelete = false
    @FocusState private var amountFocused: Bool

    init(vehicle: Vehicle, record: ExpenseRecord?) {
        self.vehicle = vehicle
        self.record = record
        _category = State(initialValue: record?.category ?? .parking)
        _amountText = State(initialValue: record.map { String($0.amount) } ?? "")
        _date = State(initialValue: record?.date ?? Date())
        _odometerText = State(initialValue: record?.odometer.map(Formatting.editable) ?? "")
        _note = State(initialValue: record?.note ?? "")
    }

    private var amount: Int? { NumberInput.int(amountText).flatMap { $0 > 0 ? $0 : nil } }

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 8)]

    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリ") {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(ExpenseCategory.selectable) { item in
                            categoryChip(item)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    HStack {
                        Text("金額")
                        Spacer()
                        TextField("0", text: $amountText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                            .focused($amountFocused)
                        Text("円").foregroundStyle(.secondary)
                    }
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                }

                Section {
                    HStack {
                        Text("走行距離")
                        Spacer()
                        TextField("任意", text: $odometerText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                        Text("km").foregroundStyle(.secondary)
                    }
                    TextField("メモ", text: $note, axis: .vertical)
                } header: {
                    Text("任意")
                }

                if record != nil {
                    Section {
                        Button("この記録を削除", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(record == nil ? "費用を記録" : "費用を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .fontWeight(.semibold)
                        .disabled(amount == nil)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { amountFocused = false; hideKeyboard() }
                }
            }
            .confirmationDialog("この記録を削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    if let record { modelContext.delete(record) }
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .tint(Theme.accent)
    }

    private func categoryChip(_ item: ExpenseCategory) -> some View {
        let isSelected = item == category
        return Button {
            category = item
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.symbolName)
                    .font(.body)
                Text(item.label)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? Color.white : Color(hex: item.colorHex))
            .background(
                isSelected ? Color(hex: item.colorHex) : Color(hex: item.colorHex).opacity(0.1),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func save() {
        guard let amount else { return }
        let odometer = NumberInput.double(odometerText).flatMap { $0 > 0 ? $0 : nil }
        if let record {
            record.category = category
            record.amount = amount
            record.date = date
            record.odometer = odometer
            record.note = note
        } else {
            let new = ExpenseRecord(date: date, category: category, amount: amount, odometer: odometer, note: note)
            new.vehicle = vehicle
            modelContext.insert(new)
        }
        try? modelContext.save()
        if odometer != nil {
            // 走行距離が進むと距離ベースのメンテ予定も動く。
            let context = modelContext
            Task { await NotificationScheduler.shared.rebuild(context: context) }
        }
        dismiss()
    }
}
