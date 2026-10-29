import SwiftUI
import UIKit

/// 砂のケージとハイイエローの体色をイメージした配色。ダークモードは夜のケージ。
enum Terrarium {
    static let sand = adaptive(light: 0xF5EFE1, dark: 0x16150F)
    static let card = adaptive(light: 0xFFFDF7, dark: 0x24221A)
    static let moss = adaptive(light: 0x4E7A36, dark: 0x8DBF6A)
    static let yolk = adaptive(light: 0xE6A817, dark: 0xF2C14E)
    static let spot = adaptive(light: 0x3B2F22, dark: 0xD9CBB0)
    static let alert = adaptive(light: 0xC2452D, dark: 0xF07A5E)
    static let shed = adaptive(light: 0x6E7FA8, dark: 0xA9B8DE)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// 小さな丸い札（「今日」「拒食2回」など）。
struct Tag: View {
    let text: String
    var color: Color = Terrarium.moss
    var symbol: String?

    var body: some View {
        HStack(spacing: 3) {
            if let symbol { Image(systemName: symbol).font(.caption2.weight(.bold)) }
            Text(text).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .foregroundStyle(color)
        .background(color.opacity(0.14), in: Capsule())
    }
}

/// 個体の顔写真。写真がなければ名前の頭文字をヒョウ柄の丸に出す。
struct GeckoAvatar: View {
    let name: String
    let portrait: Data?
    var size: CGFloat = 52

    var body: some View {
        Group {
            if let portrait, let image = UIImage(data: portrait) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    Terrarium.yolk
                    SpotPattern().opacity(0.35)
                    Text(String(name.prefix(1)))
                        .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                        .foregroundStyle(Terrarium.spot)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// レオパの斑点。座標は固定（描くたびに模様が変わらないように）。
struct SpotPattern: View {
    private static let spots: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
        (0.18, 0.22, 0.07), (0.72, 0.16, 0.06), (0.86, 0.55, 0.08), (0.12, 0.70, 0.06),
        (0.45, 0.88, 0.07), (0.62, 0.78, 0.05), (0.32, 0.40, 0.04), (0.80, 0.86, 0.04),
    ]

    var body: some View {
        Canvas { context, size in
            for spot in Self.spots {
                let r = spot.r * size.width
                let rect = CGRect(x: spot.x * size.width - r, y: spot.y * size.height - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(Terrarium.spot))
            }
        }
    }
}

extension View {
    func cardSurface() -> some View {
        padding(14)
            .background(Terrarium.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension Date {
    /// 「今日」「昨日」「10/24(金)」。
    var shortDayText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "今日" }
        if calendar.isDateInYesterday(self) { return "昨日" }
        if calendar.isDateInTomorrow(self) { return "明日" }
        return formatted(.dateTime.month(.defaultDigits).day().weekday(.abbreviated).locale(Locale(identifier: "ja_JP")))
    }
}
