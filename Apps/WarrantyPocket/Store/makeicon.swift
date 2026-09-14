import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// アプリアイコン（1024x1024・アルファなし）を生成する。
// App Store はアルファ付きアイコンを受け付けないため、alpha を持たない CGContext に直接描く。
// 使い方: swift Store/makeicon.swift WarrantyPocket/Resources/Assets.xcassets/AppIcon.appiconset/icon.png
_ = NSApplication.shared

let size = 1024
let out = CommandLine.arguments[1]

guard let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("context") }

// 背景: AccentColor（#4A55A2）と同系のインディゴのグラデーション。
let deep = NSColor(srgbRed: 0.22, green: 0.25, blue: 0.52, alpha: 1)
let light = CGColor(srgbRed: 0.38, green: 0.44, blue: 0.78, alpha: 1)
guard let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [light, deep.cgColor] as CFArray, locations: [0, 1]
) else { fatalError("gradient") }
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

/// SF Symbol を指定色の CGImage にする。
/// palette を複数渡すと、盾の中のチェックなど前面の層に先頭の色が付く。
func symbolImage(_ name: String, points: CGFloat, color: NSColor, palette: [NSColor]? = nil) -> CGImage? {
    let config = NSImage.SymbolConfiguration(pointSize: points, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: palette ?? [color]))
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

// 本体: 白い書類（保証書）。右下にバッジを置くぶん、少し左上へ寄せる。
guard let doc = symbolImage("doc.text.fill", points: 512, color: .white) else { fatalError("doc") }
draw(doc, centeredAt: CGPoint(x: 470, y: 560), width: 470)

// バッジ: 白丸にインディゴのチェック付き盾。「保証」と「守られている」を1目で伝える。
// iOS の角丸マスクに食われないよう、バッジは角から十分内側に置く。
let badge = CGPoint(x: 700, y: 290)
let radius: CGFloat = 170
context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
context.fillEllipse(in: CGRect(x: badge.x - radius, y: badge.y - radius, width: radius * 2, height: radius * 2))
guard let shield = symbolImage("checkmark.shield.fill", points: 240, color: deep, palette: [.white, deep])
else { fatalError("shield") }
draw(shield, centeredAt: CGPoint(x: badge.x, y: badge.y - 4), width: 190)

guard let image = context.makeImage() else { fatalError("image") }
let url = URL(fileURLWithPath: out)
guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("destination") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("finalize") }
print("wrote \(out)")
