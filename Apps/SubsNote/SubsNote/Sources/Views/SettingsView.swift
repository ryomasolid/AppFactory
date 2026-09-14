import SwiftData
import SwiftUI
import UIKit

/// 設定。通知・書き出し・Pro。
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Environment(\.openURL) private var openURL
    @Query(sort: \Subscription.createdAt) private var subscriptions: [Subscription]

    @AppStorage(StorageKey.reminderDays) private var reminderDaysRaw = NotificationSettings.encode(NotificationSettings.defaultReminderDays)
    @AppStorage(StorageKey.notifyHour) private var notifyHour = 9
    @AppStorage(StorageKey.notifyMinute) private var notifyMinute = 0
    @AppStorage(StorageKey.trialAlerts) private var trialAlerts = true
    @AppStorage(StorageKey.yearlyWeekBefore) private var yearlyWeekBefore = true

    @State private var showPaywall = false
    @State private var authorizationDenied = false
    @State private var scheduledCount: Int?
    @State private var exportFile: ExportFile?

    private struct ExportFile: Identifiable {
        let url: URL
        var id: URL { url }
    }

    static let privacyPolicyURL = URL(string: "https://ryomasolid.github.io/privacy-subsnote.html")

    var body: some View {
        NavigationStack {
            Form {
                reminderSection
                trialSection
                statusSection
                dataSection
                proSection
                aboutSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView().environment(store)
            }
            .sheet(item: $exportFile) { file in
                ActivityView(items: [file.url])
                    .presentationDetents([.medium, .large])
            }
            .task { await refreshStatus() }
            .onChange(of: reminderDaysRaw) { Task { await rebuild(requestingAuthorization: false) } }
            .onChange(of: notifyHour) { Task { await rebuild(requestingAuthorization: false) } }
            .onChange(of: notifyMinute) { Task { await rebuild(requestingAuthorization: false) } }
            .onChange(of: trialAlerts) { Task { await rebuild(requestingAuthorization: false) } }
            .onChange(of: yearlyWeekBefore) { Task { await rebuild(requestingAuthorization: false) } }
        }
        .tint(Theme.accent)
    }

    // MARK: - 通知

    private var reminderSection: some View {
        Section {
            ForEach(ReminderDay.allCases) { day in
                Toggle(day.label, isOn: dayBinding(day.rawValue))
            }
            DatePicker("時刻", selection: notifyTimeBinding, displayedComponents: .hourAndMinute)
        } header: {
            Text("支払日のお知らせ")
        } footer: {
            Text("オンにしたタイミングすべてで、金額と支払い方法を添えて通知します。")
        }
    }

    private func dayBinding(_ day: Int) -> Binding<Bool> {
        Binding(
            get: { NotificationSettings.decode(reminderDaysRaw).contains(day) },
            set: { isOn in
                var days = NotificationSettings.decode(reminderDaysRaw)
                if isOn { days.insert(day) } else { days.remove(day) }
                reminderDaysRaw = NotificationSettings.encode(days)
            }
        )
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

    private var trialSection: some View {
        Section {
            Toggle("無料体験の終了（3日前と前日）", isOn: $trialAlerts)
            Toggle("年払いの更新は7日前にも", isOn: $yearlyWeekBefore)
        } header: {
            Text("解約し忘れを防ぐ")
        } footer: {
            Text("無料体験の終わりと年払いの更新は、気づかないまま支払いになりやすいので別にお知らせします。")
        }
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
            Text("通知は近いものから\(NotificationPlanner.budget)件まで予約し、アプリを開いたときとバックグラウンドで作り直します。")
        }
    }

    // MARK: - 書き出し

    private var dataSection: some View {
        Section {
            Button {
                if ProLimits.canExport(isPro: store.isPro) {
                    exportCSV()
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Label("CSVで書き出す", systemImage: "tablecells")
                    Spacer()
                    if !store.isPro { ProBadge() }
                }
            }
            .disabled(subscriptions.isEmpty)
        } header: {
            Text("書き出し")
        } footer: {
            Text("家計簿や表計算ソフトで開けます。記録はすべてこの端末の中だけに保存されています。")
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
                        store.isPro ? "Pro を利用中" : "Pro（登録無制限・内訳・書き出し・広告なし）",
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
            Text("表示される金額・支払日・料金プランの候補は、登録された内容と一般的な料金からの目安です。実際の請求額と解約の方法は、ご契約のサービスでご確認ください。")
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
        await NotificationRefresh.run(container: modelContext.container, requestingAuthorization: requestingAuthorization)
        await refreshStatus()
    }

    private func exportCSV() {
        let stamp = Date().formatted(.iso8601.year().month().day().dateSeparator(.omitted))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SubsNote-\(stamp).csv")
        do {
            try CSVExport.data(rows: subscriptions.map { $0.exportRow() }).write(to: url, options: .atomic)
            exportFile = ExportFile(url: url)
        } catch {
            exportFile = nil
        }
    }
}
