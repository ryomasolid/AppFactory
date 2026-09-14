import Foundation
import Testing
@testable import CarLog

/// 走行ペースと到達日の予測。
struct OdometerProjectionTests {

    @Test func noPaceWithFewerThanTwoRecords() {
        #expect(OdometerProjection.pace(for: [], calendar: jst) == nil)
        #expect(OdometerProjection.pace(for: [fuel(day(2026, 1, 1), odometer: 1000, liters: 30)], calendar: jst) == nil)
    }

    @Test func paceIsDistancePerDay() {
        let records = [
            fuel(day(2026, 1, 1), odometer: 1000, liters: 30),
            fuel(day(2026, 1, 11), odometer: 1500, liters: 25),
        ]
        let pace = OdometerProjection.pace(for: records, calendar: jst)
        #expect(pace?.kilometersPerDay == 50)
        #expect(pace?.days == 10)
        #expect(pace?.kilometersPerMonth == 1500)
    }

    @Test func paceUsesTheLast90DaysWhenAvailable() {
        // 1年前は月100kmしか走っていなかったが、直近は1日50km。直近のペースを使う。
        let records = [
            fuel(day(2025, 1, 1), odometer: 0, liters: 30),
            fuel(day(2025, 12, 1), odometer: 1000, liters: 30),
            fuel(day(2026, 1, 1), odometer: 2550, liters: 30),
        ]
        let pace = OdometerProjection.pace(for: records, calendar: jst)
        #expect(pace?.kilometersPerDay == 50)
    }

    @Test func sparseRecordsFallBackToTheWholeHistory() {
        // 直近90日に1件しか無ければ、全期間の最古から出す。
        let records = [
            fuel(day(2025, 1, 1), odometer: 0, liters: 30),
            fuel(day(2026, 1, 1), odometer: 3650, liters: 30),
        ]
        #expect(OdometerProjection.pace(for: records, calendar: jst)?.kilometersPerDay == 10)
    }

    @Test func noPaceWhenOdometerWentBackwards() {
        let records = [
            fuel(day(2026, 1, 1), odometer: 2000, liters: 30),
            fuel(day(2026, 1, 11), odometer: 1500, liters: 25),
        ]
        #expect(OdometerProjection.pace(for: records, calendar: jst) == nil)
    }

    @Test func dateReachingRoundsUpToWholeDays() {
        let pace = DrivingPace(kilometersPerDay: 30, days: 30, distance: 900)
        // 残り100km ÷ 30km/日 = 3.33日 → 4日後。
        let date = OdometerProjection.dateReaching(
            1100, currentOdometer: 1000, pace: pace, from: day(2026, 3, 1), calendar: jst
        )
        #expect(date == day(2026, 3, 5))
    }

    @Test func alreadyReachedReturnsToday() {
        let date = OdometerProjection.dateReaching(
            1000, currentOdometer: 1200, pace: nil, from: at(2026, 3, 1, 15), calendar: jst
        )
        #expect(date == day(2026, 3, 1))
    }

    @Test func noProjectionWithoutPaceOrTooFarAway() {
        #expect(OdometerProjection.dateReaching(5000, currentOdometer: 0, pace: nil, calendar: jst) == nil)
        let slow = DrivingPace(kilometersPerDay: 0.1, days: 100, distance: 10)
        #expect(OdometerProjection.dateReaching(5000, currentOdometer: 0, pace: slow, calendar: jst) == nil)
    }
}
