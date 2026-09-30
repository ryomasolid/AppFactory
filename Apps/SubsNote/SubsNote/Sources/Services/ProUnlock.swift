import StoreKit
import SwiftUI

/// サブスク帳 Pro（買い切り）の解放状態。
///
/// 判定は `Transaction.latest(for:)` の1件だけを見る（このアプリの商品は Pro ひとつ）。
/// 起動直後は前回の判定を `UserDefaults` から読み、StoreKit の確認が終わるまでバナーが一瞬出ないようにする。
@MainActor
@Observable
final class ProUnlock {
    static let productID = "tech.sesame.subsnote.pro"

    /// 購入画面に出す商品の状態。
    enum Offer {
        case loading
        case ready(Product)
        /// 読み込めなかった（契約・商品の未承認や通信エラー）。理由を添える。
        case unavailable(String)
    }

    private(set) var offer: Offer = .loading
    private(set) var isUnlocked: Bool
    /// 購入中・復元中はボタンを押せなくする。
    private(set) var isWorking = false

    /// スクショ撮影（`-showPaywall`）では StoreKit に触らず、価格だけ固定で見せる。
    private let isScreenshot = Launch.showPaywall
    private static let cacheKey = "sn.proUnlocked"
    private var listener: Task<Void, Never>?

    init() {
        isUnlocked = UserDefaults.standard.bool(forKey: Self.cacheKey)
        // 他の端末での購入・返金は、アプリが動いている間にここへ届く。
        listener = Task { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await self?.checkEntitlement()
            }
        }
        Task {
            await checkEntitlement()
            await loadOffer()
        }
    }

    /// 購入ボタンの価格。
    var price: String? {
        if isScreenshot { return "¥480" }
        if case .ready(let product) = offer { return product.displayPrice }
        return nil
    }

    func loadOffer() async {
        if isScreenshot { return }
        offer = .loading
        do {
            if let product = try await Product.products(for: [Self.productID]).first {
                offer = .ready(product)
            } else {
                offer = .unavailable(String(localized: "Pro の情報を取得できませんでした。少し時間をおいてからもう一度お試しください。"))
            }
        } catch {
            offer = .unavailable(error.localizedDescription)
        }
    }

    /// 購入する。解放できたら true。
    @discardableResult
    func buy() async -> Bool {
        guard case .ready(let product) = offer, !isWorking else { return false }
        isWorking = true
        defer { isWorking = false }
        do {
            if case .success(.verified(let transaction)) = try await product.purchase() {
                await transaction.finish()
                await checkEntitlement()
            }
        } catch {
            offer = .unavailable(error.localizedDescription)
        }
        return isUnlocked
    }

    /// 機種変更・再インストールのあとに、App Store と同期して解放し直す。解放できたら true。
    @discardableResult
    func restore() async -> Bool {
        guard !isWorking else { return isUnlocked }
        isWorking = true
        defer { isWorking = false }
        try? await AppStore.sync()
        await checkEntitlement()
        return isUnlocked
    }

    private func checkEntitlement() async {
        var unlocked = false
        if case .verified(let transaction) = await Transaction.latest(for: Self.productID) {
            unlocked = transaction.revocationDate == nil
        }
        isUnlocked = unlocked
        UserDefaults.standard.set(unlocked, forKey: Self.cacheKey)
    }
}
