import PhotosUI
import SwiftData
import SwiftUI

/// プロフィールとフード・消耗品の交換サイクル。
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [HamsterProfile]
    @Query(sort: \SupplyReminder.sortOrder) private var reminders: [SupplyReminder]
    @AppStorage(NotificationSettings.remindersEnabledKey) private var remindersEnabled = false

    @State private var editingProfile = false
    @State private var editingReminder: SupplyReminder?
    @State private var notificationDenied = false

    private var profile: HamsterProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let profile {
                        profileCard(profile)
                    } else {
                        VStack(spacing: 10) {
                            Text("🐹").font(.system(size: 48))
                            Text("プロフィールを登録しよう").font(.headline)
                            Button("登録する") { editingProfile = true }.buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .card()
                    }
                    remindersSection
                }
                .padding(16)
            }
            .creamBackground()
            .navigationTitle("プロフィール")
        }
        .sheet(isPresented: $editingProfile) { ProfileEditorView(profile: profile) }
        .sheet(item: $editingReminder) { ReminderEditorView(reminder: $0) }
        .alert("通知がオフになっています", isPresented: $notificationDenied) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("設定アプリで「はむ日記」の通知を許可してください。")
        }
    }

    private func profileCard(_ profile: HamsterProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                PhotoView(path: profile.photoPath)
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name).font(.title2.bold())
                    Text(profile.species).font(.subheadline).foregroundStyle(.secondary)
                    if let birth = profile.birthDate {
                        Text(HamsterAge.text(birthDate: birth))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                Spacer()
                Button("編集") { editingProfile = true }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            if profile.birthDate != nil || profile.welcomeDate != nil {
                Divider()
                HStack(spacing: 28) {
                    if let birth = profile.birthDate { dateItem("誕生日", birth) }
                    if let welcome = profile.welcomeDate {
                        dateItem("お迎え日", welcome)
                        let days = (Calendar.current.dateComponents([.day], from: welcome, to: Date()).day ?? 0) + 1
                        VStack(alignment: .leading, spacing: 2) {
                            Text("一緒に過ごして").font(.caption).foregroundStyle(.secondary)
                            Text("\(days)日目").font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }
        }
        .card()
    }

    private func dateItem(_ title: LocalizedStringKey, _ date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(date.formatted(.dateTime.year().month(.defaultDigits).day())).font(.subheadline.weight(.semibold))
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🗓️ フード・消耗品管理").font(.headline)
            Text("交換したら「交換した」を押すと、交換日が今日になります。タップでサイクルを変えられます。")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !remindersEnabled {
                Button {
                    Task {
                        if await NotificationScheduler.shared.requestAuthorizationIfNeeded() {
                            remindersEnabled = true
                            await NotificationScheduler.shared.rebuild(context: modelContext)
                        } else {
                            notificationDenied = true
                        }
                    }
                } label: {
                    Label("交換時期を通知で受け取る", systemImage: "bell.badge")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.accent)
            }

            ForEach(reminders) { reminder in
                ReminderRow(reminder: reminder) {
                    reminder.lastDate = Calendar.current.startOfDay(for: Date())
                    try? modelContext.save()
                    Task { await NotificationScheduler.shared.rebuild(context: modelContext) }
                }
                .contentShape(Rectangle())
                .onTapGesture { editingReminder = reminder }
            }
        }
    }
}

struct ReminderRow: View {
    let reminder: SupplyReminder
    var onReset: () -> Void

    var body: some View {
        let status = ReminderStatus.evaluate(lastDate: reminder.lastDate, cycleDays: reminder.cycleDays)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(reminder.emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.name).font(.subheadline.weight(.semibold))
                    Text(status.state.label).font(.caption.weight(.medium)).foregroundStyle(status.state.color)
                }
                Spacer()
                Button("交換した", action: onReset)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .sensoryFeedback(.success, trigger: reminder.lastDate)
            }
            ProgressView(value: status.progress)
                .tint(status.state.color)
            HStack {
                Text(reminder.lastDate == nil ? String(localized: "交換日が未設定") : String(localized: "\(status.daysPassed)日経過"))
                Spacer()
                Text("目安 \(reminder.cycleDays)日ごと")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .card()
    }
}

