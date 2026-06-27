import SwiftUI

/// 類似グループの一覧。各グループ内で「残す1枚」を選び、それ以外を削除候補として選択できる。
struct SimilarityGridView: View {
    @Bindable var viewModel: PhotoLibraryViewModel

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header

                ForEach(viewModel.groups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(group.count) 枚の類似写真")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(group.members) { photo in
                                SelectableThumbnail(
                                    photo: photo,
                                    service: viewModel.service,
                                    isKeep: group.keepCandidateID == photo.id,
                                    isSelected: group.selectedForDeletion.contains(photo.id),
                                    onTap: { viewModel.toggleSelection(photo.id, inGroup: group.id) },
                                    onSetKeep: { viewModel.setKeep(photo.id, inGroup: group.id) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("各グループで残す1枚以外を選んで削除できます。タップで選択を切り替え、長押しで「残す」を変更します。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

/// 削除候補の選択状態と「残す」バッジを表示するサムネイル。
private struct SelectableThumbnail: View {
    let photo: PhotoAsset
    let service: PhotoLibraryService
    let isKeep: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onSetKeep: () -> Void

    var body: some View {
        AssetThumbnailView(photo: photo, service: service)
            .overlay(alignment: .topTrailing) { selectionBadge }
            .overlay(alignment: .bottomLeading) { keepBadge }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.red : .clear, lineWidth: 3)
            }
            .opacity(isSelected ? 0.7 : 1)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .onLongPressGesture { onSetKeep() }
            .accessibilityLabel(isKeep ? "残す写真" : (isSelected ? "削除対象として選択中" : "未選択"))
    }

    @ViewBuilder
    private var selectionBadge: some View {
        if isKeep {
            EmptyView()
        } else {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? .white : .white.opacity(0.9))
                .background(isSelected ? Circle().fill(.red) : Circle().fill(.black.opacity(0.25)))
                .padding(6)
        }
    }

    @ViewBuilder
    private var keepBadge: some View {
        if isKeep {
            Text("残す")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(.green))
                .padding(6)
        }
    }
}
