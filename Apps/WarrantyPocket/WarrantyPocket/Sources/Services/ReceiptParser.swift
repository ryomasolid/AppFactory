import Foundation

/// レシート・保証書から読み取った値。確信の無い項目は nil。
struct ReceiptFields: Equatable, Sendable {
    var purchaseDate: Date?
    var price: Int?
    var storeName: String?

    var isEmpty: Bool { purchaseDate == nil && price == nil && storeName == nil }

    /// まだ埋まっていない項目だけを other で埋める（複数ページを順に読むとき用）。
    mutating func fillMissing(from other: ReceiptFields) {
        if purchaseDate == nil { purchaseDate = other.purchaseDate }
        if price == nil { price = other.price }
        if storeName == nil { storeName = other.storeName }
    }
}

/// 文字認識の結果（上から順の行）から、購入日・金額・店名を取り出す。
///
/// **確信の無い値は入れない**のが方針。間違った値が入っていると、ユーザーは確認せずに保存してしまう。
enum ReceiptParser {
    static func parse(lines rawLines: [String], now: Date = Date(), calendar: Calendar = .current) -> ReceiptFields {
        let lines = normalizedLines(rawLines)
        return ReceiptFields(
            purchaseDate: purchaseDate(in: lines, now: now, calendar: calendar),
            price: price(in: lines),
            storeName: storeName(in: lines)
        )
    }

    /// 写真の種類の推定。「保証書」と書いてあれば保証書、合計金額があればレシート。
    static func documentKind(lines rawLines: [String]) -> AttachmentKind {
        let lines = normalizedLines(rawLines)
        let text = lines.joined(separator: "\n")
        if text.contains("保証書") || text.contains("保 証 書") { return .warranty }
        if text.contains("取扱説明書") || text.contains("取り扱い説明書") { return .manual }
        if price(in: lines) != nil { return .receipt }
        return .warranty
    }

    // MARK: - 正規化

