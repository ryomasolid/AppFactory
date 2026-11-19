import SwiftData
import SwiftUI

/// カメの登録と編集。
struct TurtleEditor: View {
    let turtle: Turtle?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Turtle.order) private var all: [Turtle]

    @State private var name = ""
    @State private var habitat: Habitat = .water
    @State private var species: Species = .redEared
    @State private var sex: Sex = .unknown
    @State private var knowsHatch = false
    @State private var hatchedOn = Date()
    @State private var arrivedOn = Date()
    @State private var photo: Data?
    @State private var feedEvery: Int?
    @State private var tidyEvery: Int?
    @State private var soakEvery: Int?
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名前", text: $name)
                        .accessibilityIdentifier("turtle-name")
                    PhotoPick(title: "写真をえらぶ", data: $photo)
                }

                Section("種類") {
                    Picker("くらし", selection: $habitat) {
                        Text("ミズガメ").tag(Habitat.water)
                        Text("リクガメ").tag(Habitat.land)
                    }
                    .pickerStyle(.segmented)
                    Picker("種類", selection: $species) {
                        ForEach(Species.choices(habitat)) { Text($0.label).tag($0) }
                    }
                    Picker("性別", selection: $sex) {
                        ForEach(Sex.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section {
                    Toggle("ふ化した日がわかる", isOn: $knowsHatch)
                    if knowsHatch {
                        DatePicker("ふ化した日", selection: $hatchedOn, in: ...Date(), displayedComponents: .date)
                    }
                    DatePicker("うちに来た日", selection: $arrivedOn, in: ...Date(), displayedComponents: .date)
                } footer: {
                    Text("1歳まではごはんや水換えの目安がこまめになります。ふ化日がわからなければ、うちに来た日で数えます。")
                }

                Section {
                    intervalRow("ごはん", value: $feedEvery, kind: .feed)
                    intervalRow(habitat == .water ? "水換え" : "床材の交換", value: $tidyEvery, kind: habitat == .water ? .water : .bedding)
                    if habitat == .land {
                        intervalRow("温浴", value: $soakEvery, kind: .soak)
                    }
                } header: {
                    Text("世話の間隔")
                } footer: {
                    Text("最初は一般的な目安です。飼い方に合わせて変えられます。0日にすると予定に出しません。")
                }

                if turtle != nil {
                    Section {
                        Button("このカメを削除", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(turtle == nil ? "カメを登録" : "カメを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: habitat) { _, h in
                if species.habitat != h { species = Species.choices(h).first! }
            }
            .onAppear(perform: load)
            .confirmationDialog("「\(turtle?.name ?? "")」と、その記録をすべて削除します。", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("削除する", role: .destructive) {
                    if let turtle { context.delete(turtle) }
                    dismiss()
                }
            }
        }
    }

    private var young: Bool { Rhythm.isYoung(ageBase: knowsHatch ? hatchedOn : arrivedOn, now: Date()) }

    private func intervalRow(_ title: String, value: Binding<Int?>, kind: CareKind) -> some View {
        let standard = Rhythm.days(kind, habitat: habitat, young: young)
        let current = value.wrappedValue ?? standard
        return Stepper(value: Binding(get: { current }, set: { value.wrappedValue = $0 == standard ? nil : $0 }), in: 0...60) {
            HStack {
                Text(title)
                Spacer()
                Text(current == 0 ? "予定なし" : current == 1 ? "毎日" : "\(current)日ごと")
                    .foregroundStyle(value.wrappedValue == nil ? .secondary : Palette.moss)
            }
        }
    }

    private func load() {
        guard let t = turtle else { return }
        name = t.name
        habitat = t.species.habitat
        species = t.species
        sex = t.sex
        knowsHatch = t.hatchedOn != nil
        hatchedOn = t.hatchedOn ?? Date()
        arrivedOn = t.arrivedOn
        photo = t.photo
        feedEvery = t.feedEvery
        tidyEvery = t.tidyEvery
        soakEvery = t.soakEvery
    }

    private func save() {
        let target = turtle ?? Turtle(name: "", species: species, order: (all.map(\.order).max() ?? -1) + 1)
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.species = species
        target.sex = sex
        target.hatchedOn = knowsHatch ? hatchedOn : nil
        target.arrivedOn = arrivedOn
        target.photo = photo
        target.feedEvery = feedEvery
        target.tidyEvery = tidyEvery
        target.soakEvery = habitat == .land ? soakEvery : nil
        if turtle == nil {
            context.insert(target)
            UserDefaults.standard.set(target.key.uuidString, forKey: Selection.storageKey)
        }
        dismiss()
    }
}
