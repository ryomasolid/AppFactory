import SwiftData
import SwiftUI

struct SettingsTab: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Bird.sortIndex) private var birds: [Bird]
    @AppStorage(Alarm.onKey) private var alarmOn = false
    @AppStorage(Alarm.hourKey) private var hour = Alarm.defaultHour
    @State private var editing: BirdRef?
    @State private var denied = false

    var body: some View {
        NavigationStack {
            Form {
                Section("うちの子") {
                    ForEach(birds) { bird in
                        Button { editing = BirdRef(bird: bird) } label: {
                            HStack(spacing: 12) {
                                BirdBadge(bird: bird, size: 40)
                                VStack(alignment: .leading) {
                                    Text(bird.name).foregroundStyle(.primary)
                                    Text("\(bird.plumage.label)・\(bird.sex.label)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Button { editing = BirdRef(bird: nil) } label: { Label("もう1羽ふやす", systemImage: "plus.circle") }
                }
                Section {
                    Toggle("朝のお知らせ", isOn: $alarmOn)
                    if alarmOn {
                        Picker("時刻", selection: $hour) {
                            ForEach(5...11, id: \.self) { Text("\($0)時").tag($0) }
                        }
                    }
                } header: {
                    Text("お知らせ")
                } footer: {
                    Text(denied ? "通知が許可されていません。iPhone の設定 → 通知 → インコ帳 から許可してください。" : "毎朝「体重をはかろう」と、その日が目安のおせわを1通でお知らせします。はかり終わった日は出ません。")
                }
                Section("このアプリについて") {
                    Link("プライバシーポリシー", destination: URL(string: "https://ryomasolid.github.io/privacy-inkocho.html")!)
                    Link("サポート・お問い合わせ", destination: URL(string: "https://ryomasolid.github.io/support-inkocho.html")!)
                    LabeledContent("バージョン", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                }
                Section {
                    Text("記録・写真はこの iPhone の中にだけ保存され、外へ送られることはありません。無料で使えるよう、画面の下に広告（Google AdMob）を表示しています。体重や様子の声かけは目安です。気になるときは鳥をみられる病院に相談してください。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Hue.ground)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editing) { BirdForm(bird: $0.bird) }
            .onChange(of: alarmOn) { _, on in
                Task {
                    if on, !(await Alarm.requestPermission()) {
                        denied = true
                        alarmOn = false
                    }
                    await Alarm.reschedule(context)
                }
            }
            .onChange(of: hour) { _, _ in Task { await Alarm.reschedule(context) } }
        }
    }
}

struct BirdRef: Identifiable {
    let id = UUID()
    let bird: Bird?
}
