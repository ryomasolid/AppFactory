import SwiftUI

/// 写真がないときの、上から見たカメの絵。
struct TurtleArt: View {
    let species: Species

    var body: some View {
        let shell = Palette.hex(species.colors.shell)
        let skin = Palette.hex(species.colors.skin)
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // 足
                ForEach(0..<4) { i in
                    Capsule()
                        .fill(skin)
                        .frame(width: s * 0.17, height: s * 0.24)
                        .rotationEffect(.degrees([-40, 40, 140, -140][i]))
                        .offset(x: [-1, 1, 1, -1][i] * s * 0.27, y: [-1, -1, 1, 1][i] * s * 0.2)
                }
                // しっぽ
                Capsule().fill(skin).frame(width: s * 0.07, height: s * 0.16).offset(y: s * 0.36)
                // 頭
                Ellipse()
                    .fill(skin)
                    .frame(width: s * 0.22, height: s * 0.26)
                    .overlay {
                        HStack(spacing: s * 0.07) {
                            Circle().fill(.black.opacity(0.8)).frame(width: s * 0.035)
                            Circle().fill(.black.opacity(0.8)).frame(width: s * 0.035)
                        }
                        .offset(y: -s * 0.04)
                    }
                    .offset(y: -s * 0.36)
                // 甲羅
                Ellipse()
                    .fill(shell.gradient)
                    .frame(width: s * 0.6, height: s * 0.68)
                    .overlay { ShellPlates().stroke(.black.opacity(0.22), lineWidth: s * 0.012) }
                    .overlay { Ellipse().stroke(.black.opacity(0.25), lineWidth: s * 0.015) }
                    .frame(width: s * 0.6, height: s * 0.68)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// 甲羅の真ん中のならび（背甲板）。
private struct ShellPlates: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        let cx = r.midX
        let rows: [CGFloat] = [0.22, 0.4, 0.6, 0.78]
        for y in rows {
            p.move(to: CGPoint(x: r.minX + w * 0.12, y: r.minY + h * y))
            p.addLine(to: CGPoint(x: r.maxX - w * 0.12, y: r.minY + h * y))
        }
        for y in [0.22, 0.4, 0.6] as [CGFloat] {
            let top = r.minY + h * y, bottom = r.minY + h * (y + (y == 0.4 ? 0.2 : 0.18))
            p.move(to: CGPoint(x: cx - w * 0.14, y: top))
            p.addLine(to: CGPoint(x: cx - w * 0.14, y: bottom))
            p.move(to: CGPoint(x: cx + w * 0.14, y: top))
            p.addLine(to: CGPoint(x: cx + w * 0.14, y: bottom))
        }
        return p
    }
}

/// 写真か絵の丸いアイコン。
struct TurtleAvatar: View {
    let turtle: Turtle
    var size: CGFloat = 64

    var body: some View {
        Group {
            if let data = turtle.photo, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                TurtleArt(species: turtle.species).padding(size * 0.08)
                    .background(Palette.sand)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().stroke(Palette.moss.opacity(0.35), lineWidth: 2) }
    }
}
