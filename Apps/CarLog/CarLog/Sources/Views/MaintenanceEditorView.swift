import SwiftData
import SwiftUI

/// メンテ項目の追加・編集。期間と距離は両方設定でき、早く来るほうで知らせる。
struct MaintenanceEditorView: View {
    let vehicle: Vehicle
    let item: MaintenanceItem?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(StorageKey.notifyHour) private var defaultHour = 9
    @AppStorage(StorageKey.notifyMinute) private var defaultMinute = 0

    @State private var title: String
    @State private var symbolName: String
    @State private var usesMonths: Bool
    @State private var months: Int
    @State private var usesDistance: Bool
    @State private var distanceText: String
    @State private var hasLastDate: Bool
    @State private var lastDate: Date
    @State private var lastOdometerText: String
    @State private var isEnabled: Bool
    @State private var notifyDaysBefore: Int
    @State private var notifyTime: Date
    @State private var confirmDelete = false

    init(vehicle: Vehicle, item: MaintenanceItem?) {
        self.vehicle = vehicle
        self.item = item
        _title = State(initialValue: item?.title ?? "")
        _symbolName = State(initialValue: item?.symbolName ?? "wrench.and.screwdriver.fill")
        _usesMonths = State(initialValue: item.map { $0.intervalMonths != nil } ?? true)
        _months = State(initialValue: item?.intervalMonths ?? 12)
        _usesDistance = State(initialValue: item?.intervalDistance != nil)
        _distanceText = State(initialValue: item?.intervalDistance.map(Formatting.editable) ?? "")
        _hasLastDate = State(initialValue: item?.lastDoneDate != nil)
        _lastDate = State(initialValue: item?.lastDoneDate ?? Date())
        _lastOdometerText = State(initialValue: item?.lastDoneOdometer.map(Formatting.editable) ?? "")
        _isEnabled = State(initialValue: item?.isEnabled ?? true)
        _notifyDaysBefore = State(initialValue: item?.notifyDaysBefore ?? 7)
        let hour = item?.notifyHour ?? (UserDefaults.standard.object(forKey: StorageKey.notifyHour) as? Int ?? 9)
        let minute = item?.notifyMinute ?? (UserDefaults.standard.object(forKey: StorageKey.notifyMinute) as? Int ?? 0)
        _notifyTime = State(initialValue: Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date())
    }

