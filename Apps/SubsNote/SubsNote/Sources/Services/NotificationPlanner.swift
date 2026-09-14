import Foundation

/// 支払日の何日前に知らせるか（設定で組み合わせを選ぶ）。
enum ReminderDay: Int, CaseIterable, Identifiable, Sendable {
    case weekBefore = 7
    case threeDaysBefore = 3
    case dayBefore = 1
    case sameDay = 0

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .weekBefore: String(localized: "7日前")
        case .threeDaysBefore: String(localized: "3日前")
        case .dayBefore: String(localized: "前日")
        case .sameDay: String(localized: "当日")
        }
    }
}

struct NotificationSettings: Equatable, Sendable {
    static let defaultReminderDays: Set<Int> = [3, 1]

    var reminderDays: Set<Int> = NotificationSettings.defaultReminderDays
    var hour: Int = 9
    var minute: Int = 0
    /// 無料体験の終了（最終日の3日前と前日）。
    var trialAlerts = true
    /// 年払いの更新は7日前にも（金額が大きく、解約の判断に時間がかかるため）。
    var yearlyWeekBefore = true

    /// `@AppStorage` に文字列で保存する（"3,1"）。
    static func encode(_ days: Set<Int>) -> String {
        days.sorted(by: >).map(String.init).joined(separator: ",")
    }

    static func decode(_ text: String) -> Set<Int> {
        Set(text.split(separator: ",").compactMap { Int($0) }.filter { ReminderDay(rawValue: $0) != nil })
    }
}

/// 通知計画の入力。SwiftData のモデルを値に写してから渡す（純粋関数としてテストするため）。
struct SubscriptionNotificationInput: Sendable {
    var id: UUID
    var name: String
    var plan: BillingPlan
    var paymentMethod: PaymentMethod
}

/// 予約する通知1件。
struct PlannedNotification: Identifiable, Equatable, Sendable {
    var id: String
    var fireDate: Date
    var title: String
    var body: String
    var isTrial: Bool
}

/// どのサブスクを、いつ、どんな文面で通知するかを決める。
enum NotificationPlanner {
    /// iOS のローカル通知の予約上限は64件。余裕を残して60件まで予約する。
    /// 月払い20件×2通で月40通になり2か月弱で尽きるので、BGAppRefreshTask とアプリを開くたびに組み直す。
    static let budget = 60
    /// 何日先の支払日まで見るか。年払いの更新と、その7日前を拾える長さ。
    static let horizonDays = 400
    /// 無料体験の終了は、最終日の3日前と前日に知らせる。
    static let trialDaysBefore = [3, 1]

