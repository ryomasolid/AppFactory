import SwiftUI

/// Pro へのアップグレード画面。買い切りで「大きい動画」解除＋広告非表示。
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("PhotoCleaner Pro")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 18) {
                benefit("video.fill", "大きい動画の整理", "容量を最も食う動画をサイズ順に一括削除")
                benefit("rectangle.slash", "広告を非表示", "すっきり快適に")
                benefit("infinity", "今後の追加機能", "アップデートで増える機能もすべて")
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await store.purchase(); if store.isPro { dismiss() } }
                } label: {
                    Text(store.priceText.isEmpty ? "購入する" : "\(store.priceText) で購入")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }

                Button("購入を復元") {
                    Task { await store.restore(); if store.isPro { dismiss() } }
                }
                .font(.subheadline)
            }
            .padding(.horizontal)

            Button("あとで") { dismiss() }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
    }

    private func benefit(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
