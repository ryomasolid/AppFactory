import Foundation
import Testing
@testable import CarLog

/// 満タン法の燃費計算。
struct FuelEconomyTests {

    @Test func firstFullTankIsOnlyAnAnchor() {
        // 最初の満タンは基準点。燃費はまだ出ない（満タン法として正しい挙動）。
        let records = [fuel(day(2026, 1, 1), odometer: 10000, liters: 30)]
        #expect(FuelEconomy.segments(for: records).isEmpty)
        #expect(FuelEconomy.overall(for: records) == nil)
    }

    @Test func segmentBetweenTwoFullTanks() {
        let second = fuel(day(2026, 1, 15), odometer: 10500, liters: 25)
        let records = [fuel(day(2026, 1, 1), odometer: 10000, liters: 30), second]
        let segments = FuelEconomy.segments(for: records)
        #expect(segments.count == 1)
        #expect(segments[0].id == second.id)
        #expect(segments[0].distance == 500)
        #expect(segments[0].kilometersPerLiter == 20)
    }

    @Test func partialFillIsAddedToTheNextFullTank() {
        // 継ぎ足し10Lは区間を切らず、次の満タンの区間に量だけ足す。
        let records = [
            fuel(day(2026, 1, 1), odometer: 10000, liters: 30),
            fuel(day(2026, 1, 8), odometer: 10300, liters: 10, full: false),
            fuel(day(2026, 1, 15), odometer: 10600, liters: 20),
        ]
        let segments = FuelEconomy.segments(for: records)
        #expect(segments.count == 1)
        #expect(segments[0].liters == 30)
        #expect(segments[0].kilometersPerLiter == 20)
    }

    @Test func recordsBeforeTheFirstFullTankAreIgnored() {
        let records = [
            fuel(day(2026, 1, 1), odometer: 9800, liters: 10, full: false),
            fuel(day(2026, 1, 5), odometer: 10000, liters: 30),
            fuel(day(2026, 1, 20), odometer: 10400, liters: 20),
        ]
        #expect(FuelEconomy.segments(for: records).map(\.kilometersPerLiter) == [20])
    }

    @Test func overallIsDistanceWeightedNotASimpleAverage() {
        // 区間A: 100km/10L = 10、区間B: 900km/30L = 30。単純平均なら20、正しくは 1000/40 = 25。
        let records = [
            fuel(day(2026, 1, 1), odometer: 0, liters: 40),
            fuel(day(2026, 1, 2), odometer: 100, liters: 10),
            fuel(day(2026, 1, 20), odometer: 1000, liters: 30),
        ]
        #expect(FuelEconomy.overall(for: records) == 25)
        #expect(FuelEconomy.latest(for: records)?.kilometersPerLiter == 30)
    }

    @Test func unorderedInputIsSortedByOdometer() {
        let records = [
            fuel(day(2026, 1, 15), odometer: 10500, liters: 25),
            fuel(day(2026, 1, 1), odometer: 10000, liters: 30),
        ]
        #expect(FuelEconomy.overall(for: records) == 20)
    }

    @Test func odometerThatDidNotAdvanceDoesNotCrashOrProduceInfinity() {
        // 同じ距離で2回入れた（打ち間違い）。0km の区間は捨てて、次の区間は正しく出る。
        let records = [
            fuel(day(2026, 1, 1), odometer: 10000, liters: 30),
            fuel(day(2026, 1, 2), odometer: 10000, liters: 5),
            fuel(day(2026, 1, 15), odometer: 10500, liters: 25),
        ]
        let segments = FuelEconomy.segments(for: records)
        #expect(segments.count == 1)
        #expect(segments.allSatisfy { $0.kilometersPerLiter.isFinite })
        #expect(segments[0].kilometersPerLiter == 20)
    }

    @Test func segmentsByRecordIDMapsToTheClosingRecord() {
        let closing = fuel(day(2026, 1, 15), odometer: 10500, liters: 25)
        let anchor = fuel(day(2026, 1, 1), odometer: 10000, liters: 30)
        let map = FuelEconomy.segmentsByRecordID(for: [anchor, closing])
        #expect(map[closing.id] != nil)
        #expect(map[anchor.id] == nil)
    }

    @Test func totalsAndAveragePrice() {
        let records = [
            fuel(day(2026, 1, 1), odometer: 0, liters: 30, price: 5100),
            fuel(day(2026, 1, 15), odometer: 500, liters: 20, price: 3400),
        ]
        #expect(FuelEconomy.totalSpent(for: records) == 8500)
        #expect(FuelEconomy.averagePricePerLiter(for: records) == 170)
        #expect(FuelEconomy.averagePricePerLiter(for: []) == nil)
    }
}
