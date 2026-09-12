import BackgroundTasks
import Foundation

/// バックグラウンドでの通知再構築（BGAppRefreshTask）の予約。
///
/// モードB（隔週・第n曜日などを具体日で登録する方式）は120日ぶんの窓しか持たないので、
/// アプリを開かないまま窓が枯れると通知が止まる。そこで定期的にバックグラウンドで組み直す。
/// モードA（毎週くり返しのみ）は期限が無いため、予約せず OS の実行枠を使わない。
///
/// 実行はあくまで iOS の裁量で、`earliestBeginDate` は「これより前には実行しない」という下限。
/// 何日も実行されないこともあるが、窓が120日あるので実害は出ない設計にしてある。
/// いつ予約するかの判断は `BackgroundRefreshPolicy`。
enum BackgroundRefresh {
    /// Info.plist の BGTaskSchedulerPermittedIdentifiers と一致させること。
    static let taskID = "tech.sesame.gomialarm.refresh"

    /// 再構築を予約する。成功したら true。
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
