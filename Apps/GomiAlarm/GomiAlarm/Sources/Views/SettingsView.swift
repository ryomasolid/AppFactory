import SwiftData
import SwiftUI
import UserNotifications

/// 設定。通知の既定時刻・祝日の扱い・Pro・通知が届かないときの導線。
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Environment(\.openURL) private var openURL

    @State private var settings = NotificationSettings.load()
    @State private var status = RefreshStatus.load()
    @State private var authorizationDenied = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                holidaySection
                statusSection
                proSection
                aboutSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environment(store)
            }
            .task {
                settings = NotificationSettings.load()
                status = RefreshStatus.load()
                authorizationDenied = await NotificationScheduler.shared.isDenied()
            }
        }
        .tint(Theme.accent)
    }

    // MARK: - 通知

    private var notificationSection: some View {
        Section {
            Toggle("前の晩に通知", isOn: binding(\.eveningEnabled))
            if settings.eveningEnabled {
                DatePicker("時刻", selection: timeBinding(\.eveningTime), displayedComponents: .hourAndMinute)
            }
            Toggle("当日の朝に通知", isOn: binding(\.morningEnabled))
            if settings.morningEnabled {
                DatePicker("時刻", selection: timeBinding(\.morningTime), displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("通知")
        } footer: {
            Text("種類ごとに時刻を変えたい場合は「予定」タブの各種類から設定できます。")
        }
    }

    // MARK: - 祝日

    private var holidaySection: some View {
        Section {
            if store.isPro {
                Toggle("祝日は通知しない", isOn: binding(\.skipHolidays))
            } else {
                // Pro 機能。オフのまま固定し、タップで課金画面へ誘導する。
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Text("祝日は通知しない").foregroundStyle(.primary)
                        Spacer()
                        Label("Pro", systemImage: "crown.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("祝日")
        } footer: {
            Text("自治体によっては祝日も収集します。お住まいの地域が祝日も収集する場合はオフのままご利用ください。")
        }
    }

    // MARK: - 通知の状態

    private var statusSection: some View {
        Section {
            LabeledContent("通知の許可", value: authorizationDenied ? "オフ" : (status.authorized ? "オン" : "未確認"))
            LabeledContent("予約済みの通知", value: "\(status.scheduled)件")
            if status.truncated {
                // 64件上限に当たると、遠い予定から順に登録できなくなる。
                Text("登録できる通知の上限に達したため、遠い予定の一部は登録されていません。種類を減らすか、通知を前夜か朝のどちらかに絞ると改善します。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if authorizationDenied {
                Button("設定アプリで通知を許可する") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
            Button("通知を作り直す") {
                Task {
                    status = await NotificationRefresh.run(
                        container: modelContext.container, requestingAuthorization: true
                    )
                    authorizationDenied = await NotificationScheduler.shared.isDenied()
                }
            }
        } header: {
            Text("通知が届かないときは")
        } footer: {
            if let covered = status.coveredThrough {
                Text("\(covered.formatted(.dateTime.month().day()))までの収集日を予約済みです。")
            } else if status.isPermanent {
                Text("毎週くり返しの通知として予約済みです。")
            }
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
                        store.isPro ? "Pro を利用中" : "Pro（種類を無制限に・広告なし）",
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
            Text("収集日・分別のルールは自治体によって異なります。実際の収集日は各自治体の公式情報をご確認のうえ登録してください。")
        }
    }

    private static var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - 設定の保存

    /// 変更したらすぐ保存し、通知も組み直す。「設定したのに鳴らない」を作らない。
    private func binding(_ keyPath: WritableKeyPath<NotificationSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { newValue in
                settings[keyPath: keyPath] = newValue
                apply()
            }
        )
    }

    private func timeBinding(_ keyPath: WritableKeyPath<NotificationSettings, TimeOfDay>) -> Binding<Date> {
        Binding(
            get: { settings[keyPath: keyPath].date(on: Date()) ?? Date() },
            set: { date in
                settings[keyPath: keyPath] = TimeOfDay(date)
                apply()
            }
        )
    }

    private func apply() {
        settings.save()
        let container = modelContext.container
        let current = settings
        Task {
            status = await NotificationRefresh.run(container: container, settings: current)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [GarbageKind.self, CollectionRule.self, DoneRecord.self], inMemory: true)
        .environment(StoreManager())
}
