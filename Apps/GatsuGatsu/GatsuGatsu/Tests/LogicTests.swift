import Foundation
import Testing
@testable import GatsuGatsu

struct PortionsTests {
    @Test func 茹で前300gの換算はサイトの表と同じ() {
        let n = Portions.noodle(grams: 300, isBoiledFigure: false)
        #expect(abs(n.boiled - 570) < 0.01)
        #expect(abs(n.kcal - 747) < 0.01)
        #expect(abs(n.ramenCount - 2) < 0.01)
    }

    @Test func 茹で後表記は茹で前へ戻して計算する() {
        let n = Portions.noodle(grams: 570, isBoiledFigure: true)
        #expect(abs(n.raw - 300) < 0.01)
    }

    @Test func ご飯300gは茶碗2杯で468kcal() {
        #expect(Portions.riceBowls(grams: 300) == 2)
        #expect(abs(Portions.riceKcal(grams: 300) - 468) < 0.01)
    }
}

struct QueueEstimateTests {
    @Test func 席数と同じ人数なら1回転ぶん待つ() {
        #expect(QueueEstimate.minutes(people: 20, seats: 20, stay: 15) == 15)
    }

    @Test func 端数は切り上げる() {
        #expect(QueueEstimate.minutes(people: 7, seats: 20, stay: 15) == 6)
    }

    @Test func 誰も並んでいなければ0分() {
        #expect(QueueEstimate.minutes(people: 0, seats: 20, stay: 15) == 0)
    }

    @Test func 通知は5分前で_5分以下なら出さない() {
        let now = Date(timeIntervalSince1970: 1000)
        #expect(QueueEstimate.reminderDate(minutes: 5, now: now) == nil)
        #expect(QueueEstimate.reminderDate(minutes: 15, now: now) == now.addingTimeInterval(600))
    }
}

struct SplitBillTests {
    @Test func 上司が多めに出す() throws {
        let tier = SplitBill.Tier(name: "上司", count: 1, adjustment: 2000)
        let result = try SplitBill.calculate(bill: 10000, people: 5, tiers: [tier]).get()
        #expect(result.lines.map(\.perPerson) == [1600, 3600])
        #expect(result.lines.map(\.count) == [4, 1])
        #expect(result.surplus == 0)
    }

    @Test func 百円単位で切り上げた差は幹事預かりになる() throws {
        let result = try SplitBill.calculate(bill: 10000, people: 3, tiers: []).get()
        #expect(result.lines.first?.perPerson == 3400)
        #expect(result.surplus == 200)
        #expect(result.shareText.contains("幹事の預かり 200円"))
    }

    @Test func 入力の間違いを知らせる() {
        #expect(SplitBill.calculate(bill: 0, people: 3, tiers: []) == .failure(.noBill))
        #expect(SplitBill.calculate(bill: 100, people: 0, tiers: []) == .failure(.noPeople))
        let everyone = SplitBill.Tier(name: "全員", count: 3, adjustment: 0)
        #expect(SplitBill.calculate(bill: 100, people: 3, tiers: [everyone]) == .failure(.noRegulars))
    }

    @Test func 差額が大きすぎるとマイナスと分かる() {
        let tier = SplitBill.Tier(name: "後輩", count: 1, adjustment: -5000)
        #expect(SplitBill.calculate(bill: 3000, people: 3, tiers: [tier]) == .failure(.negative("後輩")))
    }
}

