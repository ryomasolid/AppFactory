import SwiftUI
import UIKit

/// 写真がないときの顔。もこもこの頭・たれ耳・まんまるの目を、毛色で描く。
struct PoodleFace: View {
    var coat: CoatColor = .apricot
    var size: CGFloat = 64

    /// (x, y, 半径) を 1辺=1 で。
    private static let topknot: [(CGFloat, CGFloat, CGFloat)] = [
        (0.50, 0.20, 0.15), (0.36, 0.25, 0.12), (0.64, 0.25, 0.12), (0.43, 0.14, 0.11), (0.57, 0.14, 0.11),
    ]
    private static let ears: [(CGFloat, CGFloat, CGFloat)] = [
        (0.20, 0.50, 0.11), (0.17, 0.63, 0.11), (0.21, 0.75, 0.10),
        (0.80, 0.50, 0.11), (0.83, 0.63, 0.11), (0.79, 0.75, 0.10),
    ]

    var body: some View {
        Canvas { context, canvas in
            let s = canvas.width
            let fur = Color(UIColor(hex: coat.hex))
            let edge = Color(UIColor(hex: coat.hex, dim: 0.8))
            let isDark = coat == .black || coat == .brown
            func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: Color) {
                context.fill(Path(ellipseIn: CGRect(x: (x - r) * s, y: (y - r) * s, width: 2 * r * s, height: 2 * r * s)), with: .color(color))
            }
            let puffs = Self.topknot + Self.ears + [(0.50, 0.55, 0.27)]
            // 外側を少し濃くしてから中を塗ると、白い子でも輪郭が見える。
            for (x, y, r) in puffs { dot(x, y, r + 0.015, edge) }
            for (x, y, r) in puffs { dot(x, y, r, fur) }
            // 口もと
            context.fill(Path(ellipseIn: CGRect(x: 0.36 * s, y: 0.58 * s, width: 0.28 * s, height: 0.2 * s)), with: .color(isDark ? edge : Color.white.opacity(0.35)))
            let eye = isDark ? Color(white: 0.05) : Color(red: 0.16, green: 0.1, blue: 0.08)
            dot(0.40, 0.52, 0.04, eye)
            dot(0.60, 0.52, 0.04, eye)
            dot(0.41, 0.51, 0.013, .white)
            dot(0.61, 0.51, 0.013, .white)
            dot(0.50, 0.63, 0.045, eye)
            // ほっぺ
            dot(0.33, 0.62, 0.035, Color(red: 0.95, green: 0.55, blue: 0.6).opacity(0.45))
            dot(0.67, 0.62, 0.035, Color(red: 0.95, green: 0.55, blue: 0.6).opacity(0.45))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// わんちゃんのアイコン（写真があれば写真、なければ似顔絵）。
struct DogAvatar: View {
    let dog: Dog
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle().fill(Tone.apricot.opacity(0.18))
            if let data = dog.portrait, let image = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: size * 3, height: size * 3)) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                PoodleFace(coat: dog.coat, size: size * 0.86)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Tone.card, lineWidth: 2))
    }
}
