import SwiftData
import SwiftUI

/// 給油の入力。必須は日付・走行距離・給油量・金額の4つだけ。
///
/// 打ち間違いは燃費を壊すので、前回より小さい走行距離やタンク容量超えは警告する。
/// ただし保存は止めない（メーター交換などの正当な理由がありうるため）。
struct FuelEntryView: View {
    let vehicle: Vehicle
    let record: FuelRecord?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var date: Date
    @State private var odometerText: String
    @State private var litersText: String
    @State private var priceText: String
    @State private var isFullTank: Bool
    @State private var stationName: String
    @State private var note: String
    @State private var confirmDelete = false
    @FocusState private var focused: Field?

    private enum Field: Hashable {
        case odometer, liters, price, station, note
    }

    init(vehicle: Vehicle, record: FuelRecord?) {
        self.vehicle = vehicle
        self.record = record
        _date = State(initialValue: record?.date ?? Date())
        _odometerText = State(initialValue: record.map { Formatting.editable($0.odometer) } ?? "")
        _litersText = State(initialValue: record.map { Formatting.editable($0.liters) } ?? "")
        _priceText = State(initialValue: record.map { String($0.totalPrice) } ?? "")
        _isFullTank = State(initialValue: record?.isFullTank ?? true)
        _stationName = State(initialValue: record?.stationName ?? "")
        _note = State(initialValue: record?.note ?? "")
    }

    private var odometer: Double? { NumberInput.double(odometerText).flatMap { $0 > 0 ? $0 : nil } }
    private var liters: Double? { NumberInput.double(litersText).flatMap { $0 > 0 ? $0 : nil } }
    private var price: Int? { NumberInput.int(priceText).flatMap { $0 > 0 ? $0 : nil } }
    private var canSave: Bool { odometer != nil && liters != nil && price != nil }

    /// 比較対象の「前回」。この記録より前の日付の記録のうち最大の走行距離。
    private var previousOdometer: Double? {
        let others = vehicle.fuelRecords.filter { $0.id != record?.id && $0.date <= date }
        return others.map(\.odometer).max()
    }

    private var unit: String { vehicle.fuelType.volumeUnit }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("日付", selection: $date, in: ...Date().addingTimeInterval(86400), displayedComponents: .date)
                    numberField("走行距離", text: $odometerText, unit: "km", field: .odometer, keyboard: .numberPad,
                                placeholder: previousOdometer.map(Formatting.editable) ?? "48000")
                    numberField("\(vehicle.fuelType.refuelLabel)量", text: $litersText, unit: unit, field: .liters, keyboard: .decimalPad, placeholder: "32.5")
                    numberField("金額", text: $priceText, unit: "円", field: .price, keyboard: .numberPad, placeholder: "5600")
                    Toggle("満タン", isOn: $isFullTank)
                } footer: {
                    Text(isFullTank
                         ? "満タンにしたときの記録から燃費を計算します。"
                         : "継ぎ足しの量は、次に満タンにしたときの燃費にまとめて反映されます。")
                }

                if !previewLines.isEmpty || !warnings.isEmpty {
                    Section {
                        ForEach(previewLines, id: \.self) { line in
                            Label(line, systemImage: "arrow.forward.circle")
                                .font(.subheadline)
                        }
                        ForEach(warnings, id: \.self) { warning in
                            Label(warning, systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "#C4622D"))
                        }
                    }
                }

                Section("任意") {
                    TextField("スタンド名", text: $stationName)
                        .focused($focused, equals: .station)
                    TextField("メモ", text: $note, axis: .vertical)
                        .focused($focused, equals: .note)
                }

                if record != nil {
                    Section {
                        Button("この記録を削除", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(record == nil ? "\(vehicle.fuelType.refuelLabel)を記録" : "記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { focused = nil }
                }
            }
            .confirmationDialog("この記録を削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("削除", role: .destructive, action: delete)
            }
            .onAppear {
                // 新規のときは走行距離から打てるようにする（入力の手数を1つ減らす）。
                if record == nil, !Launch.showFuelEntry { focused = .odometer }
            }
        }
        .tint(Theme.accent)
    }

    private func numberField(
        _ title: String, text: Binding<String>, unit: String, field: Field,
        keyboard: UIKeyboardType, placeholder: String
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .focused($focused, equals: field)
                .frame(maxWidth: 160)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(minWidth: 28, alignment: .leading)
        }
    }

    /// 入力中に即時で出す計算結果。
    private var previewLines: [String] {
        var lines: [String] = []
        if let odometer, let previous = previousOdometer, odometer > previous {
            lines.append(String(localized: "前回から +\(Formatting.kilometers(odometer - previous))"))
        }
        if let liters, let price {
            lines.append(String(localized: "単価 \(Formatting.unitPrice(Double(price) / liters, unit: unit))"))
        }
        return lines
    }

    private var warnings: [String] {
        var result: [String] = []
        if let odometer, let previous = previousOdometer, odometer <= previous {
            result.append(String(localized: "前回（\(Formatting.kilometers(previous))）以下の走行距離です。打ち間違いがないか確認してください。"))
        }
        if let liters, let tank = vehicle.tankCapacity, tank > 0, liters > tank * 1.05 {
            result.append(String(localized: "タンク容量（\(Formatting.volume(tank, unit: unit))）を超えています。"))
        }
        return result
    }

    private func save() {
        guard let odometer, let liters, let price else { return }
        if let record {
            record.date = date
            record.odometer = odometer
            record.liters = liters
            record.totalPrice = price
            record.isFullTank = isFullTank
            record.stationName = stationName.trimmingCharacters(in: .whitespacesAndNewlines)
            record.note = note
        } else {
            let new = FuelRecord(
                date: date, odometer: odometer, liters: liters, totalPrice: price,
                isFullTank: isFullTank,
                stationName: stationName.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note
            )
            new.vehicle = vehicle
            modelContext.insert(new)
        }
        finish()
    }

    private func delete() {
        if let record { modelContext.delete(record) }
        finish()
    }

    private func finish() {
        try? modelContext.save()
        // 走行距離が変わると距離ベースのメンテ予定日も動くので、通知を組み直す。
        let context = modelContext
        Task { await NotificationScheduler.shared.rebuild(context: context) }
        dismiss()
    }
}
