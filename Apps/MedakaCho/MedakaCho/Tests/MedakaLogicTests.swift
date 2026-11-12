import Foundation
import Testing
@testable import MedakaCho

private let tokyo: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return calendar
}()

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 8) -> Date {
    tokyo.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

struct WaterSenseTests {
    @Test func 水温で季節の様子が変わる() {
        #expect(WaterSense.mood(celsius: 6) == .dormant)
        #expect(WaterSense.mood(celsius: 12) == .sluggish)
        #expect(WaterSense.mood(celsius: 17) == .mild)
        #expect(WaterSense.mood(celsius: 24) == .lively)
        #expect(WaterSense.mood(celsius: 29) == .warm)
        #expect(WaterSense.mood(celsius: 32) == .tooWarm)
    }

    @Test func 過密は育ちで線が変わる() {
        #expect(WaterSense.isCrowded(liters: 10, headcount: 12, stage: .adult))
        #expect(!WaterSense.isCrowded(liters: 10, headcount: 12, stage: .juvenile))
        #expect(!WaterSense.isCrowded(liters: 10, headcount: 0, stage: .adult))
    }

    @Test func 水換えの間隔() {
        // 屋内・1匹2L → 14日
        #expect(WaterSense.waterChangeInterval(liters: 20, headcount: 10, outdoors: false, celsius: 22) == 14)
        // 屋外はゆるめ
        #expect(WaterSense.waterChangeInterval(liters: 20, headcount: 10, outdoors: true, celsius: 22) == 18)
        // 冬は控える
        #expect(WaterSense.waterChangeInterval(liters: 5, headcount: 20, outdoors: false, celsius: 8) == 30)
        // 過密で暑いと短い（下限3日）
        #expect(WaterSense.waterChangeInterval(liters: 5, headcount: 20, outdoors: false, celsius: 31) == 3)
    }
}

struct HatchClockTests {
    @Test func 積算250で孵る() {
        #expect(HatchClock.daysToHatch(celsius: 25) == 10)
        #expect(HatchClock.daysToHatch(celsius: 20) == 13)
        #expect(HatchClock.daysToHatch(celsius: 12) == nil)
    }

    @Test func 進み具合() {
        let start = date(2026, 11, 1)
        #expect(HatchClock.progress(collectedOn: start, celsius: 25, now: date(2026, 11, 6), calendar: tokyo) == 0.5)
        #expect(HatchClock.progress(collectedOn: start, celsius: 25, now: date(2026, 11, 20), calendar: tokyo) == 1)
        #expect(HatchClock.expectedDay(collectedOn: start, celsius: 25, calendar: tokyo) == tokyo.startOfDay(for: date(2026, 11, 11)))
    }

    @Test func 孵化率() {
        #expect(HatchClock.hatchRate(eggs: 30, hatched: 26) == 87)
        #expect(HatchClock.hatchRate(eggs: 0, hatched: 0) == nil)
    }
}

struct MorningDigestTests {
    @Test func 過ぎた水換えは今日にまとめて1通() {
        let today = date(2026, 11, 12)
        let items = MorningDigest.schedule(
            water: [("鉢", date(2026, 11, 10)), ("水槽", date(2026, 11, 12)), ("発泡", date(2026, 11, 14))],
            hatchDays: [date(2026, 11, 14), date(2026, 11, 14)],
            today: today,
            calendar: tokyo
        )
        #expect(items.count == 2)
        #expect(items[0].water == ["鉢", "水槽"])
        #expect(items[1].water == ["発泡"])
        #expect(items[1].hatch == 2)
        #expect(MorningDigest.message(for: items[1]) == "水換え: 発泡\n卵が孵りそう: 2組")
    }

    @Test func 一週間より先は入れない() {
        let items = MorningDigest.schedule(water: [("鉢", date(2026, 11, 30))], hatchDays: [], today: date(2026, 11, 12), calendar: tokyo)
        #expect(items.isEmpty)
    }
}

struct LogTableTests {
    @Test func カンマと引用符をくくる() {
        #expect(LogTable.quote("ふつう") == "ふつう")
        #expect(LogTable.quote("a,b") == "\"a,b\"")
        #expect(LogTable.quote("\"x\"") == "\"\"\"x\"\"\"")
    }
}
