import Foundation
import Testing
@testable import GeckoLog

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return calendar
}()

private func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 20) -> Date {
    calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

struct StageTests {
    @Test func 年齢で区切る() {
        let now = day(2026, 10, 29)
        #expect(CareRhythm.stage(hatchedOn: day(2026, 8, 1), now: now, calendar: calendar) == .baby)
        #expect(CareRhythm.stage(hatchedOn: day(2026, 3, 1), now: now, calendar: calendar) == .juvenile)
        #expect(CareRhythm.stage(hatchedOn: day(2025, 5, 1), now: now, calendar: calendar) == .adult)
        #expect(CareRhythm.stage(hatchedOn: nil, now: now, calendar: calendar) == .adult)
    }

    @Test func 年齢ごとのごはん間隔() {
        #expect(CareRhythm.suggestedFeedInterval(for: .baby) == 1)
        #expect(CareRhythm.suggestedFeedInterval(for: .juvenile) == 2)
        #expect(CareRhythm.suggestedFeedInterval(for: .adult) == 4)
    }
}

struct FeedingTests {
    @Test func 最後に与えた日から間隔ぶん後() {
        let next = CareRhythm.nextFeedingDay(lastOffered: day(2026, 10, 25, 22), interval: 4, today: day(2026, 10, 27), calendar: calendar)
        #expect(next == calendar.startOfDay(for: day(2026, 10, 29)))
    }

    @Test func 一度も与えていなければ今日() {
        let today = day(2026, 10, 29, 9)
        #expect(CareRhythm.nextFeedingDay(lastOffered: nil, interval: 4, today: today, calendar: calendar) == calendar.startOfDay(for: today))
    }

    @Test func 拒食は新しいほうから続いた回数() {
        let feedings: [(at: Date, accepted: Bool)] = [
            (day(2026, 10, 1), false),
            (day(2026, 10, 5), true),
            (day(2026, 10, 9), false),
            (day(2026, 10, 13), false),
        ]
        #expect(CareRhythm.refusalStreak(feedings) == 2)
        #expect(CareRhythm.refusalStreak([(day(2026, 10, 13), true)]) == 0)
        #expect(CareRhythm.refusalStreak([]) == 0)
    }
}

struct ShedTests {
    @Test func 直近の間隔の平均で予想する() {
        // 間隔 30, 34 → 平均 32
        let sheds = [day(2026, 8, 1), day(2026, 8, 31), day(2026, 10, 4)]
        let next = CareRhythm.nextShedDay(shedDates: sheds, stage: .adult, calendar: calendar)
        #expect(next == calendar.startOfDay(for: day(2026, 11, 5)))
    }

    @Test func 一回だけなら年齢の目安() {
        let next = CareRhythm.nextShedDay(shedDates: [day(2026, 10, 1)], stage: .baby, calendar: calendar)
        #expect(next == calendar.startOfDay(for: day(2026, 10, 11)))
    }

    @Test func 記録がなければ予想しない() {
        #expect(CareRhythm.nextShedDay(shedDates: [], stage: .adult, calendar: calendar) == nil)
    }
}

struct WeightTests {
    @Test func 一か月前と比べる() {
        let weighings: [(at: Date, grams: Double)] = [
            (day(2026, 8, 1), 70),
            (day(2026, 9, 20), 60),
            (day(2026, 10, 25), 54),
        ]
        let change = CareRhythm.weightTrend(weighings, calendar: calendar)
        #expect(change != nil)
        #expect(abs((change ?? 0) - (-10)) < 0.001)
    }

    @Test func 一回だけなら比べない() {
        #expect(CareRhythm.weightTrend([(day(2026, 10, 25), 54)], calendar: calendar) == nil)
    }
}

struct IncubationTests {
    @Test func 表の温度はそのままの日数() {
        #expect(Incubation.expectedDays(at: 28) == 53)
        #expect(Incubation.expectedDays(at: 32) == 40)
    }

    @Test func 間の温度は補間する() {
        #expect(Incubation.expectedDays(at: 28.5) == 51)
    }

    @Test func 範囲外は端の日数() {
        #expect(Incubation.expectedDays(at: 20) == 65)
        #expect(Incubation.expectedDays(at: 36) == 38)
    }

    @Test func 温度で性別の傾向が変わる() {
        #expect(Incubation.sexTendency(at: 27) == "メスが多め")
        #expect(Incubation.sexTendency(at: 32) == "オスが多め")
    }
}

struct AlarmPlanTests {
    @Test func 同じ日の子は一通にまとめる() {
        let today = day(2026, 10, 29, 8)
        let start = calendar.startOfDay(for: today)
        let plan = FeedingAlarm.plan(
            for: [
                (name: "もち", next: start, interval: 4),
                (name: "きなこ", next: start, interval: 2),
            ],
            today: today,
            calendar: calendar
        )
        #expect(plan.first?.day == start)
        #expect(plan.first?.names == ["もち", "きなこ"])
        // 7日のうち: もち 0,4 / きなこ 0,2,4,6 → 日は 0,2,4,6
        #expect(plan.count == 4)
    }

    @Test func 過ぎている子は今日にまとめる() {
        let today = day(2026, 10, 29, 8)
        let plan = FeedingAlarm.plan(for: [(name: "そら", next: day(2026, 10, 20), interval: 3)], today: today, calendar: calendar)
        #expect(plan.first?.day == calendar.startOfDay(for: today))
    }

    @Test func 四匹以上はほか何匹() {
        #expect(FeedingAlarm.body(for: ["a", "b", "c", "d", "e"]) == "a・b・c ほか2匹のごはんの日です")
        #expect(FeedingAlarm.body(for: ["もち"]) == "もちのごはんの日です")
    }
}

struct CSVTests {
    @Test func カンマや改行を含む欄はくくる() {
        #expect(CSVExport.escape("ふつう") == "ふつう")
        #expect(CSVExport.escape("床材,水入れ") == "\"床材,水入れ\"")
        #expect(CSVExport.escape("\"もち\"") == "\"\"\"もち\"\"\"")
    }
}
