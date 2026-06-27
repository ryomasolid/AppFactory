import SwiftUI

/// 削除前のプレビュー。実際に削除する写真を一覧で確認してから OS の確認ダイアログへ進む。
struct DeletionPreviewView: View {
    @Bindable var viewModel: PhotoLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 6)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(viewModel.selectedPhotos) { photo in
                        AssetThumbnailView(photo: photo, service: viewModel.service, size: 90)
                    }
                }
                .padding()
            }
            .navigationTitle("\(viewModel.selectedCount) 枚を削除")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { footer }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Text("削除した写真は「最近削除した項目」に30日間残ります。その間は端末の空き容量はすぐには増えません。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.deleteSelected()
                    dismiss()
                }
            } label: {
                HStack {
                    if viewModel.isDeleting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "trash")
                    }
                    Text("\(viewModel.selectedCount) 枚を削除する")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
            }
            .disabled(viewModel.isDeleting)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
