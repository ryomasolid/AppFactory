import Foundation
import Testing
@testable import KanshokuStop

private let tokyo: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
    return calendar
}()

private func day(_ m: Int, _ d: Int) -> Date {
    tokyo.date(from: DateComponents(year: 2026, month: m, day: d, hour: 12))!
}

private func book(_ pairs: [(Int, Int, SnackStatus)]) -> [String: DayEntry] {
    var result: [String: DayEntry] = [:]
    for (m, d, s) in pairs { result[DayKey.of(day(m, d), calendar: tokyo)] = DayEntry(status: s) }
    return result
}

struct StreakTests {
    @Test func 今日まだ記録していなければ昨日までを数える() {
        let entries = book([(11, 10, .skipped), (11, 11, .skipped), (11, 12, .skipped)])
        #expect(Streak.current(entries, today: day(11, 13), calendar: tokyo) == 3)
    }

    @Test func 今日しなかったなら今日まで数える() {
        let entries = book([(11, 12, .skipped), (11, 13, .skipped)])
        #expect(Streak.current(entries, today: day(11, 13), calendar: tokyo) == 2)
    }

    @Test func 今日しちゃったら0() {
        let entries = book([(11, 12, .skipped), (11, 13, .snacked)])
        #expect(Streak.current(entries, today: day(11, 13), calendar: tokyo) == 0)
    }

    @Test func 抜けた日があると途切れる() {
        let entries = book([(11, 9, .skipped), (11, 11, .skipped), (11, 12, .skipped)])
        #expect(Streak.current(entries, today: day(11, 13), calendar: tokyo) == 2)
        #expect(Streak.best(entries, today: day(11, 13), calendar: tokyo) == 2)
    }

    @Test func 最長は月をまたいでも数える() {
        let entries = book([(10, 30, .skipped), (10, 31, .skipped), (11, 1, .skipped), (11, 2, .snacked), (11, 3, .skipped)])
        #expect(Streak.best(entries, today: day(11, 13), calendar: tokyo) == 3)
    }

    @Test func 月ごとの日数() {
        let entries = book([(10, 31, .skipped), (11, 1, .skipped), (11, 2, .snacked), (11, 3, .skipped)])
        let tally = Streak.monthTally(entries, month: day(11, 1), calendar: tokyo)
        #expect(tally.skipped == 2)
        #expect(tally.snacked == 1)
    }
}

struct LegacyStoreTests {
    @Test func 旧版のmanifestから記録を読む() throws {
        let inner = #"{"20261101":{"status":"2","weight":"55.0","memo":"がまん"},"20261102":{"status":"1","weight":"","memo":""},"20261103":{"status":"0","weight":"","memo":""}}"#
        let manifest = try JSONSerialization.data(withJSONObject: ["calendarInfo": inner])
        let entries = try #require(LegacyStore.parse(manifest: manifest) { _ in nil })
        #expect(entries.count == 2)
        #expect(entries["20261101"] == DayEntry(status: .skipped, weight: "55.0", memo: "がまん"))
        #expect(entries["20261102"]?.status == .snacked)
    }

    @Test func 大きな値は別ファイルから読む() throws {
        let manifest = Data(#"{"calendarInfo":null}"#.utf8)
        let entries = LegacyStore.parse(manifest: manifest) { key in
            key == "calendarInfo" ? #"{"20261105":{"status":"2","weight":"","memo":""}}"# : nil
        }
        #expect(entries?["20261105"]?.status == .skipped)
    }

    @Test func 旧版のファイル名はキーのMD5() {
        #expect(LegacyStore.md5("calendarInfo").count == 32)
    }
}

struct ReviewAskTests {
    @Test func 五日たまるまでは頼まない() {
        let defaults = UserDefaults(suiteName: "review-test-\(UUID())")!
        #expect(!ReviewAsk.shouldAsk(skippedDays: 4, defaults: defaults))
        let days = UserDefaults(suiteName: "review-test-\(UUID())")!
        let quiet = ProcessInfo.processInfo.arguments.contains("-quiet")
        #expect(ReviewAsk.shouldAsk(skippedDays: 5, defaults: days) != quiet)
    }

    @Test func 頼んだら100日あける() {
        let defaults = UserDefaults(suiteName: "review-test-\(UUID())")!
        let now = Date()
        ReviewAsk.markAsked(now: now, defaults: defaults)
        #expect(!ReviewAsk.shouldAsk(skippedDays: 9, now: now.addingTimeInterval(50 * 86400), defaults: defaults))
    }
}
