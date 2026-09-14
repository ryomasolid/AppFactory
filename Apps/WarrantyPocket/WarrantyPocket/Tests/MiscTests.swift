import Foundation
import Testing
@testable import WarrantyPocket

/// 無料版の上限。課金の線引きそのものなので、境界をテストで固定する。
struct ProLimitsTests {

    @Test func freeUserCanRegisterTenItems() {
        #expect(ProLimits.canAddItem(currentCount: 9, isPro: false))
        #expect(!ProLimits.canAddItem(currentCount: 10, isPro: false))
        #expect(ProLimits.canAddItem(currentCount: 500, isPro: true))
    }

    @Test func remainingNeverNegative() {
        #expect(ProLimits.remainingItems(currentCount: 0, isPro: false) == 10)
        #expect(ProLimits.remainingItems(currentCount: 12, isPro: false) == 0)
        #expect(ProLimits.remainingItems(currentCount: 12, isPro: true) == nil)
    }

    @Test func readingAndNotificationsAreFreeExportIsPro() {
        #expect(ProLimits.isReadingFree)
        #expect(ProLimits.isNotificationFree)
        #expect(!ProLimits.canExport(isPro: false))
        #expect(ProLimits.canExport(isPro: true))
    }
}

struct FormattingTests {

    @Test func term() {
        #expect(Formatting.term(months: 6) == "6か月")
        #expect(Formatting.term(months: 12) == "1年")
        #expect(Formatting.term(months: 18) == "1年6か月")
        #expect(Formatting.term(months: 60) == "5年")
    }

    @Test func remaining() {
        let now = day(2026, 9, 14)
        func status(_ lastDay: Date) -> WarrantyStatus {
            let days = jst.dateComponents([.day], from: now, to: lastDay).day ?? 0
            return WarrantyStatus(state: days < 0 ? .expired : .active, lastDay: lastDay, remainingDays: days)
        }
        #expect(Formatting.remaining(status(day(2026, 9, 14)), now: now, calendar: jst) == "本日まで")
        #expect(Formatting.remaining(status(day(2026, 9, 26)), now: now, calendar: jst) == "あと12日")
        #expect(Formatting.remaining(status(day(2026, 11, 13)), now: now, calendar: jst) == "あと60日")
        #expect(Formatting.remaining(status(day(2027, 3, 20)), now: now, calendar: jst) == "あと6か月")
        #expect(Formatting.remaining(status(day(2027, 9, 14)), now: now, calendar: jst) == "あと1年")
        #expect(Formatting.remaining(status(day(2028, 11, 30)), now: now, calendar: jst) == "あと2年2か月")
        #expect(Formatting.remaining(status(day(2025, 3, 1)), now: now, calendar: jst) == "2025/3/1に終了")
        #expect(Formatting.badge(status(day(2025, 3, 1)), now: now, calendar: jst) == "終了")
        #expect(Formatting.remaining(.none, now: now, calendar: jst) == "保証なし")
    }

    @Test func numberInput() {
        #expect(NumberInput.int("12,800") == 12800)
        #expect(NumberInput.int("１２８００") == 12800)
        #expect(NumberInput.int("¥3,980") == 3980)
        #expect(NumberInput.int("") == nil)
        #expect(NumberInput.int("abc") == nil)
    }
}

struct ItemSearchTests {
    let fields = ["エアコン（リビング）", "", "AC-4026R", "SN12345", "サンプル電機 駅前店", "", "空調"]

    @Test func emptyQueryMatchesEverything() {
        #expect(ItemSearch.matches(query: "  ", fields: fields))
    }

    @Test func allTokensMustMatch() {
        #expect(ItemSearch.matches(query: "エアコン サンプル", fields: fields))
        #expect(!ItemSearch.matches(query: "エアコン 冷蔵庫", fields: fields))
    }

    @Test func caseWidthAndHyphenInsensitive() {
        #expect(ItemSearch.matches(query: "ac4026", fields: fields))
        #expect(ItemSearch.matches(query: "ＡＣ－４０２６", fields: fields))
        #expect(ItemSearch.matches(query: "sn123", fields: fields))
    }
}

struct CSVExportTests {

    @Test func headerRowsAndEscaping() {
        let row = ItemExportRow(
            name: "テレビ, 55V", category: "テレビ・オーディオ", maker: "", modelNumber: "TV-55", serialNumber: "",
            purchaseDate: day(2024, 3, 1), price: 139800, storeName: "サンプル電機",
            warrantyLastDay: day(2025, 2, 28), extendedLastDay: day(2029, 2, 28), extendedProvider: "サンプル電機",
            isArchived: false, note: "リビング\n壁掛け"
        )
        let older = ItemExportRow(
            name: "炊飯器", category: "キッチン家電", maker: "", modelNumber: "", serialNumber: "",
            purchaseDate: day(2023, 1, 1), price: nil, storeName: "", warrantyLastDay: nil, extendedLastDay: nil,
            extendedProvider: "", isArchived: true, note: ""
        )
        let lines = CSVExport.make(rows: [row, older], calendar: jst).components(separatedBy: "\r\n")
        #expect(lines[0].hasPrefix("商品名,カテゴリ,メーカー,型番"))
        #expect(lines[1] == "炊飯器,キッチン家電,,,,2023-01-01,,,,,,手放した,")
        #expect(lines[2].hasPrefix("\"テレビ, 55V\",テレビ・オーディオ,,TV-55,,2024-03-01,139800,サンプル電機,2025-02-28,2029-02-28,サンプル電機,,\"リビング"))
    }

    @Test func dataHasBOM() {
        let data = CSVExport.data(rows: [], calendar: jst)
        #expect(Array(data.prefix(3)) == [0xEF, 0xBB, 0xBF])
    }
}
