import Foundation
import Testing
@testable import MudaZero

private let cal: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return c
}()

private func d(_ m: Int, _ day: Int, _ h: Int = 12) -> Date {
    cal.date(from: DateComponents(year: 2026, month: m, day: day, hour: h))!
}

private func want(_ m: Int, _ day: Int, _ yen: Int, _ t: SpendType = .konbini) -> Entry { Entry(day: d(m, day), yen: yen, category: t) }
private func need(_ m: Int, _ day: Int, _ yen: Int) -> Entry { Entry(day: d(m, day), yen: yen, category: .groceries) }

struct DayKindTests {
    @Test func しめた日で出費なしは0円の日() {
        let b = Book(entries: [], closedDays: [d(11, 10)], calendar: cal)
        #expect(b.kind(on: d(11, 10)) == .zero)
    }

    @Test func 必要な出費だけなら_ムダゼロ() {
        let b = Book(entries: [need(11, 10, 1800)], closedDays: [d(11, 10, 23)], calendar: cal)
        #expect(b.kind(on: d(11, 10)) == .clean(need: 1800))
    }

    @Test func ついついがあれば_しめていても_ついつい() {
        let b = Book(entries: [want(11, 10, 300), need(11, 10, 500), want(11, 10, 200)], closedDays: [d(11, 10)], calendar: cal)
        #expect(b.kind(on: d(11, 10)) == .slipped(want: 500, need: 500))
    }

    @Test func しめていない日はまだ() {
        let b = Book(entries: [need(11, 10, 500)], closedDays: [], calendar: cal)
        #expect(b.kind(on: d(11, 10)) == .open(need: 500))
        #expect(b.kind(on: d(11, 11)) == .open(need: 0))
    }
}

struct StreakTests {
    private let book = Book(
        entries: [want(11, 12, 400), need(11, 14, 900)],
        closedDays: [d(11, 13), d(11, 14), d(11, 15), d(11, 16)],
        calendar: cal
    )

    @Test func きょうがまだならきのうまでを数える() {
        #expect(book.streak(today: d(11, 17)) == 4)
    }

    @Test func きょうしめたらきょうも入る() {
        #expect(book.streak(today: d(11, 16)) == 4)
        #expect(book.streak(today: d(11, 15)) == 3)
    }

    @Test func ついついで切れる() {
        let b = Book(entries: [want(11, 17, 100)], closedDays: [d(11, 16)], calendar: cal)
        #expect(b.streak(today: d(11, 17)) == 0)
    }

    @Test func 一日あくと切れる() {
        #expect(book.streak(today: d(11, 18)) == 0)
    }

    @Test func 最長記録() {
        let b = Book(entries: [want(11, 5, 100)], closedDays: [d(11, 1), d(11, 2), d(11, 3), d(11, 6), d(11, 7)], calendar: cal)
        #expect(b.bestStreak(through: d(11, 8)) == 3)
    }
}

struct SavedTests {
    @Test func ムダゼロの日はふだんのムダぶん浮く() {
        let b = Book(
            entries: [want(11, 2, 200), want(11, 3, 900)],
            closedDays: [d(11, 1), d(11, 4)],
            calendar: cal
        )
        // 1日 500 + 2日 300 + 3日 0（使いすぎはマイナスにしない）+ 4日 500 + 5日 まだ 0
        #expect(b.saved(from: d(11, 1), through: d(11, 5), usual: 500) == 1300)
    }

    @Test func ふだんのムダが0なら0() {
        let b = Book(entries: [], closedDays: [d(11, 1)], calendar: cal)
        #expect(b.saved(from: d(11, 1), through: d(11, 1), usual: 0) == 0)
    }
}

struct MonthTests {
    @Test func 月のまとめと内訳() {
        let b = Book(
            entries: [want(11, 2, 300, .cafe), want(11, 3, 1200, .online), want(11, 9, 400, .cafe), need(11, 4, 2000), want(10, 31, 999)],
            closedDays: [d(11, 1), d(11, 4), d(11, 5)],
            calendar: cal
        )
        let s = b.month(of: d(11, 20))
        #expect(s.zeroDays == 2)
        #expect(s.cleanDays == 1)
        #expect(s.slippedDays == 3)
        #expect(s.want == 1900)
        #expect(s.need == 2000)
        #expect(s.wantByCategory.map(\.category) == [.online, .cafe])
        #expect(s.wantByCategory.map(\.yen) == [1200, 700])
    }

    @Test func 予算のペース() {
        let b = Book(entries: [want(11, 2, 3000), want(11, 10, 1000)], closedDays: [], calendar: cal)
        let p = b.pace(budget: 10000, today: d(11, 18))
        #expect(p.spent == 4000)
        #expect(p.daysLeft == 13)
        #expect(p.left == 6000)
        #expect(p.perDay == 461)
        #expect(!p.over)
    }

    @Test func 予算オーバー() {
        let b = Book(entries: [want(11, 2, 12000)], closedDays: [], calendar: cal)
        let p = b.pace(budget: 10000, today: d(11, 30))
        #expect(p.over)
        #expect(p.perDay == 0)
        #expect(p.daysLeft == 1)
    }
}

struct NightPlanTests {
    @Test func しめた日はきょうのお知らせを出さない() {
        let b = Book(entries: [], closedDays: [d(11, 18)], calendar: cal)
        let nights = NightPlan.plan(book: b, today: d(11, 18, 9), days: 3)
        #expect(nights.count == 2)
        #expect(nights.first?.day == cal.startOfDay(for: d(11, 19)))
    }

    @Test func 連続中はその日数を伝える() {
        let b = Book(entries: [], closedDays: [d(11, 16), d(11, 17)], calendar: cal)
        let nights = NightPlan.plan(book: b, today: d(11, 18, 9), days: 1)
        #expect(nights.first?.body.contains("2日") == true)
    }
}
