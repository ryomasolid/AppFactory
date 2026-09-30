import SwiftUI

/// サブスク帳の色。意味ごとに名前を付け、画面側では色コードを直接書かない。
///
/// - `ink`: 帳簿の見出し・主ボタン（アセットの AccentColor。深い青緑）
/// - `deadline`: 無料体験の終わり・3日以内の支払い（引き落としが迫っている）
/// - `saving`: 解約で浮いた額・見直しで浮く額
/// - `idle`: ほとんど使っていないサブスク
enum Palette {
    /// `Color.accentColor` は `.buttonStyle(.plain)` の中で青に戻ることがあるので、名前で引く。
    static let ink = Color("AccentColor")
    static let deadline = Palette.rgb(0xE8590C)
    static let saving = Palette.rgb(0x2B8A3E)
    static let idle = Palette.rgb(0xC92A2A)

    /// 0xRRGGBB の整数から色を作る（色はすべてコード内の定数なので、文字列の解釈はしない）。
    static func rgb(_ value: UInt32) -> Color {
        Color(
            .sRGB,
            red: Double((value & 0xFF0000) >> 16) / 255,
            green: Double((value & 0x00FF00) >> 8) / 255,
            blue: Double(value & 0x0000FF) / 255
        )
    }
}
