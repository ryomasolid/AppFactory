import Foundation
import SwiftData
import UserNotifications

/// 支払日・無料体験のお知らせを iOS に預ける窓口。
///
/// 何をいつ知らせるかは `NotificationPlanner` が決め、ここは許可の確認と予約の入れ替えだけを行う。
/// 予約は毎回すべて入れ替える（支払日は起点から数え直せるので、差分を持つ必要がない）。
@MainActor
enum ReminderCenter {
    /// 設定画面に出す許可の状態。
    enum Permission {
        case unknown
        case allowed
        case blocked
    }

    private static var center: UNUserNotificationCenter { .current() }

    static func permission() async -> Permission {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .unknown
        case .denied: .blocked
        default: .allowed
        }
    }

    /// 未確認のときだけ許可を尋ねる。使えるなら true。
    static func askIfNeeded() async -> Bool {
        switch await permission() {
        case .allowed: return true
        case .blocked: return false
        case .unknown:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    static func pendingCount() async -> Int {
        await center.pendingNotificationRequests().count
    }

    /// いちばん近い予約（設定画面で「次のお知らせ」を見せ、ちゃんと入っていると分かるようにする）。
    struct Upcoming: Equatable {
        var date: Date
        var title: String
    }

    static func upcoming() async -> Upcoming? {
        await center.pendingNotificationRequests()
            .compactMap { request -> Upcoming? in
                guard let date = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() else { return nil }
                return Upcoming(date: date, title: request.content.title)
            }
            .min { $0.date < $1.date }
    }

    /// 設定画面の値（`@AppStorage`）。未設定の項目は既定値。
    static func savedSettings(_ defaults: UserDefaults = .standard) -> NotificationSettings {
        func value<T>(_ key: String, or fallback: T) -> T { defaults.object(forKey: key) as? T ?? fallback }
        return NotificationSettings(
            reminderDays: defaults.string(forKey: StorageKey.reminderDays).map(NotificationSettings.decode)
                ?? NotificationSettings.defaultReminderDays,
            hour: value(StorageKey.notifyHour, or: 9),
            minute: value(StorageKey.notifyMinute, or: 0),
            trialAlerts: value(StorageKey.trialAlerts, or: true),
            yearlyWeekBefore: value(StorageKey.yearlyWeekBefore, or: true)
        )
    }

    /// 予約を計画どおりに入れ替え、入った件数を返す。通知が使えなければ nil（古い予約は消す）。
    ///
    /// `ask` が false のときは許可ダイアログを出さない（許可はオンボーディングと設定画面でだけ求める）。
    @discardableResult
    static func replace(with planned: [PlannedNotification], ask: Bool) async -> Int? {
        center.removeAllPendingNotificationRequests()
        let usable = ask ? await askIfNeeded() : await permission() == .allowed
        guard usable else { return nil }
        var added = 0
        for item in planned {
            if (try? await center.add(makeRequest(item))) != nil { added += 1 }
        }
        return added
    }

    /// 無料体験と支払日は通知センターで別のまとまりにする（体験の終わりが支払いの通知に埋もれないように）。
    private static func makeRequest(_ item: PlannedNotification) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = item.body
        content.sound = .default
        content.threadIdentifier = item.isTrial ? "sn.trial" : "sn.billing"
        let when = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.fireDate)
        return UNNotificationRequest(
            identifier: item.id, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
        )
    }
}

/// 保存済みのサブスクから通知を組み直し、次のバックグラウンド組み直しを予約する入口。
///
/// 呼ぶ場所: 起動・復帰時（`SubsNoteApp`）／BGAppRefreshTask／保存・削除・解約・再開の直後／通知設定の変更後／設定の「通知を作り直す」。
@MainActor
enum NotificationRefresh {
    @discardableResult
    static func run(
        container: ModelContainer, now: Date = Date(), requestingAuthorization: Bool = false
    ) async -> Int? {
        // await の前に値へ写しておく（モデルを中断点をまたいで持ち回らない）。
        let inputs = ((try? container.mainContext.fetch(FetchDescriptor<Subscription>())) ?? [])
            .map(\.notificationInput)
        let planned = NotificationPlanner.plan(subscriptions: inputs, settings: ReminderCenter.savedSettings(), now: now)
        let added = await ReminderCenter.replace(with: planned, ask: requestingAuthorization)
        if added != nil, let date = BackgroundRefreshPolicy.nextRefreshDate(planned: planned, now: now) {
            BackgroundRefresh.schedule(at: date)
        } else {
            // 未許可・通知が不要になった場合は、残っている予約を片付ける（許可後は復帰時に組み直す）。
            BackgroundRefresh.cancel()
        }
        return added
    }
}
