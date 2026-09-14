import Foundation

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

    var colorHex: String {
        switch self {
        case .video: "#E03131"
        case .music: "#D6336C"
        case .game: "#7048E8"
        case .reading: "#1971C2"
        case .cloud: "#1098AD"
        case .ai: "#AE3EC9"
        case .fitness: "#37B24D"
        case .telecom: "#F08C00"
        case .life: "#868E96"
        }
    }
}