    private var distance: Double? { NumberInput.double(distanceText).flatMap { $0 > 0 ? $0 : nil } }
    private var lastOdometer: Double? { NumberInput.double(lastOdometerText).flatMap { $0 >= 0 ? $0 : nil } }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && (usesMonths || usesDistance)
            && (!usesDistance || distance != nil)
    }

    /// テンプレのアイコンを選択肢として使う（重複を除く）。
    private var symbolChoices: [String] {
        var seen = Set<String>()
        return (["wrench.and.screwdriver.fill"] + MaintenanceTemplate.all.map(\.symbolName))
            .filter { seen.insert($0).inserted }
    }

    var body: some View {
        NavigationStack {
            Form {
                if item == nil {
                    Section {
                        Menu {
                            ForEach(MaintenanceTemplate.all) { template in
                                Button {
                                    apply(template)
                                } label: {
                                    Label(template.title, systemImage: template.symbolName)
                                }
                            }
                        } label: {
                            Label("テンプレートから選ぶ", systemImage: "list.bullet.rectangle")
                        }
                    }
                }

                Section("項目") {
                    TextField("例：オイル交換", text: $title)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(symbolChoices, id: \.self) { symbol in
                                Button {
                                    symbolName = symbol
                                } label: {
                                    IconTile(
                                        symbolName: symbol,
                                        color: symbol == symbolName ? Theme.accent : Color(.systemGray3),
                                        size: 36
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section {
                    Toggle("期間で管理", isOn: $usesMonths)
                    if usesMonths {
                        Stepper(value: $months, in: 1...120) {
                            Text("\(months)か月ごと").monospacedDigit()
                        }
                    }
                    Toggle("距離で管理", isOn: $usesDistance)
                    if usesDistance {
                        HStack {
                            TextField("5000", text: $distanceText)
                                .keyboardType(.numberPad)
                                .monospacedDigit()
                            Text("km ごと").foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("間隔")
                } footer: {
                    Text("両方を設定すると、先に来るほうで知らせます（例：6か月 または 5,000km）。距離は給油の記録から走るペースを出して、到達日を予測します。")
                }

                Section {
                    Toggle("前回の実施日を入力", isOn: $hasLastDate)
                    if hasLastDate {
                        DatePicker("実施日", selection: $lastDate, in: ...Date(), displayedComponents: .date)
                    }
                    if usesDistance {
                        HStack {
                            Text("そのときの走行距離")
                            Spacer()
                            TextField(Formatting.editable(vehicle.purchaseOdometer), text: $lastOdometerText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .monospacedDigit()
                            Text("km").foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("前回の実施")
                } footer: {
                    Text("未入力の場合は、初度登録年月と記録開始時の走行距離から数えます。")
                }

                Section("通知") {
                    Toggle("通知する", isOn: $isEnabled)
                    if isEnabled {
                        Stepper(value: $notifyDaysBefore, in: 0...60) {
                            Text(notifyDaysBefore == 0 ? "当日に通知" : "\(notifyDaysBefore)日前に通知")
                                .monospacedDigit()
                        }
                        DatePicker("時刻", selection: $notifyTime, displayedComponents: .hourAndMinute)
                    }
                }

                if let item, !item.history.isEmpty {
                    Section("実施履歴") {
                        ForEach(item.history.sorted { $0.date > $1.date }, id: \.id) { log in
                            HStack {
                                Text(log.date.formatted(.dateTime.year().month().day()))
                                    .font(.subheadline)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 1) {
                                    if let odometer = log.odometer {
                                        Text(Formatting.kilometers(odometer)).font(.caption)
                                    }
                                    if log.cost > 0 {
                                        Text(Formatting.yen(log.cost)).font(.caption)
                                    }
                                }
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            }
                        }
                    }
                }

                if item != nil {
                    Section {
                        Button("この項目を削除", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(item == nil ? "項目を追加" : "項目を編集")
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
            }
            .confirmationDialog("この項目を削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    if let item { modelContext.delete(item) }
                    finish()
                }
            } message: {
                Text("実施履歴も削除されます。")
            }
        }
        .tint(Theme.accent)
    }

    private func apply(_ template: MaintenanceTemplate) {
        title = template.title
        symbolName = template.symbolName
        usesMonths = template.intervalMonths != nil
        months = template.intervalMonths ?? months
        usesDistance = template.intervalDistance != nil
        distanceText = template.intervalDistance.map(Formatting.editable) ?? ""
    }

    private func save() {
        let target: MaintenanceItem
        if let item {
            target = item
        } else {
            let nextOrder = (vehicle.maintenanceItems.map(\.sortOrder).max() ?? -1) + 1
            target = MaintenanceItem(title: "", sortOrder: nextOrder)
            target.vehicle = vehicle
            modelContext.insert(target)
        }
        let time = Calendar.current.dateComponents([.hour, .minute], from: notifyTime)
        target.title = title.trimmingCharacters(in: .whitespaces)
        target.symbolName = symbolName
        target.intervalMonths = usesMonths ? months : nil
        target.intervalDistance = usesDistance ? distance : nil
        target.lastDoneDate = hasLastDate ? lastDate : nil
        target.lastDoneOdometer = usesDistance ? lastOdometer : target.lastDoneOdometer
        target.isEnabled = isEnabled
        target.notifyDaysBefore = notifyDaysBefore
        target.notifyHour = time.hour ?? defaultHour
        target.notifyMinute = time.minute ?? defaultMinute
        finish()
    }

    private func finish() {
        try? modelContext.save()
        let context = modelContext
        Task { await NotificationScheduler.shared.rebuild(context: context) }
        dismiss()
    }
}
