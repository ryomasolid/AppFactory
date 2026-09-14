import BackgroundTasks
import Foundation

/// バックグラウンドでの通知の組み直し（BGAppRefreshTask）の予約。
///
/// 予約は近い順に60件までなので、月払いが多くアプリを開かないと数か月で尽きる。そこで定期的に組み直す。
/// 実行は iOS の裁量で、`earliestBeginDate` は「これより前には実行しない」という下限。
/// いつ予約するかの判断は `BackgroundRefreshPolicy`（GomiAlarm と同じ方式）。
enum BackgroundRefresh {
    /// Info.plist の BGTaskSchedulerPermittedIdentifiers と一致させること。
    static let taskID = "tech.sesame.subsnote.refresh"

    /// 組み直しを予約する。成功したら true。
    /// シミュレータや、ユーザーが「Appのバックグラウンド更新」をオフにしている場合は false になる。
    @discardableResult
    static func schedule(at date: Date) -> Bool {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = date
        // 同じ識別子の予約が残っていると submit が失敗しうるので、明示的に消してから出す。
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskID)
        do {
            try BGTaskScheduler.shared.submit(request)
            return true
        } catch {
            return false
        }
    }

    static func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskID)
    }
}

/// 「いつバックグラウンドで通知を組み直すか」の判断。BackgroundTasks に依存させず、単体テストで固定する。
enum BackgroundRefreshPolicy {
    /// 最短間隔。これより短く予約しても OS 側で間引かれるだけ。
    static let minimumDelay: TimeInterval = 24 * 60 * 60
    /// 最長間隔。予約に余裕があっても、値の変更や日付の進みを拾うために最低これくらいで組み直す。
    static let maximumDelay: TimeInterval = 7 * 24 * 60 * 60

    /// 次に組み直すべき日時。予約する通知が無ければ nil。
    ///
    /// 予約した最後の通知までの「半分」を過ぎたら組み直す。実行が遅れても残り半分は生きているので取りこぼさない。
    static func nextRefreshDate(planned: [PlannedNotification], now: Date = Date()) -> Date? {
        guard let last = planned.map(\.fireDate).max() else { return nil }
        let half = last.timeIntervalSince(now) / 2
        return now.addingTimeInterval(min(max(half, minimumDelay), maximumDelay))
    }
}
