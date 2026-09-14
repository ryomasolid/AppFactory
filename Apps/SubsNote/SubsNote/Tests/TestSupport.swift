import Foundation
@testable import SubsNote

/// テスト用の固定カレンダー。端末のタイムゾーンに依存して落ちないよう明示する。
let jst: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .gmt
    calendar.locale = Locale(identifier: "ja_JP")
    return calendar
}()

/// 日付リテラル。
func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    jst.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
}

/// 日時リテラル。
func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    jst.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? .distantPast
}

/// 支払いの計画リテラル。
func billing(
    _ anchor: Date,
    _ cycle: BillingCycle = .month,
    price: Int = 1590,
    interval: Int = 1,
    trialEnd: Date? = nil,
    cancelledAt: Date? = nil
) -> BillingPlan {
    BillingPlan(
        price: price, cycle: cycle, interval: interval, anchorDate: anchor,
        trialEndDate: trialEnd, isCancelled: cancelledAt != nil, cancelledAt: cancelledAt
    )
}

/// 通知計画の入力リテラル。
func input(_ plan: BillingPlan, name: String = "動画プラス", payment: PaymentMethod = .appStore) -> SubscriptionNotificationInput {
    SubscriptionNotificationInput(id: UUID(), name: name, plan: plan, paymentMethod: payment)
}
