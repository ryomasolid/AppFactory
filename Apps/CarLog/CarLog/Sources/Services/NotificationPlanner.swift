import Foundation

/// 予約するメンテ通知1件。
struct PlannedMaintenanceNotification: Identifiable, Equatable, Sendable {
    /// 通知の識別子。車両とメンテ項目の組で一意。
    var id: String
    var fireDate: Date
    var title: String
    var body: String
}

/// 通知計画の入力。SwiftData のモデルを値に写してから渡す（純粋関数としてテストするため）。
struct VehicleNotificationInput: Sendable {
    var id: UUID
    var name: String
    var currentOdometer: Double
    var pace: DrivingPace?
    var fallbackDate: Date?
    var fallbackOdometer: Double
    var plans: [MaintenancePlan]
}

/// どのメンテ項目を、いつ、どんな文面で通知するかを決める。
///
/// 1項目につき**次の1回だけ**予約する。距離ベースの予測日は走り方で前後するが、
/// 給油の記録・アプリ起動のたびに組み直すので、繰り返し通知を積む必要はない。
enum NotificationPlanner {
    static func plan(
        vehicles: [VehicleNotificationInput],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [PlannedMaintenanceNotification] {
        // 2台以上登録しているときだけ、どのクルマの話かをタイトルに添える。
        let showsVehicleName = vehicles.count > 1

        return vehicles.flatMap { vehicle in
            vehicle.plans.compactMap { plan -> PlannedMaintenanceNotification? in
                guard plan.isEnabled, plan.hasInterval else { return nil }
                let status = MaintenanceDue.evaluate(
                    plan: plan,
                    currentOdometer: vehicle.currentOdometer,
                    pace: vehicle.pace,
                    fallbackDate: vehicle.fallbackDate,
                    fallbackOdometer: vehicle.fallbackOdometer,
                    now: now,
                    calendar: calendar
                )
                guard let fireDate = MaintenanceDue.notificationDate(
                    for: status, plan: plan, now: now, calendar: calendar
                ) else { return nil }

                return PlannedMaintenanceNotification(
                    id: "maintenance-\(vehicle.id.uuidString)-\(plan.id.uuidString)",
                    fireDate: fireDate,
                    title: showsVehicleName
                        ? String(localized: "\(plan.title)（\(vehicle.name)）")
                        : plan.title,
                    body: body(plan: plan, status: status, calendar: calendar)
                )
            }
        }
        .sorted { $0.fireDate < $1.fireDate }
    }

    /// 通知本文。**根拠を書く**（「いつ・何を基準に」が無い通知はオフにされる）。
    ///
    /// 走った距離は通知が届く時点では古くなっているので本文には入れず、
    /// 予定日と「何ごと・前回いつ」だけを書く。
    static func body(
        plan: MaintenancePlan, status: MaintenanceStatus, calendar: Calendar = .current
    ) -> String {
        var parts: [String] = []
        if let date = status.effectiveDate {
            let dateText = date.formatted(
                Date.FormatStyle(date: .abbreviated, time: .omitted, calendar: calendar)
                    .month(.defaultDigits).day()
            )
            // 距離からの予測日は目安なので「ごろ」を付ける。
            let isProjected = status.projectedDate != nil && status.projectedDate == date
                && status.dueDate != date
            parts.append(
                isProjected
                    ? String(localized: "\(dateText)ごろが次回の目安です。")
                    : String(localized: "\(dateText)が次回の予定です。")
            )
        }

        var basis = Formatting.interval(months: plan.intervalMonths, distance: plan.intervalDistance)
        if let last = plan.lastDoneDate {
            let lastText = last.formatted(
                Date.FormatStyle(date: .abbreviated, time: .omitted, calendar: calendar)
                    .year().month(.defaultDigits).day()
            )
            if let odometer = plan.lastDoneOdometer {
                basis += String(localized: "・前回 \(lastText) / \(Formatting.kilometers(odometer))")
            } else {
                basis += String(localized: "・前回 \(lastText)")
            }
        }
        parts.append("（\(basis)）")
        return parts.joined()
    }
}
