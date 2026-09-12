import Foundation

/// 直近の通知再構築の結果。設定画面の「通知が届かないときは」やデバッグ表示に使う。
/// 通知は登録しても目に見えないので、「いつ・何件・いつまでカバーできているか」を必ず残す。
struct RefreshStatus: Codable, Equatable, Sendable {
    var lastRunAt: Date?
    /// 通知が許可されているか。false なら1件も登録されていない。
    var authorized: Bool = false
    var scheduled: Int = 0
    /// 毎週くり返しだけで組めている（＝再構築なしで鳴り続ける）か。
    var isPermanent: Bool = false
    /// 1回きりの通知でカバーできている最後の収集日。
    var coveredThrough: Date?
    /// 60件上限で切り捨てたか。設定画面で警告を出す。
    var truncated: Bool = false
    /// 次のバックグラウンド再構築の予約（あくまで最短時刻で、実行はiOS任せ）。
    var nextBackgroundRefreshAt: Date?

    private static let key = "ga.refreshStatus"

    static func load(from defaults: UserDefaults = .standard) -> RefreshStatus {
        guard let data = defaults.data(forKey: key),
              let status = try? JSONDecoder().decode(RefreshStatus.self, from: data)
        else { return RefreshStatus() }
        return status
    }

    func save(to defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
