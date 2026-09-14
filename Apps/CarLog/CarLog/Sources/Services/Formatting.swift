import Foundation

/// 金額・距離・燃費の表示形式。画面ごとに桁数がぶれないよう1か所にまとめる。
enum Formatting {
    /// "¥12,340"
    static func yen(_ amount: Int) -> String {
        "¥" + amount.formatted(.number.grouping(.automatic))
    }

    /// 小数の円（1kmあたりなど）。10円未満は小数1桁まで出さないと差が読めない。
    static func yen(_ amount: Double) -> String {
        let digits = abs(amount) < 100 ? 1 : 0
        return "¥" + amount.formatted(.number.precision(.fractionLength(digits)))
    }

    /// "12,345 km"
    static func kilometers(_ distance: Double) -> String {
        distance.formatted(.number.precision(.fractionLength(0))) + " km"
    }

    /// "21.4 km/L"
    static func economy(_ value: Double, unit: String) -> String {
        economyNumber(value) + " " + unit
    }

    /// 燃費の数値だけ（大きく表示して単位を別に添えるとき用）。
    static func economyNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    /// "32.50 L"
    static func volume(_ value: Double, unit: String) -> String {
        value.formatted(.number.precision(.fractionLength(2))) + " " + unit
    }

    /// 単価 "172.0 円/L"
    static func unitPrice(_ value: Double, unit: String) -> String {
        value.formatted(.number.precision(.fractionLength(1))) + " " + String(localized: "円/\(unit)")
    }

    /// 入力欄の初期値。整数なら小数点を付けない（"48424" / "32.5"）。
    static func editable(_ value: Double) -> String {
        if value.rounded() == value, abs(value) < 1e15 { return String(Int(value)) }
        return String(value)
    }

    /// メンテの間隔 "6か月 または 5,000km ごと"
    static func interval(months: Int?, distance: Double?) -> String {
        switch (months, distance) {
        case let (months?, distance?):
            String(localized: "\(months)か月 または \(kilometers(distance)) ごと")
        case let (months?, nil):
            String(localized: "\(months)か月ごと")
        case let (nil, distance?):
            String(localized: "\(kilometers(distance)) ごと")
        case (nil, nil):
            String(localized: "間隔未設定")
        }
    }
}

/// テキスト入力の数値解釈。テンキー入力の「,」や全角数字、空白が混ざっても読めるようにする。
enum NumberInput {
    static func double(_ text: String) -> Double? {
        let normalized = text
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalized.isEmpty, let value = Double(normalized), value.isFinite else { return nil }
        return value
    }

    static func int(_ text: String) -> Int? {
        guard let value = double(text), value < Double(Int.max) else { return nil }
        return Int(value.rounded())
    }
}
