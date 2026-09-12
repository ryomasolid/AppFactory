import SwiftUI

/// アプリ共通の見た目。
enum Theme {
    /// アセットカタログの AccentColor。
    ///
    /// `Color.accentColor` は環境の tint を返すため、`.buttonStyle(.plain)` の中などでは
    /// アセットの色ではなくシステム既定（青）に落ちる。名前で引けば必ずアセットの色になる。
    static let accent = Color("AccentColor")

    /// "#RRGGBB" を 0...1 のRGBに変換する。解釈できなければ nil。
    /// 色はユーザーが選んだ値が SwiftData に文字列で入るので、壊れた値でも落ちないようにする。
    static func rgb(fromHex hex: String) -> (red: Double, green: Double, blue: Double)? {
        let trimmed = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard trimmed.count == 6 else { return nil }
        var value: UInt64 = 0
        guard Scanner(string: trimmed).scanHexInt64(&value) else { return nil }
        return (
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

extension Color {
    /// "#RRGGBB" から生成。壊れた値のときはアクセントカラーに落とす。
    init(hex: String) {
        guard let rgb = Theme.rgb(fromHex: hex) else {
            self = Theme.accent
            return
        }
        self = Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}
