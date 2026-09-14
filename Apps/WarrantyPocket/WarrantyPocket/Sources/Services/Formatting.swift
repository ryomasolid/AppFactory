import Foundation

/// 金額・日付・期間の表示形式。画面ごとにぶれないよう1か所にまとめる。
enum Formatting {
    /// "¥12,340"
    static func yen(_ amount: Int) -> String {
        "¥" + amount.formatted(.number.grouping(.automatic))
    }

    /// "2026/9/14"（修理窓口で読み上げやすい、ゼロ埋めしない形）
    static func date(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)/\(c.month ?? 0)/\(c.day ?? 0)"
    }

    /// 保証の長さ "1年" / "6か月" / "1年6か月"
    static func term(months: Int) -> String {
        let years = months / 12
        let rest = months % 12
        switch (years, rest) {
        case (0, _): return String(localized: "\(rest)か月")
        case (_, 0): return String(localized: "\(years)年")
        default: return String(localized: "\(years)年\(rest)か月")
        }
    }

    /// 残り "あと1年2か月" / "あと12日" / "本日まで" / "2025/3/1に終了"
    static func remaining(_ status: WarrantyStatus, now: Date = Date(), calendar: Calendar = .current) -> String {
        guard let lastDay = status.lastDay, let days = status.remainingDays else {
            return String(localized: "保証なし")
        }
        if days < 0 { return String(localized: "\(date(lastDay, calendar: calendar))に終了") }
        if days == 0 { return String(localized: "本日まで") }
        // 2か月を切ったら日数で出す（「あと1か月」だと30日前と59日前の区別がつかない）。
        if days <= 60 { return String(localized: "あと\(days)日") }
        let c = calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: now), to: lastDay)
        let years = c.year ?? 0
        let months = c.month ?? 0
        if years == 0 { return String(localized: "あと\(months)か月") }
        if months == 0 { return String(localized: "あと\(years)年") }
        return String(localized: "あと\(years)年\(months)か月")
    }

    /// 一覧のバッジ用の短い表記。終了済みは日付を出さずに「終了」。
    static func badge(_ status: WarrantyStatus, now: Date = Date(), calendar: Calendar = .current) -> String {
        status.state == .expired ? String(localized: "終了") : remaining(status, now: now, calendar: calendar)
    }
}

/// テキスト入力の数値解釈。「,」や全角数字、空白が混ざっても読めるようにする。
enum NumberInput {
    static func int(_ text: String) -> Int? {
        let normalized = ReceiptParser.normalize(text)
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "円", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, let value = Double(normalized), value.isFinite, value < Double(Int.max) else {
            return nil
        }
        return Int(value.rounded())
    }
}

/// 一覧の検索。スペース区切りの語が**すべて**どれかの項目に含まれていれば一致。
enum ItemSearch {
    static func matches(query: String, fields: [String]) -> Bool {
        let tokens = normalize(query).split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else { return true }
        let haystack = fields.map { normalize($0) }
        return tokens.allSatisfy { token in
            let compact = removeHyphens(token)
            return haystack.contains { $0.contains(token) || removeHyphens($0).contains(compact) }
        }
    }

    /// 大文字小文字・全角半角の違いを無視する。
    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
    }

    /// 型番の「AC-2825」と「AC2825」を同じとみなす（長音「ー」は残す）。
    private static func removeHyphens(_ text: String) -> String {
        text.filter { !"-‐‑–—－_ ".contains($0) }
    }
}
