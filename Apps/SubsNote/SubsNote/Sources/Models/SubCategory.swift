import SwiftUI

/// サブスクのカテゴリ。内訳の切り口と、丸アイコンの色に使う。
enum SubCategory: String, CaseIterable, Identifiable, Sendable {
    case video
    case music
    case game
    case reading
    case cloud
    case ai
    case fitness
    case telecom
    case life

    var id: String { rawValue }

    var label: String {
        switch self {
        case .video: String(localized: "動画")
        case .music: String(localized: "音楽")
        case .game: String(localized: "ゲーム")
        case .reading: String(localized: "ニュース・書籍")
        case .cloud: String(localized: "クラウド・ソフト")
        case .ai: String(localized: "AI")
        case .fitness: String(localized: "フィットネス")
        case .telecom: String(localized: "通信")
        case .life: String(localized: "生活・その他")
        }
    }

    var symbolName: String {
        switch self {
        case .video: "play.rectangle.fill"
        case .music: "music.note"
        case .game: "gamecontroller.fill"
        case .reading: "book.fill"
        case .cloud: "icloud.fill"
        case .ai: "sparkles"
        case .fitness: "figure.run"
        case .telecom: "antenna.radiowaves.left.and.right"
        case .life: "bag.fill"
        }
    }

    /// アイコンの丸と内訳のバーの色。
    var tint: Color {
        switch self {
        case .video: Palette.rgb(0xE03131)
        case .music: Palette.rgb(0xD6336C)
        case .game: Palette.rgb(0x7048E8)
        case .reading: Palette.rgb(0x1971C2)
        case .cloud: Palette.rgb(0x1098AD)
        case .ai: Palette.rgb(0xAE3EC9)
        case .fitness: Palette.rgb(0x37B24D)
        case .telecom: Palette.rgb(0xF08C00)
        case .life: Palette.rgb(0x868E96)
        }
    }
}
