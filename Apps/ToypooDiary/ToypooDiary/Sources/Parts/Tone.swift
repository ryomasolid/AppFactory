import SwiftUI
import UIKit

/// ミルクティーとココアの色。アプリコットの毛色と、ほんのりローズ。夜はココアの濃いほう。
enum Tone {
    static let paper = pair(0xFBF5EE, 0x1C1714)
    static let card = pair(0xFFFFFF, 0x2A221E)
    static let cocoa = pair(0x8B5A3C, 0xE3B590)
    static let apricot = pair(0xE49A5E, 0xF2B07A)
    static let rose = pair(0xD46F7C, 0xF19AA4)
    static let leaf = pair(0x5B9469, 0x8FCB9C)
    static let alert = pair(0xC2453C, 0xF27E72)
    static let mute = pair(0x8E8077, 0xA89B92)

    static func pair(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

extension UIColor {
    convenience init(hex: UInt32, dim: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255 * dim,
            green: CGFloat((hex >> 8) & 0xFF) / 255 * dim,
            blue: CGFloat(hex & 0xFF) / 255 * dim,
            alpha: 1
        )
    }
}

extension View {
    /// 白いカード。
    func cardStyle(padding: CGFloat = 16) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tone.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Tone.cocoa.opacity(0.08), radius: 8, y: 3)
    }
}

/// 丸い小さな札。
struct Tag: View {
    let text: String
    var symbol: String?
    var tint: Color = Tone.cocoa

    var body: some View {
        HStack(spacing: 3) {
            if let symbol { Image(systemName: symbol).imageScale(.small) }
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.14), in: Capsule())
    }
}

/// 日付の言い方。
enum Words {
    private static let jp = Locale(identifier: "ja_JP")

    /// 「今日」「きのう」「11月14日(金)」。
    static func day(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "今日" }
        if calendar.isDateInYesterday(date) { return "きのう" }
        if calendar.isDateInTomorrow(date) { return "あした" }
        return date.formatted(.dateTime.month(.defaultDigits).day().weekday(.abbreviated).locale(jp))
    }

    /// 「2026年11月14日」。
    static func long(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.defaultDigits).day().locale(jp))
    }

    /// 「あと3日」「今日」「5日すぎ」。
    static func left(_ days: Int) -> String {
        switch days {
        case ..<0: "\(-days)日すぎ"
        case 0: "今日"
        case 1: "あした"
        default: "あと\(days)日"
        }
    }
}
