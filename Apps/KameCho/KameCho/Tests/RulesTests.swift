import Foundation
import Testing
@testable import KameCho

private let cal: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return c
}()

private func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

struct RhythmTests {
    @Test func youngWaterTurtleEatsDaily() {
        #expect(Rhythm.days(.feed, habitat: .water, young: true) == 1)
        #expect(Rhythm.days(.feed, habitat: .water, young: false) == 2)
        #expect(Rhythm.days(.soak, habitat: .water, young: false) == 0)
        #expect(Rhythm.days(.soak, habitat: .land, young: false) == 4)
    }

    @Test func youngUntilOneYear() {
        #expect(Rhythm.isYoung(ageBase: day(2026, 1, 1), now: day(2026, 12, 31), calendar: cal))
        #expect(!Rhythm.isYoung(ageBase: day(2025, 1, 1), now: day(2026, 1, 2), calendar: cal))
    }
}

struct DueListTests {
    @Test func neverDoneIsDueToday() {
        let list = DueList.make(intervals: [.feed: 2], lastCare: [:], lastMeasure: nil, resting: false, now: day(2026, 11, 19), calendar: cal)
        #expect(list.count == 2)
        #expect(list.allSatisfy { $0.late == 0 })
    }

    @Test func lateDaysAreCounted() {
        let list = DueList.make(intervals: [.feed: 2, .water: 3], lastCare: [.feed: day(2026, 11, 14, 20), .water: day(2026, 11, 18)], lastMeasure: day(2026, 11, 10), resting: false, now: day(2026, 11, 19), calendar: cal)
        let feed = list.first { $0.task == .care(.feed) }!
        let water = list.first { $0.task == .care(.water) }!
        let measure = list.first { $0.task == .measure }!
        #expect(feed.late == 3)
        #expect(water.late == -2)
        #expect(!water.isDue)
        #expect(measure.late == -5)
        #expect(list.first?.task == .care(.feed))
    }

    @Test func restingKeepsOnlyWeekWeighing() {
        let list = DueList.make(intervals: [.feed: 1], lastCare: [:], lastMeasure: day(2026, 11, 12), resting: true, now: day(2026, 11, 19), calendar: cal)
        #expect(list.map(\.task) == [.measure])
        #expect(list[0].late == 0)
    }

    @Test func zeroIntervalIsSkipped() {
        let list = DueList.make(intervals: [.feed: 0, .sun: 0], lastCare: [:], lastMeasure: day(2026, 11, 19), resting: false, now: day(2026, 11, 19), calendar: cal)
        #expect(list.map(\.task) == [.measure])
    }
}

struct GrowthMathTests {
    @Test func changeFromPrevious() {
        let pts = [GrowthMath.Point(on: day(2026, 1, 1), value: 80), .init(on: day(2026, 2, 1), value: 83.5)]
        #expect(GrowthMath.change(pts) == 3.5)
        #expect(GrowthMath.change(Array(pts.prefix(1))) == nil)
    }

    @Test func perYearNeedsTwoMonths() {
        let short = [GrowthMath.Point(on: day(2026, 1, 1), value: 80), .init(on: day(2026, 2, 1), value: 83)]
        #expect(GrowthMath.perYear(short, now: day(2026, 2, 1), calendar: cal) == nil)
        let long = [GrowthMath.Point(on: day(2025, 1, 1), value: 60), .init(on: day(2025, 7, 1), value: 70), .init(on: day(2026, 1, 1), value: 84)]
        let v = GrowthMath.perYear(long, now: day(2026, 1, 1), calendar: cal)!
        #expect(abs(v - 24) < 0.1)
    }
}

struct HibernationWatchTests {
    @Test func slowLossIsFine() {
        let r = HibernationWatch.check(startGrams: 500, startedOn: day(2026, 12, 1), grams: 496, on: day(2026, 12, 31), calendar: cal)!
        #expect(abs(r.lostPercent - 0.8) < 0.001)
        #expect(r.level == .fine)
    }

    @Test func fastLossIsCareful() {
        let r = HibernationWatch.check(startGrams: 500, startedOn: day(2026, 12, 1), grams: 492, on: day(2026, 12, 31), calendar: cal)!
        #expect(r.level == .careful)
    }

