import Foundation
import SwiftData

/// メンテナンスの実施履歴。「いつ・何kmで・いくらかかったか」。
@Model
final class MaintenanceLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var odometer: Double?
    var cost: Int = 0
    var note: String = ""

    var item: MaintenanceItem?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        odometer: Double? = nil,
        cost: Int = 0,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.odometer = odometer
        self.cost = cost
        self.note = note
    }
}
