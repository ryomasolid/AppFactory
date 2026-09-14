import Foundation
import Testing
@testable import WarrantyPocket

/// レシートの読み取り。「確信の無い値は入れない」を固定する。
struct ReceiptParserTests {
    let now = at(2026, 9, 14, 18)

    @Test func typicalReceipt() {
        let lines = [
            "サンプル電機 駅前店",
            "TEL 03-1234-5678",
            "2026年9月1日(火) 14:32",
            "炊飯器 RC-10VS ¥24,800",
            "小計 ¥24,800",
            "(内消費税等 ¥2,254)",
            "合計 ¥24,800",
            "お預り ¥30,000",
            "お釣り ¥5,200",
        ]
        let fields = ReceiptParser.parse(lines: lines, now: now, calendar: jst)
        #expect(fields.purchaseDate == day(2026, 9, 1))
        #expect(fields.price == 24800)
        #expect(fields.storeName == "サンプル電機 駅前店")
    }

    @Test func amountOnTheLineAfterKeyword() {
        let lines = ["お買上げ合計", "12,800円", "お預り", "20,000円"]
        #expect(ReceiptParser.parse(lines: lines, now: now, calendar: jst).price == 12800)
    }

    @Test func noTotalKeywordMeansNoPrice() {
        // 合計の行が無いのに最大金額を入れると、お預り金額などを拾ってしまう。
        let lines = ["商品A ¥1,200", "商品B ¥3,400", "お預り ¥10,000"]
        #expect(ReceiptParser.parse(lines: lines, now: now, calendar: jst).price == nil)
    }

    @Test func depositOnTheSameLineIsIgnored() {
        let lines = ["合計 ¥8,980", "お預り合計 ¥10,000"]
        #expect(ReceiptParser.parse(lines: lines, now: now, calendar: jst).price == 8980)
    }

    @Test func fullwidthDigitsAndYenVariants() {
        let lines = ["２０２６／０８／２０　１０：０５", "合計　￥１２，３４５"]
        let fields = ReceiptParser.parse(lines: lines, now: now, calendar: jst)
        #expect(fields.purchaseDate == day(2026, 8, 20))
        #expect(fields.price == 12345)
    }

    @Test func backslashIsReadAsYen() {
        #expect(ReceiptParser.amounts(in: ReceiptParser.normalize("合計 \\3,980")) == [3980])
    }

    @Test func reiwaAndShortYearDates() {
        #expect(ReceiptParser.dates(in: "令和8年9月3日", calendar: jst) == [day(2026, 9, 3)])
        #expect(ReceiptParser.dates(in: "令和元年5月1日", calendar: jst) == [day(2019, 5, 1)])
        #expect(ReceiptParser.dates(in: "R8.9.3 12:00", calendar: jst) == [day(2026, 9, 3)])
        #expect(ReceiptParser.dates(in: "26/09/03 12:00", calendar: jst) == [day(2026, 9, 3)])
    }

    @Test func phoneNumbersAndInvalidDatesAreNotDates() {
        #expect(ReceiptParser.dates(in: "TEL 03-1234-5678", calendar: jst).isEmpty)
        #expect(ReceiptParser.dates(in: "2026/2/30", calendar: jst).isEmpty)
    }

    @Test func futureAndVeryOldDatesAreRejected() {
        #expect(ReceiptParser.parse(lines: ["2026/12/01 10:00"], now: now, calendar: jst).purchaseDate == nil)
        #expect(ReceiptParser.parse(lines: ["2010/01/01 10:00"], now: now, calendar: jst).purchaseDate == nil)
    }

    @Test func dateWithTimeWinsOverEarlierDate() {
        // 保証書の「有効期限」などが上にあっても、発行日時（時刻つき）を購入日にする。
        let lines = ["ポイント有効期限 2026/03/31", "2026/09/10 19:21 レジ02"]
        #expect(ReceiptParser.parse(lines: lines, now: now, calendar: jst).purchaseDate == day(2026, 9, 10))
    }

    @Test func timeOnTheNextLine() {
        let lines = ["有効期限 2026/03/31", "2026年9月10日(木)", "19:21"]
        #expect(ReceiptParser.parse(lines: lines, now: now, calendar: jst).purchaseDate == day(2026, 9, 10))
    }

    @Test func storeNameSkipsBoilerplate() {
        let lines = ["領収書", "****************", "家電のサンプル 本店", "TEL 0120-000-000", "2026/9/1 10:00"]
        #expect(ReceiptParser.parse(lines: lines, now: now, calendar: jst).storeName == "家電のサンプル 本店")
    }

    @Test func documentKind() {
        #expect(ReceiptParser.documentKind(lines: ["保 証 書", "お買い上げ日 2026年9月1日"]) == .warranty)
        #expect(ReceiptParser.documentKind(lines: ["サンプル電機", "合計 ¥1,000"]) == .receipt)
        #expect(ReceiptParser.documentKind(lines: ["取扱説明書", "安全上のご注意"]) == .manual)
        #expect(ReceiptParser.documentKind(lines: []) == .warranty)
    }

    @Test func emptyInput() {
        #expect(ReceiptParser.parse(lines: [], now: now, calendar: jst).isEmpty)
    }

    @Test func textLinesAreGroupedByRow() {
        // Vision は「合計」と「¥24,800」を別の断片として返す。同じ高さなら1行にまとめる。
        let boxes = [
            RecognizedText(text: "¥24,800", minX: 0.7, midY: 0.401, height: 0.03),
            RecognizedText(text: "サンプル電機", minX: 0.1, midY: 0.9, height: 0.04),
            RecognizedText(text: "合計", minX: 0.1, midY: 0.4, height: 0.03),
        ]
        #expect(TextLineGrouper.lines(from: boxes) == ["サンプル電機", "合計 ¥24,800"])
    }

    @Test func demoReceiptIsReadCorrectly() {
        // スクショのデモ画像に描く文字列が、そのまま正しく読み取れること。
        let lines = DemoImages.receiptLines(
            store: "サンプル電機 駅前店", date: day(2026, 9, 12), product: "コーヒーメーカー", model: "CM-5",
            price: 12980, calendar: jst
        )
        let fields = ReceiptParser.parse(lines: lines.map(\.recognizedText), now: now, calendar: jst)
        #expect(fields.purchaseDate == day(2026, 9, 12))
        #expect(fields.price == 12980)
        #expect(fields.storeName == "サンプル電機 駅前店")
    }
}
