import PhotosUI
import SwiftData
import SwiftUI

/// 追加・編集。読み取った値には「読み取り」ラベルを付けて確認を促す。
struct ItemEditorView: View {
    let item: Item?
    var onSaved: (Item) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 編集中の写真。既存の添付（attachment）か、まだ保存していない画像。
    private struct EditorImage: Identifiable {
        let id: UUID
        var thumbnailData: Data?
        var imageData: Data?
        var kind: AttachmentKind
        var attachment: Attachment?
    }

    static let warrantyPresets = [6, 12, 24, 36, 60]
    static let extendedPresets = [36, 60, 84, 120]
    /// Picker の「その他」。
    private static let customTag = -1

    @State private var name: String
    @State private var category: ItemCategory
    @State private var purchaseDate: Date
    @State private var priceText: String
    @State private var storeName: String
    @State private var warrantyChoice: Int
    @State private var warrantyCustom: Int
    @State private var extendedChoice: Int
    @State private var extendedCustom: Int
    @State private var provider: String
    @State private var maker: String
    @State private var modelNumber: String
    @State private var serialNumber: String
    @State private var note: String
    @State private var images: [EditorImage]
    @State private var readFields: Set<ReadField>
    @State private var touched: Set<ReadField> = []

    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var photoSelection: [PhotosPickerItem] = []
    @State private var isReading = false
    @FocusState private var nameFocused: Bool

    init(item: Item?, draft: ItemDraft?, onSaved: @escaping (Item) -> Void = { _ in }) {
        self.item = item
        self.onSaved = onSaved

        let (warrantyChoice, warrantyCustom) = Self.choice(for: item?.warrantyMonths ?? (item == nil ? 12 : nil), presets: Self.warrantyPresets)
        let (extendedChoice, extendedCustom) = Self.choice(for: item?.extendedWarrantyMonths, presets: Self.extendedPresets)
        _warrantyChoice = State(initialValue: warrantyChoice)
        _warrantyCustom = State(initialValue: warrantyCustom)
        _extendedChoice = State(initialValue: extendedChoice)
        _extendedCustom = State(initialValue: extendedCustom)

        if let item {
            _name = State(initialValue: item.name)
            _category = State(initialValue: item.category)
            _purchaseDate = State(initialValue: item.purchaseDate)
            _priceText = State(initialValue: item.price.map(String.init) ?? "")
            _storeName = State(initialValue: item.storeName)
            _provider = State(initialValue: item.extendedWarrantyProvider)
            _maker = State(initialValue: item.maker)
            _modelNumber = State(initialValue: item.modelNumber)
            _serialNumber = State(initialValue: item.serialNumber)
            _note = State(initialValue: item.note)
            _images = State(initialValue: item.sortedAttachments.map {
                EditorImage(id: $0.id, thumbnailData: $0.thumbnailData, imageData: nil, kind: $0.kind, attachment: $0)
            })
            _readFields = State(initialValue: [])
        } else {
            let draft = draft ?? ItemDraft()
            _name = State(initialValue: draft.name)
            _category = State(initialValue: draft.category)
            _purchaseDate = State(initialValue: draft.purchaseDate ?? Calendar.current.startOfDay(for: Date()))
            _priceText = State(initialValue: draft.price.map(String.init) ?? "")
            _storeName = State(initialValue: draft.storeName)
            _provider = State(initialValue: "")
            _maker = State(initialValue: "")
            _modelNumber = State(initialValue: "")
            _serialNumber = State(initialValue: "")
            _note = State(initialValue: "")
            _images = State(initialValue: draft.images.map {
                EditorImage(id: $0.id, thumbnailData: $0.thumbnailData, imageData: $0.imageData, kind: $0.kind)
            })
            _readFields = State(initialValue: draft.readFields)
        }
    }

    private static func choice(for months: Int?, presets: [Int]) -> (Int, Int) {
        guard let months, months > 0 else { return (0, 12) }
        return presets.contains(months) ? (months, months) : (customTag, months)
    }

    private var warrantyMonths: Int? {
        switch warrantyChoice {
        case 0: nil
        case Self.customTag: warrantyCustom
        default: warrantyChoice
        }
    }

