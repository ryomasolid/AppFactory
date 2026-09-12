import SwiftUI

/// Pro へのアップグレード画面。買い切りで「種類の無制限登録」＋広告非表示。
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("ゴミの日アラーム Pro")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 18) {
                benefit(
                    "infinity", "ゴミの種類を無制限に",
                    "無料は\(ProLimits.freeKinds)つまで。粗大ごみや資源も追加できます"
                )
                benefit("rectangle.slash", "広告を非表示", "すっきり快適に")
                benefit("sparkles", "今後の追加機能", "アップデートで増える機能もすべて")
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                if store.isPro {
                    Label("Pro を利用中です", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                } else {
                    Button {
                        Task {
                            await store.purchase()
                            if store.isPro { dismiss() }
                        }
                    } label: {
                        Text(purchaseButtonTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                store.canPurchase
                                    ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.gray),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .foregroundStyle(.white)
                    }
                    .disabled(!store.canPurchase)

                    // 商品の読み込みに失敗したときは、理由の表示と再読み込みの手段を用意する。
                    if !store.canPurchase, !store.isLoadingProduct {
                        if let error = store.purchaseError {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Button("再読み込み") {
                            Task { await store.loadProduct() }
                        }
                        .font(.subheadline)
                    }

                    Button("購入を復元") {
                        Task {
                            await store.restore()
                            if store.isPro { dismiss() }
                        }
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal)

            Button("あとで") { dismiss() }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
        .tint(Theme.accent)
        .task {
            // 初回の読み込みに失敗していても、画面表示時に再取得を試みる。
            if store.product == nil { await store.loadProduct() }
        }
    }

    private var purchaseButtonTitle: String {
        if store.canPurchase { return String(localized: "\(store.priceText) で購入") }
        return store.isLoadingProduct
            ? String(localized: "購入を準備中…")
            : String(localized: "購入を読み込めませんでした")
    }

    private func benefit(_ icon: String, _ title: LocalizedStringKey, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
