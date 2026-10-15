import SwiftData
import UIKit
import WidgetKit

/// データが変わったあとの後始末。通知の予約とウィジェットの中身を、いまのデータに合わせて作り直す。
///
/// 起動・復帰時、記録・プロフィール・消耗品・通知設定を変えたときに呼ぶ。
@MainActor
enum AppSync {
    static func refresh(context: ModelContext) async {
        WidgetSync.update(context: context)
        await NotificationScheduler.shared.rebuild(context: context)
    }

    /// 記録を保存したあとに呼ぶ。記録がとぎれたとき・記念日のお知らせは最初からオンなので、
    /// まだ通知の許可を聞いていなければ、ここ（最初に記録したあと）で聞く。
    static func recordSaved(context: ModelContext, defaults: UserDefaults = .standard) async {
        if NotificationSettings.automaticEnabled(defaults),
           await NotificationScheduler.shared.authorizationStatus() == .notDetermined {
            _ = await NotificationScheduler.shared.requestAuthorizationIfNeeded()
        }
        await refresh(context: context)
    }
}

/// ウィジェットに渡す中身を書き出す。
@MainActor
enum WidgetSync {
    /// ウィジェットのアイコン用。小さく縮めて共有フォルダに置く。
    private static let avatarSize: CGFloat = 300

    static func update(context: ModelContext, now: Date = Date()) {
        let profile = (try? context.fetch(FetchDescriptor<HamsterProfile>()))?.first
        let records = (try? context.fetch(FetchDescriptor<DiaryRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        let points = WeightSeries.points(records.map { ($0.date, $0.weight, $0.createdAt) })
        let latest = points.last
        let previous = points.dropLast().last

        var snapshot = WidgetSnapshot(
            name: profile?.name,
            birthDate: profile?.birthDate,
            welcomeDate: profile?.welcomeDate,
            // 先の日付で書いた記録があっても、今日の記録の有無を取り違えないように。
            lastRecordDate: records.first { $0.date <= now }?.date,
            latestWeight: latest?.weight,
            weightChange: latest.flatMap { latest in previous.map { ((latest.weight - $0.weight) * 10).rounded() / 10 } },
            weightDropping: WeightAlert.drop(in: points, now: now) != nil
        )

        if let avatarURL = WidgetSnapshot.avatarURL {
            if let image = PhotoStore.image(at: profile?.photoPath),
               let data = PhotoStore.resized(image, maxLength: avatarSize).jpegData(compressionQuality: 0.8) {
                try? data.write(to: avatarURL, options: .atomic)
                snapshot.hasAvatar = true
            } else {
                try? FileManager.default.removeItem(at: avatarURL)
            }
        }
        snapshot.save()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshot.widgetKind)
    }
}
