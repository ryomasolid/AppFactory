// ストア用の スクリーンショットを 作る（6.5インチ・1242x2688・透過なしJPEG）。
//
//     swift Tools/caption_screenshots.swift
//     swift Tools/caption_screenshots.swift edu   （先生・保護者 向けの カスタムプロダクトページ用）
//
// `Tools/make_screenshots.sh` で撮った `Docs/Store/screenshots/65_*.jpg` を iPhone の 枠に 入れ、
// グラデーションの 背景・ラベル・大きな 見出しを つける。見どころ（ボスの ドット絵・クイズの 枠など）は
// 拡大した カードにして 枠から 飛び出させる。できたものは `Docs/Store/screenshots_captioned/`。
import AppKit

// Apps/GeoHero で 実行する。
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let input = root.appendingPathComponent("Docs/Store/screenshots")
/// `edu` を つけると 見出しを 学び向けに かえ、`Docs/Store/screenshots_edu/` に 出す。
let isEdu = CommandLine.arguments.dropFirst().first == "edu"
let output = root.appendingPathComponent(isEdu ? "Docs/Store/screenshots_edu" : "Docs/Store/screenshots_captioned")
try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let width: CGFloat = 1242, height: CGFloat = 2688

func rgb(_ hex: UInt32) -> NSColor {
    NSColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

/// 飛び出す カード。`crop` は 元の スクショ（1242x2688・上が 0）の 切り抜き。
/// `center` は できあがりの 画像での 中心（上が 0）、`cardWidth` は 横幅、`tilt` は 傾き（度）。
struct Popout {
    let crop: NSRect
    let center: NSPoint
    let cardWidth: CGFloat
    let tilt: CGFloat
}

struct Shot {
    let file: String
    let name: String
    let tag: String
    let title: String
    let accent: String
    let top: NSColor
    let bottom: NSColor
    let popout: Popout
    /// iPhone の 枠を 左右どちらに 寄せるか（カードの 反対がわ）。
    let deviceShift: CGFloat
}

/// 並べる順と 見出し。App Store の インストール画面には 最初の3枚が出る。
let shots: [Shot] = [
    Shot(file: "65_1_title", name: "title", tag: "ドット絵 RPG", title: "北海道を", accent: "冒険しよう",
         top: rgb(0x1B1F4B), bottom: rgb(0x4A2C7A),
         popout: Popout(crop: NSRect(x: 250, y: 1030, width: 790, height: 400),
                        center: NSPoint(x: 700, y: 1860), cardWidth: 820, tilt: -5),
         deviceShift: -90),
    Shot(file: "65_4_quiz", name: "quiz", tag: "地理クイズ", title: "ちしきで", accent: "おいうち！",
         top: rgb(0x2A7DE1), bottom: rgb(0x0E3A7A),
         popout: Popout(crop: NSRect(x: 150, y: 520, width: 950, height: 380),
                        center: NSPoint(x: 621, y: 1330), cardWidth: 1080, tilt: -4),
         deviceShift: 0),
    Shot(file: "65_2_field", name: "field", tag: "3つの 地方", title: "北海道を", accent: "飛行機で めぐる",
         top: rgb(0x35B566), bottom: rgb(0x0F5C35),
         popout: Popout(crop: NSRect(x: 180, y: 860, width: 600, height: 520),
                        center: NSPoint(x: 900, y: 1500), cardWidth: 540, tilt: 5),
         deviceShift: -90),
    Shot(file: "65_3_town", name: "town", tag: "9つの 街", title: "名所と 人に", accent: "出会う 旅",
         top: rgb(0xF5A04A), bottom: rgb(0xB24A22),
         popout: Popout(crop: NSRect(x: 230, y: 520, width: 700, height: 640),
                        center: NSPoint(x: 330, y: 1480), cardWidth: 540, tilt: -5),
         deviceShift: 90),
    Shot(file: "65_5_boss", name: "boss", tag: "ボスバトル", title: "ご当地の ぬしと", accent: "白熱バトル",
         top: rgb(0xD0343F), bottom: rgb(0x3E0A18),
         popout: Popout(crop: NSRect(x: 380, y: 400, width: 560, height: 580),
                        center: NSPoint(x: 900, y: 1330), cardWidth: 520, tilt: 6),
         deviceShift: -90),
    Shot(file: "65_6_shop", name: "shop", tag: "名産アイテム", title: "名産の 道具で", accent: "強くなる",
         top: rgb(0x8A55D6), bottom: rgb(0x341A66),
         popout: Popout(crop: NSRect(x: 19, y: 752, width: 1210, height: 418),
                        center: NSPoint(x: 621, y: 2080), cardWidth: 1100, tilt: -3),
         deviceShift: 0),
]

/// 先生・保護者 向けの 見出し（ラベル・1行目・2行目）。絵と 並びは 同じ。
let eduTexts: [String: (tag: String, title: String, accent: String)] = [
    "title": ("授業・自由研究に", "遊びながら", "北海道を 学ぶ"),
    "quiz": ("地理クイズ", "五稜郭・運河・流氷", "楽しく 覚える"),
    "field": ("地図で 学ぶ", "地方の 位置が", "歩いて わかる"),
    "town": ("名所の 看板", "街の人と 看板が", "先生に なる"),
    "boss": ("ご当地バトル", "正解すると", "有利に なる"),
    "shop": ("安心して 遊べる", "広告・課金・通信", "いっさい なし"),
]

// MARK: - 描く部品（AppKit は 下が 0。上から はかる 値は `flip` で なおす）

func flip(_ y: CGFloat) -> CGFloat { height - y }

func text(_ string: String, size: CGFloat, weight: String = "W8", color: NSColor) -> NSAttributedString {
    let font = NSFont(name: "HiraginoSans-\(weight)", size: size) ?? .boldSystemFont(ofSize: size)
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    return NSAttributedString(string: string, attributes: [
        .font: font, .foregroundColor: color, .paragraphStyle: style, .kern: size * 0.02,
    ])
}

/// 上から `centerY` の 位置に 1行 書く。
func drawLine(_ string: NSAttributedString, centerY: CGFloat, shadow: Bool = true) {
    NSGraphicsContext.saveGraphicsState()
    if shadow {
        let s = NSShadow()
        s.shadowColor = NSColor.black.withAlphaComponent(0.28)
        s.shadowOffset = NSSize(width: 0, height: -8)
        s.shadowBlurRadius = 18
        s.set()
    }
    let size = string.size()
    string.draw(at: NSPoint(x: (width - size.width) / 2, y: flip(centerY) - size.height / 2))
    NSGraphicsContext.restoreGraphicsState()
}

/// 背景：ななめの グラデーション・ぼんやり 光る 丸・ドット絵ふうの 小さな 四角。
func drawBackground(_ shot: Shot, seed: Int) {
    NSGradient(starting: shot.top, ending: shot.bottom)!
        .draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -70)
    for (x, y, r, a) in [(1100.0, 420.0, 520.0, 0.16), (80.0, 1900.0, 620.0, 0.10)] {
        let glow = NSGradient(colors: [NSColor.white.withAlphaComponent(a), NSColor.white.withAlphaComponent(0)])!
        glow.draw(fromCenter: NSPoint(x: x, y: flip(y)), radius: 0, toCenter: NSPoint(x: x, y: flip(y)), radius: r, options: [])
    }
    // 毎回 同じ 並びに なるよう、決まった 式で 散らす。
    var state = UInt64(seed * 7919 + 17)
    func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(state >> 33) / CGFloat(UInt32.max >> 1)
    }
    for _ in 0..<26 {
        let size = [12, 18, 24][Int(next() * 3) % 3]
        let x = next() * width, y = next() * height
        NSColor.white.withAlphaComponent(0.08 + next() * 0.14).setFill()
        NSRect(x: x, y: y, width: CGFloat(size), height: CGFloat(size)).fill()
    }
}

