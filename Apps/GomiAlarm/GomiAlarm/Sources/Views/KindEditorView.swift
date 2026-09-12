import SwiftUI

/// ゴミの種類の編集。名前・色・アイコン・メモ・収集の周期・通知時刻をここで完結させる。
///
/// 編集は `KindDraft`（値型）の上で行い、「保存」を押したときだけモデルに書き戻す。
/// 途中でキャンセルしても、作りかけの種類やルールが残らない。
struct KindEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let title: LocalizedStringKey
    let onSave: (KindDraft) -> Void
    let onDelete: (() -> Void)?

    @State private var draft: KindDraft
    @State private var editingRule: RuleIndex?
    @State private var isAddingRule = false
    @State private var showDeleteConfirmation = false

    /// シートで開き直すために、編集中のルールの位置を Identifiable にしたもの。
    private struct RuleIndex: Identifiable, Equatable {
        let id: Int
    }

    init(
        title: LocalizedStringKey,
        draft: KindDraft,
        onSave: @escaping (KindDraft) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.onSave = onSave
        self.onDelete = onDelete
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                appearanceSection
                rulesSection
                notificationSection
                if onDelete != nil { deleteSection }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!draft.isValid)
                }
            }
            .sheet(isPresented: $isAddingRule) {
                RuleEditorView(spec: nil) { spec in
                    draft.specs.append(spec)
                }
            }
            .sheet(item: $editingRule) { target in
                RuleEditorView(
                    spec: draft.specs[target.id],
                    onSave: { spec in draft.specs[target.id] = spec },
                    onDelete: { draft.specs.remove(at: target.id) }
                )
            }
            .confirmationDialog(
                "この種類を削除しますか？",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("登録した収集の周期と通知も一緒に削除されます。")
            }
        }
        .tint(Theme.accent)
    }

    // MARK: - セクション

    private var nameSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: draft.symbolName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Color(hex: draft.colorHex),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                TextField("名前（例: 燃えるゴミ）", text: $draft.name)
                    .font(.body)
            }
            TextField("分別メモ（例: キャップは外す）", text: $draft.note)
        } footer: {
            Text("メモは通知にも表示されます。")
        }
    }

    private var appearanceSection: some View {
        Section("色とアイコン") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                ForEach(KindPalette.colors, id: \.self) { hex in
                    Button {
                        draft.colorHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(height: 36)
                            .overlay {
                                if draft.colorHex == hex {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("色")
                    .accessibilityAddTraits(draft.colorHex == hex ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(.vertical, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                ForEach(KindPalette.symbols, id: \.self) { symbol in
                    Button {
                        draft.symbolName = symbol
                    } label: {
                        Image(systemName: symbol)
                            .font(.headline)
                            .frame(height: 36)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(draft.symbolName == symbol ? Color.white : Color.primary)
                            .background(
                                draft.symbolName == symbol
                                    ? Color(hex: draft.colorHex) : Color(.tertiarySystemFill),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("アイコン")
                    .accessibilityAddTraits(draft.symbolName == symbol ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var rulesSection: some View {
        Section {
            ForEach(Array(draft.specs.enumerated()), id: \.offset) { index, spec in
                Button {
                    editingRule = RuleIndex(id: index)
                } label: {
                    HStack {
                        Text(spec.isValid ? spec.summary : String(localized: "未設定の周期"))
                            .foregroundStyle(spec.isValid ? .primary : .secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                // 周期の要約は「内容」なので、ボタンの色で染めない（追加ボタンは色付きのまま）。
                .buttonStyle(.plain)
            }
            .onDelete { draft.specs.remove(atOffsets: $0) }

            Button {
                isAddingRule = true
            } label: {
                Label("収集の周期を追加", systemImage: "plus")
            }
        } header: {
            Text("収集の周期")
        } footer: {
            if draft.specs.isEmpty {
                Text("収集の周期を1つ以上登録すると保存できます。")
            } else {
                Text("複数の周期を登録できます（例: 毎週 月・木 と 第2・第4 水曜）")
            }
        }
    }

    private var notificationSection: some View {
        Section {
            Toggle("前夜の時刻を変える", isOn: overrideBinding(for: .evening))
            if draft.eveningTime != nil {
                DatePicker("前夜", selection: timeBinding(for: .evening), displayedComponents: .hourAndMinute)
            }
            Toggle("当日朝の時刻を変える", isOn: overrideBinding(for: .morning))
            if draft.morningTime != nil {
                DatePicker("当日朝", selection: timeBinding(for: .morning), displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("通知")
        } footer: {
            let settings = NotificationSettings.load()
            Text("変えない場合は設定の既定（前夜 \(settings.eveningTime.label) ／ 当日朝 \(settings.morningTime.label)）で通知します。")
        }
    }

    private var deleteSection: some View {
        Section {
            Button("この種類を削除", role: .destructive) {
                showDeleteConfirmation = true
            }
        }
    }

    // MARK: - 通知時刻の上書き

    private func overrideBinding(for timing: NotificationTiming) -> Binding<Bool> {
        Binding(
            get: {
                switch timing {
                case .evening: return draft.eveningTime != nil
                case .morning: return draft.morningTime != nil
                }
            },
            set: { isOn in
                let settings = NotificationSettings.load()
                switch timing {
                case .evening:
                    draft.eveningTime = isOn ? (draft.eveningTime ?? settings.eveningTime) : nil
                case .morning:
                    draft.morningTime = isOn ? (draft.morningTime ?? settings.morningTime) : nil
                }
            }
        )
    }

    private func timeBinding(for timing: NotificationTiming) -> Binding<Date> {
        Binding(
            get: {
                let settings = NotificationSettings.load()
                let time: TimeOfDay
                switch timing {
                case .evening: time = draft.eveningTime ?? settings.eveningTime
                case .morning: time = draft.morningTime ?? settings.morningTime
                }
                return time.date(on: Date()) ?? Date()
            },
            set: { date in
                switch timing {
                case .evening: draft.eveningTime = TimeOfDay(date)
                case .morning: draft.morningTime = TimeOfDay(date)
                }
            }
        )
    }
}

#Preview("新規") {
    KindEditorView(title: "種類を追加", draft: KindDraft()) { _ in }
}

#Preview("編集") {
    var draft = KindDraft()
    draft.name = "資源ごみ"
    draft.colorHex = KindPalette.colors[3]
    draft.symbolName = KindPalette.symbols[1]
    draft.note = "新聞は紐でしばる"
    draft.specs = [
        RuleSpec(frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth])
    ]
    return KindEditorView(title: "種類を編集", draft: draft, onSave: { _ in }, onDelete: {})
}
