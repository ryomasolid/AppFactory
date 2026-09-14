import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// アプリアイコン（1024x1024・アルファなし）を生成する。
// App Store はアルファ付きアイコンを受け付けないため、alpha を持たない CGContext に直接描く。
// 使い方: swift Store/makeicon.swift SubsNote/Resources/Assets.xcassets/AppIcon.appiconset/icon.png
_ = NSApplication.shared

let size = 1024
let out = CommandLine.arguments[1]

guard let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("context") }

// 背景: AccentColor（#16877A）と同系のティールのグラデーション。
let deep = NSColor(srgbRed: 0.05, green: 0.42, blue: 0.38, alpha: 1)
let light = CGColor(srgbRed: 0.20, green: 0.66, blue: 0.58, alpha: 1)
guard let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [light, deep.cgColor] as CFArray, locations: [0, 1]
) else { fatalError("gradient") }
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

/// SF Symbol を指定色の CGImage にする。
func symbolImage(_ name: String, points: CGFloat, palette: [NSColor]) -> CGImage? {
    let config = NSImage.SymbolConfiguration(pointSize: points, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: palette))
    guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else { return nil }
    var rect = CGRect(origin: .zero, size: image.size)
    return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
}

func draw(_ image: CGImage, centeredAt center: CGPoint, width: CGFloat) {
    let ratio = CGFloat(image.height) / CGFloat(image.width)
    let height = width * ratio
    context.draw(image, in: CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height))
}

// 本体: 白い円に「くり返し」の矢印と円記号。「毎月の支払い」を1目で伝える。
let center = CGPoint(x: 490, y: 540)
guard let cycle = symbolImage("arrow.triangle.2.circlepath", points: 512, palette: [.white]) else { fatalError("cycle") }
draw(cycle, centeredAt: center, width: 600)
guard let yen = symbolImage("yensign", points: 400, palette: [.white]) else { fatalError("yen") }
draw(yen, centeredAt: CGPoint(x: center.x, y: center.y + 4), width: 190)

// バッジ: 白丸にティールのベル。「支払日の前に知らせる」。
// iOS の角丸マスクに食われないよう、バッジは角から十分内側に置く。
let badge = CGPoint(x: 740, y: 270)
let radius: CGFloat = 150
context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
context.fillEllipse(in: CGRect(x: badge.x - radius, y: badge.y - radius, width: radius * 2, height: radius * 2))
guard let bell = symbolImage("bell.fill", points: 240, palette: [deep]) else { fatalError("bell") }
draw(bell, centeredAt: badge, width: 160)

guard let image = context.makeImage() else { fatalError("image") }
let url = URL(fileURLWithPath: out)
guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("destination") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("finalize") }
print("wrote \(out)")
