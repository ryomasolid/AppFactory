import SwiftUI

/// Pro へのアップグレード画面。買い切りで「登録無制限」「内訳」「CSV書き出し」「広告非表示」。
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("サブスク帳 Pro")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 18) {
                benefit(
                    "square.stack.3d.up.fill", "サブスクを何件でも",
                    String(localized: "無料は\(ProLimits.freeSubscriptions)件まで（解約済みは数えません）")
                )
                benefit(
                    "chart.bar.fill", "カテゴリ別・支払い方法別の内訳",
                    String(localized: "どこにいくら払っているかが分かり、見直しやすくなります")
                )
                benefit("tablecells", "CSVで書き出し", String(localized: "家計簿や表計算ソフトに"))
                benefit("rectangle.slash", "広告を非表示", String(localized: "すっきり快適に"))
            }
            .padding(.horizontal, 32)

            Text("支払日と無料体験のお知らせ、合計とカレンダーは無料版でも使えます。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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
        if store.canPurchase { return String(localized: "\(store.priceText) で購入（買い切り）") }
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
