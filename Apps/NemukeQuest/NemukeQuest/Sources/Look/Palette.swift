import SwiftUI

/// 夜のダンジョンの色（旧版のダークグラス調を引き継ぐ）。画面はダーク固定。
enum Palette {
    static let background = Color(hex: 0x0B0F1E)
    static let surface = Color(hex: 0x161B2E)
    static let surfaceLight = Color(hex: 0x232B4A)
    static let border = Color.white.opacity(0.08)
    static let primary = Color(hex: 0x7C6CFF)
    static let accent = Color(hex: 0x34D399)
    static let gold = Color(hex: 0xFBBF24)
    static let danger = Color(hex: 0xF87171)
    static let fire = Color(hex: 0xFB923C)
    static let text = Color(hex: 0xF1F5F9)
    static let textMuted = Color(hex: 0x94A3B8)
    static let textFaint = Color(hex: 0x5A6478)

    static let card = LinearGradient(colors: [Color(hex: 0x1B2240), Color(hex: 0x141A30)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let hero = LinearGradient(colors: [Color(hex: 0x7C6CFF), Color(hex: 0x4F8EF7)], startPoint: .leading, endPoint: .trailing)
    static let demon = LinearGradient(colors: [Color(hex: 0x3B1D4F), Color(hex: 0x1E1230)], startPoint: .top, endPoint: .bottom)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// 枠つきの暗いカード。
struct Panel<Content: View>: View {
    var dimmed = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.border))
            .opacity(dimmed ? 0.5 : 1)
    }
}

/// 横に伸びるバー（EXP・HP）。
struct Meter: View {
    let ratio: Double
    let tint: Color
    var track: Color = Palette.surfaceLight

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(tint).frame(width: geo.size.width * min(max(ratio, 0), 1))
            }
        }
        .frame(height: 10)
        .animation(.easeOut(duration: 0.6), value: ratio)
    }
}
