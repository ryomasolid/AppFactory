import Foundation
import SwiftData

/// 定期的に実施するメンテナンス項目（オイル交換・車検・保険更新など）。
///
/// 期間と距離は**両方**設定できる。「6か月 または 5,000km」が実際の指定の形なので、
/// 先に来たほうを次回予定として扱う（`MaintenanceDue` が判定する）。
@Model
final class MaintenanceItem {
    var id: UUID = UUID()
    var title: String = ""
    var symbolName: String = "wrench.and.screwdriver.fill"
    /// 実施間隔（月）。距離だけで管理する項目では nil。
    var intervalMonths: Int?
    /// 実施間隔（km）。期間だけで管理する項目（車検・保険）では nil。
    var intervalDistance: Double?
    var lastDoneDate: Date?
    var lastDoneOdometer: Double?
    /// 予定日の何日前に通知するか。
    var notifyDaysBefore: Int = 7
    var notifyHour: Int = 9
    var notifyMinute: Int = 0
    var isEnabled: Bool = true
    var sortOrder: Int = 0

    var vehicle: Vehicle?

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceLog.item)
    var history: [MaintenanceLog] = []

    init(
        id: UUID = UUID(),
        title: String,
        symbolName: String = "wrench.and.screwdriver.fill",
        intervalMonths: Int? = nil,
        intervalDistance: Double? = nil,
        lastDoneDate: Date? = nil,
        lastDoneOdometer: Double? = nil,
        notifyDaysBefore: Int = 7,
        notifyHour: Int = 9,
        notifyMinute: Int = 0,
        isEnabled: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.symbolName = symbolName
        self.intervalMonths = intervalMonths
        self.intervalDistance = intervalDistance
        self.lastDoneDate = lastDoneDate
        self.lastDoneOdometer = lastDoneOdometer
        self.notifyDaysBefore = notifyDaysBefore
        self.notifyHour = notifyHour
        self.notifyMinute = notifyMinute
        self.isEnabled = isEnabled
        self.sortOrder = sortOrder
    }

    var plan: MaintenancePlan {
        MaintenancePlan(
            id: id, title: title, symbolName: symbolName,
            intervalMonths: intervalMonths, intervalDistance: intervalDistance,
            lastDoneDate: lastDoneDate, lastDoneOdometer: lastDoneOdometer,
            notifyDaysBefore: notifyDaysBefore,
            notifyHour: notifyHour, notifyMinute: notifyMinute,
            isEnabled: isEnabled
        )
    }

    /// 実施を記録して、次回予定の起点を更新する。
    func markDone(date: Date, odometer: Double?, cost: Int, note: String) -> MaintenanceLog {
        let log = MaintenanceLog(date: date, odometer: odometer, cost: cost, note: note)
        log.item = self
        history.append(log)
        lastDoneDate = date
        // 距離を入れなかったときは前回の距離を残す（上書きして nil にすると距離管理が壊れる）。
        if let odometer { lastDoneOdometer = odometer }
        return log
    }
}

/// 判定に渡すメンテ項目の値型スナップショット。
struct MaintenancePlan: Identifiable, Equatable, Sendable {
    var id: UUID
    var title: String
    var symbolName: String
    var intervalMonths: Int?
    var intervalDistance: Double?
    var lastDoneDate: Date?
    var lastDoneOdometer: Double?
    var notifyDaysBefore: Int
    var notifyHour: Int
    var notifyMinute: Int
    var isEnabled: Bool

    /// 期間・距離のどちらも設定されていない項目は予定を出しようがない。
    var hasInterval: Bool { intervalMonths != nil || intervalDistance != nil }
}
