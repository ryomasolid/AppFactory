import SwiftData
import SwiftUI

/// クルマの追加・編集。必須は名前だけ。
struct VehicleEditorView: View {
    let vehicle: Vehicle?
    var onCreate: ((Vehicle) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]

    @State private var name: String
    @State private var makerModel: String
    @State private var fuelType: FuelType
    @State private var colorHex: String
    @State private var symbolName: String
    @State private var tankText: String
    @State private var odometerText: String
    @State private var hasRegistration: Bool
    @State private var registrationDate: Date
    @State private var confirmDelete = false

    init(vehicle: Vehicle?, onCreate: ((Vehicle) -> Void)? = nil) {
        self.vehicle = vehicle
        self.onCreate = onCreate
        _name = State(initialValue: vehicle?.name ?? "")
        _makerModel = State(initialValue: vehicle?.makerModel ?? "")
        _fuelType = State(initialValue: vehicle?.fuelType ?? .regular)
        _colorHex = State(initialValue: vehicle?.colorHex ?? VehiclePalette.colors[0])
        _symbolName = State(initialValue: vehicle?.symbolName ?? VehiclePalette.symbols[0])
        _tankText = State(initialValue: vehicle?.tankCapacity.map(Formatting.editable) ?? "")
        _odometerText = State(initialValue: vehicle.map { Formatting.editable($0.purchaseOdometer) } ?? "")
        _hasRegistration = State(initialValue: vehicle?.firstRegistrationDate != nil)
        _registrationDate = State(initialValue: vehicle?.firstRegistrationDate ?? Date())
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名前（例：プリウス、通勤用）", text: $name)
                    TextField("メーカー・車種（任意）", text: $makerModel)
                    Picker("燃料", selection: $fuelType) {
                        ForEach(FuelType.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section("見た目") {
                    paletteRow(VehiclePalette.colors) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if hex == colorHex {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture { colorHex = hex }
                    }
                    paletteRow(VehiclePalette.symbols) { symbol in
                        IconTile(
                            symbolName: symbol,
                            color: symbol == symbolName ? Color(hex: colorHex) : Color(.systemGray3),
                            size: 36
                        )
                        .onTapGesture { symbolName = symbol }
                    }
                }

                Section {
                    HStack {
                        Text("記録開始時の走行距離")
                        Spacer()
                        TextField("0", text: $odometerText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                        Text("km").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("タンク容量")
                        Spacer()
                        TextField("任意", text: $tankText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                        Text(fuelType.volumeUnit).foregroundStyle(.secondary)
                    }
                    Toggle("初度登録年月を入力", isOn: $hasRegistration)
                    if hasRegistration {
                        DatePicker("初度登録", selection: $registrationDate, in: ...Date(), displayedComponents: .date)
                    }
                } header: {
                    Text("詳細（任意）")
                } footer: {
                    Text("タンク容量は給油量の打ち間違いの検知に、初度登録年月は前回の実施日が未入力のメンテ項目（車検など）の起算に使います。")
                }

                if vehicle != nil {
                    Section {
                        Button("このクルマを削除", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(vehicle == nil ? "クルマを追加" : "クルマを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .fontWeight(.semibold)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .confirmationDialog("このクルマを削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    if let vehicle { modelContext.delete(vehicle) }
                    finish()
                }
            } message: {
                Text("給油・費用・メンテの記録もすべて削除されます。")
            }
        }
        .tint(Theme.accent)
    }

    private func paletteRow<Content: View>(
        _ values: [String], @ViewBuilder content: @escaping (String) -> Content
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(values, id: \.self) { content($0) }
            }
            .padding(.vertical, 2)
        }
    }

    private func save() {
        let target: Vehicle
        if let vehicle {
            target = vehicle
        } else {
            target = Vehicle(name: trimmedName, isDefault: vehicles.isEmpty, sortOrder: (vehicles.map(\.sortOrder).max() ?? -1) + 1)
            modelContext.insert(target)
        }
        target.name = trimmedName
        target.makerModel = makerModel.trimmingCharacters(in: .whitespacesAndNewlines)
        target.fuelType = fuelType
        target.colorHex = colorHex
        target.symbolName = symbolName
        target.tankCapacity = NumberInput.double(tankText).flatMap { $0 > 0 ? $0 : nil }
        target.purchaseOdometer = NumberInput.double(odometerText).map { max(0, $0) } ?? 0
        target.firstRegistrationDate = hasRegistration ? registrationDate : nil
        if vehicle == nil { onCreate?(target) }
        finish()
    }

    private func finish() {
        try? modelContext.save()
        let context = modelContext
        Task { await NotificationScheduler.shared.rebuild(context: context) }
        dismiss()
    }
}
