import StoreKit
import SwiftUI

/// StoreKit 2 による課金管理。Pro（買い切り・非消耗型）の購入・復元・所有判定を担う。
@MainActor
@Observable
final class StoreManager {
    /// Pro のプロダクトID（App Store Connect で同じIDの非消耗型アイテムを登録する）。
    static let proID = "tech.sesame.carlog.pro"

    private(set) var product: Product?
    private(set) var isPro = false
    private(set) var isLoadingProduct = false
    var purchaseError: String?

    /// App Review 用スクリーンショット撮影モード。実際の課金なしで課金画面を正しく表示する。
    /// （起動引数はデバッグ/シミュレータでのみ渡せるため、本番挙動には影響しない。）
    private let screenshotMode = Launch.showPaywall

    private var updatesTask: Task<Void, Never>?

    init() {
        // 別端末/再インストールでの購入反映のため、トランザクション更新を監視する。
        updatesTask = Task { [weak self] in
            for await _ in Transaction.updates {
                await self?.refreshEntitlements()
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlements()
        }
    }

    var priceText: String { screenshotMode ? "¥480" : (product?.displayPrice ?? "") }

    /// 購入ボタンを有効にできるか（＝商品が読み込めているか）。
    var canPurchase: Bool { screenshotMode || product != nil }

    func loadProduct() async {
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        do {
            let products = try await Product.products(for: [Self.proID])
            product = products.first
            if product == nil {
                // 商品が構成/承認されていない、または契約未締結だと空で返る。
                purchaseError = String(localized: "商品を読み込めませんでした。時間をおいて再度お試しください。")
            } else {
                purchaseError = nil
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    /// 購入。成功すると isPro が true になる。
    func purchase() async {
        guard let product else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    isPro = true
                    await transaction.finish()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    /// 購入の復元（機種変更・再インストール時）。
    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    /// 現在の所有権を確認して isPro を更新する。
    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        isPro = owned
    }
}
