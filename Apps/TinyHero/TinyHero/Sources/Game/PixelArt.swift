import CoreGraphics
import SwiftUI

/// ドット絵の識別子。絵そのもの（16×16 の文字列）は `TileArt` / `CharacterArt` / `EnemyArt` に置く。
enum SpriteID: String, CaseIterable {
    // 地形
    case grass, forest, hills, mountain, water, road, bridge, town, cave
    case townFloor, house, innRoof, shopRoof, fountain, wall, caveFloor, stairsUp, stairsDown
    case houseWall, innSign, shopSign, door, woodFloor, counter, bed, shelf, innerWall, darkness
    /// 街と ほらあなを 1マスより大きく描くための、背景を透かした版。
    case townLarge, caveLarge
    case chestClosed, chestOpen
    // 人（勇者は hero1/hero2 が下向き、ほかの向きはそれぞれ歩きの2コマ）
    case hero1, hero2, heroUp1, heroUp2, heroLeft1, heroLeft2, heroRight1, heroRight2
    case elder, innkeeper, shopkeeper, villager

    /// 向きと歩数から勇者の絵を選ぶ（1歩ごとに2コマを交互に）。
    static func hero(facing: Direction, step: Int) -> SpriteID {
        let second = step % 2 != 0
        switch facing {
        case .down: return second ? .hero2 : .hero1
        case .up: return second ? .heroUp2 : .heroUp1
        case .left: return second ? .heroLeft2 : .heroLeft1
        case .right: return second ? .heroRight2 : .heroRight1
        }
    }
    // 敵
    case potato, kelpSlime, scallop, fox, cod, snowman, iceGolem, guardian

    static let art: [SpriteID: [String]] = TileArt.all
        .merging(CharacterArt.all) { first, _ in first }
        .merging(EnemyArt.all) { first, _ in first }

    init(tile: Tile) {
        switch tile {
        case .grass: self = .grass
        case .forest: self = .forest
        case .hills: self = .hills
        case .mountain: self = .mountain
        case .water: self = .water
        case .road: self = .road
        case .bridge: self = .bridge
        case .town: self = .town
        case .cave: self = .cave
        case .townFloor, .exit: self = .townFloor
        case .house: self = .house
        case .innRoof: self = .innRoof
        case .shopRoof: self = .shopRoof
        case .fountain: self = .fountain
        case .wall: self = .wall
        case .caveFloor: self = .caveFloor
        case .stairsUp: self = .stairsUp
        case .stairsDown: self = .stairsDown
        case .houseWall: self = .houseWall
        case .innSign: self = .innSign
        case .shopSign: self = .shopSign
        case .door: self = .door
        case .woodFloor: self = .woodFloor
        case .counter: self = .counter
        case .bed: self = .bed
        case .shelf: self = .shelf
        case .innerWall: self = .innerWall
        case .darkness: self = .darkness
        }
    }

    init(enemy: EnemyKind) {
        switch enemy {
        case .potato: self = .potato
        case .kelpSlime: self = .kelpSlime
        case .scallop: self = .scallop
        case .fox: self = .fox
        case .cod: self = .cod
        case .snowman: self = .snowman
        case .iceGolem: self = .iceGolem
        case .guardian: self = .guardian
        }
    }

    init(npc role: NPCRole) {
        switch role {
        case .innkeeper: self = .innkeeper
        case .shopkeeper: self = .shopkeeper
        case .elder: self = .elder
        case .villager: self = .villager
        }
    }
}

/// ドット絵の色。文字1つ＝1色、`.` は透明。
enum Palette {
    static let colors: [Character: (r: UInt8, g: UInt8, b: UInt8)] = [
        "k": (16, 16, 24),     // 黒
        "w": (248, 248, 240),  // 白
        "a": (150, 150, 160),  // 灰
        "A": (84, 84, 96),     // 濃い灰
        "g": (88, 184, 72),    // 緑
        "G": (40, 112, 48),    // 濃い緑
        "l": (152, 216, 96),   // 明るい緑
        "b": (64, 128, 232),   // 青
        "B": (32, 64, 160),    // 濃い青
        "c": (136, 200, 248),  // 水色
        "y": (248, 208, 64),   // 黄
        "o": (232, 128, 40),   // 橙
        "r": (216, 48, 48),    // 赤
        "R": (128, 24, 32),    // 暗い赤
        "n": (160, 104, 56),   // 茶
        "N": (96, 56, 32),     // 濃い茶
        "t": (216, 184, 128),  // 砂
        "s": (248, 192, 152),  // 肌
        "p": (152, 88, 200),   // 紫
        "P": (80, 40, 112),    // 濃い紫
    ]
}

@MainActor
enum SpriteCache {
    /// 1ドットをこの倍率で焼き込む。表示側で縮小してもにじみにくい。
    static let scale = 8
    private static var images: [SpriteID: CGImage] = [:]

    static func image(_ id: SpriteID) -> Image {
        if let cached = images[id] { return Image(decorative: cached, scale: 1) }
        let rendered = render(SpriteID.art[id] ?? []) ?? placeholder
        images[id] = rendered
        return Image(decorative: rendered, scale: 1)
    }

    private static let placeholder: CGImage = render(Array(repeating: String(repeating: "p", count: 16), count: 16))!

    /// 文字列のドット絵を RGBA のビットマップにする（行が上から、列が左から）。
    static func render(_ rows: [String]) -> CGImage? {
        let height = rows.count
        let width = rows.map(\.count).max() ?? 0
        guard width > 0, height > 0 else { return nil }
        let w = width * scale
        let h = height * scale
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        for (y, row) in rows.enumerated() {
            for (x, char) in row.enumerated() {
                guard let color = Palette.colors[char] else { continue }
                for dy in 0..<scale {
                    for dx in 0..<scale {
                        let i = ((y * scale + dy) * w + (x * scale + dx)) * 4
                        pixels[i] = color.r
                        pixels[i + 1] = color.g
                        pixels[i + 2] = color.b
                        pixels[i + 3] = 255
                    }
                }
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )
    }
}
