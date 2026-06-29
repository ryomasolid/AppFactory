import SwiftUI

/// 「スクリーンショット」カテゴリ。溜まったスクショを一覧して一括削除。
struct ScreenshotsView: View {
    @State private var viewModel = AssetGridViewModel()
    @State private var loaded = false

    var body: some View {
        AssetCleanupView(
            viewModel: viewModel,
            title: "スクリーンショット",
            emptyTitle: "スクリーンショットはありません",
            emptyIcon: "camera.viewfinder"
        )
        .task {
            guard !loaded else { return }
            loaded = true
            await viewModel.load { viewModel.service.fetchScreenshots() }
        }
    }
}
