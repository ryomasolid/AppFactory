import Foundation
import SwiftData

/// 契約しているサブスク1件。支払日は `anchorDate` から数える（`BillingSchedule`）。
@Model
final class Subscription {
    var id: UUID = UUID()
    /// 「Netflix」「ジム」など表示名（必須）。
    var name: String = ""
    /// `ServicePreset` のキー。料金プランの候補を編集画面で出し直すのに使う。
    var presetKey: String?
    var categoryRaw: String = SubCategory.life.rawValue
    /// 1回の支払い額（円・税込）。
    var price: Int = 0
    var cycleRaw: String = BillingCycle.month.rawValue
    /// 何週・何か月・何年ごとか。「3か月ごと」は 月×3。
    var cycleInterval: Int = 1
    /// 支払日の起点。無料体験があるときは体験最終日の翌日（保存時にそろえる）。
    var anchorDate: Date = Date()
    /// 無料体験の最終日。
    var trialEndDate: Date?
    var paymentMethodRaw: String = PaymentMethod.creditCard.rawValue
    /// 「楽天カード」など。
    var paymentNote: String = ""
    /// 解約の手順（支払い方法ごとの一般的な手順が初期値。ユーザーが書き換えられる）。
    var cancelNote: String = ""
    var note: String = ""
    /// 解約済み。合計・通知から外し、「解約済み」に残す（解約で浮いた額の表示に使う）。
    var isCancelled: Bool = false
    var cancelledAt: Date?
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String = "",
        presetKey: String? = nil,
        category: SubCategory = .life,
        price: Int = 0,
        cycle: BillingCycle = .month,
        cycleInterval: Int = 1,
        anchorDate: Date = Date(),
        trialEndDate: Date? = nil,
        paymentMethod: PaymentMethod = .creditCard,
        paymentNote: String = "",
        cancelNote: String = "",
        note: String = "",
        isCancelled: Bool = false,
        cancelledAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.presetKey = presetKey
        self.categoryRaw = category.rawValue
        self.price = price
        self.cycleRaw = cycle.rawValue
        self.cycleInterval = cycleInterval
        self.anchorDate = anchorDate
        self.trialEndDate = trialEndDate
        self.paymentMethodRaw = paymentMethod.rawValue
        self.paymentNote = paymentNote
        self.cancelNote = cancelNote
        self.note = note
        self.isCancelled = isCancelled
        self.cancelledAt = cancelledAt
        self.createdAt = createdAt
    }

    var category: SubCategory {
        get { SubCategory(rawValue: categoryRaw) ?? .life }
        set { categoryRaw = newValue.rawValue }
    }

    var cycle: BillingCycle {
        get { BillingCycle(rawValue: cycleRaw) ?? .month }
        set { cycleRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .other }
        set { paymentMethodRaw = newValue.rawValue }
    }
}

extension Subscription {
    /// 計算用の値。
    var plan: BillingPlan {
        BillingPlan(
            price: price, cycle: cycle, interval: cycleInterval, anchorDate: anchorDate,
            trialEndDate: trialEndDate, isCancelled: isCancelled, cancelledAt: cancelledAt
        )
    }

    func state(today: Date = AppClock.now, calendar: Calendar = .current) -> BillingState {
        BillingSchedule.state(of: plan, today: today, calendar: calendar)
    }

    func nextBillingDate(today: Date = AppClock.now, calendar: Calendar = .current) -> Date? {
        BillingSchedule.nextBillingDate(onOrAfter: today, plan: plan, calendar: calendar)
    }

    var monthlyAmount: Int { CostSummary.monthly(plan) }

    /// 解約の手順。未入力なら支払い方法ごとの一般的な手順。
    var cancelGuide: String {
        let trimmed = cancelNote.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? paymentMethod.cancelGuide : trimmed
    }

    var notificationInput: SubscriptionNotificationInput {
        SubscriptionNotificationInput(id: id, name: name, plan: plan, paymentMethod: paymentMethod)
    }

    func exportRow(today: Date = AppClock.now, calendar: Calendar = .current) -> SubscriptionExportRow {
        SubscriptionExportRow(
            name: name,
            category: category.label,
            price: price,
            cycle: Formatting.cycle(cycle, interval: cycleInterval),
            monthly: CostSummary.monthly(plan),
            yearly: CostSummary.yearly(plan).rounded(),
            nextBillingDate: nextBillingDate(today: today, calendar: calendar),
            paymentMethod: paymentMethod.label,
            paymentNote: paymentNote,
            trialEndDate: trialEndDate,
            state: state(today: today, calendar: calendar),
            cancelledAt: cancelledAt,
            note: note
        )
    }
}
