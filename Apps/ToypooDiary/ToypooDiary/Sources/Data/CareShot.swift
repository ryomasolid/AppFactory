import Foundation
import SwiftData

/// 予防・健康まわりの記録（ワクチン・フィラリアの薬・ノミダニの薬・健康診断）。
@Model
final class CareShot {
    var on: Date = Date()
    var kindCode: String = CareKind.combo.rawValue
    var clinic: String = ""
    var note: String = ""
    var dog: Dog?

    init(kind: CareKind, on: Date, clinic: String = "", dog: Dog) {
        self.kindCode = kind.rawValue
        self.on = on
        self.clinic = clinic
        self.dog = dog
    }

    var kind: CareKind {
        get { CareKind(rawValue: kindCode) ?? .combo }
        set { kindCode = newValue.rawValue }
    }
}

enum CareKind: String, CaseIterable, Identifiable {
    case rabies, combo, heartworm, fleaTick, checkup
    var id: String { rawValue }
    var label: String {
        switch self {
        case .rabies: "狂犬病ワクチン"
        case .combo: "混合ワクチン"
        case .heartworm: "フィラリアの薬"
        case .fleaTick: "ノミ・ダニの薬"
        case .checkup: "健康診断"
        }
    }

    var symbol: String {
        switch self {
        case .rabies: "syringe.fill"
        case .combo: "cross.vial.fill"
        case .heartworm: "heart.fill"
        case .fleaTick: "ladybug.fill"
        case .checkup: "stethoscope"
        }
    }

    /// 毎月飲ませる（つける）もの。
    var isMonthly: Bool { self == .heartworm || self == .fleaTick }
}
