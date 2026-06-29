import SwiftUI

/// 整理カテゴリのホーム。重複・類似／スクリーンショット／大きい動画 を選ぶ。
struct CategoryHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    SimilarPhotosView()
                } label: {
                    row("重複・類似写真", "photo.stack", "似た写真をまとめて整理", .blue)
                }
                NavigationLink {
                    ScreenshotsView()
                } label: {
                    row("スクリーンショット", "camera.viewfinder", "溜まったスクショを一括削除", .orange)
                }
                NavigationLink {
                    LargeVideosView()
                } label: {
                    row("大きい動画", "video.fill", "容量の大きい動画から削除", .pink)
                }
            }
            .navigationTitle("PhotoCleaner")
        }
    }

    private func row(_ title: String, _ icon: String, _ subtitle: String, _ color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
