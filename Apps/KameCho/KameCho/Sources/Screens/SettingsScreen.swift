import SwiftData
import SwiftUI

struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Turtle.order) private var turtles: [Turtle]
    @AppStorage(Reminders.enabledKey) private var remind = false
    @AppStorage(Reminders.hourKey) private var hour = Reminders.defaultHour
    @State private var editing: Turtle?
    @State private var adding = false
    @State private var denied = false

    var body: some View {
        NavigationStack {
            Form {
                Section("うちのカメ") {
                    ForEach(turtles) { t in
                        Button { editing = t } label: {
                            HStack(spacing: 12) {
                                TurtleAvatar(turtle: t, size: 40)
                                VStack(alignment: .leading) {
                                    Text(t.name).foregroundStyle(Palette.ink)
                                    Text(t.species.label).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onMove(perform: move)
                    Button { adding = true } label: { Label("カメを追加", systemImage: "plus.circle") }
                        .accessibilityIdentifier("add-turtle")
                }

                Section {
                    Toggle("朝のお知らせ", isOn: $remind)
                        .accessibilityIdentifier("remind")
                    if remind {
                        Picker("時刻", selection: $hour) {
                            ForEach(5...11, id: \.self) { Text("\($0):00").tag($0) }
                        }
                    }
                } footer: {
                    Text(denied
                        ? "通知が許可されていません。iPhone の「設定」→「通知」→「カメ帳」から許可してください。"
                        : "ごはん・水換え・温浴・計測の予定日と、器具の交換時期を、朝に1通でお知らせします。")
                }

                Section("このアプリについて") {
                    Link("プライバシーポリシー", destination: URL(string: "https://ryomasolid.github.io/privacy-kamecho.html")!)
                    Link("サポート", destination: URL(string: "https://ryomasolid.github.io/support-kamecho.html")!)
                    LabeledContent("バージョン", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                }
                Section {
                    Text("記録はこの iPhone の中にだけ保存され、外へは送りません。体調の判断は目安です。気になるときは爬虫類を診られる動物病院に相談してください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
            .toolbar { if turtles.count > 1 { EditButton() } }
            .sheet(item: $editing) { TurtleEditor(turtle: $0) }
            .sheet(isPresented: $adding) { TurtleEditor(turtle: nil) }
            .onChange(of: remind) { _, on in
                Task {
                    if on, !(await Reminders.askPermission()) {
                        remind = false
                        denied = true
                    }
                    await Reminders.refresh(context)
                }
            }
            .onChange(of: hour) { _, _ in Task { await Reminders.refresh(context) } }
        }
    }

    private func move(from: IndexSet, to: Int) {
        var list = turtles
        list.move(fromOffsets: from, toOffset: to)
        for (i, t) in list.enumerated() { t.order = i }
    }
}
