import Foundation
import SwiftData

/// 1回の給油。
@Model
final class FuelRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    /// 給油時点の総走行距離(km)。燃費計算の基準なので必須。
    var odometer: Double = 0
    /// 給油量(L)。EV は kWh。
    var liters: Double = 0
    /// 支払総額(円)。単価はここから導出する（レシートは総額のほうが打ちやすく、丸め誤差も出ない）。
    var totalPrice: Int = 0
    /// 満タンにしたか。満タン法の区間の切れ目になる。
    var isFullTank: Bool = true
    var stationName: String = ""
    var note: String = ""

    var vehicle: Vehicle?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        odometer: Double,
        liters: Double,
        totalPrice: Int,
        isFullTank: Bool = true,
        stationName: String = "",
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.odometer = odometer
        self.liters = liters
        self.totalPrice = totalPrice
        self.isFullTank = isFullTank
        self.stationName = stationName
        self.note = note
    }

    var entry: FuelEntry {
        FuelEntry(
            id: id, date: date, odometer: odometer, liters: liters,
            totalPrice: totalPrice, isFullTank: isFullTank
        )
    }
}

/// 計算に渡す給油記録の値型スナップショット。
/// 計算ロジックを SwiftData から切り離して、純粋関数としてテストできるようにするため。
struct FuelEntry: Identifiable, Equatable, Sendable {
    var id: UUID
    var date: Date
    var odometer: Double
    var liters: Double
    var totalPrice: Int
    var isFullTank: Bool

    /// 1Lあたりの単価(円)。給油量が 0 のときは nil。
    var pricePerLiter: Double? {
        guard liters > 0 else { return nil }
        return Double(totalPrice) / liters
    }
}
