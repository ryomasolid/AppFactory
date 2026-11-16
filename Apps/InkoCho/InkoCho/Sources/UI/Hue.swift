import SwiftUI
import UIKit

/// 空色とレモン色。セキセイインコの羽の色から。夜は濃紺。
enum Hue {
    static let sky = dyn(0x2F8FD8, 0x6CB8F0)
    static let lemon = dyn(0xF2C641, 0xF5D56A)
    static let leaf = dyn(0x4FA45A, 0x83CF8C)
    static let blush = dyn(0xE5788F, 0xF29AAD)
    static let danger = dyn(0xD2463B, 0xF27B70)
    static let ground = dyn(0xF3F8FC, 0x101820)
    static let card = dyn(0xFFFFFF, 0x1C2733)
    static let ink = dyn(0x23384D, 0xE3EDF6)
    static let soft = dyn(0x7A8A99, 0x9AABBA)

    private static func dyn(_ day: UInt32, _ night: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? .rgb(night) : .rgb(day) })
    }
}

extension UIColor {
    static func rgb(_ v: UInt32, scale: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat(v >> 16 & 0xFF) / 255 * scale, green: CGFloat(v >> 8 & 0xFF) / 255 * scale, blue: CGFloat(v & 0xFF) / 255 * scale, alpha: 1)
    }
}

extension View {
    func tile(_ inset: CGFloat = 16) -> some View {
        padding(inset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Hue.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct Chip: View {
    let text: String
    var icon: String?
    var color: Color = Hue.sky

    var body: some View {
        HStack(spacing: 3) {
            if let icon { Image(systemName: icon).imageScale(.small) }
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.13), in: Capsule())
    }
}

enum Say {
    static let jp = Locale(identifier: "ja_JP")

    static func day(_ d: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(d) { return "今日" }
        if calendar.isDateInYesterday(d) { return "きのう" }
        return d.formatted(.dateTime.month(.defaultDigits).day().weekday(.abbreviated).locale(jp))
    }

    static func ymd(_ d: Date) -> String {
        d.formatted(.dateTime.year().month(.defaultDigits).day().locale(jp))
    }

    static func until(_ days: Int) -> String {
        switch days {
        case ..<0: "\(-days)日すぎ"
        case 0: "今日"
        case 1: "あした"
        default: "あと\(days)日"
        }
    }
}
