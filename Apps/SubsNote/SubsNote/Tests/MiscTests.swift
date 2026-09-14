import Foundation
import Testing
@testable import SubsNote

/// 無料版の上限。課金の線引きそのものなので、境界をテストで固定する。
struct ProLimitsTests {

    @Test func freeUserCanRegisterFive() {
        #expect(ProLimits.canAdd(activeCount: 4, isPro: false))
        #expect(!ProLimits.canAdd(activeCount: 5, isPro: false))
        #expect(ProLimits.canAdd(activeCount: 100, isPro: true))
    }

    @Test func cancelledAreNotCounted() {
        #expect(ProLimits.countedSubscriptions(isCancelled: [false, true, true, false, false]) == 3)
        #expect(ProLimits.remaining(activeCount: 3, isPro: false) == 2)
        #expect(ProLimits.remaining(activeCount: 7, isPro: false) == 0)
        #expect(ProLimits.remaining(activeCount: 7, isPro: true) == nil)
    }

    @Test func notificationsAndTotalsAreFree() {
        #expect(ProLimits.isNotificationFree)
        #expect(ProLimits.isTotalFree)
        #expect(!ProLimits.canSeeBreakdown(isPro: false))
        #expect(!ProLimits.canExport(isPro: false))
        #expect(ProLimits.canSeeBreakdown(isPro: true))
        #expect(ProLimits.canExport(isPro: true))
    }
}

struct FormattingTests {

    @Test func cycleAndPrice() {
        #expect(Formatting.cyclePrice(price: 1490, cycle: .month, interval: 1) == "月 ¥1,490")
        #expect(Formatting.cyclePrice(price: 3000, cycle: .month, interval: 3) == "3か月 ¥3,000")
        #expect(Formatting.cyclePrice(price: 5900, cycle: .year, interval: 1) == "年 ¥5,900")
        #expect(Formatting.cyclePrice(price: 300, cycle: .week, interval: 2) == "2週 ¥300")
        #expect(Formatting.cycle(.month, interval: 1) == "毎月")
        #expect(Formatting.cycle(.year, interval: 2) == "2年ごと")
    }

    @Test func recurrence() {
        #expect(Formatting.recurrence(anchor: day(2026, 9, 17), cycle: .month, interval: 1, calendar: jst) == "毎月17日")
        #expect(Formatting.recurrence(anchor: day(2026, 1, 31), cycle: .month, interval: 1, calendar: jst) == "毎月31日（ない月は末日）")
        #expect(Formatting.recurrence(anchor: day(2026, 1, 10), cycle: .month, interval: 3, calendar: jst) == "3か月ごとの10日")
        #expect(Formatting.recurrence(anchor: day(2026, 9, 16), cycle: .week, interval: 1, calendar: jst) == "毎週水曜日")
        #expect(Formatting.recurrence(anchor: day(2026, 3, 1), cycle: .year, interval: 1, calendar: jst) == "毎年3月1日")
        #expect(Formatting.recurrence(anchor: day(2028, 2, 29), cycle: .year, interval: 1, calendar: jst) == "毎年2月29日（平年は2月28日）")
    }

    @Test func datesAndDays() {
        #expect(Formatting.shortDateWithWeekday(day(2026, 9, 17), calendar: jst) == "9/17（木）")
        #expect(Formatting.monthDay(day(2026, 9, 17), calendar: jst) == "9月17日")
        #expect(Formatting.yearMonth(day(2026, 9, 17), calendar: jst) == "2026年9月")
        #expect(Formatting.days(from: at(2026, 9, 14, 23), to: day(2026, 9, 17), calendar: jst) == 3)
        #expect(Formatting.daysUntil(0) == "今日")
        #expect(Formatting.daysUntil(1) == "明日")
        #expect(Formatting.daysUntil(12) == "あと12日")
        #expect(Formatting.daysUntil(-2) == "2日前")
    }

    @Test func numberInput() {
        #expect(NumberInput.int("1,590") == 1590)
        #expect(NumberInput.int("１５９０") == 1590)
        #expect(NumberInput.int("¥3,980") == 3980)
        #expect(NumberInput.int("980円") == 980)
        #expect(NumberInput.int("") == nil)
        #expect(NumberInput.int("abc") == nil)
        #expect(NumberInput.int("-5") == nil)
    }

