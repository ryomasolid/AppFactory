import Foundation

/// 画面と通知で共通に使う、クルマ単位の計算の入口。
extension Vehicle {
    var sortedFuelRecords: [FuelRecord] {
        fuelRecords.sorted { $0.date == $1.date ? $0.odometer > $1.odometer : $0.date > $1.date }
    }

    var sortedMaintenanceItems: [MaintenanceItem] {
        maintenanceItems.sorted { $0.sortOrder == $1.sortOrder ? $0.title < $1.title : $0.sortOrder < $1.sortOrder }
    }

    var pace: DrivingPace? { OdometerProjection.pace(for: fuelEntries) }

    /// 各メンテ項目の次回予定。ペースの計算を項目ごとにやり直さないよう、まとめて出す。
    func maintenanceStatuses(now: Date = Date()) -> [UUID: MaintenanceStatus] {
        let pace = pace
        let odometer = currentOdometer
        return Dictionary(uniqueKeysWithValues: maintenanceItems.map { item in
            (item.id, MaintenanceDue.evaluate(
                plan: item.plan,
                currentOdometer: odometer,
                pace: pace,
                fallbackDate: firstRegistrationDate,
                fallbackOdometer: purchaseOdometer,
                now: now
            ))
        })
    }

    var notificationInput: VehicleNotificationInput {
        VehicleNotificationInput(
            id: id,
            name: name,
            currentOdometer: currentOdometer,
            pace: pace,
            fallbackDate: firstRegistrationDate,
            fallbackOdometer: purchaseOdometer,
            plans: maintenancePlans
        )
    }

    /// CSV 用の行。
    var csvRows: [CSVRow] {
        let fuel = fuelRecords.map {
            CSVRow(
                kind: .fuel, date: $0.date, vehicleName: name, odometer: $0.odometer,
                liters: $0.liters, amount: $0.totalPrice, isFullTank: $0.isFullTank,
                category: $0.stationName, note: $0.note
            )
        }
        let expenses = self.expenses.map {
            CSVRow(
                kind: .expense, date: $0.date, vehicleName: name, odometer: $0.odometer,
                liters: nil, amount: $0.amount, isFullTank: nil,
                category: $0.category.label, note: $0.note
            )
        }
        let logs = maintenanceItems.flatMap { item in
            item.history.map {
                CSVRow(
                    kind: .maintenance, date: $0.date, vehicleName: name, odometer: $0.odometer,
                    liters: nil, amount: $0.cost, isFullTank: nil,
                    category: item.title, note: $0.note
                )
            }
        }
        return fuel + expenses + logs
    }

    /// 選択中のクルマを解決する。保存したIDが消えていたら先頭に落とす。
    static func resolve(_ vehicles: [Vehicle], selectedID: String) -> Vehicle? {
        vehicles.first { $0.id.uuidString == selectedID } ?? vehicles.first
    }
}
