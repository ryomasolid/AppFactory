import Photos
import SwiftUI

public struct ContentView: View {
    @State private var viewModel = PhotoLibraryViewModel()
    @State private var showDeletePreview = false

    public init() {}

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("PhotoCleaner")
                .toolbar {
                    if case .ready = viewModel.phase, !viewModel.groups.isEmpty {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(viewModel.isAllSelected ? "全解除" : "全選択") {
                                viewModel.toggleSelectAll()
                            }
                            .disabled(viewModel.isDeleting)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                Task { await viewModel.rescan() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .disabled(viewModel.isDeleting)
                        }
                    }
                }
        }
        .task {
            await viewModel.loadIfAuthorized()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.authorizationStatus {
        case .authorized, .limited:
            authorizedContent
        default:
            PermissionView(status: viewModel.authorizationStatus) {
                await viewModel.requestAccessAndLoad()
            }
        }
    }

    @ViewBuilder
    private var authorizedContent: some View {
        switch viewModel.phase {
        case .idle, .loading:
            ProgressView("写真を読み込み中…")
        case .scanning(let progress):
            VStack(spacing: 12) {
                ProgressView(value: progress)
                    .frame(maxWidth: 240)
                Text("類似写真を解析中… \(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        case .ready:
            if viewModel.groups.isEmpty {
                ContentUnavailableView(
                    "類似写真は見つかりませんでした",
                    systemImage: "checkmark.circle",
                    description: Text("\(viewModel.assetCount) 枚をスキャンしました")
                )
            } else {
                SimilarityGridView(viewModel: viewModel)
                    .safeAreaInset(edge: .bottom) { deleteBar }
                    .sheet(isPresented: $showDeletePreview) {
                        DeletionPreviewView(viewModel: viewModel)
                    }
                    .alert("削除しました", isPresented: $viewModel.showDeletionInfo) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("\(viewModel.lastDeletionCount) 枚を削除しました。\n\n削除した写真は「最近削除した項目」に30日間残り、その間は端末の空き容量はすぐには増えません。完全に削除して容量を空けるには、写真アプリの「最近削除した項目」から削除してください。")
                    }
                    .alert("削除に失敗しました", isPresented: errorBinding) {
                        Button("OK", role: .cancel) { viewModel.deletionError = nil }
                    } message: {
                        Text(viewModel.deletionError ?? "")
                    }
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.deletionError != nil },
            set: { if !$0 { viewModel.deletionError = nil } }
        )
    }

    @ViewBuilder
    private var deleteBar: some View {
        if viewModel.selectedCount > 0 {
            Button {
                showDeletePreview = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("\(viewModel.selectedCount) 枚を確認して削除")
                        .fontWeight(.semibold)
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

#Preview {
    ContentView()
}
