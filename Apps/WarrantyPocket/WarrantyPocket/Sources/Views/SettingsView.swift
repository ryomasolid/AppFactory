import SwiftData
import SwiftUI
import UIKit

/// 設定。通知・手放した商品・書き出し・Pro。
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Environment(\.openURL) private var openURL
    @Query(sort: \Item.purchaseDate) private var items: [Item]

    @AppStorage(StorageKey.notificationTiming) private var timingRaw = NotificationTiming.thirtyAndSeven.rawValue
    @AppStorage(StorageKey.notifyHour) private var notifyHour = 9
    @AppStorage(StorageKey.notifyMinute) private var notifyMinute = 0

    @State private var showPaywall = false
    @State private var authorizationDenied = false
    @State private var scheduledCount: Int?
    @State private var exportFile: ExportFile?
    @State private var isExporting = false

    private struct ExportFile: Identifiable {
        let url: URL
        var id: URL { url }
    }

    static let privacyPolicyURL = URL(string: "https://ryomasolid.github.io/privacy-warrantypocket.html")

    private var archivedCount: Int { items.filter(\.isArchived).count }

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                statusSection
                archiveSection
                dataSection
                proSection
                aboutSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Item.self) { ItemDetailView(item: $0) }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environment(store)
            }
            .sheet(item: $exportFile) { file in
                ActivityView(items: [file.url])
                    .presentationDetents([.medium, .large])
            }
            .overlay {
                if isExporting { ProgressView().controlSize(.large) }
            }
            .task { await refreshStatus() }
            .onChange(of: timingRaw) { Task { await rebuild(requestingAuthorization: false) } }
            .onChange(of: notifyHour) { Task { await rebuild(requestingAuthorization: false) } }
            .onChange(of: notifyMinute) { Task { await rebuild(requestingAuthorization: false) } }
        }
        .tint(Theme.accent)
    }

    // MARK: - 通知

    private var notificationSection: some View {
        Section {
            Picker("お知らせするタイミング", selection: $timingRaw) {
                ForEach(NotificationTiming.allCases) { timing in
                    Text(timing.label).tag(timing.rawValue)
                }
            }
            if timingRaw != NotificationTiming.off.rawValue {
                DatePicker("時刻", selection: notifyTimeBinding, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("保証終了のお知らせ")
        } footer: {
            Text("メーカー保証と延長保証のそれぞれについて、最終日の何日前に知らせるかを選べます。")
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
            LabeledContent(
                "通知の許可",
                value: authorizationDenied
                    ? String(localized: "オフ")
                    : (scheduledCount == nil ? String(localized: "未確認") : String(localized: "オン"))
            )
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
            Text("通知は近いものから\(NotificationPlanner.budget)件まで予約し、アプリを開くたびに作り直します。")
        }
    }

    // MARK: - 手放した商品

    private var archiveSection: some View {
        Section {
            NavigationLink {
                ArchivedItemsView()
            } label: {
                LabeledContent("手放した商品", value: String(localized: "\(archivedCount)件"))
            }
        } footer: {
            Text("手放した商品は一覧と通知から外れますが、写真と記録は残ります。")
        }
    }

    // MARK: - データ

    private var dataSection: some View {
        Section {
            exportButton(title: "PDFで書き出す", systemImage: "doc.richtext") { exportPDF() }
            exportButton(title: "CSVで書き出す", systemImage: "tablecells") { exportCSV() }
        } header: {
            Text("書き出し")
        } footer: {
            Text("引越しや火災保険の請求、家族への共有に。PDFには保証書とレシートの写真も入ります。記録はすべてこの端末の中だけに保存されています。")
        }
    }

    private func exportButton(title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            if ProLimits.canExport(isPro: store.isPro) {
                action()
            } else {
                showPaywall = true
            }
        } label: {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                if !store.isPro { ProBadge() }
            }
        }
        .disabled(items.isEmpty || isExporting)
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Label(
                        store.isPro ? "Pro を利用中" : "Pro（登録無制限・書き出し・広告なし）",
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
            if let url = Self.privacyPolicyURL {
                Button("プライバシーポリシー") { openURL(url) }
            }
            LabeledContent("バージョン", value: Self.versionText)
        } header: {
            Text("このアプリについて")
        } footer: {
            Text("保証の期間・対象・条件は、保証書やお店の規約の記載をご確認ください。本アプリの表示は登録された購入日と期間からの目安です。")
        }
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

    private static var fileStamp: String {
        Date().formatted(.iso8601.year().month().day().dateSeparator(.omitted))
    }

    private func exportCSV() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("WarrantyPocket-\(Self.fileStamp).csv")
        do {
            try CSVExport.data(rows: items.map(\.exportRow)).write(to: url, options: .atomic)
            exportFile = ExportFile(url: url)
        } catch {
            exportFile = nil
        }
    }

    private func exportPDF() {
        isExporting = true
        let entries = items.map { item in
            PDFEntry(
                row: item.exportRow,
                images: item.sortedAttachments.compactMap { attachment in
                    (attachment.imageData ?? attachment.thumbnailData).map { (attachment.kind.label, $0) }
                }
            )
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("WarrantyPocket-\(Self.fileStamp).pdf")
        Task {
            // 描画を始める前にインジケータを出す。
            try? await Task.sleep(for: .milliseconds(50))
            let data = PDFExport.make(entries: entries)
            do {
                try data.write(to: url, options: .atomic)
                exportFile = ExportFile(url: url)
            } catch {
                exportFile = nil
            }
            isExporting = false
        }
    }
}

/// 手放した商品の一覧。スワイプで一覧に戻せる。
struct ArchivedItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Item> { $0.isArchived == true }, sort: \Item.purchaseDate, order: .reverse)
    private var items: [Item]

    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        item.isArchived = false
                        try? modelContext.save()
                        let context = modelContext
                        Task { await NotificationScheduler.shared.rebuild(context: context) }
                    } label: {
                        Label("一覧に戻す", systemImage: "arrow.uturn.backward")
                    }
                    .tint(Theme.accent)
                }
            }
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(
                    "手放した商品はありません",
                    systemImage: "archivebox",
                    description: Text("詳細画面の「手放した」で、一覧と通知から外せます。")
                )
            }
        }
        .navigationTitle("手放した商品")
        .navigationBarTitleDisplayMode(.inline)
    }
}
