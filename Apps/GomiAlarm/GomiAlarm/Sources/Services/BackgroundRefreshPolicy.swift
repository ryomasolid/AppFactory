import Foundation

/// 「いつバックグラウンドで通知を組み直すか」の判断。
///
/// 予約しすぎると OS の実行枠を無駄に食い、遅すぎると通知の窓が枯れて鳴らなくなる。
/// BackgroundTasks に依存しない純粋ロジックにして、判断だけを単体テストで固定する
/// （実際の予約は `BackgroundRefresh`）。
enum BackgroundRefreshPolicy {
    /// 再構築の最短間隔。これより短く予約しても OS 側で間引かれるだけなので下限を設ける。
    static let minimumDelay: TimeInterval = 24 * 60 * 60
    /// 最長間隔。窓に余裕があっても最低これくらいの頻度では組み直す。
    static let maximumDelay: TimeInterval = 7 * 24 * 60 * 60

    /// 次にバックグラウンド再構築すべき日時。不要なら nil。
    ///
    /// カバー範囲の「半分」を過ぎたら組み直す方針。
    /// 実行が遅れても残り半分ぶんの通知は生きているので、取りこぼしにならない。
    static func nextRefreshDate(
        for result: NotificationScheduler.RebuildResult, now: Date = Date()
    ) -> Date? {
        // 毎週くり返しだけで組めている場合は期限が無いので、バックグラウンド実行は不要。
        guard !result.isPermanent else { return nil }
        // 未許可なら組み直しても登録できない。許可されたらフォアグラウンド復帰時に組み直す。
        guard result.authorized else { return nil }
        guard let covered = result.coveredThrough else { return now.addingTimeInterval(maximumDelay) }
        let half = covered.timeIntervalSince(now) / 2
        return now.addingTimeInterval(min(max(half, minimumDelay), maximumDelay))
    }
}
