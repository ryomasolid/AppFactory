import Foundation
import Testing
@testable import InkoCho

private let cal: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return c
}()

private func d(_ m: Int, _ day: Int, _ h: Int = 8) -> Date {
    cal.date(from: DateComponents(year: 2026, month: m, day: day, hour: h))!
}

struct GramWatchTests {
    private func series(_ grams: [Double], endingOn end: Date = d(11, 16)) -> [(day: Date, grams: Double)] {
        grams.enumerated().map { (cal.date(byAdding: .day, value: $0.offset - grams.count + 1, to: end)!, $0.element) }
    }

    @Test func ふだんどおり() {
        let r = GramWatch.read(series([35, 35.2, 34.8, 35, 35.1, 35, 34.9, 35.0]), calendar: cal)
        #expect(r?.level == .steady)
        #expect(r?.usual == 35.0)
    }

    @Test func 五パーセント減で注意() {
        let r = GramWatch.read(series([35, 35, 35, 35, 35, 35, 35, 33.2]), calendar: cal)
        #expect(r?.level == .dipping(percent: 5))
    }

    @Test func 十パーセント減は急ぐ() {
        let r = GramWatch.read(series([35, 35, 35, 35, 35, 35, 35, 31.0]), calendar: cal)
        #expect(r?.level == .falling(percent: 11))
    }

    @Test func 増えすぎ() {
        let r = GramWatch.read(series([35, 35, 35, 39]), calendar: cal)
        #expect(r?.level == .rising(percent: 11))
    }

    @Test func 比べる記録がなければ静か() {
        let r = GramWatch.read(series([30]), calendar: cal)
        #expect(r?.level == .steady)
        #expect(r?.usual == nil)
        // 8日以上前の記録とはくらべない
        let old = [(d(11, 1), 40.0), (d(11, 16), 35.0)]
        #expect(GramWatch.read(old, calendar: cal)?.level == .steady)
    }

    @Test func 三回つづけて減る() {
        #expect(GramWatch.read(series([35.4, 35.2, 35.0, 34.8]), calendar: cal)?.slidingDown == true)
        #expect(GramWatch.read(series([35.4, 35.2, 35.3, 34.8]), calendar: cal)?.slidingDown == false)
    }
}

struct WarmthTests {
    @Test func おとなの目安() {
        #expect(Warmth.verdict(celsius: 13) == .cold)
        #expect(Warmth.verdict(celsius: 18) == .chilly)
        #expect(Warmth.verdict(celsius: 24) == .good)
        #expect(Warmth.verdict(celsius: 30) == .warm)
        #expect(Warmth.verdict(celsius: 33) == .hot)
    }

    @Test func ヒナは高め() {
        #expect(Warmth.verdict(celsius: 23, young: true) == .chilly)
        #expect(Warmth.verdict(celsius: 26, young: true) == .good)
        #expect(Warmth.isYoung(hatchedOn: d(8, 1), now: d(11, 16), calendar: cal))
        #expect(!Warmth.isYoung(hatchedOn: d(1, 1), now: d(11, 16), calendar: cal))
    }

    @Test func 年齢() {
        #expect(Warmth.ageText(hatchedOn: d(11, 1), now: d(11, 16), calendar: cal) == "生まれたて")
        #expect(Warmth.ageText(hatchedOn: d(8, 10), now: d(11, 16), calendar: cal) == "3か月")
        #expect(Warmth.ageText(hatchedOn: cal.date(byAdding: .month, value: -26, to: d(11, 16))!, now: d(11, 16), calendar: cal) == "2さい2か月")
    }
}

struct SeasonsTests {
    @Test func 換羽の日数() {
        let days = [d(11, 12), d(11, 13), d(11, 14), d(11, 15)]
        #expect(Seasons.moltDays(days, now: d(11, 15), calendar: cal) == 4)
        #expect(Seasons.moltDays(days, now: d(11, 16), calendar: cal) == 4)
        #expect(Seasons.moltDays(days, now: d(11, 18), calendar: cal) == 0)
    }

