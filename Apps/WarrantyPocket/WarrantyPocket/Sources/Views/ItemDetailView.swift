import SwiftData
import SwiftUI
import UIKit

/// 詳細。壊れたときに開く画面なので、写真と「まだ保証が使えるか」を最初に出す。
struct ItemDetailView: View {
    let item: Item

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    @State private var showEditor = false
    @State private var viewer: ViewerSelection?
    @State private var confirmDelete = false
    @State private var copiedValue: String?

    struct ViewerSelection: Identifiable {
        let index: Int
        var id: Int { index }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photos
                warranties
                info
                actions
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            ItemEditorView(item: item, draft: nil).environment(store)
        }
        .fullScreenCover(item: $viewer) { selection in
            PhotoViewer(attachments: item.sortedAttachments, index: selection.index)
        }
        .confirmationDialog(
            Text("「\(item.name)」を削除しますか？"), isPresented: $confirmDelete, titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) { delete() }
        } message: {
            Text("写真も一緒に削除され、元に戻せません。手放しただけなら「手放した」にすると記録を残せます。")
        }
    }

    // MARK: - 写真

    @ViewBuilder
    private var photos: some View {
        let attachments = item.sortedAttachments
        if attachments.isEmpty {
            Button { showEditor = true } label: {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill").font(.title2)
                    Text("保証書やレシートの写真を追加").font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .foregroundStyle(Theme.accent)
                .background(Theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        } else {
            TabView {
                ForEach(Array(attachments.enumerated()), id: \.element.id) { index, attachment in
                    Button { viewer = ViewerSelection(index: index) } label: {
                        AttachmentImage(data: attachment.imageData ?? attachment.thumbnailData)
                            .overlay(alignment: .topLeading) {
                                Label(attachment.kind.label, systemImage: attachment.kind.symbolName)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .padding(10)
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption.weight(.bold))
                                    .padding(8)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .padding(10)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("\(attachment.kind.label)を拡大"))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: attachments.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(height: 300)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - 保証

    @ViewBuilder
    private var warranties: some View {
        let periods = item.periods()
        if periods.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("保証期間が設定されていません").font(.headline)
                Text("保証書の「お買い上げ日から○年」を編集で設定すると、終了前にお知らせします。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .card()
        } else {
            ForEach(periods, id: \.kind) { period in
                WarrantyCard(
                    period: period,
                    provider: period.kind == .extended ? item.extendedWarrantyProvider : ""
                )
            }
        }
    }

    // MARK: - 情報

    private var info: some View {
        VStack(spacing: 0) {
            infoRow("カテゴリ", item.category.label)
            infoRow("購入日", Formatting.date(item.purchaseDate))
            if let price = item.price { infoRow("金額", Formatting.yen(price)) }
            if !item.storeName.isEmpty { infoRow("購入店", item.storeName) }
            if !item.maker.isEmpty { infoRow("メーカー", item.maker) }
            if !item.modelNumber.isEmpty { infoRow("型番", item.modelNumber, copyable: true) }
            if !item.serialNumber.isEmpty { infoRow("シリアル番号", item.serialNumber, copyable: true) }
            if !item.note.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("メモ").font(.subheadline).foregroundStyle(.secondary)
                    Text(item.note).font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
            }
        }
        .card(padding: 14)
    }

    private func infoRow(_ title: LocalizedStringKey, _ value: String, copyable: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline).foregroundStyle(.secondary)
                Spacer(minLength: 12)
                if copyable {
                    Button {
                        UIPasteboard.general.string = value
                        copiedValue = value
                    } label: {
                        HStack(spacing: 6) {
                            Text(value).font(.body.monospaced()).foregroundStyle(.primary)
                            Image(systemName: copiedValue == value ? "checkmark" : "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("コピーします"))
                } else {
                    Text(value).font(.body).multilineTextAlignment(.trailing)
                }
            }
            .padding(.vertical, 10)
            Divider()
        }
    }

    // MARK: - 操作

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                toggleArchive()
            } label: {
                Label(
                    item.isArchived ? "一覧に戻す" : "手放した（一覧から外す）",
                    systemImage: item.isArchived ? "arrow.uturn.backward" : "archivebox"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("削除", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 4)
    }

    private func toggleArchive() {
        item.isArchived.toggle()
        try? modelContext.save()
        let context = modelContext
        Task { await NotificationScheduler.shared.rebuild(context: context) }
        if item.isArchived { dismiss() }
    }

    private func delete() {
        let target = item
        let context = modelContext
        dismiss()
        // 画面が閉じてから消す（表示中のモデルを消すと描画中に参照して落ちる）。
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            context.delete(target)
            try? context.save()
            await NotificationScheduler.shared.rebuild(context: context)
        }
    }
}

/// 保証期間1つのカード。残りのバーと最終日。
struct WarrantyCard: View {
    let period: WarrantyPeriod
    var provider: String = ""

    var body: some View {
        let status = WarrantyTerm.status(of: period)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(period.kind.label).font(.headline)
                    Text(provider.isEmpty ? Formatting.term(months: period.months) : "\(Formatting.term(months: period.months))・\(provider)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(Formatting.remaining(status))
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(status.state.color)
            }
            ProgressView(value: WarrantyTerm.elapsedFraction(of: period))
                .tint(status.state.color)
            HStack {
                Text("\(Formatting.date(period.startDate)) 購入")
                Spacer()
                Text("\(Formatting.date(period.lastDay)) まで")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// 画像データを縦横比を保って表示する。
struct AttachmentImage: View {
    let data: Data?

    var body: some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