    @Test func launchParsesFixedToday() {
        #expect(Launch.parseDay("2026-09-14", calendar: jst) == at(2026, 9, 14, 12))
        #expect(Launch.parseDay("2026/09/14", calendar: jst) == nil)
    }
}

struct ServicePresetTests {

    @Test func keysAreUniqueAndPlansArePositive() {
        let keys = ServicePreset.all.map(\.key)
        #expect(Set(keys).count == keys.count)
        #expect(ServicePreset.all.allSatisfy { !$0.kana.isEmpty })
        #expect(ServicePreset.all.flatMap(\.plans).allSatisfy { $0.price > 0 && $0.interval >= 1 })
        #expect(ServicePreset.popular.count == 6)
    }

    @Test func searchByKanaInEitherScript() {
        #expect(ServicePreset.search("ねっとふりっくす").map(\.key) == ["netflix"])
        #expect(ServicePreset.search("ネットフリックス").map(\.key) == ["netflix"])
        #expect(ServicePreset.search("NETFLIX").map(\.key) == ["netflix"])
        #expect(ServicePreset.search("ｽﾎﾟﾃｨﾌｧｲ").map(\.key) == ["spotify"])
    }

    @Test func allTokensMustMatch() {
        #expect(Set(ServicePreset.search("ゆーちゅーぶ").map(\.key)) == ["youtubePremium", "youtubeMusic"])
        #expect(ServicePreset.search("ゆーちゅーぶ みゅーじっく").map(\.key) == ["youtubeMusic"])
        #expect(ServicePreset.search("存在しないサービス").isEmpty)
        #expect(ServicePreset.search("  ").count == ServicePreset.all.count)
    }
}

struct CSVExportTests {

    @Test func headerOrderAndEscaping() {
        let active = SubscriptionExportRow(
            name: "動画, プラス", category: "動画", price: 1590, cycle: "毎月", monthly: 1590, yearly: 19080,
            nextBillingDate: day(2026, 9, 17), paymentMethod: "クレジットカード", paymentNote: "", trialEndDate: nil,
            state: .active, cancelledAt: nil, note: "家族で\n共有"
        )
        let trial = SubscriptionExportRow(
            name: "シネマパス", category: "動画", price: 990, cycle: "毎月", monthly: 990, yearly: 11880,
            nextBillingDate: day(2026, 9, 16), paymentMethod: "App Store", paymentNote: "", trialEndDate: day(2026, 9, 15),
            state: .trial, cancelledAt: nil, note: ""
        )
        let cancelled = SubscriptionExportRow(
            name: "マンガ読み放題", category: "ニュース・書籍", price: 980, cycle: "毎月", monthly: 980, yearly: 11760,
            nextBillingDate: nil, paymentMethod: "App Store", paymentNote: "", trialEndDate: nil,
            state: .cancelled, cancelledAt: day(2026, 8, 5), note: ""
        )
        let lines = CSVExport.make(rows: [cancelled, active, trial], calendar: jst).components(separatedBy: "\r\n")
        #expect(lines[0] == "サービス名,カテゴリ,金額(円),周期,月あたり(円),年あたり(円),次回の支払日,支払い方法,支払いのメモ,無料体験の最終日,状態,解約日,メモ")
        #expect(lines[1] == "シネマパス,動画,990,毎月,990,11880,2026-09-16,App Store,,2026-09-15,無料体験中,,")
        #expect(lines[2].hasPrefix("\"動画, プラス\",動画,1590,毎月,1590,19080,2026-09-17,クレジットカード,,,契約中,,\"家族で"))
        #expect(lines.contains("マンガ読み放題,ニュース・書籍,980,毎月,980,11760,,App Store,,,解約済み,2026-08-05,"))
    }

    @Test func dataHasBOM() {
        let data = CSVExport.data(rows: [], calendar: jst)
        #expect(Array(data.prefix(3)) == [0xEF, 0xBB, 0xBF])
    }
}
