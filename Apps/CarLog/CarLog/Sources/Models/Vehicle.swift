import Foundation
import SwiftData

/// 登録したクルマ。給油・費用・メンテ項目はすべてこの下にぶら下がる。
@Model
final class Vehicle {
    /// 通知の識別子や CSV のキーに使うので、SwiftData の永続IDとは別に安定したIDを持つ。
    var id: UUID = UUID()
    var name: String = ""
    /// メーカー・車種。表示用の自由記述で、計算には使わない。
    var makerModel: String = ""
    var colorHex: String = VehiclePalette.colors[0]
    var symbolName: String = VehiclePalette.symbols[0]
    /// `FuelType` の rawValue。SwiftData に enum を直接持たせない（マイグレーションが固くなるため）。
    var fuelTypeRaw: String = FuelType.regular.rawValue
    /// タンク容量(L)。給油量の打ち間違い検知だけに使う任意項目。
    var tankCapacity: Double?
    /// 記録を始めた時点の走行距離(km)。メンテの起点にもなる。
    var purchaseOdometer: Double = 0
    /// 初度登録年月。車検（初回3年・以降2年）の起算日。
    var firstRegistrationDate: Date?
    var isDefault: Bool = false
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \FuelRecord.vehicle)
    var fuelRecords: [FuelRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \ExpenseRecord.vehicle)
    var expenses: [ExpenseRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceItem.vehicle)
    var maintenanceItems: [MaintenanceItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        makerModel: String = "",
        colorHex: String = VehiclePalette.colors[0],
        symbolName: String = VehiclePalette.symbols[0],
        fuelType: FuelType = .regular,
        tankCapacity: Double? = nil,
        purchaseOdometer: Double = 0,
        firstRegistrationDate: Date? = nil,
        isDefault: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.makerModel = makerModel
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.fuelTypeRaw = fuelType.rawValue
        self.tankCapacity = tankCapacity
        self.purchaseOdometer = purchaseOdometer
        self.firstRegistrationDate = firstRegistrationDate
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var fuelType: FuelType {
        get { FuelType(rawValue: fuelTypeRaw) ?? .regular }
        set { fuelTypeRaw = newValue.rawValue }
    }

    /// 現在の走行距離。記録があれば最大の odometer、無ければ記録開始時の値。
    var currentOdometer: Double {
        let fromFuel = fuelRecords.map(\.odometer).max() ?? 0
        let fromExpense = expenses.compactMap(\.odometer).max() ?? 0
        let fromLogs = maintenanceItems.flatMap(\.history).compactMap(\.odometer).max() ?? 0
        return max(purchaseOdometer, max(fromFuel, max(fromExpense, fromLogs)))
    }

    /// 記録開始からの走行距離。
    var traveledDistance: Double { max(0, currentOdometer - purchaseOdometer) }

    var fuelEntries: [FuelEntry] { fuelRecords.map(\.entry) }
    var expenseEntries: [ExpenseEntry] { expenses.map(\.entry) }
    var maintenancePlans: [MaintenancePlan] { maintenanceItems.map(\.plan) }
}
