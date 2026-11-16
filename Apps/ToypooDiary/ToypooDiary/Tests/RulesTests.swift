import Foundation
import Testing
@testable import ToypooDiary

private let jst: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return c
}()

private func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9) -> Date {
    jst.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

struct DogYearsTests {
    @Test func 人でいうと() {
        #expect(DogYears.human(months: 0) == 0)
        #expect(DogYears.human(months: 2) == 3)
        #expect(DogYears.human(months: 12) == 15)
        #expect(DogYears.human(months: 24) == 24)
        #expect(DogYears.human(months: 36) == 28)
        #expect(DogYears.human(months: 120) == 56)
        // 表のあいだは なめらかに
        #expect(DogYears.human(months: 4) == 6)
    }

    @Test func 年齢のことば() {
        #expect(DogYears.text(months: 5) == "5か月")
        #expect(DogYears.text(months: 24) == "2さい")
        #expect(DogYears.text(months: 27) == "2さい3か月")
        #expect(DogYears.months(from: day(2023, 11, 15), to: day(2026, 11, 14), calendar: jst) == 35)
        #expect(DogYears.months(from: day(2023, 11, 14), to: day(2026, 11, 14), calendar: jst) == 36)
    }

    @Test func ステージ() {
        #expect(DogYears.stage(months: 6) == .puppy)
        #expect(DogYears.stage(months: 12) == .adult)
        #expect(DogYears.stage(months: 90) == .senior)
    }

    @Test func 記念日までの日数() {
        #expect(DogYears.daysUntilNext(anniversaryOf: day(2022, 11, 14), from: day(2026, 11, 14, 20), calendar: jst) == 0)
        #expect(DogYears.daysUntilNext(anniversaryOf: day(2022, 11, 17), from: day(2026, 11, 14), calendar: jst) == 3)
        #expect(DogYears.daysUntilNext(anniversaryOf: day(2022, 11, 13), from: day(2026, 11, 14), calendar: jst) == 364)
    }
}

struct TrimRhythmTests {
    @Test func 記録がなければ目安なし() {
        let s = TrimRhythm.status(cuts: [], now: day(2026, 11, 14), calendar: jst)
        #expect(s.phase == .noRecord)
        #expect(s.nextDue == nil)
        #expect(s.interval == 30)
    }

    @Test func 間隔は最近の真ん中() {
        let cuts = [day(2026, 6, 1), day(2026, 7, 1), day(2026, 8, 5), day(2026, 9, 1), day(2026, 10, 1)]
        // 30, 35, 27, 30 → 並べて 27,30,30,35 → (30+30)/2
        #expect(TrimRhythm.interval(cuts: cuts, calendar: jst) == 30)
        // 1回だけなら月1回
        #expect(TrimRhythm.interval(cuts: [day(2026, 10, 1)], calendar: jst) == 30)
        // ありえない間隔はおさえる
        #expect(TrimRhythm.interval(cuts: [day(2026, 1, 1), day(2026, 10, 1)], calendar: jst) == 90)
    }

    @Test func 前回からの日数と毛の伸び() {
        let s = TrimRhythm.status(cuts: [day(2026, 9, 14), day(2026, 10, 14)], now: day(2026, 11, 2), calendar: jst)
        #expect(s.daysSince == 19)
        #expect(s.grownCm == 0.6)
        #expect(s.daysLeft == 11)
        #expect(s.phase == .growing)
        #expect(s.nextDue == jst.startOfDay(for: day(2026, 11, 13)))
    }

    @Test func そろそろとすぎ() {
        let cuts = [day(2026, 9, 14), day(2026, 10, 14)]
        #expect(TrimRhythm.status(cuts: cuts, now: day(2026, 10, 16), calendar: jst).phase == .fresh)
        #expect(TrimRhythm.status(cuts: cuts, now: day(2026, 11, 8), calendar: jst).phase == .soon)
        #expect(TrimRhythm.status(cuts: cuts, now: day(2026, 11, 13), calendar: jst).phase == .soon)
        #expect(TrimRhythm.status(cuts: cuts, now: day(2026, 11, 14), calendar: jst).phase == .overdue)
    }
}

struct PreventionPlanTests {
    let heart = PreventionPlan.Season(start: 5, end: 12)

    @Test func ワクチンは1年後() {
        #expect(PreventionPlan.next(kind: .combo, last: day(2026, 4, 10), season: heart, today: day(2026, 11, 14), calendar: jst) == jst.startOfDay(for: day(2027, 4, 10)))
        #expect(PreventionPlan.next(kind: .rabies, last: nil, season: heart, today: day(2026, 11, 14), calendar: jst) == nil)
    }

    @Test func シーズン中は1か月後() {
        #expect(PreventionPlan.next(kind: .heartworm, last: day(2026, 10, 20), season: heart, today: day(2026, 11, 14), calendar: jst) == jst.startOfDay(for: day(2026, 11, 20)))
    }

    @Test func シーズン最後のあとは来年の初め() {
        #expect(PreventionPlan.next(kind: .heartworm, last: day(2026, 12, 5), season: heart, today: day(2026, 12, 6), calendar: jst) == jst.startOfDay(for: day(2027, 5, 1)))
        // シーズン外で過ぎていても、遅れではなく次のシーズン
        #expect(PreventionPlan.next(kind: .heartworm, last: day(2026, 11, 5), season: heart, today: day(2027, 2, 1), calendar: jst) == jst.startOfDay(for: day(2027, 5, 1)))
    }

    @Test func シーズン中の遅れは今シーズンの初めより前にしない() {
        #expect(PreventionPlan.next(kind: .heartworm, last: day(2025, 11, 5), season: heart, today: day(2026, 6, 10), calendar: jst) == jst.startOfDay(for: day(2026, 5, 1)))
        #expect(PreventionPlan.next(kind: .heartworm, last: day(2026, 5, 5), season: heart, today: day(2026, 6, 10), calendar: jst) == jst.startOfDay(for: day(2026, 6, 5)))
    }

    @Test func 記録なし() {
        #expect(PreventionPlan.next(kind: .heartworm, last: nil, season: heart, today: day(2026, 6, 10), calendar: jst) == jst.startOfDay(for: day(2026, 6, 10)))
        #expect(PreventionPlan.next(kind: .heartworm, last: nil, season: heart, today: day(2026, 2, 10), calendar: jst) == jst.startOfDay(for: day(2026, 5, 1)))
    }

    @Test func 年をまたぐシーズンと通年() {
        let winter = PreventionPlan.Season(start: 11, end: 2)
        #expect(winter.contains(month: 1))
        #expect(!winter.contains(month: 5))
        #expect(PreventionPlan.Season.allYear.isAllYear)
        #expect(PreventionPlan.next(kind: .fleaTick, last: day(2026, 12, 20), season: .allYear, today: day(2026, 12, 21), calendar: jst) == jst.startOfDay(for: day(2027, 1, 20)))
        #expect(PreventionPlan.next(kind: .fleaTick, last: day(2026, 2, 20), season: winter, today: day(2026, 3, 1), calendar: jst) == jst.startOfDay(for: day(2026, 11, 1)))
    }
}

struct WeightTrendTests {
    @Test func ひと月で5パーセント減ると声をかける() {
        let r = WeightTrend.read([(day(2026, 10, 10), 3.4), (day(2026, 11, 10), 3.2)], calendar: jst)
        #expect(r?.alert == .dropping(percent: 6))
        #expect(r?.sincePrevious == -0.2)
    }

    @Test func 少しの変化は静か() {
        let r = WeightTrend.read([(day(2026, 10, 10), 3.4), (day(2026, 11, 10), 3.35)], calendar: jst)
        #expect(r?.alert == nil)
    }

    @Test func 近すぎる比較はしない() {
        let r = WeightTrend.read([(day(2026, 11, 1), 3.4), (day(2026, 11, 10), 3.0)], calendar: jst)
        #expect(r?.monthRatio == nil)
        #expect(r?.alert == nil)
    }

    @Test func パピーは増えても声をかけない() {
        let points = [(day(2026, 10, 10), 1.5), (day(2026, 11, 10), 1.8)]
        #expect(WeightTrend.read(points, growing: true, calendar: jst)?.alert == nil)
        #expect(WeightTrend.read(points, growing: false, calendar: jst)?.alert == .gaining(percent: 20))
    }
}

struct WalkTallyTests {
    @Test func 七日間の散歩() {
        let pages = [(day(2026, 11, 14), 30, 2), (day(2026, 11, 10), 20, 1), (day(2026, 11, 7), 60, 2), (day(2026, 11, 12), 0, 0)]
        let week = WalkTally.week(pages: pages, now: day(2026, 11, 14), calendar: jst)
        #expect(week.minutes == 50)
        #expect(week.walkedDays == 2)
    }

    @Test func つづけて書いた日数() {
        let days = [day(2026, 11, 13), day(2026, 11, 12), day(2026, 11, 10)]
        #expect(WalkTally.streak(days: days, now: day(2026, 11, 14), calendar: jst) == 2)
        #expect(WalkTally.streak(days: days + [day(2026, 11, 14)], now: day(2026, 11, 14), calendar: jst) == 3)
        #expect(WalkTally.streak(days: [day(2026, 11, 10)], now: day(2026, 11, 14), calendar: jst) == 0)
    }
}

struct DailyNudgeTests {
    @Test func 過ぎた予防は今日の朝にまとめる() {
        let care = [DailyNudge.DueThing(dog: "むぎ", what: "フィラリアの薬", day: day(2026, 11, 10)),
                    DailyNudge.DueThing(dog: "むぎ", what: "混合ワクチン", day: day(2026, 11, 16))]
        let trims = [DailyNudge.DueThing(dog: "あずき", what: "トリミング", day: day(2026, 11, 16))]
        let mornings = DailyNudge.mornings(prevention: care, trims: trims, today: day(2026, 11, 14), calendar: jst)
        #expect(mornings.count == 2)
        #expect(mornings[0].lines == ["むぎ：フィラリアの薬の日です"])
        #expect(mornings[1].lines == ["むぎ：混合ワクチンの日です", "あずき：そろそろトリミングの時期です"])
    }

    @Test func 過ぎたトリミングは毎朝言わない() {
        let trims = [DailyNudge.DueThing(dog: "むぎ", what: "トリミング", day: day(2026, 11, 1))]
        #expect(DailyNudge.mornings(prevention: [], trims: trims, today: day(2026, 11, 14), calendar: jst).isEmpty)
    }

    @Test func 夜は書いた日をとばす() {
        #expect(DailyNudge.eveningDays(writtenToday: true, today: day(2026, 11, 14), calendar: jst).count == 6)
        #expect(DailyNudge.eveningDays(writtenToday: false, today: day(2026, 11, 14), calendar: jst).first == jst.startOfDay(for: day(2026, 11, 14)))
    }

    @Test func 長い通知はたたむ() {
        let m = DailyNudge.Morning(day: day(2026, 11, 14), lines: ["a", "b", "c", "d", "e"])
        #expect(DailyNudge.body(m) == "a\nb\nc\nほか2件")
    }
}
