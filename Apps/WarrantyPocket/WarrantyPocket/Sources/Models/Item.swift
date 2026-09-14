import Foundation
import SwiftData

/// 登録する商品（家電・持ち物）1つ。保証の起算日と期間、写真を持つ。
@Model
final class Item {
    var id: UUID = UUID()
    /// 「リビングのエアコン」など表示名（必須）。
    var name: String = ""
    var maker: String = ""
    var modelNumber: String = ""
    var serialNumber: String = ""
    var categoryRaw: String = ItemCategory.other.rawValue
    /// 保証の起算日。
    var purchaseDate: Date = Date()
    /// 購入金額（円）。
    var price: Int?
    var storeName: String = ""
    /// メーカー保証の月数。保証なしは nil。
    var warrantyMonths: Int? = 12
    /// 延長保証の月数（購入日起算）。入っていなければ nil。
    var extendedWarrantyMonths: Int?
    /// 延長保証の窓口（「購入した量販店」など）。
    var extendedWarrantyProvider: String = ""
    var note: String = ""
    /// 手放した・捨てた。通知と一覧から外すが、写真と記録は残す。
    var isArchived: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Attachment.item)
    var attachments: [Attachment] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        maker: String = "",
        modelNumber: String = "",
        serialNumber: String = "",
        category: ItemCategory = .other,
        purchaseDate: Date = Date(),
        price: Int? = nil,
        storeName: String = "",
        warrantyMonths: Int? = 12,
        extendedWarrantyMonths: Int? = nil,
        extendedWarrantyProvider: String = "",
        note: String = "",
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.maker = maker
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.categoryRaw = category.rawValue
        self.purchaseDate = purchaseDate
        self.price = price
        self.storeName = storeName
        self.warrantyMonths = warrantyMonths
        self.extendedWarrantyMonths = extendedWarrantyMonths
        self.extendedWarrantyProvider = extendedWarrantyProvider
        self.note = note
        self.isArchived = isArchived
        self.createdAt = createdAt
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
