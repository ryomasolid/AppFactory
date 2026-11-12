import SwiftData
import SwiftUI

struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @AppStorage(MorningDigest.onKey) private var digestOn = false
    @AppStorage(MorningDigest.hourKey) private var hour = MorningDigest.defaultHour
    @AppStorage(MorningDigest.minuteKey) private var minute = 0
    @Query(sort: \PondLog.at) private var logs: [PondLog]
    @State private var blocked = false
    @State private var shared: SharedFile?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("朝のお知らせ", isOn: $digestOn)
                    if digestOn {
                        DatePicker("時刻", selection: time, displayedComponents: .hourAndMinute)
                    }
                    if blocked {
                        Button("iPhone の設定で通知を許可する") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    }
                } footer: {
                    Text("水換えの目安が来た容器と、孵りそうな卵がある日だけ、1日1通お知らせします。")
                }

                Section {
                    Button("記録をCSVで書き出す", systemImage: "square.and.arrow.up") { shared = export() }
                        .disabled(logs.isEmpty)
                } footer: {
                    Text("Numbers や Excel で開けます。機種変更の前の控えにもどうぞ。")
                }

                Section("めだか帳について") {
                    LabeledContent("バージョン", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                    Text("記録はこの iPhone の中だけに保存されます。アカウント登録はありません。")
                    Text("画面の下に Google AdMob の広告が出ます。広告のために、広告 ID などが Google に送られることがあります。")
                    Link("プライバシーポリシー", destination: URL(string: "https://ryomasolid.github.io/privacy-medakacho.html")!)
                    Text("水換えの間隔・えさの量・孵化の日数は一般的な目安です。めだかの様子を見て調整してください。")
                }
                .font(.footnote)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.water)
            .navigationTitle("設定")
            .onChange(of: digestOn) { _, on in
                Task {
                    if on {
                        let granted = await MorningDigest.askPermission()
                        blocked = !granted
                        if !granted { digestOn = false }
                    }
                    await MorningDigest.refresh(context: context)
                }
            }
            .onChange(of: hour) { reschedule() }
            .onChange(of: minute) { reschedule() }
            .sheet(item: $shared) { ActivitySheet(url: $0.url) }
        }
    }

    private var time: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        } set: { value in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: value)
            hour = parts.hour ?? MorningDigest.defaultHour
            minute = parts.minute ?? 0
        }
    }

    private func reschedule() {
        let context = context
        Task { await MorningDigest.refresh(context: context) }
    }

    private func export() -> SharedFile? {
        let stamp = Date().formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("めだか帳_\(stamp).csv")
        // BOM を付けると Excel でも文字化けしない。
        let bytes = Data([0xEF, 0xBB, 0xBF]) + Data(LogTable.csv(logs).utf8)
        guard (try? bytes.write(to: url, options: .atomic)) != nil else { return nil }
        return SharedFile(url: url)
    }
}

struct SharedFile: Identifiable {
    let url: URL
    var id: String { url.path }
}

enum LogTable {
    static let columns = ["日時", "容器", "品種", "記録", "割合(%)", "数", "移した先", "水温(℃)", "メモ"]

    static func csv(_ logs: [PondLog]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let rows = logs.sorted { $0.at < $1.at }.map { log -> [String] in
            [
                formatter.string(from: log.at),
                log.vessel?.name ?? "",
                log.vessel?.breedLabel ?? "",
                log.kind.label,
                log.percent.map(String.init) ?? "",
                log.count.map(String.init) ?? "",
                log.destination,
                log.celsius.map { String(format: "%.1f", $0) } ?? "",
                log.note,
            ]
        }
        return ([columns] + rows).map { $0.map(quote).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    static func quote(_ field: String) -> String {
        let special: Set<Character> = [",", "\"", "\n", "\r"]
        guard field.contains(where: special.contains) else { return field }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}

private struct ActivitySheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
