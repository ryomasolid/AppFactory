import SwiftUI
import UIKit

/// 夏の睡蓮鉢の色。水面の青緑・楊貴妃の朱・浮き草の緑。ダークモードは夜の鉢。
enum Palette {
    static let water = tone(0xE8F3F1, 0x0E1A1C)
    static let surface = tone(0xFFFFFF, 0x18272A)
    static let deep = tone(0x1F6F78, 0x6FC3C9)
    static let koi = tone(0xE0612F, 0xFF8A5C)
    static let duckweed = tone(0x5A8F3C, 0x9ACB72)
    static let warn = tone(0xC0392B, 0xF0786A)
    static let mute = tone(0x6A7D80, 0x9AB0B3)

    private static func tone(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light) })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat(rgb >> 16 & 0xFF) / 255, green: CGFloat(rgb >> 8 & 0xFF) / 255, blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }
}

/// 角丸の小さな札。
struct Pill: View {
    let text: String
    var tint: Color = Palette.deep
    var icon: String?

    var body: some View {
        Label {
            Text(text)
        } icon: {
            if let icon { Image(systemName: icon) }
        }
        .labelStyle(PillLabelStyle(hasIcon: icon != nil))
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct PillLabelStyle: LabelStyle {
    let hasIcon: Bool
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            if hasIcon { configuration.icon.imageScale(.small) }
            configuration.title
        }
    }
}

/// 容器を上から見た絵。水の色は季節（水温）で変え、中に数ぶんの小さな魚影を置く。
struct BowlGlyph: View {
    let style: VesselStyle
    let headcount: Int
    var mood: WaterSense.Mood?
    var size: CGFloat = 56

    private var waterColor: Color {
        switch mood {
        case .dormant: Palette.mute
        case .warm, .tooWarm: Palette.duckweed
        default: Palette.deep
        }
    }

    /// 魚影の置き場（固定。描くたびに動かないように）。
    private static let spots: [CGPoint] = [
        .init(x: 0.35, y: 0.38), .init(x: 0.62, y: 0.55), .init(x: 0.42, y: 0.68),
        .init(x: 0.66, y: 0.32), .init(x: 0.28, y: 0.56),
    ]

    var body: some View {
        let shape = style == .bowl ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        ZStack {
            shape.fill(waterColor.opacity(0.22))
            shape.stroke(waterColor.opacity(0.55), lineWidth: 2).padding(1)
            Canvas { context, canvas in
                for spot in Self.spots.prefix(min(headcount, Self.spots.count)) {
                    let w = canvas.width * 0.16, h = canvas.width * 0.07
                    let rect = CGRect(x: spot.x * canvas.width - w / 2, y: spot.y * canvas.height - h / 2, width: w, height: h)
                    context.fill(Path(ellipseIn: rect), with: .color(Palette.koi))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

extension View {
    func panel() -> some View {
        padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

enum DayText {
    private static let jp = Locale(identifier: "ja_JP")

    /// 「今日」「あした」「11/12(水)」。
    static func short(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "今日" }
        if calendar.isDateInYesterday(date) { return "きのう" }
        if calendar.isDateInTomorrow(date) { return "あした" }
        return date.formatted(.dateTime.month(.defaultDigits).day().weekday(.abbreviated).locale(jp))
    }

    /// 「3日後」「2日すぎ」。
    static func relative(days: Int) -> String {
        switch days {
        case ..<0: "\(-days)日すぎ"
        case 0: "今日"
        case 1: "あした"
        default: "\(days)日後"
        }
    }
}