    @Test func 直近の卵() {
        let eggs = [d(10, 30), d(11, 3), d(11, 5), d(11, 7)]
        #expect(Seasons.recentEggs(eggs, now: d(11, 16), calendar: cal) == 3)
    }

    @Test func 放鳥の平均() {
        let e = [(d(11, 16), 40), (d(11, 15), 0), (d(11, 14), 60), (d(11, 1), 300)]
        #expect(Seasons.outsideAverage(e, now: d(11, 16), calendar: cal) == 50)
        #expect(Seasons.outsideAverage([], now: d(11, 16), calendar: cal) == nil)
    }
}

struct ChoreClockTests {
    @Test func 次の目安() {
        let due = ChoreClock.due(kind: .cage, last: d(11, 10), now: d(11, 16), calendar: cal)
        #expect(due.daysLeft == 1)
        #expect(due.next == cal.startOfDay(for: d(11, 17)))
        #expect(ChoreClock.due(kind: .nail, last: nil, now: d(11, 16), calendar: cal).next == nil)
    }
}

struct WatchlistTests {
    private func facts(weight: GramWatch.Level = .steady, look: Look? = nil, droppings: [Dropping?] = [], warmth: Warmth.Verdict? = nil, eggs: Int = 0, female: Bool = false, molt: Int = 0) -> Watchlist.Facts {
        Watchlist.Facts(
            weight: GramWatch.Reading(latest: 35, latestDay: d(11, 16), usual: 35, level: weight, slidingDown: false),
            lastLook: look, recentDroppings: droppings, warmth: warmth, eggsIn14Days: eggs, isFemale: female, moltDays: molt
        )
    }

    @Test func 何もなければ空() {
        #expect(Watchlist.items(facts()).isEmpty)
    }

    @Test func ふくらみと体重減は急ぐ() {
        let items = Watchlist.items(facts(weight: .dipping(percent: 6), look: .fluffed))
        #expect(items.first?.severity == .urgent)
        #expect(items.map(\.id).contains("weight"))
        #expect(Watchlist.items(facts(look: .fluffed)).first?.severity == .caution)
    }

    @Test func フンは二日つづいたら() {
        #expect(Watchlist.items(facts(droppings: [.watery])).isEmpty)
        #expect(Watchlist.items(facts(droppings: [.watery, .green])).map(\.id) == ["dropping"])
        #expect(Watchlist.items(facts(droppings: [.watery, .normal])).isEmpty)
    }

    @Test func 卵はメスだけ() {
        #expect(Watchlist.items(facts(eggs: 3, female: true)).map(\.id) == ["eggs"])
        #expect(Watchlist.items(facts(eggs: 3, female: false)).isEmpty)
    }

    @Test func 重いものが先() {
        let items = Watchlist.items(facts(weight: .falling(percent: 12), warmth: .chilly, molt: 3))
        #expect(items.map(\.severity) == [.urgent, .note, .note])
    }
}

struct MorningPlanTests {
    @Test func はかった日はとばす() {
        let plan = MorningPlan.plan(birdNames: ["ソラ"], weighedToday: true, chores: [], today: d(11, 16), calendar: cal)
        #expect(plan.count == 6)
        #expect(plan.first?.body == "ソラの体重をはかろう")
    }

    @Test func 過ぎたおせわは今日にまとめる() {
        let chores: [(bird: String, kind: ChoreKind, due: Date)] = [("ソラ", .cage, d(11, 10)), ("キウイ", .cage, d(11, 16)), ("ソラ", .nail, d(11, 18))]
        let plan = MorningPlan.plan(birdNames: ["ソラ", "キウイ"], weighedToday: false, chores: chores, today: d(11, 16), calendar: cal)
        #expect(plan[0].body == "ソラ・キウイの体重をはかろう\nおせわ：ケージの大掃除")
        #expect(plan[2].body.contains("爪切り"))
    }
}
