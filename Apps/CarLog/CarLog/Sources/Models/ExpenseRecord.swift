import Foundation
import SwiftData

/// 給油以外の維持費。
@Model
final class ExpenseRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    /// `ExpenseCategory` の rawValue。
    var categoryRaw: String = ExpenseCategory.other.rawValue
    var amount: Int = 0
    /// そのときの走行距離(km)。任意（車検・整備では入れておくと履歴として役に立つ）。
    var odometer: Double?
    var note: String = ""

    var vehicle: Vehicle?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        category: ExpenseCategory,
        amount: Int,
        odometer: Double? = nil,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.categoryRaw = category.rawValue
        self.amount = amount
        self.odometer = odometer
        self.note = note
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var entry: ExpenseEntry {
        ExpenseEntry(id: id, date: date, category: category, amount: amount)
    }
}

/// 集計に渡す費用の値型スナップショット。
struct ExpenseEntry: Identifiable, Equatable, Sendable {
    var id: UUID
    var date: Date
    var category: ExpenseCategory
    var amount: Int
}