    @Test func tenPercentMeansWake() {
        let r = HibernationWatch.check(startGrams: 500, startedOn: day(2026, 11, 1), grams: 450, on: day(2027, 3, 1), calendar: cal)!
        #expect(r.level == .wake)
    }

    @Test func firstDaysAreNotOverread() {
        // 3日で 0.5% 減っても、2週間ぶんとして割る。
        let r = HibernationWatch.check(startGrams: 400, startedOn: day(2026, 12, 1), grams: 398, on: day(2026, 12, 4), calendar: cal)!
        #expect(r.level == .careful || r.level == .fine)
        #expect(r.perMonth < 1.1)
    }
}

struct HeatTests {
    @Test func bandsDifferByHabitat() {
        #expect(Heat.band(for: .redEared).base == 24...28)
        #expect(Heat.band(for: .sulcata).spot == 33...40)
        #expect(Heat.judge(22, in: 24...28) == .low)
        #expect(Heat.judge(29, in: 24...28) == .high)
        #expect(Heat.judge(26, in: 24...28) == .ok)
    }
}

struct GearLifeTests {
    @Test func uvbHalfYear() {
        let left = GearLife.daysLeft(installedOn: day(2026, 6, 1), lifeDays: 180, now: day(2026, 11, 19), calendar: cal)
        #expect(left == 9)
        #expect(GearLife.soon(daysLeft: left))
        let used = GearLife.used(installedOn: day(2026, 6, 1), lifeDays: 180, now: day(2026, 11, 19), calendar: cal)
        #expect(abs(used - 0.95) < 0.001)
    }

    @Test func overdueIsNegative() {
        #expect(GearLife.daysLeft(installedOn: day(2026, 1, 1), lifeDays: 30, now: day(2026, 2, 5), calendar: cal) == -5)
        #expect(GearLife.used(installedOn: day(2026, 1, 1), lifeDays: 30, now: day(2026, 2, 5), calendar: cal) == 1)
    }
}

struct ConcernsTests {
    private func input(_ change: (inout Concerns.Input) -> Void = { _ in }) -> Concerns.Input {
        var i = Concerns.Input(species: .reeves, resting: false, appetites: [], recentSigns: [], baseC: nil, spotC: nil, hibernation: nil, month: 6)
        change(&i)
        return i
    }

    @Test func quietDayHasNothing() {
        #expect(Concerns.list(input()).isEmpty)
    }

    @Test func threeMissedMeals() {
        let list = Concerns.list(input { $0.appetites = [.none, .none, .none, .all] })
        #expect(list.count == 1)
        #expect(list[0].level == .careful)
        #expect(Concerns.list(input { $0.appetites = [.none, .some, .none] }).isEmpty)
    }

    @Test func seriousSignComesFirst() {
        let list = Concerns.list(input {
            $0.recentSigns = [.gaping]
            $0.baseC = 20
        })
        #expect(list.first?.level == .urgent)
        #expect(list.count == 2)
    }

    @Test func coldWaterWhileRestingIsFine() {
        #expect(Concerns.list(input {
            $0.resting = true
            $0.baseC = 8
        }).isEmpty)
    }

    @Test func tropicalMustNotRest() {
        let list = Concerns.list(input {
            $0.species = .sulcata
            $0.resting = true
            $0.month = 1
        })
        #expect(list.first?.level == .urgent)
    }

    @Test func hibernationLoss() {
        let h = HibernationWatch.Result(lostPercent: 11, perMonth: 3, level: .wake)
        let list = Concerns.list(input {
            $0.resting = true
            $0.hibernation = h
        })
        #expect(list.first?.level == .urgent)
    }
}

struct MorningNoteTests {
    @Test func groupsByTask() {
        let body = MorningNote.body(lines: [.init(turtle: "かめきち", task: "ごはん"), .init(turtle: "ぽんず", task: "ごはん"), .init(turtle: "かめきち", task: "水換え")], gearNames: ["UVB"])
        #expect(body == "ごはん：かめきち・ぽんず\n水換え：かめきち\n交換の時期：UVB")
        #expect(MorningNote.body(lines: [], gearNames: []) == nil)
    }
}

struct ParseTests {
    @Test func acceptsFullWidthAndComma() {
        #expect(Fmt.parse("１２３．５") == 123.5)
        #expect(Fmt.parse("12,5") == 12.5)
        #expect(Fmt.parse("") == nil)
    }
}