struct BiteStatsTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return c
    }

    private func date(_ day: Int, month: Int = 10, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    private func bite(_ day: Int, _ kcal: Double, place: String? = nil, month: Int = 10) -> Bite {
        Bite(eatenAt: date(day, month: month), name: "x", place: place, kcal: kcal, protein: 10)
    }

    @Test func 手入力はPFCなしでも合計できる() {
        let stats = BiteStats(bites: [bite(1, 234), Bite(eatenAt: date(1), name: "y", kcal: 234)], calendar: calendar)
        let sum = stats.summary(of: stats.bites)
        #expect(sum.kcal == 468)
        #expect(sum.protein == 10)
        #expect(abs(sum.riceBowls - 2) < 0.01)
    }

    @Test func 七日ぶんは記録のない日を0で埋めて古い順() {
        let stats = BiteStats(bites: [bite(10, 500), bite(10, 100), bite(4, 300), bite(3, 999)], calendar: calendar)
        let week = stats.lastWeek(until: date(10))
        #expect(week.count == 7)
        #expect(week.first?.kcal == 300)
        #expect(week.last?.kcal == 600)
        #expect(week[1].kcal == 0)
    }

    @Test func 月のまとめは今月だけを数える() {
        let stats = BiteStats(bites: [
            bite(1, 500, place: "吉野家"), bite(1, 300, place: "吉野家"), bite(2, 1000, place: "松屋"), bite(30, 9999, month: 9),
        ], calendar: calendar)
        let month = stats.monthReport(containing: date(15))
        #expect(month.summary.kcal == 1800)
        #expect(month.activeDays == 2)
        #expect(month.biggestDay?.kcal == 1000)
        #expect(month.favoritePlace == "吉野家")
        #expect(month.kcalPerActiveDay == 900)
    }

    @Test func 記録がない月でも落ちない() {
        let month = BiteStats(bites: [], calendar: calendar).monthReport(containing: date(1))
        #expect(month.biggestDay == nil)
        #expect(month.kcalPerActiveDay == 0)
    }
}

struct AdPacingTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func readyToShow() -> AdPacing {
        var p = AdPacing()
        p.noteLaunch(now: start)
        for _ in 0..<AdPacing.pagesPerInterstitial { p.notePageFinished() }
        return p
    }

    @Test func 起動直後は出さない() {
        #expect(!readyToShow().allowsInterstitial(now: start.addingTimeInterval(10)))
        #expect(readyToShow().allowsInterstitial(now: start.addingTimeInterval(AdPacing.launchGrace)))
    }

    @Test func 読み終えた数が足りなければ出さない() {
        var p = AdPacing()
        p.noteLaunch(now: start)
        p.notePageFinished()
        #expect(!p.allowsInterstitial(now: start.addingTimeInterval(3600)))
    }

    @Test func 出したあとは数え直して間隔も空ける() {
        var p = readyToShow()
        let shown = start.addingTimeInterval(100)
        p.noteInterstitialShown(now: shown)
        #expect(p.pagesSinceFullScreen == 0)
        for _ in 0..<AdPacing.pagesPerInterstitial { p.notePageFinished() }
        #expect(!p.allowsInterstitial(now: shown.addingTimeInterval(60)))
        #expect(p.allowsInterstitial(now: shown.addingTimeInterval(AdPacing.minimumGap)))
    }

    @Test func 一日の上限で止まり_翌日に戻る() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let noon = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12))!
        var p = AdPacing()
        p.noteLaunch(now: noon.addingTimeInterval(-3600))
        var clock = noon
        for _ in 0..<AdPacing.dailyInterstitialCap {
            p.noteInterstitialShown(now: clock, calendar: calendar)
            clock.addTimeInterval(AdPacing.minimumGap)
        }
        for _ in 0..<AdPacing.pagesPerInterstitial { p.notePageFinished() }
        #expect(!p.allowsInterstitial(now: clock, calendar: calendar))
        #expect(p.allowsInterstitial(now: clock.addingTimeInterval(24 * 3600), calendar: calendar))
    }

    @Test func 地図を見て戻っただけではアプリ起動広告を出さない() {
        var p = AdPacing()
        for _ in 0..<AdPacing.appOpenMinimumLaunches { p.noteLaunch(now: start) }
        #expect(!p.allowsAppOpen(awayFor: 60, now: start))
        #expect(p.allowsAppOpen(awayFor: AdPacing.appOpenMinimumAway, now: start))
    }

    @Test func 使い始めの人にはアプリ起動広告を出さない() {
        var p = AdPacing()
        p.noteLaunch(now: start)
        #expect(!p.allowsAppOpen(awayFor: 3600 * 24, now: start))
    }

    @Test func アプリ起動広告は4時間に1回まで() {
        var p = AdPacing()
        for _ in 0..<AdPacing.appOpenMinimumLaunches { p.noteLaunch(now: start) }
        p.noteAppOpenShown(now: start)
        #expect(!p.allowsAppOpen(awayFor: 3600, now: start.addingTimeInterval(3600)))
        #expect(p.allowsAppOpen(awayFor: 3600, now: start.addingTimeInterval(AdPacing.appOpenGap)))
    }
}
