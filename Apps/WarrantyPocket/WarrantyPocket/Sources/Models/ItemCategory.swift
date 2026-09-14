import Foundation

/// 商品のカテゴリ。一覧の絞り込みと、写真が無いときのアイコンに使う。
enum ItemCategory: String, CaseIterable, Identifiable, Sendable {
    case kitchen
    case living
    case climate
    case av
    case digital
    case camera
    case furniture
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .kitchen: String(localized: "キッチン家電")
        case .living: String(localized: "生活家電")
        case .climate: String(localized: "空調")
        case .av: String(localized: "テレビ・オーディオ")
        case .digital: String(localized: "PC・スマホ")
        case .camera: String(localized: "カメラ")
        case .furniture: String(localized: "家具")
        case .other: String(localized: "その他")
        }
    }

    var symbolName: String {
        switch self {
        case .kitchen: "refrigerator.fill"
        case .living: "washer.fill"
        case .climate: "air.conditioner.horizontal.fill"
        case .av: "tv.fill"
        case .digital: "laptopcomputer"
        case .camera: "camera.fill"
        case .furniture: "sofa.fill"
        case .other: "shippingbox.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .kitchen: "#E07A3F"
        case .living: "#3F8FD2"
        case .climate: "#35A7A0"
        case .av: "#6C5FC7"
        case .digital: "#5A6B7D"
        case .camera: "#C9567A"
        case .furniture: "#9A7348"
        case .other: "#8E8E93"
        }
    }
}
