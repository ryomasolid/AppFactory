import SwiftUI

/// フラットなアセット一覧の整理画面（スクショ／動画で共用）。
/// 複数選択 → まとめて削除（OS確認）＋削減容量表示。
struct AssetCleanupView: View {
    @Bindable var viewModel: AssetGridViewModel
    let title: String
    let emptyTitle: String
    let emptyIcon: String
    /// 各セルにファイルサイズを表示する（動画向け）。
    var showsItemSize: Bool = false

    @State private var showDeletePreview = false
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.phase == .ready, !viewModel.assets.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(viewModel.isAllSelected ? "全解除" : "全選択") {
                            viewModel.toggleSelectAll()
                        }
                        .disabled(viewModel.isDeleting)
                    }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView("読み込み中…")
        case .ready:
            if viewModel.assets.isEmpty {
                ContentUnavailableView(emptyTitle, systemImage: emptyIcon)
            } else {
                grid
                    .safeAreaInset(edge: .bottom) { deleteBar }
                    .sheet(isPresented: $showDeletePreview) { preview }
                    .alert("削除しました", isPresented: $viewModel.showDeletionInfo) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("\(viewModel.lastDeletionCount) 件を削除しました。\n\n削除した項目は「最近削除した項目」に30日間残り、その間は端末の空き容量はすぐには増えません。完全に削除して容量を空けるには、写真アプリの「最近削除した項目」から削除してください。")
                    }
                    .alert("削除に失敗しました", isPresented: errorBinding) {
                        Button("OK", role: .cancel) { viewModel.deletionError = nil }
                    } message: {
                        Text(viewModel.deletionError ?? "")
                    }
            }
        }
    }

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Label("\(viewModel.assets.count) 件 ・ 合計 約 \(viewModel.formattedSize(viewModel.totalByteSize))", systemImage: "internaldrive")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.assets) { photo in
                        cell(photo)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func cell(_ photo: PhotoAsset) -> some View {
        let selected = viewModel.selection.contains(photo.id)
        return AssetThumbnailView(photo: photo, service: viewModel.service)
            .overlay(alignment: .topTrailing) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? .white : .white.opacity(0.9))
                    .background(selected ? Circle().fill(.red) : Circle().fill(.black.opacity(0.25)))
                    .padding(6)
            }
            .overlay(alignment: .bottomTrailing) {
                if showsItemSize {
                    Text(viewModel.formattedSize(viewModel.size(of: photo)))
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.5), in: Capsule())
                        .padding(6)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(selected ? Color.red : .clear, lineWidth: 3)
            }
            .opacity(selected ? 0.75 : 1)
            .contentShape(Rectangle())
            .onTapGesture { viewModel.toggle(photo.id) }
            .accessibilityLabel(selected ? "選択中" : "未選択")
    }

    private var deleteBar: some View {
        Group {
            if viewModel.selectedCount > 0 {
                Button {
                    showDeletePreview = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        VStack(spacing: 1) {
                            Text("\(viewModel.selectedCount) 件を確認して削除").fontWeight(.semibold)
                            if viewModel.selectedByteSize > 0 {
                                Text("約 \(viewModel.formattedSize(viewModel.selectedByteSize)) を削減")
                                    .font(.caption).opacity(0.9)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                }
                .disabled(viewModel.isDeleting)
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }

    private var preview: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 6)], spacing: 6) {
                    ForEach(viewModel.selectedPhotos) { photo in
                        AssetThumbnailView(photo: photo, service: viewModel.service, size: 90)
                    }
                }
                .padding()
            }
            .navigationTitle("\(viewModel.selectedCount) 件を削除")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if viewModel.selectedByteSize > 0 {
                        Label("約 \(viewModel.formattedSize(viewModel.selectedByteSize)) を削減できます", systemImage: "internaldrive")
                            .font(.subheadline.bold())
                    }
                    Text("削除した項目は「最近削除した項目」に30日間残ります。その間は端末の空き容量はすぐには増えません。")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button {
                        Task {
                            await viewModel.deleteSelected()
                            showDeletePreview = false
                        }
                    } label: {
                        HStack {
                            if viewModel.isDeleting { ProgressView().tint(.white) } else { Image(systemName: "trash") }
                            Text("\(viewModel.selectedCount) 件を削除する").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(.red, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                    .disabled(viewModel.isDeleting)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.deletionError != nil },
            set: { if !$0 { viewModel.deletionError = nil } }
        )
    }
}