    static func normalizedLines(_ lines: [String]) -> [String] {
        lines
            .map { normalize($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// 全角の英数字・記号を半角に、円記号のゆれ（￥ \）を「¥」に揃える。カタカナはそのまま。
    static func normalize(_ line: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in line.unicodeScalars {
            switch scalar.value {
            case 0xFFE5, 0x5C:
                scalars.append("¥")
            case 0xFF01...0xFF5E:
                scalars.append(Unicode.Scalar(scalar.value - 0xFEE0) ?? scalar)
            case 0x3000:
                scalars.append(" ")
            case 0x2010, 0x2011, 0x2012, 0x2013, 0x2212:
                scalars.append("-")
            default:
                scalars.append(scalar)
            }
        }
        return String(scalars)
    }

    // MARK: - 購入日

    /// 日付の後ろ（同じ行か次の行）に時刻があるものを優先する（レシートの発行日時）。
    /// 無ければ最初に見つかった日付。未来日と10年以上前は捨てる。
    static func purchaseDate(in lines: [String], now: Date, calendar: Calendar) -> Date? {
        var first: Date?
        for (index, line) in lines.enumerated() {
            guard let date = dates(in: line, calendar: calendar)
                .first(where: { isPlausible($0, now: now, calendar: calendar) })
            else { continue }
            let next = index + 1 < lines.count ? lines[index + 1] : ""
            if hasTime(line) || (hasTime(next) && dates(in: next, calendar: calendar).isEmpty) {
                return date
            }
            if first == nil { first = date }
        }
        return first
    }

    private static func hasTime(_ line: String) -> Bool {
        line.contains(#/\d{1,2}:\d{2}/#)
    }

    static func dates(in line: String, calendar: Calendar) -> [Date] {
        var results: [Date] = []
        func add(_ year: Int?, _ month: Substring, _ day: Substring) {
            if let date = makeDate(year, Int(month), Int(day), calendar: calendar) { results.append(date) }
        }
        // 2026年9月14日 / 2026/09/14 / 2026-9-14 / 2026.9.14
        for match in line.matches(of: #/(20\d{2})\s*[年/.\-]\s*(\d{1,2})\s*[月/.\-]\s*(\d{1,2})(?!\d)/#) {
            add(Int(match.1), match.2, match.3)
        }
        // 令和8年9月14日 / 令和元年
        for match in line.matches(of: #/令和\s*(\d{1,2}|元)\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})(?!\d)/#) {
            let era = match.1 == "元" ? 1 : Int(match.1)
            add(era.map { 2018 + $0 }, match.2, match.3)
        }
        // R8.9.14
        for match in line.matches(of: #/(?:^|[^A-Za-z0-9])R\s*(\d{1,2})\s*[年/.\-]\s*(\d{1,2})\s*[月/.\-]\s*(\d{1,2})(?!\d)/#) {
            add(Int(match.1).map { 2018 + $0 }, match.2, match.3)
        }
        // 26/09/14 / 26.09.14（電話番号と区別するため「-」区切りは読まない）
        for match in line.matches(of: #/(?:^|[^\d/.\-])(\d{2})[/.](\d{1,2})[/.](\d{1,2})(?!\d)/#) {
            add(Int(match.1).map { 2000 + $0 }, match.2, match.3)
        }
        return results
    }

    private static func makeDate(_ year: Int?, _ month: Int?, _ day: Int?, calendar: Calendar) -> Date? {
        guard let year, let month, let day, (1...12).contains(month), (1...31).contains(day),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: day))
        else { return nil }
        // 2/30 などは翌月に繰り上がるので、組み立て直して一致するものだけを採る。
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard components.year == year, components.month == month, components.day == day else { return nil }
        return date
    }

    private static func isPlausible(_ date: Date, now: Date, calendar: Calendar) -> Bool {
        let today = calendar.startOfDay(for: now)
        guard date <= today, let limit = calendar.date(byAdding: .year, value: -10, to: today) else { return false }
        return date >= limit
    }

    // MARK: - 金額

    static let totalKeywords = ["合計", "お買上", "お買い上げ", "お支払", "総額", "税込", "ご請求", "領収金額", "ｺﾞｳｹｲ"]
    /// 合計と紛らわしい行。お預り金額を合計と取るのが一番多い誤りなので必ず除く。
    static let excludedKeywords = [
        "お預", "預り", "預かり", "お釣", "釣銭", "おつり", "ポイント", "値引", "割引", "消費税", "税額", "内税", "小計",
    ]

    /// 合計のキーワードがある行（無ければその次の行）の最大金額。キーワードの行が無ければ入れない。
    static func price(in lines: [String]) -> Int? {
        var candidates: [Int] = []
        for (index, line) in lines.enumerated() {
            guard totalKeywords.contains(where: { line.contains($0) }), !isExcluded(line) else { continue }
            var found = amounts(in: line)
            if found.isEmpty, index + 1 < lines.count, !isExcluded(lines[index + 1]) {
                found = amounts(in: lines[index + 1])
            }
            candidates += found
        }
        return candidates.max()
    }

    private static func isExcluded(_ line: String) -> Bool {
        excludedKeywords.contains { line.contains($0) }
    }

    static func amounts(in line: String) -> [Int] {
        var values: [Int] = []
        for match in line.matches(of: #/¥\s*(\d{1,3}(?:,\d{3})+|\d+)/#) {
            values.append(integer(match.1))
        }
        for match in line.matches(of: #/(\d{1,3}(?:,\d{3})+|\d+)\s*円/#) {
            values.append(integer(match.1))
        }
        if values.isEmpty {
            // 記号なし: 桁区切りのある数字か、行末の3桁以上の数字だけを金額とみなす（「3点」などを拾わない）。
            for match in line.matches(of: #/(?:^|[^\d.,])(\d{1,3}(?:,\d{3})+)(?![\d.%])/#) {
                values.append(integer(match.1))
            }
            if values.isEmpty, let match = line.firstMatch(of: #/(?:^|[^\d.,])(\d{3,})\s*$/#) {
                values.append(integer(match.1))
            }
        }
        return values.filter { (1...100_000_000).contains($0) }
    }

    private static func integer(_ text: Substring) -> Int {
        Int(text.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    // MARK: - 店名

    static let storeExcludedKeywords = [
        "tel", "電話", "http", "www", "@", "領収", "レシート", "ご来店", "ありがと", "いらっしゃいませ",
        "登録番号", "¥", "円", "合計", "no.", "保証書", "取扱説明書",
    ]

    /// 先頭4行のうち、数字・電話番号・定型文を含まない最も長い行。
    static func storeName(in lines: [String]) -> String? {
        let candidates = lines.prefix(4).filter { line in
            guard line.filter(\.isNumber).count < 4, (2...30).contains(line.count) else { return false }
            let lower = line.lowercased()
            guard !storeExcludedKeywords.contains(where: { lower.contains($0) }) else { return false }
            // 罫線（---- や ****）だけの行は店名ではない。
            return line.contains { $0.isLetter }
        }
        return candidates.max { $0.count < $1.count }
    }
}
