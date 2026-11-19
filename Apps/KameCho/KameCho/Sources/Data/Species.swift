import Foundation

/// 水で暮らすカメか、陸で暮らすカメか。世話の中身がまるで変わる。
enum Habitat: String {
    case water, land

    var label: String { self == .water ? "ミズガメ" : "リクガメ" }
}

/// よく飼われている種類。わからなければ「その他」。
enum Species: String, CaseIterable, Identifiable {
    case redEared, reeves, japanesePond, yellowPond, musk, otherWater
    case russian, hermann, greek, boxTurtle, sulcata, leopard, indianStar, redFoot, otherLand

    var id: Self { self }

    var label: String {
        switch self {
        case .redEared: "ミシシッピアカミミガメ"
        case .reeves: "クサガメ"
        case .japanesePond: "ニホンイシガメ"
        case .yellowPond: "ミナミイシガメ"
        case .musk: "ニオイガメ・ドロガメ"
        case .otherWater: "その他のミズガメ"
        case .russian: "ロシアリクガメ"
        case .hermann: "ヘルマンリクガメ"
        case .greek: "ギリシャリクガメ"
        case .boxTurtle: "セマルハコガメ"
        case .sulcata: "ケヅメリクガメ"
        case .leopard: "ヒョウモンガメ"
        case .indianStar: "インドホシガメ"
        case .redFoot: "アカアシガメ"
        case .otherLand: "その他のリクガメ"
        }
    }

    var habitat: Habitat {
        switch self {
        case .redEared, .reeves, .japanesePond, .yellowPond, .musk, .otherWater: .water
        default: .land
        }
    }

    /// 暑い地域の種類。冬眠させず、一年じゅう保温する。
    var tropical: Bool {
        switch self {
        case .sulcata, .leopard, .indianStar, .redFoot: true
        default: false
        }
    }

    var canHibernate: Bool { !tropical }

    static func choices(_ habitat: Habitat) -> [Species] { allCases.filter { $0.habitat == habitat } }

    /// 似顔絵の (甲羅, 皮ふ) の色。
    var colors: (shell: UInt32, skin: UInt32) {
        switch self {
        case .redEared: (0x5E7B3A, 0x7C9A4A)
        case .reeves: (0x5B4A36, 0x6E6650)
        case .japanesePond: (0x9A7146, 0x8C7A55)
        case .yellowPond: (0x8B6F43, 0x9C8B5C)
        case .musk: (0x4A4136, 0x6B6355)
        case .otherWater: (0x5F7350, 0x84926A)
        case .russian: (0xB08A4E, 0xA89270)
        case .hermann: (0xC9A04F, 0xB7A27A)
        case .greek: (0xB9924C, 0xAE9A73)
        case .boxTurtle: (0x6B4F33, 0x9C7D4E)
        case .sulcata: (0xC7A76B, 0xC2AE86)
        case .leopard: (0xD3B87A, 0xC9B48A)
        case .indianStar: (0x3F3426, 0xC9A65A)
        case .redFoot: (0x3E3530, 0x5A4C44)
        case .otherLand: (0xB3955E, 0xAA9878)
        }
    }
}

enum Sex: String, CaseIterable, Identifiable {
    case male, female, unknown
    var id: Self { self }
    var label: String {
        switch self {
        case .male: "オス"
        case .female: "メス"
        case .unknown: "不明"
        }
    }
}