    private var extendedMonths: Int? {
        switch extendedChoice {
        case 0: nil
        case Self.customTag: extendedCustom
        default: extendedChoice
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                basicSection
                warrantySection
                extendedSection
                detailSection
            }
            .navigationTitle(item == nil ? "商品を追加" : "編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(trimmedName.isEmpty)
                }
            }
            .photosPicker(
                isPresented: $showPhotoPicker, selection: $photoSelection, maxSelectionCount: 5, matching: .images
            )
            .onChange(of: photoSelection) { _, newValue in
                guard !newValue.isEmpty else { return }
                Task { await loadPhotos(newValue) }
            }
            .fullScreenCover(isPresented: $showScanner) {
                DocumentScannerView { scanned in
                    showScanner = false
                    Task { await addImages(scanned) }
                } onCancel: {
                    showScanner = false
                }
                .ignoresSafeArea()
            }
            .overlay {
                if isReading { ReadingOverlay() }
            }
            .onAppear {
                // 読み取り後は商品名だけが空なので、そこにフォーカスする（スクショ撮影時はキーボードを出さない）。
                if item == nil, name.isEmpty, !Launch.isDemo { nameFocused = true }
            }
        }
        .tint(Theme.accent)
    }

    // MARK: - 写真

    private var photoSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(images) { image in
                        imageTile(image)
                    }
                    addPhotoMenu
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("保証書・レシートの写真")
        } footer: {
            if !images.isEmpty {
                Text("長押しで種類の変更・削除ができます。")
            }
        }
    }

    private func imageTile(_ image: EditorImage) -> some View {
        VStack(spacing: 4) {
            Group {
                if let data = image.thumbnailData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.tertiarySystemFill)
                }
            }
            .frame(width: 78, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.primary.opacity(0.1))
            )
            Text(image.kind.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Picker("種類", selection: kindBinding(for: image.id)) {
                ForEach(AttachmentKind.allCases) { kind in
                    Label(kind.label, systemImage: kind.symbolName).tag(kind)
                }
            }
            Button(role: .destructive) {
                images.removeAll { $0.id == image.id }
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(image.kind.label))
    }

    private func kindBinding(for id: UUID) -> Binding<AttachmentKind> {
        Binding(
            get: { images.first { $0.id == id }?.kind ?? .other },
            set: { newValue in
                if let index = images.firstIndex(where: { $0.id == id }) { images[index].kind = newValue }
            }
        )
    }

    private var addPhotoMenu: some View {
        Menu {
            if DocumentScannerView.isAvailable {
                Button { showScanner = true } label: {
                    Label("書類をスキャン", systemImage: "doc.viewfinder")
                }
            }
            Button { showPhotoPicker = true } label: {
                Label("写真から選ぶ", systemImage: "photo.on.rectangle")
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                Text("追加")
                    .font(.caption)
            }
            .frame(width: 78, height: 100)
            .foregroundStyle(Theme.accent)
            .background(Theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Theme.accent.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
            .padding(.bottom, 18)
        }
    }

    // MARK: - 基本

    private var basicSection: some View {
        Section {
            TextField("商品名（例：リビングのエアコン）", text: $name)
                .font(.body.weight(.medium))
                .focused($nameFocused)
                .submitLabel(.done)

            Picker("カテゴリ", selection: $category) {
                ForEach(ItemCategory.allCases) { value in
                    Label(value.label, systemImage: value.symbolName).tag(value)
                }
            }

            DatePicker(selection: purchaseDateBinding, in: ...Date(), displayedComponents: .date) {
                fieldLabel("購入日", field: .purchaseDate)
            }

            HStack {
                fieldLabel("金額", field: .price)
                TextField("0", text: priceBinding)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("円").foregroundStyle(.secondary)
            }

            HStack {
                fieldLabel("購入店", field: .storeName)
                TextField("未入力", text: storeBinding)
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("基本")
        } footer: {
            if !readFields.isEmpty {
                Text("「読み取り」の項目は写真から自動で入れました。念のため確認してください。")
            }
        }
    }

    private func fieldLabel(_ title: LocalizedStringKey, field: ReadField) -> some View {
        HStack(spacing: 6) {
            Text(title)
            if readFields.contains(field) { ReadBadge() }
        }
    }

    /// ユーザーが触ったら「読み取り」ラベルを外し、以降の読み取りで上書きしない。
    private var purchaseDateBinding: Binding<Date> {
        Binding(
            get: { purchaseDate },
            set: {
                purchaseDate = $0
                readFields.remove(.purchaseDate)
                touched.insert(.purchaseDate)
            }
        )
    }

    private var priceBinding: Binding<String> {
        Binding(
            get: { priceText },
            set: {
                priceText = $0
                readFields.remove(.price)
                touched.insert(.price)
            }
        )
    }

    private var storeBinding: Binding<String> {
        Binding(
            get: { storeName },
            set: {
                storeName = $0
                readFields.remove(.storeName)
                touched.insert(.storeName)
            }
        )
    }

    // MARK: - 保証

    private var warrantySection: some View {
        Section {
            Picker("期間", selection: $warrantyChoice) {
                Text("なし").tag(0)
                ForEach(Self.warrantyPresets, id: \.self) { Text(Formatting.term(months: $0)).tag($0) }
                Text("その他").tag(Self.customTag)
            }
            if warrantyChoice == Self.customTag {
                Stepper(value: $warrantyCustom, in: 1...240) {
                    Text(Formatting.term(months: warrantyCustom))
                }
            }
            lastDayRow(months: warrantyMonths)
        } header: {
            Text("メーカー保証")
        } footer: {
            Text("保証書の「お買い上げ日から○年」を選んでください。多くの家電は1年です。")
        }
    }

    private var extendedSection: some View {
        Section {
            Picker("期間", selection: $extendedChoice) {
                Text("なし").tag(0)
                ForEach(Self.extendedPresets, id: \.self) { Text(Formatting.term(months: $0)).tag($0) }
                Text("その他").tag(Self.customTag)
            }
            if extendedChoice == Self.customTag {
                Stepper(value: $extendedCustom, in: 1...240) {
                    Text(Formatting.term(months: extendedCustom))
                }
            }
            if extendedMonths != nil {
                HStack {
                    Text("窓口")
                    TextField("購入したお店など", text: $provider)
                        .multilineTextAlignment(.trailing)
                }
                lastDayRow(months: extendedMonths)
            }
        } header: {
            Text("延長保証")
        } footer: {
            Text("家電量販店などの延長保証に入った場合に設定します。購入日から数えます。")
        }
    }

    @ViewBuilder
    private func lastDayRow(months: Int?) -> some View {
        if let months, let lastDay = WarrantyTerm.lastDay(purchaseDate: purchaseDate, months: months) {
            LabeledContent("最終日", value: Formatting.date(lastDay))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 詳細

    private var detailSection: some View {
        Section {
            HStack {
                Text("メーカー")
                TextField("未入力", text: $maker).multilineTextAlignment(.trailing)
            }
            HStack {
                Text("型番")
                TextField("未入力", text: $modelNumber)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }
            HStack {
                Text("シリアル番号")
                TextField("未入力", text: $serialNumber)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }
            TextField("メモ（設置場所・保証書の保管場所など）", text: $note, axis: .vertical)
                .lineLimit(2...5)
        } header: {
            Text("詳細")
        } footer: {
            Text("型番やシリアル番号は、修理の申し込みで聞かれます。本体のラベルや保証書に書かれています。")
        }
    }

    // MARK: - 処理

    private func loadPhotos(_ selection: [PhotosPickerItem]) async {
        photoSelection = []
        var loaded: [UIImage] = []
        for item in selection {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                loaded.append(image)
            }
        }
        await addImages(loaded)
    }

    /// 写真を足す。空いている項目（ユーザーが触っていない項目）にだけ読み取り結果を入れる。
    private func addImages(_ newImages: [UIImage]) async {
        guard !newImages.isEmpty else { return }
        isReading = true
        let result = await DraftBuilder.read(newImages)
        isReading = false
        images += result.images.map {
            EditorImage(id: $0.id, thumbnailData: $0.thumbnailData, imageData: $0.imageData, kind: $0.kind)
        }
        if !touched.contains(.purchaseDate), !readFields.contains(.purchaseDate), let date = result.fields.purchaseDate {
            purchaseDate = date
            readFields.insert(.purchaseDate)
        }
        if priceText.isEmpty, let price = result.fields.price {
            priceText = String(price)
            readFields.insert(.price)
        }
        if storeName.isEmpty, let store = result.fields.storeName {
            storeName = store
            readFields.insert(.storeName)
        }
    }

    private func save() {
        let target: Item
        if let item {
            target = item
        } else {
            target = Item()
            modelContext.insert(target)
        }
        target.name = trimmedName
        target.category = category
        target.purchaseDate = Calendar.current.startOfDay(for: purchaseDate)
        target.price = NumberInput.int(priceText)
        target.storeName = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        target.warrantyMonths = warrantyMonths
        target.extendedWarrantyMonths = extendedMonths
        target.extendedWarrantyProvider = extendedMonths == nil
            ? "" : provider.trimmingCharacters(in: .whitespacesAndNewlines)
        target.maker = maker.trimmingCharacters(in: .whitespacesAndNewlines)
        target.modelNumber = modelNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        target.serialNumber = serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let keptIDs = Set(images.compactMap { $0.attachment?.id })
        for attachment in Array(target.attachments) where !keptIDs.contains(attachment.id) {
            modelContext.delete(attachment)
        }
        for (order, image) in images.enumerated() {
            if let attachment = image.attachment {
                attachment.kind = image.kind
                attachment.sortOrder = order
            } else if let data = image.imageData {
                let attachment = Attachment(
                    kind: image.kind, imageData: data, thumbnailData: image.thumbnailData, sortOrder: order
                )
                modelContext.insert(attachment)
                attachment.item = target
            }
        }
        try? modelContext.save()

        let context = modelContext
        Task { await NotificationScheduler.shared.rebuild(context: context) }
        onSaved(target)
        dismiss()
    }
}
