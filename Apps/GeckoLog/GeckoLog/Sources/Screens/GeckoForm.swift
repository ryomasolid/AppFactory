import PhotosUI
import SwiftData
import SwiftUI

/// 個体の登録・編集。
struct GeckoForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Gecko.position) private var geckos: [Gecko]

    let gecko: Gecko?
    /// 「この子の記録を消す」が押された。消すのは詳細画面を閉じてから（開いたまま消すと画面が古い個体を読みに行く）。
    var onRemove: (() -> Void)?

    @State private var name = ""
    @State private var morph = ""
    @State private var sex: GeckoSex = .unknown
    @State private var knowsHatch = false
    @State private var hatchedOn = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
    @State private var knowsArrival = true
    @State private var arrivedOn = Date()
    @State private var intervalOverride = 0
    @State private var portrait: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var confirmingRemoval = false
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            VStack(spacing: 6) {
                                GeckoAvatar(name: name.isEmpty ? "🦎" : name, portrait: portrait, size: 88)
                                Text(portrait == nil ? "写真をえらぶ" : "写真をかえる").font(.caption)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                Section {
                    TextField("名前（例: もち）", text: $name)
                    TextField("モルフ（例: ハイイエロー）", text: $morph)
                    Picker("性別", selection: $sex) {
                        ForEach(GeckoSex.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Toggle("ハッチ日がわかる", isOn: $knowsHatch.animation())
                    if knowsHatch {
                        DatePicker("ハッチ日", selection: $hatchedOn, in: ...Date(), displayedComponents: .date)
                    }
                    Toggle("お迎えした日を入れる", isOn: $knowsArrival.animation())
                    if knowsArrival {
                        DatePicker("お迎え日", selection: $arrivedOn, in: ...Date(), displayedComponents: .date)
                    }
                } footer: {
                    Text("ハッチ日から ベビー（〜4か月）・ヤング（〜1歳）・アダルト を判断して、ごはんの間隔の目安に使います。わからなければアダルトとして扱います。")
                }
                Section {
                    Picker("ごはんの間隔", selection: $intervalOverride) {
                        Text("年齢に合わせる（\(suggestedInterval)日おき）").tag(0)
                        ForEach(1...10, id: \.self) { Text("\($0)日おき").tag($0) }
                    }
                } footer: {
                    Text("太りぎみ・冬場など、ショップや獣医さんの指示があればそちらに合わせてください。")
                }
                if gecko != nil {
                    Section {
                        Button("この子の記録を消す", role: .destructive) { confirmingRemoval = true }
                    }
                }
            }
            .navigationTitle(gecko == nil ? "うちの子を登録" : "プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("\(gecko?.name ?? "")の記録をすべて消しますか？", isPresented: $confirmingRemoval, titleVisibility: .visible) {
                Button("消す", role: .destructive) {
                    onRemove?()
                    dismiss()
                }
            } message: {
                Text("ごはん・脱皮・体重などの記録も一緒に消え、元に戻せません。")
            }
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(item) }
            }
            .onAppear(perform: load)
        }
    }

    private var suggestedInterval: Int {
        CareRhythm.suggestedFeedInterval(for: CareRhythm.stage(hatchedOn: knowsHatch ? hatchedOn : nil, now: Date()))
    }

    private func load() {
        guard !loaded, let gecko else { return }
        loaded = true
        name = gecko.name
        morph = gecko.morph
        sex = gecko.sex
        knowsHatch = gecko.hatchedOn != nil
        if let date = gecko.hatchedOn { hatchedOn = date }
        knowsArrival = gecko.arrivedOn != nil
        if let date = gecko.arrivedOn { arrivedOn = date }
        intervalOverride = gecko.feedIntervalOverride
        portrait = gecko.portrait
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        portrait = Self.shrink(image)
    }

    /// 丸いアイコンにしか使わないので 600px・JPEG に縮めて持つ。
    static func shrink(_ image: UIImage, side: CGFloat = 600) -> Data? {
        let scale = min(1, side / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }

    private func save() {
        let target = gecko ?? Gecko(name: "", position: (geckos.map(\.position).max() ?? -1) + 1)
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.morph = morph.trimmingCharacters(in: .whitespaces)
        target.sex = sex
        target.hatchedOn = knowsHatch ? Calendar.current.startOfDay(for: hatchedOn) : nil
        target.arrivedOn = knowsArrival ? Calendar.current.startOfDay(for: arrivedOn) : nil
        target.feedIntervalOverride = intervalOverride
        target.portrait = portrait
        if gecko == nil { context.insert(target) }
        try? context.save()
        Task { await FeedingAlarm.reschedule(context: context) }
        dismiss()
    }
}
