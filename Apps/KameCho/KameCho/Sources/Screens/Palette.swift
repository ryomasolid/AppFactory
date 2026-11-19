import SwiftUI
import UIKit

/// 色。池と甲羅の緑・砂の色。ダークモードでは暗い土の色。
enum Palette {
    static let moss = Color(light: 0x4F8A5B, dark: 0x7DBB87)
    static let pond = Color(light: 0x3E86A0, dark: 0x6DB3CB)
    static let sand = Color(light: 0xF4EFE4, dark: 0x171714)
    static let paper = Color(light: 0xFFFDF8, dark: 0x25241F)
    static let ink = Color(light: 0x2F3A2C, dark: 0xE9E6DA)
    static let amber = Color(light: 0xD98B1F, dark: 0xF0AA45)
    static let rust = Color(light: 0xC2492F, dark: 0xF07A5F)

    static func hex(_ value: UInt32) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }

    static func level(_ level: Concern.Level) -> Color {
        switch level {
        case .note: pond
        case .careful: amber
        case .urgent: rust
        }
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let v = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
        })
    }
}

/// 角の丸いカード。
struct Panel<Content: View>: View {
    var title: String?
    var symbol: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Label {
                    Text(title).font(.headline)
                } icon: {
                    if let symbol { Image(systemName: symbol).foregroundStyle(Palette.moss) }
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

enum Fmt {
    static func number(_ v: Double, digits: Int = 1) -> String {
        v.formatted(.number.precision(.fractionLength(0...digits)))
    }

    static func signed(_ v: Double, digits: Int = 1) -> String {
        (v >= 0 ? "+" : "") + number(v, digits: digits)
    }

    static func day(_ d: Date) -> String { d.formatted(.dateTime.month().day()) }

    static func age(from base: Date, now: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month], from: base, to: now)
        let y = c.year ?? 0, m = c.month ?? 0
        if y == 0 { return "\(max(m, 0))か月" }
        return m == 0 ? "\(y)歳" : "\(y)歳\(m)か月"
    }

    /// 入力欄の文字を数に（全角や「,」もゆるす）。
    static func parse(_ text: String) -> Double? {
        let half = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        return Double(half.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
    }
}
