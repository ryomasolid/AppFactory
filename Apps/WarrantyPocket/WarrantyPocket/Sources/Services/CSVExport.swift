import Foundation

/// 書き出し（CSV・PDF）用の商品1件。
struct ItemExportRow: Equatable, Sendable {
    var name: String
    var category: String
    var maker: String
    var modelNumber: String
    var serialNumber: String
    var purchaseDate: Date
    var price: Int?
    var storeName: String
    var warrantyLastDay: Date?
    var extendedLastDay: Date?
    var extendedProvider: String
    var isArchived: Bool
    var note: String
}

/// 商品の一覧を CSV にする（Pro）。
///
/// Excel（日本語版）でそのまま開いても文字化けしないよう、UTF-8 の BOM を付けて書き出す。
enum CSVExport {
    static let header = [
        "商品名", "カテゴリ", "メーカー", "型番", "シリアル番号", "購入日", "金額(円)", "購入店",
        "メーカー保証の最終日", "延長保証の最終日", "延長保証の窓口", "状態", "メモ",
    ]

    static func make(rows: [ItemExportRow], calendar: Calendar = .current) -> String {
        let sorted = rows.sorted {
            $0.purchaseDate == $1.purchaseDate ? $0.name < $1.name : $0.purchaseDate < $1.purchaseDate
        }
        let lines: [[String]] = [header] + sorted.map { fields(of: $0, calendar: calendar) }
        return lines.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    /// BOM 付き UTF-8。
    static func data(rows: [ItemExportRow], calendar: Calendar = .current) -> Data {
        Data([0xEF, 0xBB, 0xBF]) + Data(make(rows: rows, calendar: calendar).utf8)
    }

    private static func fields(of row: ItemExportRow, calendar: Calendar) -> [String] {
        [
            row.name,
            row.category,
            row.maker,
            row.modelNumber,
            row.serialNumber,
            dateText(row.purchaseDate, calendar: calendar),
            row.price.map(String.init) ?? "",
            row.storeName,
            row.warrantyLastDay.map { dateText($0, calendar: calendar) } ?? "",
            row.extendedLastDay.map { dateText($0, calendar: calendar) } ?? "",
            row.extendedProvider,
            row.isArchived ? String(localized: "手放した") : "",
            row.note,
        ]
    }

    /// カンマ・改行・ダブルクォートを含むフィールドだけ囲む（RFC 4180）。
    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func dateText(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