/// 交換サイクルと前回の交換日を直す。
struct ReminderEditorView: View {
    @Bindable var reminder: SupplyReminder
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var hasDate = false
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名前", text: $reminder.name)
                    Stepper("目安 \(reminder.cycleDays)日ごと", value: $reminder.cycleDays, in: 1...365)
                }
                Section {
                    Toggle("前回の交換日を入れる", isOn: $hasDate)
                    if hasDate {
                        DatePicker("前回の交換日", selection: $date, in: ...Date(), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("\(reminder.emoji) \(reminder.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        reminder.lastDate = hasDate ? Calendar.current.startOfDay(for: date) : nil
                        try? modelContext.save()
                        Task { await NotificationScheduler.shared.rebuild(context: modelContext) }
                        dismiss()
                    }
                }
            }
            .onAppear {
                hasDate = reminder.lastDate != nil
                date = reminder.lastDate ?? Date()
            }
        }
        .presentationDetents([.medium])
    }
}

/// プロフィールの登録・編集。
struct ProfileEditorView: View {
    let profile: HamsterProfile?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var species = ""
    @State private var hasBirth = false
    @State private var birth = Date()
    @State private var hasWelcome = false
    @State private var welcome = Date()
    @State private var photoPath: String?
    @State private var newPhoto: UIImage?
    @State private var pickedItem: PhotosPickerItem?
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $pickedItem, matching: .images) {
                            Group {
                                if let newPhoto {
                                    Image(uiImage: newPhoto).resizable().scaledToFill()
                                } else {
                                    PhotoView(path: photoPath)
                                }
                            }
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "camera.circle.fill")
                                    .font(.title2)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Theme.accent)
                            }
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                Section("名前") {
                    TextField("例: ゴールくん", text: $name)
                }
                Section("種類") {
                    TextField("例: ゴールデンハムスター", text: $species)
                    FlowLayout(spacing: 6) {
                        ForEach(Defaults.species, id: \.self) { item in
                            Button { species = item } label: { ChipLabel(text: item, selected: species == item) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section {
                    Toggle("誕生日", isOn: $hasBirth)
                    if hasBirth { DatePicker("誕生日", selection: $birth, in: ...Date(), displayedComponents: .date) }
                    Toggle("お迎え日", isOn: $hasWelcome)
                    if hasWelcome { DatePicker("お迎え日", selection: $welcome, in: ...Date(), displayedComponents: .date) }
                } footer: {
                    Text("誕生日を入れると年齢を自動で表示します")
                }
            }
            .navigationTitle(profile == nil ? "プロフィールを登録" : "プロフィールを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .fontWeight(.bold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || species.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
            .onChange(of: pickedItem) { _, item in
                Task {
                    guard let item else { return }
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        newPhoto = image
                    }
                    pickedItem = nil
                }
            }
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let profile else { return }
        name = profile.name
        species = profile.species
        hasBirth = profile.birthDate != nil
        birth = profile.birthDate ?? Date()
        hasWelcome = profile.welcomeDate != nil
        welcome = profile.welcomeDate ?? Date()
        photoPath = profile.photoPath
    }

    private func save() {
        var path = photoPath
        if let newPhoto, let saved = PhotoStore.save(PhotoStore.resized(newPhoto, maxLength: 800)) {
            if let old = photoPath { PhotoStore.delete(old) }
            path = saved
        }
        let calendar = Calendar.current
        let target = profile ?? {
            let created = HamsterProfile(name: "", species: "")
            modelContext.insert(created)
            return created
        }()
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.species = species.trimmingCharacters(in: .whitespaces)
        target.birthDate = hasBirth ? calendar.startOfDay(for: birth) : nil
        target.welcomeDate = hasWelcome ? calendar.startOfDay(for: welcome) : nil
        target.photoPath = path
        try? modelContext.save()
        dismiss()
    }
}
