import SwiftData
import SwiftUI

struct SettingsTab: View {
    @AppStorage(Plan.usualKey) private var usual = Plan.usualDefault
    @AppStorage(Plan.budgetKey) private var budget = Plan.budgetDefault
    @AppStorage(Plan.goalNameKey) private var goalName = ""
    @AppStorage(Plan.goalYenKey) private var goalYen = 0
    @AppStorage(Notice.onKey) private var noticeOn = false
    @AppStorage(Notice.hourKey) private var noticeHour = Notice.defaultHour
    @Environment(\.modelContext) private var context
    @State private var editingGoal = false
    @State private var denied = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    YenField(title: "ふだんのムダ（1日）", value: $usual)
                    YenField(title: "1か月のムダ予算", value: $budget)
                } header: {
                    Text("お金の目安")
                } footer: {
                    Text("ムダゼロの日は「ふだんのムダ」の分が浮いたとかぞえます。ムダ予算は ついつい の出費だけで使います。")
                }

                Section("ためる もくひょう") {
                    Button {
                        editingGoal = true
                    } label: {
                        HStack {
                            Text(goalYen > 0 ? (goalName.isEmpty ? "もくひょう" : goalName) : "まだ決めていない")
                                .foregroundStyle(Hue.ink)
                            Spacer()
                            if goalYen > 0 { Text(goalYen.yen).foregroundStyle(Hue.soft) }
                            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Hue.soft)
                        }
                    }
                }

                Section {
                    Toggle("夜のお知らせ", isOn: $noticeOn)
                        .accessibilityIdentifier("notice-toggle")
                    if noticeOn {
                        Picker("時刻", selection: $noticeHour) {
                            ForEach(18...23, id: \.self) { Text("\($0):00").tag($0) }
                        }
                    }
                } header: {
                    Text("お知らせ")
                } footer: {
                    Text(denied
                        ? "通知が許可されていません。iPhone の「設定」→「通知」→「ムダゼロ」から許可してください。"
                        : "まだしめていない日だけ、1日1回お知らせします。")
                }

                Section("このアプリについて") {
                    Link("プライバシーポリシー", destination: URL(string: "https://ryomasolid.github.io/privacy-mudazero.html")!)
                    Link("サポート", destination: URL(string: "https://ryomasolid.github.io/support-mudazero.html")!)
                    LabeledContent("バージョン", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                }
                Section {
                    Text("記録はこの iPhone の中にだけ保存します。銀行やカードとはつながりません。")
                        .font(.footnote)
                        .foregroundStyle(Hue.soft)
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $editingGoal) { GoalForm() }
            .onChange(of: noticeOn) { _, on in
                Task {
                    if on, !(await Notice.ask()) {
                        noticeOn = false
                        denied = true
                    }
                    await Notice.reschedule(context)
                }
            }
            .onChange(of: noticeHour) { _, _ in Task { await Notice.reschedule(context) } }
        }
    }
}

struct YenField: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110)
            Text("円").foregroundStyle(Hue.soft)
        }
    }
}
