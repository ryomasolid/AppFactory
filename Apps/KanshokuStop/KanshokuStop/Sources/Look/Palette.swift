import SwiftUI
import UIKit

/// パン屋の朝の色。生成りの地に、しなかった日の若草色と しちゃった日のこんがり色。ダークモードは夜の台所。
enum Palette {
    static let paper = tone(0xFBF6EE, 0x15130F)
    static let surface = tone(0xFFFFFF, 0x221F19)
    static let ink = tone(0x2E2A24, 0xF2ECE2)
    static let mute = tone(0x8A8175, 0xA59C8F)
    /// 間食しなかった日。
    static let leaf = tone(0x2FA864, 0x5FD08C)
    static let leafSoft = tone(0xDDF3E5, 0x1E3A2A)
    /// 間食しちゃった日。
    static let crust = tone(0xE07A2E, 0xF39A55)
    static let crustSoft = tone(0xFBE5D2, 0x3F2A1A)
    static let flame = tone(0xE5532B, 0xFF7A50)
    static let trophy = tone(0xC99A1A, 0xF0C445)

    private static func tone(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light) })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat(rgb >> 16 & 0xFF) / 255, green: CGFloat(rgb >> 8 & 0xFF) / 255, blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }
}

/// 白い角丸の台。
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// 連続記録の札（いま・最長）。
struct StreakTiles: View {
    let current: Int
    let best: Int

    var body: some View {
        HStack(spacing: 12) {
            tile(icon: "flame.fill", tint: Palette.flame, label: "いまの連続記録", days: current)
            tile(icon: "trophy.fill", tint: Palette.trophy, label: "最長の連続記録", days: best)
        }
    }

    private func tile(icon: String, tint: Color, label: String, days: Int) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Label(label, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(days)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText())
                    Text("日")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.mute)
                }
            }
        }
    }
}

/// 「しなかった／しちゃった」の丸いボタン。選ばれているとチェックが付く。
struct StatusBubble: View {
    let status: SnackStatus
    let isOn: Bool
    var diameter: CGFloat = 140
    let action: () -> Void

    private var tint: Color { status == .skipped ? Palette.leaf : Palette.crust }
    private var soft: Color { status == .skipped ? Palette.leafSoft : Palette.crustSoft }
    private var title: String { status == .skipped ? "しなかった" : "しちゃった" }
    private var icon: String { status == .skipped ? "leaf.fill" : "birthday.cake.fill" }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark" : icon)
                    .font(.system(size: diameter * 0.22, weight: .bold))
                Text("間食")
                    .font(.system(size: diameter * 0.11, weight: .semibold))
                Text(title)
                    .font(.system(size: diameter * 0.13, weight: .bold))
            }
            .foregroundStyle(isOn ? Color.white : tint)
            .frame(width: diameter, height: diameter)
            .background(Circle().fill(isOn ? tint : soft))
            .overlay(Circle().strokeBorder(tint.opacity(isOn ? 0 : 0.5), lineWidth: 2))
            .shadow(color: tint.opacity(isOn ? 0.35 : 0), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isOn) { _, now in now }
        .accessibilityLabel("間食\(title)")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
