import SwiftData
import SwiftUI
import UIKit

/// 設定。クルマの管理・通知・CSV書き出し・Pro。
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Environment(\.openURL) private var openURL
    @Query(sort: [SortDescriptor(\Vehicle.sortOrder), SortDescriptor(\Vehicle.createdAt)])
    private var vehicles: [Vehicle]
    @AppStorage(StorageKey.selectedVehicleID) private var selectedID = ""
    @AppStorage(StorageKey.notifyHour) private var notifyHour = 9
    @AppStorage(StorageKey.notifyMinute) private var notifyMinute = 0

    @State private var editingVehicle: Vehicle?
    @State private var showNewVehicle = false
    @State private var showPaywall = false
    @State private var authorizationDenied = false
    @State private var scheduledCount: Int?
    @State private var exportFile: ExportFile?

    private struct ExportFile: Identifiable {
        let url: URL
        var id: URL { url }
    }

    var body: some View {
        NavigationStack {
            Form {
                vehicleSection
                notificationSection
                statusSection
                dataSection
                proSection
                aboutSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingVehicle) { VehicleEditorView(vehicle: $0) }
            .sheet(isPresented: $showNewVehicle) {
                VehicleEditorView(vehicle: nil) { selectedID = $0.id.uuidString }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environment(store)
            }
            .sheet(item: $exportFile) { file in
                ActivityView(items: [file.url])
                    .presentationDetents([.medium, .large])
            }
            .task { await refreshStatus() }
        }
        .tint(Theme.accent)
    }

    // MARK: - クルマ

    private var vehicleSection: some View {
        Section {
            ForEach(vehicles, id: \.id) { vehicle in
                Button {
                    editingVehicle = vehicle
                } label: {
                    HStack(spacing: 12) {
                        IconTile(symbolName: vehicle.symbolName, color: Color(hex: vehicle.colorHex), size: 32)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(vehicle.name).foregroundStyle(.primary)
                            Text([vehicle.makerModel, vehicle.fuelType.label].filter { !$0.isEmpty }.joined(separator: "・"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Button {
                if ProLimits.canAddVehicle(currentCount: vehicles.count, isPro: store.isPro) {
                    showNewVehicle = true
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label("クルマを追加", systemImage: "plus")
                    Spacer()
                    if !ProLimits.canAddVehicle(currentCount: vehicles.count, isPro: store.isPro) {
                        proBadge
                    }
                }
            }
        } header: {
            Text("クルマ")
        }
    }

    // MARK: - 通知

    private var notificationSection: some View {
        Section {
            DatePicker("通知の時刻", selection: notifyTimeBinding, displayedComponents: .hourAndMinute)
            Button("すべての項目をこの時刻にする") {
                for item in vehicles.flatMap(\.maintenanceItems) {
                    item.notifyHour = notifyHour
                    item.notifyMinute = notifyMinute
                }
                try? modelContext.save()
                Task { await rebuild(requestingAuthorization: false) }
            }
            .disabled(vehicles.allSatisfy { $0.maintenanceItems.isEmpty })
        } header: {
            Text("通知")
        } footer: {
            Text("新しく追加するメンテ項目の通知時刻です。何日前に知らせるかは項目ごとに変えられます。")
        }
    }

    private var notifyTimeBinding: Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: notifyHour, minute: notifyMinute, second: 0, of: Date()) ?? Date() },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                notifyHour = components.hour ?? 9
                notifyMinute = components.minute ?? 0
            }
        )
    }

    private var statusSection: some View {
        Section {
            LabeledContent("通知の許可", value: authorizationDenied ? String(localized: "オフ") : (scheduledCount == nil ? String(localized: "未確認") : String(localized: "オン")))
            if let scheduledCount {
                LabeledContent("予約済みの通知", value: String(localized: "\(scheduledCount)件"))
            }
            if authorizationDenied {
                Button("設定アプリで通知を許可する") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
            Button("通知を作り直す") {
                Task { await rebuild(requestingAuthorization: true) }
            }
        } header: {
            Text("通知が届かないときは")
        } footer: {
            Text("予定日が過ぎた項目は通知せず、メンテ画面に「期限切れ」と表示します。")
        }
    }

    // MARK: - データ

    private var dataSection: some View {
        Section {
            Button {
                if ProLimits.canExportCSV(isPro: store.isPro) {
                    export()
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label("CSVで書き出す", systemImage: "square.and.arrow.up")
                    Spacer()
                    if !store.isPro { proBadge }
                }
            }
            .disabled(vehicles.isEmpty)
        } header: {
            Text("データ")
        } footer: {
            Text("給油・費用・メンテの実施記録を1つのCSVにまとめます。記録はすべてこの端末の中だけに保存されています。")
        }
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Label(
                        store.isPro ? "Pro を利用中" : "Pro（クルマ・メンテ無制限・広告なし）",
                        systemImage: store.isPro ? "checkmark.seal.fill" : "crown.fill"
                    )
                    Spacer()
                    if !store.isPro {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            if !store.isPro {
                Button("購入を復元") {
                    Task { await store.restore() }
                }
            }
        }
    }

    // MARK: - このアプリについて

    private var aboutSection: some View {
        Section {
            Button("お問い合わせ") {
                if let url = URL(string: "mailto:oga.sesame.tech@gmail.com") { openURL(url) }
            }
            LabeledContent("バージョン", value: Self.versionText)
        } header: {
            Text("このアプリについて")
        } footer: {
            Text("メンテナンスの間隔は一般的な目安です。実際の時期は取扱説明書や整備工場の指示に従ってください。")
        }
    }

    private var proBadge: some View {
        Label("Pro", systemImage: "crown.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.accent)
    }

    private static var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - 処理

    private func refreshStatus() async {
        authorizationDenied = await NotificationScheduler.shared.isDenied()
        scheduledCount = await NotificationScheduler.shared.isAuthorized()
            ? await NotificationScheduler.shared.pendingCount()
            : nil
    }

    private func rebuild(requestingAuthorization: Bool) async {
        await NotificationScheduler.shared.rebuild(
            context: modelContext, requestingAuthorization: requestingAuthorization
        )
        await refreshStatus()
    }

    private func export() {
        let rows = vehicles.flatMap(\.csvRows)
        let stamp = Date().formatted(.iso8601.year().month().day().dateSeparator(.omitted))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CarLog-\(stamp).csv")
        do {
            try CSVExport.data(rows: rows).write(to: url, options: .atomic)
            exportFile = ExportFile(url: url)
        } catch {
            exportFile = nil
        }
    }
}

/// 共有シート（CSV の保存先を選ぶ）。
private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
