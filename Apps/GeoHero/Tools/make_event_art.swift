// アプリ内イベント用の 画像を作る（カード 1920x1080・詳細 1080x1920、透過なしJPEG）。
//
//     swiftc -O Tools/make_event_art.swift -o /tmp/event_art && /tmp/event_art   （Apps/GeoHero で）
//
// `Docs/Store/screenshots/` の スクリーンショットを 並べる。できたものは `Docs/Store/event/`。
// App Store は 画像の 下のほうに イベント名を かさねるので、下には 文字を 置かない。
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let input = root.appendingPathComponent("Docs/Store/screenshots")
let output = root.appendingPathComponent("Docs/Store/event")
try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func image(_ name: String) -> NSImage { NSImage(contentsOf: input.appendingPathComponent(name + ".jpg"))! }

func canvas(_ width: Int, _ height: Int, draw: () -> Void) -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    // 空から 夜の海へ（ゲームの タイトル画面の 色）。
    NSGradient(starting: NSColor(red: 0.16, green: 0.24, blue: 0.52, alpha: 1),
               ending: NSColor(red: 0.05, green: 0.06, blue: 0.16, alpha: 1))!
        .draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])!
}

/// 角を まるめて 白い ふちを つけた スクリーンショット。
func phone(_ image: NSImage, in frame: NSRect, radius: CGFloat) {
    let path = NSBezierPath(roundedRect: frame, xRadius: radius, yRadius: radius)
    NSColor.white.setStroke()
    path.lineWidth = radius / 4
    path.stroke()
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    image.draw(in: frame)
    NSGraphicsContext.restoreGraphicsState()
}

func title(_ text: String, size: CGFloat, width: CGFloat, top: CGFloat) {
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let string = NSAttributedString(string: text, attributes: [
        .font: NSFont(name: "HiraginoSans-W8", size: size) ?? .boldSystemFont(ofSize: size),
        .foregroundColor: NSColor(red: 1, green: 0.84, blue: 0.25, alpha: 1),
        .paragraphStyle: style,
    ])
    string.draw(in: NSRect(x: 0, y: top - size * 1.3, width: width, height: size * 1.4))
}

let shots = ["65_3_town", "65_2_field", "65_4_quiz"].map(image)

// カード（横長）。上に 見出し、まんなかに スクリーンショットを 3枚。下 3分の1は あける。
let card = canvas(1920, 1080) {
    title("北海道 めいしょスタンプラリー", size: 84, width: 1920, top: 1040)
    let height: CGFloat = 640
    let width = height * 1242 / 2688
    for (index, shot) in shots.enumerated() {
        let x = 1920 / 2 - width * 1.5 - 60 + CGFloat(index) * (width + 60)
        phone(shot, in: NSRect(x: x, y: 290, width: width, height: height), radius: 36)
    }
}
try card.write(to: output.appendingPathComponent("event_card_1920x1080.jpg"))

// 詳細ページ（縦長）。上に 見出し、まんなかに 大きく 1枚。
let detail = canvas(1080, 1920) {
    title("めいしょ", size: 120, width: 1080, top: 1860)
    title("スタンプラリー", size: 120, width: 1080, top: 1700)
    let height: CGFloat = 1100
    let width = height * 1242 / 2688
    phone(shots[0], in: NSRect(x: (1080 - width) / 2, y: 420, width: width, height: height), radius: 48)
}
try detail.write(to: output.appendingPathComponent("event_detail_1080x1920.jpg"))
print("Docs/Store/event/ に 2枚")
