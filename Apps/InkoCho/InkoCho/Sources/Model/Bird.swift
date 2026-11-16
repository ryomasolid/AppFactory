import Foundation
import SwiftData

/// 1羽ぶんのプロフィール。きょうの記録・言葉・おせわは、すべてどの子のものかを持つ。
@Model
final class Bird {
    var tag: UUID = UUID()
    var name: String = ""
    /// 生まれた日（わかれば）。ヒナの保温の目安と年齢に使う。
    var hatchedOn: Date?
    var cameHomeOn: Date?
    var sexRaw: String = BirdSex.unknown.rawValue
    var plumageRaw: String = Plumage.blue.rawValue
    @Attribute(.externalStorage) var picture: Data?
    var sortIndex: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \DayLog.bird) var logs: [DayLog]? = []
    @Relationship(deleteRule: .cascade, inverse: \Word.bird) var words: [Word]? = []
    @Relationship(deleteRule: .cascade, inverse: \Chore.bird) var chores: [Chore]? = []

    init(name: String, sex: BirdSex = .unknown, plumage: Plumage = .blue, hatchedOn: Date? = nil, cameHomeOn: Date? = nil, sortIndex: Int = 0) {
        self.name = name
        self.sexRaw = sex.rawValue
        self.plumageRaw = plumage.rawValue
        self.hatchedOn = hatchedOn
        self.cameHomeOn = cameHomeOn
        self.sortIndex = sortIndex
    }

    var sex: BirdSex {
        get { BirdSex(rawValue: sexRaw) ?? .unknown }
        set { sexRaw = newValue.rawValue }
    }

    var plumage: Plumage {
        get { Plumage(rawValue: plumageRaw) ?? .blue }
        set { plumageRaw = newValue.rawValue }
    }

    /// 古い日 → 新しい日。
    var timeline: [DayLog] { (logs ?? []).sorted { $0.day < $1.day } }

    func log(on date: Date, calendar: Calendar = .current) -> DayLog? {
        (logs ?? []).first { calendar.isDate($0.day, inSameDayAs: date) }
    }

    var vocabulary: [Word] { (words ?? []).sorted { $0.heardOn > $1.heardOn } }
}

enum BirdSex: String, CaseIterable, Identifiable {
    case male, female, unknown
    var id: Self { self }
    var label: String {
        switch self {
        case .male: "オス"
        case .female: "メス"
        case .unknown: "わからない"
        }
    }
}

/// 羽の色（よく見る品種）。似顔絵の色に使う。
enum Plumage: String, CaseIterable, Identifiable {
    case blue, green, lutino, albino, yellowface, violet, pied, rainbow
    var id: Self { self }
    var label: String {
        switch self {
        case .blue: "ブルー"
        case .green: "グリーン"
        case .lutino: "ルチノー"
        case .albino: "アルビノ"
        case .yellowface: "イエローフェイス"
        case .violet: "バイオレット"
        case .pied: "パイド"
        case .rainbow: "レインボー"
        }
    }

    /// (体の色, 顔の色)
    var colors: (body: UInt32, face: UInt32) {
        switch self {
        case .blue: (0x5DA9E9, 0xFFFFFF)
        case .green: (0x6CC24A, 0xF7E04B)
        case .lutino: (0xF7E04B, 0xFFF4B0)
        case .albino: (0xF5F5F2, 0xFFFFFF)
        case .yellowface: (0x62B6C9, 0xF4E07A)
        case .violet: (0x8C7BD8, 0xFFFFFF)
        case .pied: (0x8FD16A, 0xF7E04B)
        case .rainbow: (0x7FC8C4, 0xF6DB6A)
        }
    }
}
