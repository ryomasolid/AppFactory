import Foundation

/// 日本の祝日。設定「祝日は通知しない」がオンのときだけ使う。
///
/// 年ごとの表を手で持つとメンテが必要になるため、祝日法のルールから計算する。
/// 春分日・秋分日は 1980〜2099 年で使える近似式（国立天文台の暦要項に一致）を用いている。
/// 皇室行事などの臨時の祝日は再現できないので、必要になったら `extraHolidays` に足す。
enum HolidayCalendar {

    /// 臨時の祝日（即位の礼など）。必要になったら "yyyy-MM-dd" で追加する。
    private static let extraHolidays: Set<String> = []

    /// 指定期間に含まれる祝日（振替休日・国民の休日を含む）を返す。
    static func holidays(from: Date, through: Date, calendar: Calendar = .current) -> Set<Date> {
        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: through)
        guard start <= end else { return [] }
        let years = Set([
            calendar.component(.year, from: start),
            calendar.component(.year, from: end),
        ])
        var result = Set<Date>()
        for year in years {
            for day in cache.holidays(inYear: year, calendar: calendar) where day >= start && day <= end {
                result.insert(day)
            }
        }
        return result
    }

    /// その日が祝日か（UI の色分けなど単発の判定用）。
    static func isHoliday(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return cache.holidays(inYear: calendar.component(.year, from: day), calendar: calendar).contains(day)
    }

    // MARK: - 計算

    private static let cache = Cache()

    /// 年ごとの計算結果をキャッシュする。複数スレッドから触られてもよいようロックで守る。
    private final class Cache: @unchecked Sendable {
        private let lock = NSLock()
        private var storage: [Int: Set<Date>] = [:]

        func holidays(inYear year: Int, calendar: Calendar) -> Set<Date> {
            lock.lock()
            defer { lock.unlock() }
            if let cached = storage[year] { return cached }
            let computed = HolidayCalendar.compute(year: year, calendar: calendar)
            storage[year] = computed
            return computed
        }
    }

    private static func compute(year: Int, calendar: Calendar) -> Set<Date> {
        var base = Set<Date>()

        // 日付が固定の祝日。
        let fixed: [(Int, Int)] = [
            (1, 1),    // 元日
            (2, 11),   // 建国記念の日
            (2, 23),   // 天皇誕生日
            (4, 29),   // 昭和の日
            (5, 3),    // 憲法記念日
            (5, 4),    // みどりの日
            (5, 5),    // こどもの日
            (8, 11),   // 山の日
            (11, 3),   // 文化の日
            (11, 23),  // 勤労感謝の日
        ]
        for (month, day) in fixed {
            if let date = date(year: year, month: month, day: day, calendar: calendar) { base.insert(date) }
        }

        // ハッピーマンデー（第n月曜）。
        let mondays: [(Int, Int)] = [
            (1, 2),    // 成人の日 = 1月第2月曜
            (7, 3),    // 海の日 = 7月第3月曜
            (9, 3),    // 敬老の日 = 9月第3月曜
            (10, 2),   // スポーツの日 = 10月第2月曜
        ]
        for (month, nth) in mondays {
            if let date = nthMonday(year: year, month: month, nth: nth, calendar: calendar) { base.insert(date) }
        }

        // 春分の日・秋分の日（近似式）。
        let offset = Double(year - 1980)
        let leaps = Double((year - 1980) / 4)
        let vernal = Int(floor(20.8431 + 0.242194 * offset - leaps))
        let autumnal = Int(floor(23.2488 + 0.242194 * offset - leaps))
        if let date = date(year: year, month: 3, day: vernal, calendar: calendar) { base.insert(date) }
        if let date = date(year: year, month: 9, day: autumnal, calendar: calendar) { base.insert(date) }

        // 臨時の祝日。
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        for text in extraHolidays {
            guard let date = formatter.date(from: text) else { continue }
            base.insert(calendar.startOfDay(for: date))
        }

        var result = base

        // 国民の休日: 祝日に挟まれた平日（前後が「祝日」で、その日が日曜でも祝日でもない）。
        for day in base {
            guard let next = calendar.date(byAdding: .day, value: 2, to: day),
                  base.contains(next),
                  let between = calendar.date(byAdding: .day, value: 1, to: day),
                  !base.contains(between),
                  calendar.component(.weekday, from: between) != 1
            else { continue }
            result.insert(between)
        }

        // 振替休日: 祝日が日曜なら、その後の最初の「祝日でない日」を休日にする。
        for day in base where calendar.component(.weekday, from: day) == 1 {
            var candidate = day
            while true {
                guard let next = calendar.date(byAdding: .day, value: 1, to: candidate) else { break }
                candidate = calendar.startOfDay(for: next)
                if !result.contains(candidate) {
                    result.insert(candidate)
                    break
                }
            }
        }

        return result
    }

    private static func date(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day)).map { calendar.startOfDay(for: $0) }
    }

    private static func nthMonday(year: Int, month: Int, nth: Int, calendar: Calendar) -> Date? {
        guard let first = date(year: year, month: month, day: 1, calendar: calendar) else { return nil }
        let firstWeekday = calendar.component(.weekday, from: first)   // 1=日
        // 月初から最初の月曜（weekday=2）までの日数。
        let offsetToMonday = (2 - firstWeekday + 7) % 7
        let day = 1 + offsetToMonday + (nth - 1) * 7
        return date(year: year, month: month, day: day, calendar: calendar)
    }
}
