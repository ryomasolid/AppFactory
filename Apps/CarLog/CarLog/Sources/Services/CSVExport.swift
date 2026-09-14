import Foundation

/// CSV の1行ぶん。給油・費用・メンテ実施を同じ表に並べる。
struct CSVRow: Equatable, Sendable {
    enum Kind: String, Sendable {
        case fuel
        case expense
        case maintenance

        var label: String {
            switch self {
            case .fuel: String(localized: "給油")
            case .expense: String(localized: "費用")
            case .maintenance: String(localized: "メンテ")
            }
        }
    }

    var kind: Kind
    var date: Date
    var vehicleName: String
    var odometer: Double?
    var liters: Double?
    var amount: Int
    var isFullTank: Bool?
    /// 費用はカテゴリ名、メンテは項目名。
    var category: String
    var note: String
}

/// 記録を CSV にする（Pro）。
///
/// Excel（日本語版）でそのまま開いても文字化けしないよう、UTF-8 の BOM を付けて書き出す。
enum CSVExport {
    static let header = [
        "種類", "日付", "クルマ", "走行距離(km)", "給油量", "金額(円)", "満タン", "カテゴリ・項目", "メモ",
    ]

    static func make(rows: [CSVRow], calendar: Calendar = .current) -> String {
        let sorted = rows.sorted {
            $0.date == $1.date ? $0.kind.rawValue < $1.kind.rawValue : $0.date < $1.date
        }
        let lines: [[String]] = [header] + sorted.map { fields(of: $0, calendar: calendar) }
        return lines.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    private static func fields(of row: CSVRow, calendar: Calendar) -> [String] {
        let odometer: String = row.odometer.map(Formatting.editable) ?? ""
        let liters: String = row.liters.map { String(format: "%.2f", $0) } ?? ""
        let fullTank: String = row.isFullTank.map { $0 ? "○" : "" } ?? ""
        return [
            row.kind.label,
            dateText(row.date, calendar: calendar),
            row.vehicleName,
            odometer,
            liters,
            String(row.amount),
            fullTank,
            row.category,
            row.note,
        ]
    }

    /// BOM 付き UTF-8。
    static func data(rows: [CSVRow], calendar: Calendar = .current) -> Data {
        Data([0xEF, 0xBB, 0xBF]) + Data(make(rows: rows, calendar: calendar).utf8)
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
