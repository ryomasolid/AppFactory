import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @AppStorage(NotificationSettings.remindersEnabledKey) private var remindersEnabled = false
    @AppStorage(NotificationSettings.dailyEnabledKey) private var dailyEnabled = false
    @AppStorage(NotificationSettings.dailyHourKey) private var dailyHour = 20

    @State private var notificationDenied = false
    @State private var isExporting = false
    @State private var importing = false
    @State private var pendingImport: DataSnapshot?
    @State private var importPreview = DiaryData.ImportSummary()
    @State private var message: Message?

    private struct Message: Identifiable {
        var title: String
        var body: String
        var id: String { title + body }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("記録の項目") {
                    NavigationLink { CleaningOptionsEditor() } label: {
                        Label("お掃除項目", systemImage: "sparkles")
                    }
                    NavigationLink { PresetMealsEditor() } label: {
                        Label("献立テンプレート", systemImage: "fork.knife")
                    }
                    NavigationLink { SingleFoodsEditor() } label: {
                        Label("おやつ・フード", systemImage: "carrot")
                    }
                }

                Section {
                    Toggle(isOn: notificationBinding($remindersEnabled)) {
                        Label("交換時期のお知らせ", systemImage: "calendar.badge.clock")
                    }
                    Toggle(isOn: notificationBinding($dailyEnabled)) {
                        Label("毎日の記録リマインド", systemImage: "bell")
                    }
                    if dailyEnabled {
                        Picker("通知する時刻", selection: $dailyHour) {
                            ForEach(NotificationSettings.dailyHourChoices, id: \.self) { Text("\($0):00").tag($0) }
                        }
                    }
                } header: {
                    Text("通知")
                } footer: {
                    Text("交換時期のお知らせは、交換予定日の朝9時に届きます。")
                }

                Section {
                    Button(action: exportBackup) {
                        Label(isExporting ? "書き出し中…" : "データを送る", systemImage: "square.and.arrow.up")
                    }
                    .disabled(isExporting)
                    Button { importing = true } label: {
                        Label("データを取り込む", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("データ管理")
                } footer: {
                    Text("AirDrop や LINE で家族に送ったり、機種変更のバックアップに使えます。受け取ったファイルは今の日記と合体します。")
                }

                Section("はむはむ日記を応援する") {
                    Button { openURL(AppLinks.writeReviewURL) } label: {
                        Label("レビューを書く", systemImage: "star")
                    }
                    ShareLink(item: AppLinks.shareMessage) {
                        Label("ハム友にすすめる", systemImage: "heart")
                    }
                }

                Section {
                    LabeledContent("バージョン", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-")
                }
            }
            .creamBackground()
            .navigationTitle("設定")
        }
        .onChange(of: remindersEnabled) { rebuildNotifications() }
        .onChange(of: dailyEnabled) { rebuildNotifications() }
        .onChange(of: dailyHour) { rebuildNotifications() }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result { prepareImport(url) }
        }
        .alert("データを取り込む", isPresented: Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } })) {
            Button("取り込む") { runImport() }
            Button("キャンセル", role: .cancel) { pendingImport = nil }
        } message: {
            Text("\(importPreview.added)件追加、\(importPreview.updated)件を新しい内容に更新します。よろしいですか？")
        }
        .alert(item: $message) { Alert(title: Text($0.title), message: Text($0.body)) }
        .alert("通知がオフになっています", isPresented: $notificationDenied) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("設定アプリで「はむ日記」の通知を許可してください。")
        }
    }

    /// オンにするときだけ通知の許可を求める。断られていたらオンにせず、設定アプリへ案内する。
    private func notificationBinding(_ value: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { value.wrappedValue },
            set: { newValue in
                guard newValue else { value.wrappedValue = false; return }
                Task {
                    if await NotificationScheduler.shared.requestAuthorizationIfNeeded() {
                        value.wrappedValue = true
                    } else {
                        notificationDenied = true
                    }
                }
            }
        )
    }

    private func rebuildNotifications() {
        Task { await NotificationScheduler.shared.rebuild(context: modelContext) }
    }

    // MARK: - バックアップ

    private func exportBackup() {
        isExporting = true
        defer { isExporting = false }
        let file = BackupFile(snapshot: DiaryData.snapshot(modelContext, includingPhotos: true))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let stamp = DateFormatter()
        stamp.locale = Locale(identifier: "en_US_POSIX")
        stamp.dateFormat = "yyyyMMdd-HHmmss"
        // 旧版と同じ名前の付け方（hamuhamu-20260930-143000.json）。
        let name = "hamuhamu-\(stamp.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appending(path: name)
        do {
            try encoder.encode(file).write(to: url, options: .atomic)
            ActivitySheet.present([url])
        } catch {
            message = Message(title: String(localized: "エラー"), body: String(localized: "データの書き出しに失敗しました。"))
        }
    }

    private func prepareImport(_ url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(BackupFile.self, from: data) else {
            message = Message(
                title: String(localized: "エラー"),
                body: String(localized: "ファイルの形式が正しくありません。はむはむ日記のバックアップファイルを選択してください。")
            )
            return
        }
        let snapshot = file.snapshot
        importPreview = DiaryData.preview(snapshot, into: modelContext)
        if importPreview.total == 0 {
            message = Message(title: String(localized: "取り込み結果"), body: String(localized: "新しいデータはありませんでした。"))
        } else {
            pendingImport = snapshot
        }
    }

    private func runImport() {
        guard let snapshot = pendingImport else { return }
        pendingImport = nil
        do {
            let summary = try DiaryData.merge(snapshot, into: modelContext)
            rebuildNotifications()
            message = Message(title: String(localized: "完了"), body: String(localized: "\(summary.total)件のデータを取り込みました🐹"))
        } catch {
            message = Message(title: String(localized: "エラー"), body: String(localized: "データの取り込みに失敗しました。"))
        }
    }
}

