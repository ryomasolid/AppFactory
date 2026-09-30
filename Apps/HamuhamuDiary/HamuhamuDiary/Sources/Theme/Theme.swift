import SwiftUI

/// アプリ共通の見た目。旧版と同じ、クリーム地にオレンジのあたたかい配色。
enum Theme {
    /// アセットカタログの AccentColor。
    ///
    /// `Color.accentColor` は環境の tint を返すため、`.buttonStyle(.plain)` の中などでは
    /// アセットの色ではなくシステム既定（青）に落ちる。名前で引けば必ずアセットの色になる。
    static let accent = Color("AccentColor")
    /// 画面の地の色（クリーム）。
    static let background = Color("Background")
    /// カードの色。
    static let card = Color("CardBackground")
    /// 入力欄・チップなどの淡いオレンジ。
    static let softFill = Color("SoftFill")

    static let ok = Color(red: 0.20, green: 0.70, blue: 0.40)
    static let soon = Color(red: 0.93, green: 0.58, blue: 0.10)
    static let due = Color(red: 0.86, green: 0.30, blue: 0.27)
}

extension ReminderStatus.State {
    var color: Color {
        switch self {
        case .ok: Theme.ok
        case .soon: Theme.soon
        case .due: Theme.due
        }
    }

    var label: String {
        switch self {
        case .ok: String(localized: "良好")
        case .soon: String(localized: "もうすぐ交換")
        case .due: String(localized: "交換時期です")
        }
    }
}
