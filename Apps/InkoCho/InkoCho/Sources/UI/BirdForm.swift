import SwiftData
import SwiftUI

/// 1羽の登録・編集。
struct BirdForm: View {
    let bird: Bird?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Bird.sortIndex) private var birds: [Bird]
    @AppStorage(Picked.key) private var picked = ""

    @State private var name = ""
    @State private var sex = BirdSex.unknown
    @State private var plumage = Plumage.blue
    @State private var picture: Data?
    @State private var hasHatch = false
    @State private var hatchedOn = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
    @State private var hasHome = false
    @State private var cameHomeOn = Date()
    @State private var askDelete = false

    private var cleanName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            if picture == nil {
                                Circle().fill(Hue.sky.opacity(0.14)).frame(width: 110, height: 110)
                                BudgieFace(plumage: plumage, sex: sex, size: 96).offset(y: 6).allowsHitTesting(false)
                            }
                            PhotoField(data: $picture, round: true).opacity(picture == nil ? 0.02 : 1)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.circle.fill").font(.title).symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Hue.sky).allowsHitTesting(false)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
                Section("なまえ") {
                    TextField("ソラ", text: $name).accessibilityIdentifier("bird-name")
                }
                Section("羽の色") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                        ForEach(Plumage.allCases) { p in
                            Button { plumage = p } label: {
                                VStack(spacing: 4) {
                                    BudgieFace(plumage: p, sex: sex, size: 40)
                                        .padding(4)
                                        .background(Circle().fill(plumage == p ? Hue.sky.opacity(0.2) : .clear))
                                        .overlay(Circle().stroke(plumage == p ? Hue.sky : .clear, lineWidth: 2))
                                    Text(p.label).font(.caption2).lineLimit(1).minimumScaleFactor(0.7).foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section {
                    Picker("性別", selection: $sex) { ForEach(BirdSex.allCases) { Text($0.label).tag($0) } }
                    Toggle("生まれた日がわかる", isOn: $hasHatch)
                    if hasHatch { DatePicker("生まれた日", selection: $hatchedOn, in: ...Date(), displayedComponents: .date) }
                    Toggle("お迎えした日を残す", isOn: $hasHome)
                    if hasHome { DatePicker("お迎えした日", selection: $cameHomeOn, in: ...Date(), displayedComponents: .date) }
                } footer: {
                    Text("生後6か月までは、室温の目安を高めにします。メスは産卵の記録ができます。")
                }
                if bird != nil {
                    Section { Button("この子の記録をすべて消す", role: .destructive) { askDelete = true } }
                }
            }
            .navigationTitle(bird == nil ? "うちの子を登録" : "プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save).disabled(cleanName.isEmpty) }
            }
            .confirmationDialog("\(bird?.name ?? "")の体重・記録・言葉がすべて消えます。", isPresented: $askDelete, titleVisibility: .visible) {
                Button("消す", role: .destructive) {
                    if let bird {
                        if picked == bird.tag.uuidString { picked = "" }
                        context.delete(bird)
                        try? context.save()
                    }
                    dismiss()
                }
            }
            .onAppear {
                guard let bird else { return }
                name = bird.name
                sex = bird.sex
                plumage = bird.plumage
                picture = bird.picture
                if let d = bird.hatchedOn { hasHatch = true; hatchedOn = d }
                if let d = bird.cameHomeOn { hasHome = true; cameHomeOn = d }
            }
        }
    }

    private func save() {
        let target = bird ?? Bird(name: cleanName, sortIndex: (birds.map(\.sortIndex).max() ?? -1) + 1)
        target.name = cleanName
        target.sex = sex
        target.plumage = plumage
        target.picture = picture
        target.hatchedOn = hasHatch ? hatchedOn : nil
        target.cameHomeOn = hasHome ? cameHomeOn : nil
        if bird == nil {
            context.insert(target)
            picked = target.tag.uuidString
        }
        try? context.save()
        dismiss()
    }
}
