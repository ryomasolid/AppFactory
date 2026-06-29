import SwiftUI

/// 整理カテゴリのホーム。重複・類似／スクリーンショット／大きい動画 を選ぶ。
/// 「大きい動画」は Pro 限定で、未購入時はペイウォールへ。
struct CategoryHomeView: View {
    @Environment(StoreManager.self) private var store

    @State private var path: [Category] = []
    @State private var showPaywall = false

    enum Category: Hashable { case similar, screenshots, videos }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: Category.similar) {
                    row("重複・類似写真", "photo.stack", "似た写真をまとめて整理", .blue, pro: false)
                }
                NavigationLink(value: Category.screenshots) {
                    row("スクリーンショット", "camera.viewfinder", "溜まったスクショを一括削除", .orange, pro: false)
                }
                NavigationLink(value: Category.videos) {
                    row("大きい動画", "video.fill", "容量の大きい動画から削除", .pink, pro: !store.isPro)
                }
            }
            .navigationTitle("PhotoCleaner")
            .navigationDestination(for: Category.self) { category in
                switch category {
                case .similar: SimilarPhotosView()
                case .screenshots: ScreenshotsView()
                case .videos:
                    if store.isPro { LargeVideosView() } else { PaywallView() }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if store.isPro {
                        Label("PRO", systemImage: "crown.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.yellow)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Pro", systemImage: "crown")
                        }
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .safeAreaInset(edge: .bottom) {
                // 無料ユーザーにはバナー広告を表示（Pro で非表示）。
                if !store.isPro {
                    BannerAdView()
                        .frame(height: 50)
                }
            }
        }
    }

    private func row(_ title: String, _ icon: String, _ subtitle: String, _ color: Color, pro: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.headline)
                    if pro {
                        Text("PRO")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.yellow, in: Capsule())
                    }
                }
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
