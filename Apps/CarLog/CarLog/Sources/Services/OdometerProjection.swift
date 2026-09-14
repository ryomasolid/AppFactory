import Foundation

/// 走行ペース。「1日あたり何km走るか」。
struct DrivingPace: Equatable, Sendable {
    var kilometersPerDay: Double
    /// 何日ぶんの記録から出したか（表示して信頼度を伝えるため）。
    var days: Int
    var distance: Double

    /// 月あたりの走行距離（30日換算）。
    var kilometersPerMonth: Double { kilometersPerDay * 30 }
}

/// 走行距離の推移から、指定距離に到達する日を予測する。
///
/// 距離で管理するメンテ（オイル交換 5,000km など）を「日付の通知」に変換するために要る。
enum OdometerProjection {
    /// ペースの算出に使う期間。これより古い記録は、乗り方が変わっている可能性が高いので使わない。
    static let windowDays = 90
    /// これより先の予測は誤差が大きすぎて意味がないので出さない。
    static let maximumProjectionDays = 3650

    /// 走行ペース。記録が1件以下、または期間・距離が取れないときは nil。
    static func pace(
        for records: [FuelEntry], now: Date = Date(), calendar: Calendar = .current
    ) -> DrivingPace? {
        let sorted = records.sorted { $0.date < $1.date }
        guard let latest = sorted.last, sorted.count >= 2 else { return nil }

        // 直近 windowDays 以内で最も古い記録を基準にする。
        // 窓の中に1件しか無ければ、全期間の最古まで遡る（記録が疎なユーザーでもペースが出るように）。
        let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: latest.date)
        let inWindow = sorted.filter { record in
            guard let windowStart else { return true }
            return record.date >= windowStart
        }
        let base = inWindow.count >= 2 ? inWindow[0] : sorted[0]

        guard let days = calendar.dateComponents([.day], from: base.date, to: latest.date).day,
              days >= 1
        else { return nil }

        let distance = latest.odometer - base.odometer
        guard distance > 0 else { return nil }

        return DrivingPace(
            kilometersPerDay: distance / Double(days), days: days, distance: distance
        )
    }

    /// 目標距離に到達する日。すでに到達していれば `from` の当日を返す。
    ///
    /// ペースが取れない・遅すぎて10年より先になる場合は nil（「予測できない」と表示する）。
    static func dateReaching(
        _ target: Double,
        currentOdometer: Double,
        pace: DrivingPace?,
        from: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        let today = calendar.startOfDay(for: from)
        let remaining = target - currentOdometer
        if remaining <= 0 { return today }

        guard let pace, pace.kilometersPerDay > 0 else { return nil }
        let days = (remaining / pace.kilometersPerDay).rounded(.up)
        guard days.isFinite, days <= Double(maximumProjectionDays) else { return nil }

        return calendar.date(byAdding: .day, value: Int(days), to: today)
    }
}
