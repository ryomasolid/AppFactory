import SwiftData
import SwiftUI

struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Dog.order) private var dogs: [Dog]
    @AppStorage(Reminders.morningKey) private var morning = false
    @AppStorage(Reminders.eveningKey) private var evening = false
    @State private var editing: DogPick?
    @State private var heartworm = SeasonSetting.load(.heartworm)
    @State private var fleaTick = SeasonSetting.load(.fleaTick)
    @State private var deniedNotice = false

    var body: some View {
        NavigationStack {
            Form {
                Section("うちの子") {
                    ForEach(dogs) { dog in
                        Button { editing = DogPick(dog: dog) } label: {
                            HStack(spacing: 12) {
                                DogAvatar(dog: dog, size: 40)
                                VStack(alignment: .leading) {
                                    Text(dog.name).foregroundStyle(.primary)
                                    Text("\(dog.coat.label)・\(dog.sex.label)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Button { editing = DogPick(dog: nil) } label: { Label("もう1頭ふやす", systemImage: "plus.circle") }
                }

                Section {
                    Toggle("予防とトリミングの日（朝8時）", isOn: $morning)
                    Toggle("日記のおさそい（夜8時）", isOn: $evening)
                } header: {
                    Text("お知らせ")
                } footer: {
                    Text(deniedNotice ? "通知が許可されていません。iPhone の設定 → 通知 → といぷー日記 から許可してください。" : "夜のお知らせは、その日の日記を書いていれば出ません。")
                }

                Section {
                    seasonRow("フィラリア", $heartworm)
                    seasonRow("ノミ・ダニ", $fleaTick)
                } header: {
                    Text("毎月のお薬のシーズン")
                } footer: {
                    Text("地域や病院によって時期がちがいます。1年じゅう続ける場合は 1月〜12月 にしてください。")
                }

                Section("このアプリについて") {
                    Link("プライバシーポリシー", destination: URL(string: "https://ryomasolid.github.io/privacy-toypoodiary.html")!)
                    Link("サポート・お問い合わせ", destination: URL(string: "https://ryomasolid.github.io/support-toypoodiary.html")!)
                    LabeledContent("バージョン", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                }
                Section {
                    Text("日記・写真・記録はこの iPhone の中にだけ保存され、外へ送られることはありません。無料で使えるよう、画面の下に広告（Google AdMob）を表示しています。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Tone.paper)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editing) { DogEditor(dog: $0.dog) }
            .onChange(of: morning) { _, on in if on { askThenRebuild() } else { rebuild() } }
            .onChange(of: evening) { _, on in if on { askThenRebuild() } else { rebuild() } }
            .onChange(of: heartworm) { _, value in SeasonSetting.save(value, for: .heartworm); rebuild() }
            .onChange(of: fleaTick) { _, value in SeasonSetting.save(value, for: .fleaTick); rebuild() }
        }
    }

    private func seasonRow(_ title: String, _ season: Binding<PreventionPlan.Season>) -> some View {
        HStack {
            Text(title)
            Spacer()
            Picker(title, selection: season.start) { ForEach(1...12, id: \.self) { Text("\($0)月").tag($0) } }
                .labelsHidden()
            Text("〜").foregroundStyle(.secondary)
            Picker(title, selection: season.end) { ForEach(1...12, id: \.self) { Text("\($0)月").tag($0) } }
                .labelsHidden()
        }
    }

    private func askThenRebuild() {
        Task {
            let granted = await Reminders.ask()
            deniedNotice = !granted
            if !granted {
                morning = false
                evening = false
            }
            await Reminders.rebuild(context)
        }
    }

    private func rebuild() {
        Task { await Reminders.rebuild(context) }
    }
}

struct DogPick: Identifiable {
    let id = UUID()
    let dog: Dog?
}
