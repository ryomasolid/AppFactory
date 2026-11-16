import SwiftData
import SwiftUI

struct TrimEditor: View {
    let dog: Dog
    let trim: Trim?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var on = Date()
    @State private var menu = TrimMenu.full
    @State private var style = ""
    @State private var salon = ""
    @State private var priceText = ""
    @State private var note = ""
    @State private var photo: Data?
    @State private var confirmingDelete = false

    /// 前に行ったお店（新しい順・重なりなし）。
    private var pastSalons: [String] {
        var seen = Set<String>()
        return dog.trimHistory.map(\.salon).filter { !$0.isEmpty && seen.insert($0).inserted }.prefix(4).map { $0 }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotoSlot(data: $photo)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } footer: {
                    Text("仕上がりの写真を残しておくと、次のオーダーのときに見せられます。")
                }
                Section {
                    DatePicker("行った日", selection: $on, in: ...Date(), displayedComponents: .date)
                    Picker("メニュー", selection: $menu) {
                        ForEach(TrimMenu.allCases) { Text($0.label).tag($0) }
                    }
                }
                Section("スタイル") {
                    TextField("テディベアカット", text: $style)
                        .accessibilityIdentifier("trim-style")
                    chips(TrimStyles.presets) { style = $0 }
                }
                Section("お店") {
                    TextField("サロンの名前・おうちカット", text: $salon)
                    if !pastSalons.isEmpty { chips(pastSalons) { salon = $0 } }
                    HStack {
                        Text("料金")
                        TextField("7700", text: $priceText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("円").foregroundStyle(.secondary)
                    }
                }
                Section("メモ") {
                    TextField("耳は短めに・しっぽはまるく など", text: $note, axis: .vertical).lineLimit(2...6)
                }
                if trim != nil {
                    Section { Button("この記録を消す", role: .destructive) { confirmingDelete = true } }
                }
            }
            .navigationTitle(trim == nil ? "トリミングを記録" : "トリミング")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() } }
            }
            .confirmationDialog("このトリミングの記録を消しますか？", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("消す", role: .destructive) {
                    if let trim { context.delete(trim) }
                    try? context.save()
                    dismiss()
                }
            }
            .onAppear(perform: load)
        }
    }

    private func chips(_ words: [String], pick: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(words, id: \.self) { word in
                    Button(word) { pick(word) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        }
    }

    private func load() {
        guard let trim else { return }
        on = trim.on
        menu = trim.menu
        style = trim.style
        salon = trim.salon
        priceText = trim.price.map(String.init) ?? ""
        note = trim.note
        photo = trim.photo
    }

    private func save() {
        let target = trim ?? Trim(on: on, menu: menu, dog: dog)
        target.on = on
        target.menu = menu
        target.style = style.trimmingCharacters(in: .whitespaces)
        target.salon = salon.trimmingCharacters(in: .whitespaces)
        target.price = Int(priceText.filter(\.isNumber))
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        target.photo = photo
        if trim == nil { context.insert(target) }
        try? context.save()
        dismiss()
    }
}
