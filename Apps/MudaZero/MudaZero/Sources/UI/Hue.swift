import SwiftUI
import UIKit

/// ミントグリーン（ムダゼロ）と金色（0円の日）。ついつい は落ち着いたサーモン。
enum Hue {
    static let mint = dyn(0x1F9E78, 0x4FD1A5)
    static let gold = dyn(0xE0A82E, 0xF2C760)
    static let salmon = dyn(0xE06B57, 0xF2917F)
    static let ground = dyn(0xF4F6F1, 0x111613)
    static let card = dyn(0xFFFFFF, 0x1B221E)
    static let ink = dyn(0x1E2B25, 0xE4ECE7)
    static let soft = dyn(0x76847D, 0x98A69F)
    static let line = dyn(0xE3E8E4, 0x2A332E)

    private static func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? .hex(dark) : .hex(light) })
    }
}

extension UIColor {
    static func hex(_ v: UInt32) -> UIColor {
        UIColor(red: CGFloat(v >> 16 & 0xFF) / 255, green: CGFloat(v >> 8 & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }
}

extension DayKind {
    var color: Color {
        switch self {
        case .zero: Hue.gold
        case .clean: Hue.mint
        case .slipped: Hue.salmon
        case .open: Hue.soft
        }
    }
}

extension View {
    func card(_ inset: CGFloat = 16) -> some View {
        padding(inset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Hue.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// 細い横棒のメーター。
struct Meter: View {
    let ratio: Double
    var color: Color = Hue.mint

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Hue.line)
                Capsule().fill(color).frame(width: max(ratio > 0 ? 8 : 0, geo.size.width * min(1, max(0, ratio))))
            }
        }
        .frame(height: 10)
    }
}

struct Pill: View {
    let text: String
    var icon: String?
    var color: Color = Hue.mint

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).imageScale(.small) }
            Text(text)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.14), in: Capsule())
    }
}

enum Words {
    static let jp = Locale(identifier: "ja_JP")

    static func day(_ d: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(d) { return "きょう" }
        if calendar.isDateInYesterday(d) { return "きのう" }
        return d.formatted(.dateTime.month(.defaultDigits).day().weekday(.abbreviated).locale(jp))
    }

    static func long(_ d: Date) -> String {
        d.formatted(.dateTime.month(.defaultDigits).day().weekday(.wide).locale(jp))
    }

    static func month(_ d: Date) -> String {
        d.formatted(.dateTime.year().month(.defaultDigits).locale(jp))
    }
}
