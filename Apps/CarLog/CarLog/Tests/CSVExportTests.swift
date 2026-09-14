import Foundation
import Testing
@testable import CarLog

/// CSV 書き出しと数値入力の解釈。
struct CSVExportTests {

    @Test func escapesOnlyWhenNeeded() {
        #expect(CSVExport.escape("ENEOS") == "ENEOS")
        #expect(CSVExport.escape("a,b") == "\"a,b\"")
        #expect(CSVExport.escape("say \"hi\"") == "\"say \"\"hi\"\"\"")
        #expect(CSVExport.escape("1行目\n2行目") == "\"1行目\n2行目\"")
    }

    @Test func rowsAreSortedByDateWithHeader() {
        let rows = [
            CSVRow(kind: .expense, date: day(2026, 3, 5), vehicleName: "プリウス", odometer: nil, liters: nil,
                   amount: 11000, isFullTank: nil, category: "駐車場", note: "月極"),
            CSVRow(kind: .fuel, date: day(2026, 3, 1), vehicleName: "プリウス", odometer: 48424, liters: 21.2,
                   amount: 3654, isFullTank: true, category: "ENEOS", note: ""),
        ]
        let lines = CSVExport.make(rows: rows, calendar: jst).components(separatedBy: "\r\n")
        #expect(lines[0].hasPrefix("種類,日付,クルマ"))
        #expect(lines[1] == "給油,2026-03-01,プリウス,48424,21.20,3654,○,ENEOS,")
        #expect(lines[2] == "費用,2026-03-05,プリウス,,,11000,,駐車場,月極")
    }

    @Test func dataStartsWithBOMForExcel() {
        let data = CSVExport.data(rows: [], calendar: jst)
        #expect(Array(data.prefix(3)) == [0xEF, 0xBB, 0xBF])
    }

    @Test func numberInputAcceptsCommasAndFullWidthDigits() {
        #expect(NumberInput.double("48,424") == 48424)
        #expect(NumberInput.double("３２．５") == 32.5)
        #expect(NumberInput.double(" 12 ") == 12)
        #expect(NumberInput.double("") == nil)
        #expect(NumberInput.double("abc") == nil)
        #expect(NumberInput.int("5,600") == 5600)
    }

    @Test func intervalText() {
        #expect(Formatting.interval(months: 6, distance: 5000).contains("6か月"))
        #expect(Formatting.interval(months: nil, distance: 30000).contains("30,000 km"))
        #expect(Formatting.interval(months: 24, distance: nil) == "24か月ごと")
    }
}
