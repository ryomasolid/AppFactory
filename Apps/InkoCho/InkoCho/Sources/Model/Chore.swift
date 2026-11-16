import Foundation
import SwiftData

/// ときどきするおせわ（ケージの大掃除・爪切り・病院など）を「した日」。
@Model
final class Chore {
    var doneOn: Date = Date()
    var kindRaw: String = ChoreKind.cage.rawValue
    var memo: String = ""
    var bird: Bird?

    init(kind: ChoreKind, doneOn: Date, bird: Bird) {
        self.kindRaw = kind.rawValue
        self.doneOn = doneOn
        self.bird = bird
    }

    var kind: ChoreKind {
        get { ChoreKind(rawValue: kindRaw) ?? .cage }
        set { kindRaw = newValue.rawValue }
    }
}

enum ChoreKind: String, CaseIterable, Identifiable {
    case cage, perch, nail, bath, checkup
    var id: Self { self }
    var label: String {
        switch self {
        case .cage: "ケージの大掃除"
        case .perch: "止まり木・おもちゃを洗う"
        case .nail: "爪切り"
        case .bath: "水浴び"
        case .checkup: "健康診断"
        }
    }

    var symbol: String {
        switch self {
        case .cage: "square.grid.3x3.fill"
        case .perch: "line.diagonal"
        case .nail: "scissors"
        case .bath: "drop.fill"
        case .checkup: "stethoscope"
        }
    }

    /// 目安の間隔（日）。
    var everyDays: Int {
        switch self {
        case .cage: 7
        case .perch: 14
        case .nail: 45
        case .bath: 3
        case .checkup: 180
        }
    }
}

enum Schema1 {
    static let all: [any PersistentModel.Type] = [Bird.self, DayLog.self, Word.self, Chore.self]
}
