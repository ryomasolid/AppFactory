import StoreKit
import SwiftUI

/// StoreKit 2 による課金管理。Pro（買い切り・非消耗型）の購入・復元・所有判定を担う。
@MainActor
@Observable
final class StoreManager {
    /// Pro のプロダクトID（App Store Connect で同じIDの非消耗型アイテムを登録する）。
    static let proID = "tech.sesame.photocleaner.pro"

    private(set) var product: Product?
    private(set) var isPro = false
    var purchaseError: String?

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

    var priceText: String { product?.displayPrice ?? "" }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.proID]).first
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
