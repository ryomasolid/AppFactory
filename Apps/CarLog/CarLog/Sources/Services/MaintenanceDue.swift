import Foundation

/// メンテ項目の切迫度。
enum DueState: String, Equatable, Sendable {
    /// 予定日を過ぎた、または予定距離を超えた。
    case overdue
    /// 通知日数以内、または残り距離がインターバルの10%以内。
    case soon
    case ok
}

/// メンテ項目の次回予定と状態。
struct MaintenanceStatus: Identifiable, Equatable, Sendable {
    var id: UUID
    /// 期間から出した次回予定日。距離だけで管理する項目では nil。
    var dueDate: Date?
    /// 距離から出した次回予定距離(km)。期間だけの項目では nil。
    var dueOdometer: Double?
    /// 予定距離に到達する予測日。走行ペースが出ないときは nil。
    var projectedDate: Date?
    /// 通知・表示の基準になる日。`dueDate` と `projectedDate` の早いほう。
    var effectiveDate: Date?
    /// 今日から `effectiveDate` までの日数（過ぎていれば負）。
    var remainingDays: Int?
    /// 予定距離までの残り(km)（超えていれば負）。
    var remainingDistance: Double?
    var state: DueState
}

/// 前回実施＋インターバルから次回予定を出し、期間と距離の早いほうを採用する。
enum MaintenanceDue {
    /// 残り距離がインターバルのこの割合を切ったら「もうすぐ」。
    static let soonDistanceRatio = 0.1

    static func evaluate(
        plan: MaintenancePlan,
        currentOdometer: Double,
        pace: DrivingPace?,
        fallbackDate: Date?,
        fallbackOdometer: Double,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> MaintenanceStatus {
        let today = calendar.startOfDay(for: now)

        // 前回実施が未入力なら、クルマの起点（初度登録／記録開始時の距離）から数える。
        let baseDate = plan.lastDoneDate ?? fallbackDate
        let baseOdometer = plan.lastDoneOdometer ?? fallbackOdometer

        let dueDate: Date? = {
            guard let months = plan.intervalMonths, let baseDate else { return nil }
            return calendar.date(
                byAdding: .month, value: months, to: calendar.startOfDay(for: baseDate)
            )
        }()

        let dueOdometer: Double? = plan.intervalDistance.map { baseOdometer + $0 }

        let projectedDate: Date? = dueOdometer.flatMap {
            OdometerProjection.dateReaching(
                $0, currentOdometer: currentOdometer, pace: pace, from: today, calendar: calendar
            )
        }

        let effectiveDate = [dueDate, projectedDate].compactMap { $0 }.min()
        let remainingDays = effectiveDate.flatMap {
            calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: $0)).day
        }
        let remainingDistance = dueOdometer.map { $0 - currentOdometer }

        let state = state(
            plan: plan, today: today, calendar: calendar,
            dueDate: dueDate, dueOdometer: dueOdometer, projectedDate: projectedDate,
            remainingDistance: remainingDistance
        )

        return MaintenanceStatus(
            id: plan.id,
            dueDate: dueDate,
            dueOdometer: dueOdometer,
            projectedDate: projectedDate,
            effectiveDate: effectiveDate,
            remainingDays: remainingDays,
            remainingDistance: remainingDistance,
            state: state
        )
    }

    private static func state(
        plan: MaintenancePlan,
        today: Date,
        calendar: Calendar,
        dueDate: Date?,
        dueOdometer: Double?,
        projectedDate: Date?,
        remainingDistance: Double?
    ) -> DueState {
        // 期間・距離のどちらも設定されていない項目は、判定しようがないので ok 扱い。
        guard plan.hasInterval else { return .ok }

        if let dueDate, calendar.startOfDay(for: dueDate) < today { return .overdue }
        if let remainingDistance, dueOdometer != nil, remainingDistance <= 0 { return .overdue }

        func isWithinNotice(_ date: Date?) -> Bool {
            guard let date,
                  let days = calendar.dateComponents(
                      [.day], from: today, to: calendar.startOfDay(for: date)
                  ).day
            else { return false }
            return days <= plan.notifyDaysBefore
        }

        if isWithinNotice(dueDate) || isWithinNotice(projectedDate) { return .soon }
        if let remainingDistance, let interval = plan.intervalDistance,
           interval > 0, remainingDistance <= interval * soonDistanceRatio {
            return .soon
        }
        return .ok
    }

    /// 通知を出す日時。予定日の `notifyDaysBefore` 日前の指定時刻。
    ///
    /// その時刻がすでに過ぎている場合は予定日当日の同時刻に寄せる。
    /// それも過ぎているなら nil（通知は出さず、画面の「期限切れ」バッジで伝える）。
    static func notificationDate(
        for status: MaintenanceStatus,
        plan: MaintenancePlan,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        guard plan.isEnabled, let effectiveDate = status.effectiveDate else { return nil }

        func time(onDayOffsetBy offset: Int, from date: Date) -> Date? {
            guard let day = calendar.date(
                byAdding: .day, value: offset, to: calendar.startOfDay(for: date)
            ) else { return nil }
            return calendar.date(
                bySettingHour: plan.notifyHour, minute: plan.notifyMinute, second: 0, of: day
            )
        }

        if let early = time(onDayOffsetBy: -plan.notifyDaysBefore, from: effectiveDate), early > now {
            return early
        }
        if let onDay = time(onDayOffsetBy: 0, from: effectiveDate), onDay > now {
            return onDay
        }
        return nil
    }
}