/// 上の ラベル（まるい 札）と 2行の 見出し。
func drawHeadline(_ shot: Shot) {
    let tag = text(shot.tag, size: 46, weight: "W6", color: .white)
    let tagSize = tag.size()
    let pill = NSRect(x: (width - tagSize.width) / 2 - 38, y: flip(215) - 44, width: tagSize.width + 76, height: 88)
    NSColor.white.withAlphaComponent(0.20).setFill()
    NSBezierPath(roundedRect: pill, xRadius: 44, yRadius: 44).fill()
    NSColor.white.withAlphaComponent(0.55).setStroke()
    let border = NSBezierPath(roundedRect: pill.insetBy(dx: 1.5, dy: 1.5), xRadius: 43, yRadius: 43)
    border.lineWidth = 3
    border.stroke()
    tag.draw(at: NSPoint(x: pill.midX - tagSize.width / 2, y: pill.midY - tagSize.height / 2))

    drawLine(text(shot.title, size: 118, weight: "W9", color: .white), centerY: 390)
    drawLine(text(shot.accent, size: 128, weight: "W9", color: rgb(0xFFD84A)), centerY: 545)
}

/// iPhone の 枠に スクショを 入れる。下は 画像の 外へ はみ出す。
func drawDevice(_ screenshot: NSImage, shift: CGFloat) {
    let screenWidth: CGFloat = 880
    let screenHeight = screenWidth * 2688 / 1242
    let bezel: CGFloat = 30
    let frame = NSRect(x: (width - screenWidth) / 2 - bezel + shift, y: flip(700) - screenHeight - bezel * 2,
                       width: screenWidth + bezel * 2, height: screenHeight + bezel * 2)
    // 影
    NSGraphicsContext.saveGraphicsState()
    let s = NSShadow()
    s.shadowColor = NSColor.black.withAlphaComponent(0.45)
    s.shadowOffset = NSSize(width: 0, height: -30)
    s.shadowBlurRadius = 70
    s.set()
    rgb(0x111114).setFill()
    NSBezierPath(roundedRect: frame, xRadius: 130, yRadius: 130).fill()
    NSGraphicsContext.restoreGraphicsState()
    // ふちの 光
    rgb(0x3A3A42).setStroke()
    let rim = NSBezierPath(roundedRect: frame.insetBy(dx: 4, dy: 4), xRadius: 126, yRadius: 126)
    rim.lineWidth = 6
    rim.stroke()
    // 画面
    let screen = frame.insetBy(dx: bezel, dy: bezel)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: screen, xRadius: 100, yRadius: 100).addClip()
    NSGraphicsContext.current?.imageInterpolation = .high
    screenshot.draw(in: screen)
    NSGraphicsContext.restoreGraphicsState()
    // ダイナミックアイランド
    let island = NSRect(x: screen.midX - 110, y: screen.maxY - 30 - 64, width: 220, height: 64)
    NSColor.black.setFill()
    NSBezierPath(roundedRect: island, xRadius: 32, yRadius: 32).fill()
}

