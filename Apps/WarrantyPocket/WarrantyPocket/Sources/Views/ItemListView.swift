import PhotosUI
import SwiftData
import SwiftUI

/// 一覧（ホーム）。保証中の件数と、検索・カテゴリ絞り込み・追加。
struct ItemListView: View {
    var onShowTimeline: () -> Void = {}

    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Query(sort: \Item.createdAt, order: .reverse) private var allItems: [Item]

    @State private var searchText = Launch.searchText ?? ""
    @State private var category: ItemCategory?
    @State private var path: [Item] = []
    @State private var adder = ItemAdder()

    private var activeItems: [Item] { allItems.filter { !$0.isArchived } }

    private var filteredItems: [Item] {
        activeItems.filter { item in
            (category == nil || item.category == category) && item.matches(searchText)
        }
    }

    /// 登録済みのカテゴリだけをチップに出す（使っていないカテゴリで横に長くしない）。
    private var usedCategories: [ItemCategory] {
        let used = Set(activeItems.map(\.category))
        return ItemCategory.allCases.filter(used.contains)
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if searchText.isEmpty, !activeItems.isEmpty {
                    summary
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }
                if usedCategories.count > 1 {
                    categoryChips
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Section {
                    ForEach(filteredItems) { item in
                        NavigationLink(value: item) {
                            ItemRow(item: item)
                        }
                    }
                } footer: {
                    // 上限が近づいてから知らせる（最初から「あと○件」を出すと、使う前に制限を意識させてしまう）。
                    if searchText.isEmpty, !Launch.isDemo,
                       let remaining = ProLimits.remainingItems(currentCount: allItems.count, isPro: store.isPro),
                       remaining <= 3 {
                        Text("無料版であと\(remaining)件登録できます（手放した商品を含めて\(ProLimits.freeItems)件まで）。")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay { emptyState }
            .navigationTitle("保証書ポケット")
            .searchable(text: $searchText, prompt: Text("商品名・メーカー・型番"))
            .navigationDestination(for: Item.self) { ItemDetailView(item: $0) }
            .safeAreaInset(edge: .bottom) {
                if !activeItems.isEmpty {
                    HStack {
                        Spacer()
                        addMenu { addButtonLabel }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            .itemAdder(adder, itemCount: allItems.count) { saved in
                path = [saved]
            }
            .task(id: allItems.count) {
                // スクショ撮影用: デモ投入後に詳細画面を開く。
                if Launch.showDetail, path.isEmpty,
                   let item = activeItems.first(where: { $0.name == Launch.demoDetailName }) {
                    path = [item]
                }
            }
        }
    }

    // MARK: - 上部のまとめ

    private var summary: some View {
        let statuses = activeItems.map { $0.overallStatus() }
        let covered = statuses.filter(\.isCovered).count
        let soon = statuses.filter { $0.state == .soon }.count

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("保証中", systemImage: "checkmark.shield.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WarrantyState.active.color)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(covered)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("件").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .card(padding: 14)

            Button(action: onShowTimeline) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("まもなく終了", systemImage: "clock.badge.exclamationmark.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(soon > 0 ? WarrantyState.soon.color : .secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(soon)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("件").font(.subheadline).foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .card(padding: 14)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("期限の一覧を開きます"))
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: String(localized: "すべて"), isSelected: category == nil) { category = nil }
                ForEach(usedCategories) { value in
                    chip(title: value.label, isSelected: category == value) {
                        category = category == value ? nil : value
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(
                    isSelected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - 追加

    private func addMenu(@ViewBuilder label: () -> some View) -> some View {
        Menu {
            if DocumentScannerView.isAvailable {
                Button { adder.start(.scan, itemCount: allItems.count, isPro: store.isPro) } label: {
                    Label("書類をスキャン", systemImage: "doc.viewfinder")
                }
            }
            Button { adder.start(.photos, itemCount: allItems.count, isPro: store.isPro) } label: {
                Label("写真から選ぶ", systemImage: "photo.on.rectangle")
            }
            Button { adder.start(.manual, itemCount: allItems.count, isPro: store.isPro) } label: {
                Label("手で入力", systemImage: "square.and.pencil")
            }
        } label: {
            label()
        }
    }

    private var addButtonLabel: some View {
        Label("撮影して追加", systemImage: "camera.fill")
            .font(.headline)
            .padding(.horizontal, 22)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(Theme.accent, in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
    }

    // MARK: - 空の状態

    @ViewBuilder
    private var emptyState: some View {
        if activeItems.isEmpty {
            VStack(spacing: 18) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                Text("まずは最近買った家電のレシートを撮ってみましょう")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("購入日と金額を読み取って入力します。保証が切れる前にお知らせします。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                addMenu { PrimaryButtonLabel(title: "撮影して追加", systemImage: "camera.fill") }
                    .padding(.top, 6)
            }
            .padding(32)
        } else if filteredItems.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }
}

/// 一覧の1行。
struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView(data: item.sortedAttachments.first?.thumbnailData, category: item.category, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text("\(Formatting.date(item.purchaseDate)) 購入")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            StatusBadge(status: item.overallStatus())
        }
        .padding(.vertical, 2)
    }
}
