import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// アプリアイコン（1024x1024・アルファなし）を生成する。
// App Store はアルファ付きアイコンを受け付けないため、alpha を持たない CGContext に直接描く。
_ = NSApplication.shared

let size = 1024
let out = CommandLine.arguments[1]

guard let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("context") }

// 背景: AccentColor と同系の緑のグラデーション。
let dark = CGColor(srgbRed: 0.16, green: 0.50, blue: 0.31, alpha: 1)
let light = CGColor(srgbRed: 0.29, green: 0.70, blue: 0.45, alpha: 1)
guard let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [light, dark] as CFArray, locations: [0, 1]
) else { fatalError("gradient") }
context.drawLinearGradient(
    gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: []
)

/// SF Symbol を指定色の CGImage にする。
func symbolImage(_ name: String, points: CGFloat, color: NSColor) -> CGImage? {
    let config = NSImage.SymbolConfiguration(pointSize: points, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
    guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else { return nil }
    var rect = CGRect(origin: .zero, size: image.size)
    return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
}

func draw(_ image: CGImage, centeredAt center: CGPoint, height: CGFloat) {
    let ratio = CGFloat(image.width) / CGFloat(image.height)
    let width = height * ratio
    context.draw(image, in: CGRect(x: center.x - width / 2, y: center.y - height / 2,
                                   width: width, height: height))
}

// 本体: ゴミ箱。右下にベルのバッジを置くぶん、少し左上へ寄せる。
guard let trash = symbolImage("trash.fill", points: 512, color: .white) else { fatalError("trash") }
draw(trash, centeredAt: CGPoint(x: 450, y: 585), height: 505)

// バッジ: 白丸に緑のベル。「ゴミ」と「通知」を1目で伝える。
// iOS の角丸マスクに食われないよう、バッジは角から十分内側に置く。
let badge = CGPoint(x: 660, y: 370)
let radius: CGFloat = 180
context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
context.fillEllipse(in: CGRect(x: badge.x - radius, y: badge.y - radius,
                               width: radius * 2, height: radius * 2))
guard let bell = symbolImage("bell.fill", points: 220, color: NSColor(srgbRed: 0.16, green: 0.50, blue: 0.31, alpha: 1))
else { fatalError("bell") }
draw(bell, centeredAt: badge, height: 195)

guard let image = context.makeImage() else { fatalError("image") }
let url = URL(fileURLWithPath: out)
guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("destination") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("finalize") }
print("wrote \(out)")
