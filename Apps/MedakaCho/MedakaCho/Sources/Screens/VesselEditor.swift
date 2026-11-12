import SwiftData
import SwiftUI

/// 容器の登録と編集。
struct VesselEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let vessel: Vessel?
    let nextOrder: Int
    /// 詳細画面から開いたとき、削除は詳細画面を閉じてから行う（消えた容器を描きにいかないように）。
    var requestDelete: (() -> Void)?

    @State private var name = ""
    @State private var style = VesselStyle.bowl
    @State private var outdoors = true
    @State private var liters = 20.0
    @State private var breed = ""
    @State private var stage = LifeStage.adult
    @State private var headcount = 5
    @State private var setUpOn = Date()
    @State private var hasHeater = false
    @State private var note = ""
    @State private var confirmDelete = false

    /// よく飼われている品種。入力の手間を減らす候補で、ここにない名前も自由に書ける。
    static let popularBreeds = ["楊貴妃", "幹之", "黒めだか", "白めだか", "青めだか", "オーロラ", "三色", "紅白", "夜桜", "ラメ", "ブラックダイヤ", "オロチ"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名前（例: 玄関の鉢）", text: $name)
                        .accessibilityIdentifier("vessel-name")
                    Picker("入れもの", selection: $style) {
                        ForEach(VesselStyle.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("置き場所", selection: $outdoors) {
                        Text("屋外").tag(true)
                        Text("屋内").tag(false)
                    }
                    .pickerStyle(.segmented)
                    Stepper("水の量 \(VesselScreen.liters(liters))", value: $liters, in: 1...500, step: liters < 10 ? 1 : 5)
                    if !outdoors { Toggle("ヒーターあり", isOn: $hasHeater) }
                }

                Section {
                    TextField("品種（空ならミックス）", text: $breed)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Self.popularBreeds, id: \.self) { name in
                                Button(name) { breed = name }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(breed == name ? Palette.koi : Palette.mute)
                            }
                        }
                    }
                    Picker("育ち", selection: $stage) {
                        ForEach(LifeStage.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Stepper("いまの数 \(headcount)匹", value: $headcount, in: 0...999)
                } header: {
                    Text("中のめだか")
                } footer: {
                    Text("数はだいたいで大丈夫です。あとで「★になった」「移した」を記録すると増減します。")
                }

                Section {
                    DatePicker("立ち上げた日", selection: $setUpOn, in: ...Date(), displayedComponents: .date)
                    TextField("メモ（水草・底床など）", text: $note, axis: .vertical)
                }

                if vessel != nil {
                    Section {
                        Button("この容器を削除", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(vessel == nil ? "容器を登録" : "容器を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("この容器と記録をすべて削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("削除する", role: .destructive) {
                    dismiss()
                    if let requestDelete {
                        requestDelete()
                    } else if let vessel {
                        context.delete(vessel)
                        try? context.save()
                    }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let vessel else { return }
        name = vessel.name
        style = vessel.style
        outdoors = vessel.outdoors
        liters = vessel.liters
        breed = vessel.breed
        stage = vessel.stage
        headcount = vessel.headcount
        setUpOn = vessel.setUpOn
        hasHeater = vessel.hasHeater
        note = vessel.note
    }

    private func save() {
        let target = vessel ?? Vessel(name: "", style: style, outdoors: outdoors, liters: liters, breed: "", stage: stage, headcount: 0, order: nextOrder)
        if vessel == nil { context.insert(target) }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.style = style
        target.outdoors = outdoors
        target.liters = liters
        target.breed = breed.trimmingCharacters(in: .whitespaces)
        target.stage = stage
        target.headcount = headcount
        target.setUpOn = setUpOn
        target.hasHeater = !outdoors && hasHeater
        target.note = note
        try? context.save()
        let context = context
        Task { await MorningDigest.refresh(context: context) }
        dismiss()
    }
}
