import Foundation
import SwiftData

/// 飼っている1匹。レオパは多頭飼いが普通なので、何匹でも登録できる。
@Model
final class Gecko {
    var uid: UUID = UUID()
    var name: String = ""
    /// モルフ（ハイイエロー、マックスノー、トレンパーアルビノ など）。自由入力。
    var morph: String = ""
    var sexCode: String = GeckoSex.unknown.rawValue
    /// ハッチ（孵化）日。わからなければ nil（成体として扱う）。
    var hatchedOn: Date?
    /// お迎えした日。
    var arrivedOn: Date?
    /// 給餌の間隔（日）。0 なら年齢から決める（`CareRhythm.suggestedFeedInterval`）。
    var feedIntervalOverride: Int = 0
    @Attribute(.externalStorage) var portrait: Data?
    /// 一覧の並び順。
    var position: Int = 0
    var registeredAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \CareEntry.gecko)
    var entries: [CareEntry]? = []

    init(name: String, morph: String = "", sex: GeckoSex = .unknown, hatchedOn: Date? = nil, arrivedOn: Date? = nil, position: Int = 0) {
        self.name = name
        self.morph = morph
        self.sexCode = sex.rawValue
        self.hatchedOn = hatchedOn
        self.arrivedOn = arrivedOn
        self.position = position
    }

    var sex: GeckoSex {
        get { GeckoSex(rawValue: sexCode) ?? .unknown }
        set { sexCode = newValue.rawValue }
    }

    var allEntries: [CareEntry] { entries ?? [] }
}

enum GeckoSex: String, CaseIterable, Identifiable {
    case male, female, unknown
    var id: String { rawValue }

    var label: String {
        switch self {
        case .male: "オス"
        case .female: "メス"
        case .unknown: "不明"
        }
    }

    var mark: String {
        switch self {
        case .male: "♂"
        case .female: "♀"
        case .unknown: "?"
        }
    }
}
