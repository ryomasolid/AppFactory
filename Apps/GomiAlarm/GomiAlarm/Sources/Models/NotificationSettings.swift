import Foundation

/// 通知の既定設定。種類ごとに時刻を上書きしていない場合はここの値を使う。
struct NotificationSettings: Codable, Equatable, Sendable {
    /// 前夜通知（収集日の前日に鳴らす）。
    var eveningEnabled: Bool = true
    var eveningTime: TimeOfDay = TimeOfDay(hour: 20, minute: 0)
    /// 当日朝の通知。
    var morningEnabled: Bool = true
    var morningTime: TimeOfDay = TimeOfDay(hour: 6, minute: 30)
    /// 祝日は通知しない。自治体によって祝日も収集するため既定はオフ。
    var skipHolidays: Bool = false

    static let `default` = NotificationSettings()

    // MARK: - UserDefaults（設定画面は @AppStorage で同じキーを読む）

    enum Key {
        static let eveningEnabled = "ga.eveningEnabled"
        static let eveningMinutes = "ga.eveningMinutes"
        static let morningEnabled = "ga.morningEnabled"
        static let morningMinutes = "ga.morningMinutes"
        static let skipHolidays = "ga.skipHolidays"
    }

    static func load(from defaults: UserDefaults = .standard) -> NotificationSettings {
        var settings = NotificationSettings()
        if defaults.object(forKey: Key.eveningEnabled) != nil {
            settings.eveningEnabled = defaults.bool(forKey: Key.eveningEnabled)
        }
        if defaults.object(forKey: Key.morningEnabled) != nil {
            settings.morningEnabled = defaults.bool(forKey: Key.morningEnabled)
        }
        if let minutes = defaults.object(forKey: Key.eveningMinutes) as? Int {
            settings.eveningTime = TimeOfDay(minutesFromMidnight: minutes)
        }
        if let minutes = defaults.object(forKey: Key.morningMinutes) as? Int {
            settings.morningTime = TimeOfDay(minutesFromMidnight: minutes)
        }
        settings.skipHolidays = defaults.bool(forKey: Key.skipHolidays)
        return settings
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(eveningEnabled, forKey: Key.eveningEnabled)
        defaults.set(eveningTime.minutesFromMidnight, forKey: Key.eveningMinutes)
        defaults.set(morningEnabled, forKey: Key.morningEnabled)
        defaults.set(morningTime.minutesFromMidnight, forKey: Key.morningMinutes)
        defaults.set(skipHolidays, forKey: Key.skipHolidays)
    }
}

/// 通知のタイミング。
enum NotificationTiming: String, Codable, CaseIterable, Sendable {
    case evening   // 収集日の前夜
    case morning   // 収集日の当日朝
}
