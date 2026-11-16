import SwiftUI
import UIKit

/// 写真がないときのインコの絵（横向きの頭と胸）。羽の色・ろう膜（オスは青、メスは茶）で描き分ける。
struct BudgieFace: View {
    var plumage: Plumage = .blue
    var sex: BirdSex = .unknown
    var size: CGFloat = 60

    var body: some View {
        Canvas { ctx, box in
            let s = box.width
            let (bodyHex, faceHex) = plumage.colors
            func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: x * s, y: y * s, width: w * s, height: h * s))
            }
            // 胸と体
            ctx.fill(oval(0.18, 0.42, 0.66, 0.6), with: .color(Color(UIColor.rgb(bodyHex))))
            // 頭（顔の色）
            ctx.fill(oval(0.22, 0.1, 0.56, 0.52), with: .color(Color(UIColor.rgb(faceHex))))
            // 頭のしま模様
            var stripes = Path()
            for i in 0..<4 {
                let y = 0.16 + CGFloat(i) * 0.06
                stripes.move(to: CGPoint(x: 0.36 * s, y: y * s))
                stripes.addQuadCurve(to: CGPoint(x: 0.66 * s, y: (y - 0.01) * s), control: CGPoint(x: 0.5 * s, y: (y + 0.03) * s))
            }
            ctx.stroke(stripes, with: .color(Color(UIColor.rgb(0x3A3A3A)).opacity(plumage == .lutino || plumage == .albino ? 0.12 : 0.45)), lineWidth: s * 0.018)
            // ほっぺの青い点
            ctx.fill(oval(0.27, 0.43, 0.09, 0.09), with: .color(Color(UIColor.rgb(plumage == .lutino || plumage == .albino ? 0xD8D8E8 : 0x4C57C8))))
            ctx.fill(oval(0.64, 0.43, 0.09, 0.09), with: .color(Color(UIColor.rgb(plumage == .lutino || plumage == .albino ? 0xD8D8E8 : 0x4C57C8))))
            // 目
            let eye = plumage == .lutino || plumage == .albino ? Color(UIColor.rgb(0xC0394B)) : .black
            ctx.fill(oval(0.33, 0.28, 0.09, 0.09), with: .color(eye))
            ctx.fill(oval(0.58, 0.28, 0.09, 0.09), with: .color(eye))
            ctx.fill(oval(0.35, 0.29, 0.03, 0.03), with: .color(.white))
            ctx.fill(oval(0.60, 0.29, 0.03, 0.03), with: .color(.white))
            // ろう膜（くちばしの上）
            let cere: UInt32 = switch sex {
            case .male: 0x4C7BD9
            case .female: 0xB89070
            case .unknown: 0xE7B9A5
            }
            ctx.fill(oval(0.43, 0.33, 0.14, 0.07), with: .color(Color(UIColor.rgb(cere))))
            // くちばし
            var beak = Path()
            beak.move(to: CGPoint(x: 0.43 * s, y: 0.39 * s))
            beak.addQuadCurve(to: CGPoint(x: 0.57 * s, y: 0.39 * s), control: CGPoint(x: 0.5 * s, y: 0.36 * s))
            beak.addQuadCurve(to: CGPoint(x: 0.5 * s, y: 0.52 * s), control: CGPoint(x: 0.56 * s, y: 0.47 * s))
            beak.addQuadCurve(to: CGPoint(x: 0.43 * s, y: 0.39 * s), control: CGPoint(x: 0.44 * s, y: 0.47 * s))
            ctx.fill(beak, with: .color(Color(UIColor.rgb(0xF0C27A))))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// 丸いアイコン（写真か絵）。
struct BirdBadge: View {
    let bird: Bird
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle().fill(Hue.sky.opacity(0.14))
            if let data = bird.picture, let ui = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: size * 3, height: size * 3)) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                BudgieFace(plumage: bird.plumage, sex: bird.sex, size: size * 0.9).offset(y: size * 0.06)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