/// 見どころを 拡大して、白い ふちの カードで 飛び出させる。ドット絵が にじまないよう 拡大は 最近傍。
func drawPopout(_ popout: Popout, from bitmap: NSBitmapImageRep) {
    let crop = popout.crop
    guard let cg = bitmap.cgImage?.cropping(to: CGRect(x: crop.minX, y: crop.minY, width: crop.width, height: crop.height))
    else { return }
    let image = NSImage(cgImage: cg, size: crop.size)
    let cardHeight = popout.cardWidth * crop.height / crop.width
    let card = NSRect(x: -popout.cardWidth / 2, y: -cardHeight / 2, width: popout.cardWidth, height: cardHeight)

    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform()
    transform.translateX(by: popout.center.x, yBy: flip(popout.center.y))
    transform.rotate(byDegrees: popout.tilt)
    transform.concat()

    let outer = card.insetBy(dx: -14, dy: -14)
    NSGraphicsContext.saveGraphicsState()
    let s = NSShadow()
    s.shadowColor = NSColor.black.withAlphaComponent(0.5)
    s.shadowOffset = NSSize(width: 0, height: -24)
    s.shadowBlurRadius = 50
    s.set()
    NSColor.white.setFill()
    NSBezierPath(roundedRect: outer, xRadius: 44, yRadius: 44).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: card, xRadius: 32, yRadius: 32).addClip()
    NSGraphicsContext.current?.imageInterpolation = .none
    image.draw(in: card)
    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.restoreGraphicsState()
}

for (index, base) in shots.enumerated() {
    var shot = base
    if isEdu, let text = eduTexts[base.name] {
        shot = Shot(file: base.file, name: base.name, tag: text.tag, title: text.title, accent: text.accent,
                    top: base.top, bottom: base.bottom, popout: base.popout, deviceShift: base.deviceShift)
    }
    let url = input.appendingPathComponent(shot.file + ".jpg")
    guard let screenshot = NSImage(contentsOf: url),
          let source = NSBitmapImageRep(data: try Data(contentsOf: url)) else {
        print("みつからない: \(shot.file)"); continue
    }
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(width), pixelsHigh: Int(height), bitsPerSample: 8, samplesPerPixel: 4,
        // 描くには アルファつきが いる（JPEG に するときに 消える）。
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { continue }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    drawBackground(shot, seed: index)
    drawHeadline(shot)
    drawDevice(screenshot, shift: shot.deviceShift)
    drawPopout(shot.popout, from: source)
    NSGraphicsContext.restoreGraphicsState()

    let name = String(format: "65_%d_%@.jpg", index + 1, shot.name)
    let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92])!
    try data.write(to: output.appendingPathComponent(name))
    print("  \(output.lastPathComponent)/\(name)")
}
