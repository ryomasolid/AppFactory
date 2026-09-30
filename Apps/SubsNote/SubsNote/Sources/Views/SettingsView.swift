import SwiftData
import SwiftUI
import UIKit

/// 設定。お知らせのタイミング・届いているかの確認・見直しの回数・書き出し・Pro。
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ProUnlock.self) private var pro
    @Environment(\.openURL) private var openURL
    @Query(sort: \Subscription.createdAt) private var subscriptions: [Subscription]

    @AppStorage(StorageKey.reminderDays) private var reminderDaysRaw = NotificationSettings.encode(NotificationSettings.defaultReminderDays)
    @AppStorage(StorageKey.notifyHour) private var notifyHour = 9
    @AppStorage(StorageKey.notifyMinute) private var notifyMinute = 0
    @AppStorage(StorageKey.trialAlerts) private var trialAlerts = true
    @AppStorage(StorageKey.yearlyWeekBefore) private var yearlyWeekBefore = true

    @State private var permission: ReminderCenter.Permission = .unknown
    @State private var pending = 0
    @State private var next: ReminderCenter.Upcoming?
    @State private var showPaywall = false
    @State private var confirmReset = false
    @State private var csvURL: URL?

    static let privacyPolicyURL = URL(string: "https://ryomasolid.github.io/privacy-subsnote.html")

    /// 見直しの回数がついているサブスクの数。
    private var ratedCount: Int { subscriptions.filter { $0.usesLastMonth != nil }.count }

    var body: some View {
        NavigationStack {
            Form {
                timingSection
                trialSection
                deliverySection
                reviewSection
                exportSection
                proSection
                appSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) { PaywallView().environment(pro) }
            .sheet(isPresented: Binding(get: { csvURL != nil }, set: { if !$0 { csvURL = nil } })) {
                if let csvURL { ActivityView(items: [csvURL]).presentationDetents([.medium, .large]) }
            }
            .confirmationDialog("見直しの回数をすべて消しますか？", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("回数を消す", role: .destructive, action: resetUsage)
            } message: {
                Text("月が変わったときに、先月の回数をつけ直すためのものです。サブスクの記録は消えません。")
            }
            .task { await loadDelivery() }
            .onChange(of: settingsKey) { Task { await reschedule(ask: false) } }
        }
        .tint(Palette.ink)
    }

    /// お知らせの設定をひとまとめにした値。どれかが変わったら予約を入れ替える。
    private var settingsKey: String {
        "\(reminderDaysRaw)|\(notifyHour):\(notifyMinute)|\(trialAlerts)|\(yearlyWeekBefore)"
    }

    // MARK: - お知らせ

    private var timingSection: some View {
        Section {
            ForEach(ReminderDay.allCases) { day in
                Toggle(day.label, isOn: reminderDay(day.rawValue))
            }
            DatePicker("時刻", selection: notifyTime, displayedComponents: .hourAndMinute)
        } header: {
            Text("支払日のお知らせ")
        } footer: {
            Text("オンにしたタイミングすべてで、金額と支払い方法を添えて通知します。")
        }
    }

    private func reminderDay(_ day: Int) -> Binding<Bool> {
        Binding(
            get: { NotificationSettings.decode(reminderDaysRaw).contains(day) },
            set: { isOn in
                var days = NotificationSettings.decode(reminderDaysRaw)
                if isOn { days.insert(day) } else { days.remove(day) }
                reminderDaysRaw = NotificationSettings.encode(days)
            }
        )
    }

    private var notifyTime: Binding<Date> {
        Binding(
            get: { Calendar.current.date(from: DateComponents(hour: notifyHour, minute: notifyMinute)) ?? .now },
            set: {
                let parts = Calendar.current.dateComponents([.hour, .minute], from: $0)
                (notifyHour, notifyMinute) = (parts.hour ?? 9, parts.minute ?? 0)
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

    // MARK: - 届いているか

    private var deliverySection: some View {
        Section {
            switch permission {
            case .blocked:
                Label("通知がオフになっています", systemImage: "bell.slash.fill")
                    .foregroundStyle(Palette.deadline)
                Button("設定アプリを開いて通知をオンにする") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            case .unknown:
                Button("通知をオンにする") { Task { await reschedule(ask: true) } }
            case .allowed:
                if let next {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("次のお知らせ・\(next.date.formatted(.dateTime.month().day().weekday().hour().minute()))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(next.title).font(.subheadline)
                    }
                    .padding(.vertical, 2)
                } else {
                    Text("予約中のお知らせはありません").foregroundStyle(.secondary)
                }
                LabeledContent("予約中", value: String(localized: "\(pending)件"))
                Button("お知らせを予約し直す") { Task { await reschedule(ask: false) } }
            }
        } header: {
            Text("お知らせが届いているか")
        } footer: {
            Text("近いものから\(NotificationPlanner.budget)件まで予約し、アプリを開いたときとバックグラウンドで先の分を足していきます。")
        }
    }

    // MARK: - 見直し

    private var reviewSection: some View {
        Section {
            LabeledContent("回数をつけたサブスク", value: String(localized: "\(ratedCount)件"))
            Button("見直しの回数をすべて消す", role: .destructive) { confirmReset = true }
                .disabled(ratedCount == 0)
        } header: {
            Text("見直し")
        } footer: {
            Text("月が変わったら回数を消して、先月の分をつけ直すと、使わなくなったサブスクに気づけます。")
        }
    }

    // MARK: - 書き出し

    private var exportSection: some View {
        Section {
            Button {
                if ProLimits.canExport(isPro: pro.isUnlocked) { writeCSV() } else { showPaywall = true }
            } label: {
                HStack {
                    Label("CSVで書き出す", systemImage: "tablecells")
                    Spacer()
                    if !pro.isUnlocked { ProBadge() }
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

    @ViewBuilder
    private var proSection: some View {
        Section {
            if pro.isUnlocked {
                Label("Pro（買い切り）を利用中です", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Palette.saving)
            } else {
                Button { showPaywall = true } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Label("サブスク帳 Pro", systemImage: "book.closed.fill")
                            .font(.body.weight(.semibold))
                        Text("登録無制限・内訳・CSV・広告なし（買い切り）")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button("以前に購入した方（購入を復元）") { Task { await pro.restore() } }
                    .disabled(pro.isWorking)
            }
        }
    }

    // MARK: - このアプリ

    private var appSection: some View {
        Section {
            Link(destination: URL(string: "mailto:oga.sesame.tech@gmail.com?subject=%E3%82%B5%E3%83%96%E3%82%B9%E3%82%AF%E5%B8%B3")!) {
                Label("ご意見・不具合の連絡（メール）", systemImage: "envelope")
            }
            if let url = Self.privacyPolicyURL {
                Link(destination: url) { Label("プライバシーポリシー", systemImage: "hand.raised") }
            }
            LabeledContent("バージョン", value: Bundle.main.versionLabel)
        } header: {
            Text("このアプリについて")
        } footer: {
            Text("表示される金額・支払日・料金プランの候補は、登録された内容と一般的な料金からの目安です。実際の請求額と解約の方法は、ご契約のサービスでご確認ください。")
        }
    }

    // MARK: - 処理

    private func loadDelivery() async {
        permission = await ReminderCenter.permission()
        guard permission == .allowed else { return }
        pending = await ReminderCenter.pendingCount()
        next = await ReminderCenter.upcoming()
    }

    private func reschedule(ask: Bool) async {
        await NotificationRefresh.run(container: modelContext.container, requestingAuthorization: ask)
        await loadDelivery()
    }

    private func resetUsage() {
        for subscription in subscriptions {
            subscription.usesLastMonth = nil
            subscription.usageCheckedAt = nil
        }
        try? modelContext.save()
    }

    private func writeCSV() {
        let stamp = Date().formatted(.iso8601.year().month().day().dateSeparator(.omitted))
        let url = URL.temporaryDirectory.appending(path: "SubsNote-\(stamp).csv")
        do {
            try CSVExport.data(rows: subscriptions.map { $0.exportRow() }).write(to: url, options: .atomic)
            csvURL = url
        } catch {
            csvURL = nil
        }
    }
}

private extension Bundle {
    /// 「1.0 (2)」の形のバージョン表記。
    var versionLabel: String {
        let short = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(short) (\(build))"
    }
}
