import Foundation

/// ゴミの種類に使える色とアイコン。
/// 自由入力にすると背景が白や極端に薄い色になってカードの文字が読めなくなるので、
/// 白文字が載る濃さの色だけを用意して選ばせる。
enum KindPalette {
    static let colors: [String] = [
        "#E8543F",  // 燃えるゴミ（赤）
        "#E0A21B",  // プラ（黄）
        "#3E9B6B",  // 缶・瓶（緑）
        "#2F7DD1",  // 資源（青）
        "#7A5CD1",  // 紫
        "#C2447A",  // ピンク
        "#8B5E3C",  // 茶
        "#5B6472",  // グレー
    ]

    static let symbols: [String] = [
        "flame.fill",
        "arrow.3.trianglepath",
        "takeoutbag.and.cup.and.straw.fill",
        "cylinder.split.1x2.fill",
        "shippingbox.fill",
        "newspaper.fill",
        "leaf.fill",
        "trash.fill",
    ]

    static var defaultColor: String { colors[0] }
    static var defaultSymbol: String { symbols.last ?? "trash.fill" }
}
