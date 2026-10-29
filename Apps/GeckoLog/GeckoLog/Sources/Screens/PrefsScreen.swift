import SwiftData
import SwiftUI

struct PrefsScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @AppStorage(FeedingAlarm.enabledKey) private var alarmOn = false
    @AppStorage(FeedingAlarm.hourKey) private var hour = FeedingAlarm.defaultHour
    @AppStorage(FeedingAlarm.minuteKey) private var minute = 0
    @Query(sort: \CareEntry.occurredAt) private var entries: [CareEntry]

    @State private var permissionDenied = false
    @State private var exportFile: ExportFile?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("ごはんの日に知らせる", isOn: $alarmOn)
                    if alarmOn {
                        DatePicker("時刻", selection: alarmTime, displayedComponents: .hourAndMinute)
                    }
                    if permissionDenied {
                        Button("iPhone の設定で通知を許可する") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    }
                } header: {
                    Text("お知らせ")
                } footer: {
                    Text("ごはんの日の子が何匹いても、1日1通にまとめてお知らせします。")
                }

                Section {
                    Button("記録をCSVで書き出す", systemImage: "square.and.arrow.up") { exportFile = makeExport() }
                        .disabled(entries.isEmpty)
                } header: {
                    Text("データ")
                } footer: {
                    Text("Numbers や Excel で開けます。動物病院で見せるときや、機種変更前の控えにどうぞ。")
                }

                Section("このアプリについて") {
                    LabeledContent("バージョン", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                    Text("記録と写真はこの iPhone の中だけに保存されます。アカウント登録はなく、外部へ送信することもありません。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("ごはんの間隔・脱皮・孵化の日数は一般的な目安です。体調が心配なときは爬虫類を診られる動物病院に相談してください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("せってい")
            .onChange(of: alarmOn) { _, on in
                Task {
                    if on {
                        let granted = await FeedingAlarm.requestPermission()
                        permissionDenied = !granted
                        if !granted { alarmOn = false }
                    }
                    await FeedingAlarm.reschedule(context: context)
                }
            }
            .onChange(of: hour) { reschedule() }
            .onChange(of: minute) { reschedule() }
            .sheet(item: $exportFile) { file in
                ShareSheet(items: [file.url])
            }
        }
    }

    private var alarmTime: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            hour = parts.hour ?? FeedingAlarm.defaultHour
            minute = parts.minute ?? 0
        }
    }

    private func reschedule() {
        Task { await FeedingAlarm.reschedule(context: context) }
    }

    private func makeExport() -> ExportFile? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("げこログ_\(Date().formatted(.iso8601.year().month().day())).csv")
        // Excel で文字化けしないよう BOM を付ける。
        let data = Data([0xEF, 0xBB, 0xBF]) + Data(CSVExport.make(entries).utf8)
        do {
            try data.write(to: url, options: .atomic)
            return ExportFile(url: url)
        } catch {
            return nil
        }
    }
}

struct ExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}

enum CSVExport {
    static let header = ["日時", "名前", "種類", "エサ", "数", "食べた", "ダスティング", "皮残り", "体重(g)", "うんち", "温度(℃)", "湿度(%)", "メモ"]

    static func make(_ entries: [CareEntry]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        var lines = [header.joined(separator: ",")]
        for entry in entries.sorted(by: { $0.occurredAt < $1.occurredAt }) {
            let isFeeding = entry.kind == .feeding
            let row: [String] = [
                formatter.string(from: entry.occurredAt),
                entry.gecko?.name ?? "",
                entry.kind.label,
                entry.feeder?.label ?? "",
                isFeeding && entry.feederCount > 0 ? "\(entry.feederCount)" : "",
                isFeeding ? (entry.accepted ? "はい" : "いいえ") : "",
                isFeeding && entry.dusted ? "はい" : "",
                entry.kind == .shed ? (entry.skinLeftover ? "あり" : "なし") : "",
                entry.grams.map { String(format: "%g", $0) } ?? "",
                entry.dropping?.label ?? "",
                entry.warmSideC.map { String(format: "%g", $0) } ?? "",
                entry.humidityPercent.map { String(format: "%g", $0) } ?? "",
                entry.note,
            ]
            lines.append(row.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
