import PhotosUI
import SwiftData
import SwiftUI

/// 記録の入力・編集。体重以外はすべて任意で、よく使うごはんはテンプレートから1タップで入る。
struct RecordEditorView: View {
    let record: DiaryRecord?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PresetMeal.sortOrder) private var presetMeals: [PresetMeal]
    @Query(sort: \SingleFood.sortOrder) private var singleFoods: [SingleFood]
    @Query(sort: \CleaningOption.sortOrder) private var cleaningOptions: [CleaningOption]

    @State private var date = Calendar.current.startOfDay(for: Date())
    @State private var weightText = ""
    @State private var food = ""
    @State private var cleaningKeys: Set<String> = []
    @State private var memo = ""
    @State private var photoPath: String?
    @State private var newPhoto: UIImage?
    @State private var pickedItem: PhotosPickerItem?
    @State private var confirmDelete = false
    @State private var loaded = false
    @FocusState private var focused: Field?

    private enum Field { case weight, food, memo }

    private var isEditing: Bool { record != nil }

    /// 空なら nil、範囲外・数字でなければ .invalid。
    private var weightValue: WeightInput {
        let text = weightText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !text.isEmpty else { return .empty }
        guard let value = Double(text), (0...999.9).contains(value) else { return .invalid }
        return .value((value * 10).rounded() / 10)
    }

    private enum WeightInput: Equatable { case empty, invalid, value(Double) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    section("📅 日付") {
                        DatePicker("日付", selection: $date, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                    }
                    section("⚖️ 体重（任意）") { weightField }
                    section("🌾 ごはん（任意）") { foodField }
                    section("🧹 今日のお掃除（任意）") { cleaningField }
                    section("📷 写真・メモ（任意）") { photoAndMemo }
                    if isEditing {
                        Button("この記録を削除", role: .destructive) { confirmDelete = true }
                            .padding(.top, 4)
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .creamBackground()
            .navigationTitle(isEditing ? "記録を編集" : "記録する")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "更新" : "保存", action: save)
                        .fontWeight(.bold)
                        .disabled(weightValue == .invalid)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { focused = nil }
                }
            }
            .confirmationDialog("この記録を削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("削除", role: .destructive, action: delete)
            }
        }
        .onAppear(perform: load)
        .onChange(of: pickedItem) { _, item in Task { await loadPicked(item) } }
    }

    // MARK: - 入力欄

    private var weightField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                TextField("0.0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .focused($focused, equals: .weight)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 10)
                    .background(Theme.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text("g").font(.title3.weight(.semibold)).foregroundStyle(.secondary)
            }
            if weightValue == .invalid {
                Text("0〜999.9 の範囲で入力してください").font(.caption).foregroundStyle(Theme.due)
            }
        }
    }

    private var foodField: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("ごはんの内容（例: ペレット 4g、にんじん少々）", text: $food, axis: .vertical)
                .lineLimit(3...6)
                .focused($focused, equals: .food)
                .padding(12)
                .background(Theme.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            HStack(spacing: 10) {
                Menu {
                    ForEach(presetMeals) { meal in
                        Button { append(meal.text) } label: { Text(meal.name); Text(meal.text) }
                    }
                } label: {
                    Label("献立から", systemImage: "fork.knife").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(presetMeals.isEmpty)

                Menu {
                    ForEach(singleFoods) { item in
                        Button(item.name) { append(item.name) }
                    }
                } label: {
                    Label("フードを追加", systemImage: "carrot").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(singleFoods.isEmpty)
            }
        }
    }

    private var cleaningField: some View {
        FlowLayout(spacing: 8) {
            ForEach(cleaningOptions) { option in
                let selected = cleaningKeys.contains(option.key)
                Button {
                    if selected { cleaningKeys.remove(option.key) } else { cleaningKeys.insert(option.key) }
                } label: {
                    ChipLabel(text: "\(option.emoji) \(option.name)", selected: selected)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selected)
            }
        }
    }

    private var photoAndMemo: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = newPhoto ?? PhotoStore.image(at: photoPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            newPhoto = nil
                            photoPath = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.5))
                        }
                        .padding(8)
                        .accessibilityLabel("写真を外す")
                    }
            }
            PhotosPicker(selection: $pickedItem, matching: .images) {
                Label(newPhoto == nil && photoPath == nil ? "写真を追加" : "写真を変更", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            TextField("今日の様子をメモ", text: $memo, axis: .vertical)
                .lineLimit(2...6)
                .focused($focused, equals: .memo)
                .padding(12)
                .background(Theme.softFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: memo) { _, value in
                    if value.count > 500 { memo = String(value.prefix(500)) }
                }
        }
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold))
            content()
        }
        .card()
    }

    // MARK: - 動作

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let record else { return }
        date = record.date
        weightText = record.weight.map(Formatting.weight) ?? ""
        food = record.food
        cleaningKeys = Set(record.cleaningKeys)
        memo = record.memo
        photoPath = record.photoPath
    }

    private func append(_ text: String) {
        let trimmed = food.trimmingCharacters(in: .whitespacesAndNewlines)
        food = trimmed.isEmpty ? text : "\(trimmed)\n\(text)"
    }

    private func loadPicked(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
            newPhoto = image
        }
        pickedItem = nil
    }

    private func save() {
        let weight: Double? = if case .value(let value) = weightValue { value } else { nil }
        // 並び順は設定の順。設定から消した項目のキー（画面に出ないもの）は、記録に残しておく。
        let known = Set(cleaningOptions.map(\.key))
        let keys = cleaningOptions.map(\.key).filter(cleaningKeys.contains)
            + (record?.cleaningKeys.filter { !known.contains($0) } ?? [])

        var finalPhoto = photoPath
        if let newPhoto, let saved = PhotoStore.save(newPhoto) { finalPhoto = saved }
        if let old = record?.photoPath, old != finalPhoto { PhotoStore.delete(old) }

        let day = Calendar.current.startOfDay(for: date)
        if let record {
            record.date = day
            record.weight = weight
            record.food = food.trimmingCharacters(in: .whitespacesAndNewlines)
            record.cleaningKeys = keys
            record.memo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
            record.photoPath = finalPhoto
            record.updatedAt = Date()
        } else {
            modelContext.insert(DiaryRecord(
                date: day, weight: weight, food: food.trimmingCharacters(in: .whitespacesAndNewlines),
                cleaningKeys: keys, memo: memo.trimmingCharacters(in: .whitespacesAndNewlines), photoPath: finalPhoto
            ))
        }
        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        guard let record else { return }
        PhotoStore.delete(record.photoPath)
        modelContext.delete(record)
        try? modelContext.save()
        dismiss()
    }
}