/// 共有シートを一番上の画面に重ねて出す（ファイルを作ってから出すので ShareLink では間に合わない）。
@MainActor
enum ActivitySheet {
    static func present(_ items: [Any]) {
        let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              var top = scene.keyWindow?.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }
        sheet.popoverPresentationController?.sourceView = top.view
        top.present(sheet, animated: true)
    }
}

// MARK: - 項目の編集

/// 並べ替えたあと、表示順を 0,1,2… に振り直す。
private func renumber<T: Sortable>(_ items: [T], moving source: IndexSet, to destination: Int) {
    var reordered = items
    reordered.move(fromOffsets: source, toOffset: destination)
    for (index, item) in reordered.enumerated() { item.sortOrder = index }
}

struct CleaningOptionsEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CleaningOption.sortOrder) private var options: [CleaningOption]
    @State private var editing: CleaningOption?
    @State private var adding = false

    var body: some View {
        List {
            ForEach(options) { option in
                Button { editing = option } label: {
                    Text("\(option.emoji)  \(option.name)").foregroundStyle(.primary)
                }
            }
            .onMove { renumber(options, moving: $0, to: $1); try? modelContext.save() }
            .onDelete { offsets in
                offsets.map { options[$0] }.forEach(modelContext.delete)
                try? modelContext.save()
            }
            Button("項目を追加", systemImage: "plus") { adding = true }
        }
        .creamBackground()
        .navigationTitle("お掃除項目")
        .toolbar { EditButton() }
        .sheet(item: $editing) { option in
            TextPairEditor(title: "お掃除項目", first: ("絵文字", option.emoji), second: ("項目名", option.name), firstLimit: 2) { emoji, name in
                option.emoji = emoji.isEmpty ? "🧹" : emoji
                option.name = name
                try? modelContext.save()
            }
        }
        .sheet(isPresented: $adding) {
            TextPairEditor(title: "お掃除項目を追加", first: ("絵文字", ""), second: ("項目名", ""), firstLimit: 2) { emoji, name in
                modelContext.insert(CleaningOption(name: name, emoji: emoji.isEmpty ? "🧹" : emoji, sortOrder: (options.last?.sortOrder ?? -1) + 1))
                try? modelContext.save()
            }
        }
    }
}

