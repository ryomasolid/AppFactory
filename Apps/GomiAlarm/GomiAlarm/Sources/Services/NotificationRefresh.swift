import Foundation
import SwiftData

/// 保存済みのゴミの種類から通知を組み直し、必要なら次のバックグラウンド再構築を予約する入口。
///
/// 呼ぶ場所は4つ:
/// - アプリ起動／フォアグラウンド復帰時（`GomiAlarmApp`）
/// - 種類・ルール・通知設定を変更した直後
/// - BGAppRefreshTask から（`GomiAlarmApp` の `.backgroundTask`）
/// - 設定画面の「通知を作り直す」
@MainActor
enum NotificationRefresh {

    /// 通知を組み直す。
    /// - Parameter requestingAuthorization: 未確認なら許可ダイアログを出すか。
    ///   自動実行（起動時・バックグラウンド）では false にして、許可はオンボーディングでだけ求める。
    @discardableResult
    static func run(
        container: ModelContainer,
        settings: NotificationSettings = .load(),
        now: Date = Date(),
        requestingAuthorization: Bool = false
    ) async -> RefreshStatus {
        let descriptor = FetchDescriptor<GarbageKind>(sortBy: [SortDescriptor(\.sortOrder)])
        let kinds = (try? container.mainContext.fetch(descriptor)) ?? []

        let result = await NotificationScheduler.shared.rebuild(
            kinds: kinds.map(KindPlan.init),
            settings: settings,
            now: now,
            requestingAuthorization: requestingAuthorization
        )

        var nextRefresh: Date?
        if let date = BackgroundRefreshPolicy.nextRefreshDate(for: result, now: now) {
            nextRefresh = BackgroundRefresh.schedule(at: date) ? date : nil
        } else {
            // 永続モードに変わった／通知が不要になった場合は、残っている予約を片付ける。
            BackgroundRefresh.cancel()
        }

        let status = RefreshStatus(
            lastRunAt: now,
            authorized: result.authorized,
            scheduled: result.scheduled,
            isPermanent: result.isPermanent,
            coveredThrough: result.coveredThrough,
            truncated: result.truncated,
            nextBackgroundRefreshAt: nextRefresh
        )
        status.save()
        return status
    }
}
