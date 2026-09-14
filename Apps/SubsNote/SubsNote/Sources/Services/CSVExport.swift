import Foundation

/// 書き出し用のサブスク1件。
struct SubscriptionExportRow: Equatable, Sendable {
    var name: String
    var category: String
    var price: Int
    var cycle: String
    var monthly: Int
    var yearly: Int
    var nextBillingDate: Date?
    var paymentMethod: String
    var paymentNote: String
    var trialEndDate: Date?
    var state: BillingState
    var cancelledAt: Date?
    var note: String
}

/// サブスクの一覧を CSV にする（Pro）。
///
/// Excel（日本語版）でそのまま開いても文字化けしないよう、UTF-8 の BOM を付けて書き出す。
enum CSVExport {
    static let header = [
        "サービス名", "カテゴリ", "金額(円)", "周期", "月あたり(円)", "年あたり(円)", "次回の支払日",
        "支払い方法", "支払いのメモ", "無料体験の最終日", "状態", "解約日", "メモ",
    ]

    /// 契約中・体験中を次回の支払日の順に、解約済みを最後に並べる。
    static func make(rows: [SubscriptionExportRow], calendar: Calendar = .current) -> String {
        let sorted = rows.sorted { lhs, rhs in
            let lhsCancelled = lhs.state == .cancelled
            let rhsCancelled = rhs.state == .cancelled
            if lhsCancelled != rhsCancelled { return !lhsCancelled }
            let lhsDate = lhs.nextBillingDate ?? .distantFuture
            let rhsDate = rhs.nextBillingDate ?? .distantFuture
            return lhsDate == rhsDate ? lhs.name < rhs.name : lhsDate < rhsDate
        }
        let lines: [[String]] = [header] + sorted.map { fields(of: $0, calendar: calendar) }
        return lines.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    /// BOM 付き UTF-8。
    static func data(rows: [SubscriptionExportRow], calendar: Calendar = .current) -> Data {
        Data([0xEF, 0xBB, 0xBF]) + Data(make(rows: rows, calendar: calendar).utf8)
    }

    private static func fields(of row: SubscriptionExportRow, calendar: Calendar) -> [String] {
        [
            row.name,
            row.category,
            String(row.price),
            row.cycle,
            String(row.monthly),
            String(row.yearly),
            row.nextBillingDate.map { dateText($0, calendar: calendar) } ?? "",
            row.paymentMethod,
            row.paymentNote,
            row.trialEndDate.map { dateText($0, calendar: calendar) } ?? "",
            row.state.label,
            row.cancelledAt.map { dateText($0, calendar: calendar) } ?? "",
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
