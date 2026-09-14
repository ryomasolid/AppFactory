import Foundation

/// 金額・日付・周期の表示形式。画面ごとにぶれないよう1か所にまとめる。
enum Formatting {
    private static let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    /// "¥12,340"
    static func yen(_ amount: Int) -> String {
        "¥" + amount.formatted(.number.grouping(.automatic))
    }

    /// "2026/9/17"
    static func date(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)/\(c.month ?? 0)/\(c.day ?? 0)"
    }

    /// "2026/9/17（木）"
    static func dateWithWeekday(_ date: Date, calendar: Calendar = .current) -> String {
        "\(Formatting.date(date, calendar: calendar))（\(weekday(date, calendar: calendar))）"
    }

    /// "9/17"
    static func shortDate(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.month, .day], from: date)
        return "\(c.month ?? 0)/\(c.day ?? 0)"
    }

    /// "9/17（木）"
    static func shortDateWithWeekday(_ date: Date, calendar: Calendar = .current) -> String {
        "\(shortDate(date, calendar: calendar))（\(weekday(date, calendar: calendar))）"
    }

    /// "9月17日"（通知の本文用）
    static func monthDay(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.month, .day], from: date)
        return String(localized: "\(c.month ?? 0)月\(c.day ?? 0)日")
    }

    /// "9月17日（木）"
    static func monthDayWithWeekday(_ date: Date, calendar: Calendar = .current) -> String {
        "\(monthDay(date, calendar: calendar))（\(weekday(date, calendar: calendar))）"
    }

    /// "2026年9月"
    static func yearMonth(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(localized: "\(String(c.year ?? 0))年\(c.month ?? 0)月")
    }

    /// "木"
    static func weekday(_ date: Date, calendar: Calendar = .current) -> String {
        let index = (calendar.component(.weekday, from: date) - 1) % 7
        return weekdays[max(0, index)]
    }

    /// 周期 "毎月" / "3か月ごと" / "毎年" / "毎週" / "2週ごと"
    static func cycle(_ cycle: BillingCycle, interval: Int) -> String {
        switch (cycle, interval) {
        case (.week, ...1): String(localized: "毎週")
        case (.week, _): String(localized: "\(interval)週ごと")
        case (.month, ...1): String(localized: "毎月")
        case (.month, _): String(localized: "\(interval)か月ごと")
        case (.year, ...1): String(localized: "毎年")
        case (.year, _): String(localized: "\(interval)年ごと")
        }
    }

    /// 1回の支払い "月 ¥1,490" / "3か月 ¥3,000" / "年 ¥5,900" / "週 ¥300"
    static func cyclePrice(price: Int, cycle: BillingCycle, interval: Int) -> String {
        let unit: String = switch (cycle, interval) {
        case (.week, ...1): String(localized: "週")
        case (.week, _): String(localized: "\(interval)週")
        case (.month, ...1): String(localized: "月")
        case (.month, _): String(localized: "\(interval)か月")
        case (.year, ...1): String(localized: "年")
        case (.year, _): String(localized: "\(interval)年")
        }
        return "\(unit) \(yen(price))"
    }

    /// 以後の支払日の言い方 "毎月17日" / "毎年3月1日" / "毎週水曜日" / "3か月ごとの10日"
    static func recurrence(anchor: Date, cycle: BillingCycle, interval: Int, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.month, .day], from: anchor)
        let month = c.month ?? 0
        let day = c.day ?? 0
        switch cycle {
        case .week:
            let weekday = weekday(anchor, calendar: calendar)
            return interval <= 1
                ? String(localized: "毎週\(weekday)曜日")
                : String(localized: "\(interval)週ごとの\(weekday)曜日")
        case .month:
            var text = interval <= 1
                ? String(localized: "毎月\(day)日")
                : String(localized: "\(interval)か月ごとの\(day)日")
            // 31日起点なら 2月は28日、4月は30日に払う（BillingSchedule と同じ）。
            if day >= 29 { text += String(localized: "（ない月は末日）") }
            return text
        case .year:
            var text = interval <= 1
                ? String(localized: "毎年\(month)月\(day)日")
                : String(localized: "\(interval)年ごとの\(month)月\(day)日")
            if month == 2, day == 29 { text += String(localized: "（平年は2月28日）") }
            return text
        }
    }

    /// "今日" / "明日" / "あと3日" / "2日前"
    static func daysUntil(_ days: Int) -> String {
        switch days {
        case ..<0: String(localized: "\(-days)日前")
        case 0: String(localized: "今日")
        case 1: String(localized: "明日")
        default: String(localized: "あと\(days)日")
        }
    }

    /// 日付の差（日数）。時刻は無視する。
    static func days(from start: Date, to end: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
    }
}

/// テキスト入力の数値解釈。「,」や全角数字、「¥」「円」が混ざっても読めるようにする。
enum NumberInput {
    static func int(_ text: String) -> Int? {
        let halfwidth = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        let normalized = halfwidth
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
            .replacingOccurrences(of: "円", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, let value = Double(normalized), value.isFinite, value >= 0, value < 100_000_000 else {
            return nil
        }
        return Int(value.rounded())
    }
}

/// 画面に出す「今日」。スクショ撮影時は起動引数（`-fixedToday`）で固定する。
/// 通知の予約には使わない（実際の時刻で予約する）。
enum AppClock {
    static var now: Date { Launch.fixedToday ?? Date() }
}
