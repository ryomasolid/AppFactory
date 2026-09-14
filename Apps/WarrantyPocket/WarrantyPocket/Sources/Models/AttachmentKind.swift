import Foundation

/// 写真の種類。
enum AttachmentKind: String, CaseIterable, Identifiable, Sendable {
    case warranty
    case receipt
    case manual
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .warranty: String(localized: "保証書")
        case .receipt: String(localized: "レシート")
        case .manual: String(localized: "取扱説明書")
        case .other: String(localized: "その他")
        }
    }

    var symbolName: String {
        switch self {
        case .warranty: "checkmark.seal.fill"
        case .receipt: "receipt"
        case .manual: "book.closed.fill"
        case .other: "photo"
        }
    }
}
