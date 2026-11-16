import SwiftData
import SwiftUI

/// わんちゃんの登録・編集。
struct DogEditor: View {
    let dog: Dog?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Dog.order) private var dogs: [Dog]
    @AppStorage(CurrentDog.storageKey) private var currentKey = ""

    @State private var name = ""
    @State private var coat = CoatColor.apricot
    @State private var sex = DogSex.unknown
    @State private var portrait: Data?
    @State private var knowsBirthday = false
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
    @State private var knowsHomeDay = false
    @State private var homeDay = Date()
    @State private var confirmingDelete = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotoSlot(data: $portrait) { data in
                            ZStack(alignment: .bottomTrailing) {
                                ZStack {
                                    Circle().fill(Tone.apricot.opacity(0.18))
                                    if let data, let image = UIImage(data: data) {
                                        Image(uiImage: image).resizable().scaledToFill()
                                    } else {
                                        PoodleFace(coat: coat, size: 104)
                                    }
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 32))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Tone.cocoa)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                Section("おなまえ") {
                    TextField("むぎ", text: $name)
                        .accessibilityIdentifier("dog-name")
                }
                Section("毛色") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 92))], spacing: 10) {
                        ForEach(CoatColor.allCases) { color in
                            Button { coat = color } label: {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(UIColor(hex: color.hex)))
                                        .frame(width: 30, height: 30)
                                        .overlay(Circle().stroke(coat == color ? Tone.cocoa : Tone.mute.opacity(0.3), lineWidth: coat == color ? 3 : 1))
                                    Text(color.label).font(.caption2).foregroundStyle(.primary).lineLimit(1).minimumScaleFactor(0.7)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section {
                    Picker("性別", selection: $sex) {
                        ForEach(DogSex.allCases) { Text($0.label).tag($0) }
                    }
                    Toggle("お誕生日がわかる", isOn: $knowsBirthday)
                    if knowsBirthday {
                        DatePicker("お誕生日", selection: $birthday, in: ...Date(), displayedComponents: .date)
                    }
                    Toggle("うちに来た日を残す", isOn: $knowsHomeDay)
                    if knowsHomeDay {
                        DatePicker("うちに来た日", selection: $homeDay, in: ...Date(), displayedComponents: .date)
                    }
                } footer: {
                    Text("お誕生日から「人でいうと何さい」を出します。")
                }
                if dog != nil {
                    Section {
                        Button("この子の記録をすべて消す", role: .destructive) { confirmingDelete = true }
                    }
                }
            }
            .navigationTitle(dog == nil ? "うちの子を登録" : "プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(trimmedName.isEmpty)
                }
            }
            .confirmationDialog("\(dog?.name ?? "")の日記・トリミング・健康の記録がすべて消えます。", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("消す", role: .destructive) { remove() }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let dog else { return }
        name = dog.name
        coat = dog.coat
        sex = dog.sex
        portrait = dog.portrait
        if let day = dog.birthday { knowsBirthday = true; birthday = day }
        if let day = dog.homeDay { knowsHomeDay = true; homeDay = day }
    }

    private func save() {
        let target = dog ?? Dog(name: trimmedName, order: (dogs.map(\.order).max() ?? -1) + 1)
        target.name = trimmedName
        target.coat = coat
        target.sex = sex
        target.portrait = portrait
        target.birthday = knowsBirthday ? birthday : nil
        target.homeDay = knowsHomeDay ? homeDay : nil
        if dog == nil {
            context.insert(target)
            currentKey = target.key.uuidString
        }
        try? context.save()
        dismiss()
    }

    private func remove() {
        guard let dog else { return }
        if currentKey == dog.key.uuidString { currentKey = "" }
        context.delete(dog)
        try? context.save()
        dismiss()
    }
}
