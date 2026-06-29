import SwiftUI

/// 「大きい動画」カテゴリ。動画をサイズの大きい順に並べて削除。容量削減のインパクト大。
struct LargeVideosView: View {
    @State private var viewModel = AssetGridViewModel()
    @State private var loaded = false

    var body: some View {
        AssetCleanupView(
            viewModel: viewModel,
            title: "大きい動画",
            emptyTitle: "動画はありません",
            emptyIcon: "video.slash",
            showsItemSize: true
        )
        .task {
            guard !loaded else { return }
            loaded = true
            await viewModel.load(sortBySize: true) { viewModel.service.fetchVideos() }
        }
    }
}