    static func plan(
        subscriptions: [SubscriptionNotificationInput],
        settings: NotificationSettings,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [PlannedNotification] {
        let today = calendar.startOfDay(for: now)
        guard let horizon = calendar.date(byAdding: .day, value: horizonDays, to: today) else { return [] }

        var trials: [PlannedNotification] = []
        var bills: [PlannedNotification] = []
        for sub in subscriptions where !sub.plan.isCancelled {
            // 体験終了の通知を出すときは、体験後の初回の支払日の通知は重ねない（同じ話を2回しない）。
            var coveredByTrial: Date?
            if settings.trialAlerts, let trialEnd = sub.plan.trialEndDate {
                let lastDay = calendar.startOfDay(for: trialEnd)
                coveredByTrial = BillingSchedule.firstBillingDate(afterTrialEnd: lastDay, calendar: calendar)
                for days in trialDaysBefore {
                    guard let fire = fireDate(lastDay, daysBefore: days, settings: settings, calendar: calendar),
                          fire > now
                    else { continue }
                    trials.append(
                        PlannedNotification(
                            id: "trial-\(sub.id.uuidString)-\(days)",
                            fireDate: fire,
                            title: String(localized: "\(sub.name)の無料体験がまもなく終わります"),
                            body: trialBody(sub, lastDay: lastDay, daysBefore: days, calendar: calendar),
                            isTrial: true
                        )
                    )
                }
            }

            var reminderDays = settings.reminderDays
            if sub.plan.cycle == .year, settings.yearlyWeekBefore { reminderDays.insert(7) }
            guard !reminderDays.isEmpty else { continue }

            let dates = BillingSchedule.billingDates(from: today, through: horizon, plan: sub.plan, calendar: calendar)
            for billing in dates where billing != coveredByTrial {
                for days in reminderDays.sorted(by: >) {
                    guard let fire = fireDate(billing, daysBefore: days, settings: settings, calendar: calendar),
                          fire > now
                    else { continue }
                    bills.append(
                        PlannedNotification(
                            id: "bill-\(sub.id.uuidString)-\(dayStamp(billing, calendar: calendar))-\(days)",
                            fireDate: fire,
                            title: billingTitle(name: sub.name, daysBefore: days),
                            body: billingBody(sub, billing: billing, calendar: calendar),
                            isTrial: false
                        )
                    )
                }
            }
        }

        // 一番お金を失うのは「無料体験のまま本契約になる」ことなので、体験終了を先に枠へ入れ、残りを近い順に埋める。
        let byDate: (PlannedNotification, PlannedNotification) -> Bool = {
            $0.fireDate == $1.fireDate ? $0.id < $1.id : $0.fireDate < $1.fireDate
        }
        let keptTrials = Array(trials.sorted(by: byDate).prefix(budget))
        let keptBills = Array(bills.sorted(by: byDate).prefix(budget - keptTrials.count))
        return (keptTrials + keptBills).sorted(by: byDate)
    }

    static func billingTitle(name: String, daysBefore: Int) -> String {
        switch daysBefore {
        case 0: String(localized: "\(name)の支払いが今日です")
        case 1: String(localized: "\(name)の支払いが明日です")
        case 2: String(localized: "\(name)の支払いがあさってです")
        default: String(localized: "\(name)の支払いが\(daysBefore)日後です")
        }
    }

    /// 本文は**根拠を書く**（いつ・いくら・どこで払うか）。根拠の無い通知はオフにされる。
    static func billingBody(_ sub: SubscriptionNotificationInput, billing: Date, calendar: Calendar = .current) -> String {
        let when = Formatting.monthDay(billing, calendar: calendar)
        let price = Formatting.yen(sub.plan.price)
        var text = sub.paymentMethod == .other
            ? String(localized: "\(when)に\(sub.name)の支払い（\(price)）があります。")
            : String(localized: "\(when)に\(sub.name)の支払い（\(price)・\(sub.paymentMethod.label)）があります。")
        if sub.plan.cycle == .year {
            text += String(localized: "年払いの更新です。続けない場合は早めに解約の手続きを。")
        }
        return text
    }

    static func trialBody(
        _ sub: SubscriptionNotificationInput, lastDay: Date, daysBefore: Int, calendar: Calendar = .current
    ) -> String {
        let last = Formatting.monthDay(lastDay, calendar: calendar)
        let left = daysBefore == 1 ? String(localized: "明日が最終日") : String(localized: "あと\(daysBefore)日")
        let first = Formatting.monthDay(
            BillingSchedule.firstBillingDate(afterTrialEnd: lastDay, calendar: calendar), calendar: calendar
        )
        let price = Formatting.cyclePrice(price: sub.plan.price, cycle: sub.plan.cycle, interval: sub.plan.interval)
        return String(
            localized: "無料体験は\(last)まで（\(left)）。続けない場合はそれまでに解約を。\(first)から \(price) の支払いが始まります。"
        )
    }

    private static func fireDate(_ day: Date, daysBefore: Int, settings: NotificationSettings, calendar: Calendar) -> Date? {
        guard let target = calendar.date(byAdding: .day, value: -daysBefore, to: day) else { return nil }
        return calendar.date(bySettingHour: settings.hour, minute: settings.minute, second: 0, of: target)
    }

    private static func dayStamp(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
