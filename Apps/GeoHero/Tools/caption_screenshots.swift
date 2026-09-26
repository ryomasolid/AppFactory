// ストア用の 見出し入り スクリーンショットを作る（6.5インチ・1242x2688・透過なしJPEG）。
//
//     swift Tools/caption_screenshots.swift
//
// `Tools/make_screenshots.sh` で撮った `Docs/Store/screenshots/65_*.jpg` を 少し小さくして、
// 上に 大きな 見出しを 入れる。できたものは `Docs/Store/screenshots_captioned/`。
import AppKit

// Apps/GeoHero で 実行する。
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let input = root.appendingPathComponent("Docs/Store/screenshots")
let output = root.appendingPathComponent("Docs/Store/screenshots_captioned")
try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

/// 並べる順と 見出し。App Store の インストール画面には 最初の3枚が出る。
let shots: [(file: String, title: String, sub: String, color: NSColor)] = [
    ("65_1_title", "北海道を 旅する", "ドット絵の 地理RPG", NSColor(red: 0.10, green: 0.12, blue: 0.30, alpha: 1)),
    ("65_4_quiz", "地理の ちしきで", "おいうち！", NSColor(red: 0.12, green: 0.36, blue: 0.62, alpha: 1)),
    ("65_2_field", "3つの 地方を", "飛行機で めぐる", NSColor(red: 0.16, green: 0.45, blue: 0.24, alpha: 1)),
    ("65_3_town", "9つの 街を", "歩いて 話して", NSColor(red: 0.55, green: 0.38, blue: 0.16, alpha: 1)),
    ("65_5_boss", "ご当地の ぬしに", "いどもう", NSColor(red: 0.42, green: 0.10, blue: 0.14, alpha: 1)),
    ("65_6_shop", "名産の 道具と 装備で", "強くなる", NSColor(red: 0.30, green: 0.18, blue: 0.45, alpha: 1)),
]

let width = 1242, height = 2688

func draw(_ text: String, size: CGFloat, color: NSColor, centerY: CGFloat) {
    let font = NSFont(name: "HiraginoSans-W8", size: size) ?? .boldSystemFont(ofSize: size)
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
    shadow.shadowOffset = NSSize(width: 0, height: -6)
    shadow.shadowBlurRadius = 0
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font, .foregroundColor: color, .paragraphStyle: style, .shadow: shadow,
    ]
    let string = NSAttributedString(string: text, attributes: attributes)
    let bounds = string.boundingRect(with: NSSize(width: CGFloat(width) - 80, height: 400), options: .usesLineFragmentOrigin)
    string.draw(in: NSRect(x: 40, y: centerY - bounds.height / 2, width: CGFloat(width) - 80, height: bounds.height))
}

for (index, shot) in shots.enumerated() {
    guard let screenshot = NSImage(contentsOf: input.appendingPathComponent(shot.file + ".jpg")) else {
        print("みつからない: \(shot.file)"); continue
    }
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
        // 描くには アルファつきが いる（JPEG に するときに 消える）。
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { continue }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    shot.color.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    // 見出し（上）。AppKit は 下が 0 なので 上から はかる。
    draw(shot.title, size: 104, color: .white, centerY: CGFloat(height) - 190)
    draw(shot.sub, size: 104, color: NSColor(red: 1, green: 0.84, blue: 0.25, alpha: 1), centerY: CGFloat(height) - 330)

    // スクリーンショット（下）。角を まるめ、白い ふちを つける。
    let shotHeight = CGFloat(height) - 470 - 60
    let shotWidth = shotHeight * 1242 / 2688
    let frame = NSRect(x: (CGFloat(width) - shotWidth) / 2, y: 60, width: shotWidth, height: shotHeight)
    let rounded = NSBezierPath(roundedRect: frame, xRadius: 56, yRadius: 56)
    NSColor.white.setStroke()
    rounded.lineWidth = 16
    rounded.stroke()
    NSGraphicsContext.saveGraphicsState()
    rounded.addClip()
    screenshot.draw(in: frame)
    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.restoreGraphicsState()

    let name = String(format: "65_%d_%@.jpg", index + 1, String(shot.file.split(separator: "_").last!))
    let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])!
    try data.write(to: output.appendingPathComponent(name))
    print("  Docs/Store/screenshots_captioned/\(name)")
}