struct PresetMealsEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PresetMeal.sortOrder) private var meals: [PresetMeal]
    @State private var editing: PresetMeal?
    @State private var adding = false

    var body: some View {
        List {
            ForEach(meals) { meal in
                Button { editing = meal } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.name).foregroundStyle(.primary)
                        Text(meal.text).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .onMove { renumber(meals, moving: $0, to: $1); try? modelContext.save() }
            .onDelete { offsets in
                offsets.map { meals[$0] }.forEach(modelContext.delete)
                try? modelContext.save()
            }
            Button("献立を追加", systemImage: "plus") { adding = true }
        }
        .creamBackground()
        .navigationTitle("献立テンプレート")
        .toolbar { EditButton() }
        .sheet(item: $editing) { meal in
            TextPairEditor(title: "献立", first: ("名前（例: いつものペレット）", meal.name), second: ("内容（例: ペレット 4g + にんじん少々）", meal.text)) { name, text in
                meal.name = name
                meal.text = text
                try? modelContext.save()
            }
        }
        .sheet(isPresented: $adding) {
            TextPairEditor(title: "献立を追加", first: ("名前（例: いつものペレット）", ""), second: ("内容（例: ペレット 4g + にんじん少々）", "")) { name, text in
                modelContext.insert(PresetMeal(name: name, text: text, sortOrder: (meals.last?.sortOrder ?? -1) + 1))
                try? modelContext.save()
            }
        }
    }
}

struct SingleFoodsEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SingleFood.sortOrder) private var foods: [SingleFood]
    @State private var newName = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("フードを追加（例: ひまわりの種）", text: $newName)
                        .onSubmit(add)
                    Button("追加", action: add)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            Section {
                ForEach(foods) { food in
                    TextField("名前", text: Bindable(food).name)
                        .onSubmit { try? modelContext.save() }
                }
                .onMove { renumber(foods, moving: $0, to: $1); try? modelContext.save() }
                .onDelete { offsets in
                    offsets.map { foods[$0] }.forEach(modelContext.delete)
                    try? modelContext.save()
                }
            }
        }
        .creamBackground()
        .navigationTitle("おやつ・フード")
        .toolbar { EditButton() }
    }

    private func add() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        modelContext.insert(SingleFood(name: name, sortOrder: (foods.last?.sortOrder ?? -1) + 1))
        try? modelContext.save()
        newName = ""
    }
}

/// 2つの文字列を入れる小さなシート（絵文字＋名前 / 名前＋内容）。
struct TextPairEditor: View {
    let title: LocalizedStringKey
    let firstPlaceholder: String
    let secondPlaceholder: String
    var firstLimit: Int?
    var onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var first: String
    @State private var second: String

    init(title: LocalizedStringKey, first: (String, String), second: (String, String), firstLimit: Int? = nil, onSave: @escaping (String, String) -> Void) {
        self.title = title
        firstPlaceholder = first.0
        secondPlaceholder = second.0
        self.firstLimit = firstLimit
        self.onSave = onSave
        _first = State(initialValue: first.1)
        _second = State(initialValue: second.1)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(firstPlaceholder, text: $first)
                    .onChange(of: first) { _, value in
                        if let firstLimit, value.count > firstLimit { first = String(value.prefix(firstLimit)) }
                    }
                TextField(secondPlaceholder, text: $second, axis: .vertical)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(first.trimmingCharacters(in: .whitespaces), second.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(requiredText.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    /// 絵文字は空でも既定が入るので、必須なのは名前の方。献立は名前・内容の両方が要る。
    private var requiredText: String {
        let secondText = second.trimmingCharacters(in: .whitespacesAndNewlines)
        if firstLimit != nil { return secondText }
        return first.trimmingCharacters(in: .whitespaces).isEmpty ? "" : secondText
    }
}
