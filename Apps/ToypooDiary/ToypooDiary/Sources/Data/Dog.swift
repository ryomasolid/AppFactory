import Foundation
import SwiftData

/// 家にいる わんちゃん1頭。多頭飼いでも記録はすべて どの子のものかを持つ。
@Model
final class Dog {
    /// 「いま見ている子」を覚えておくための目印（UserDefaults に入れる）。
    var key: UUID = UUID()
    var name: String = ""
    var birthday: Date?
    /// うちに来た日。記念日の表示に使う。
    var homeDay: Date?
    var sexCode: String = DogSex.unknown.rawValue
    var coatCode: String = CoatColor.apricot.rawValue
    @Attribute(.externalStorage) var portrait: Data?
    var order: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \DayPage.dog)
    var pages: [DayPage]? = []
    @Relationship(deleteRule: .cascade, inverse: \Trim.dog)
    var trims: [Trim]? = []
    @Relationship(deleteRule: .cascade, inverse: \CareShot.dog)
    var shots: [CareShot]? = []
    @Relationship(deleteRule: .cascade, inverse: \WeighIn.dog)
    var weighIns: [WeighIn]? = []

    init(name: String, birthday: Date? = nil, homeDay: Date? = nil, sex: DogSex = .unknown, coat: CoatColor = .apricot, order: Int = 0) {
        self.name = name
        self.birthday = birthday
        self.homeDay = homeDay
        self.sexCode = sex.rawValue
        self.coatCode = coat.rawValue
        self.order = order
    }

    var sex: DogSex {
        get { DogSex(rawValue: sexCode) ?? .unknown }
        set { sexCode = newValue.rawValue }
    }

    var coat: CoatColor {
        get { CoatColor(rawValue: coatCode) ?? .apricot }
        set { coatCode = newValue.rawValue }
    }

    /// 新しい日が上。
    var diary: [DayPage] { (pages ?? []).sorted { $0.day > $1.day } }
    var trimHistory: [Trim] { (trims ?? []).sorted { $0.on > $1.on } }
    var weights: [WeighIn] { (weighIns ?? []).sorted { $0.on < $1.on } }

    func page(on day: Date, calendar: Calendar = .current) -> DayPage? {
        (pages ?? []).first { calendar.isDate($0.day, inSameDayAs: day) }
    }

    func shots(of kind: CareKind) -> [CareShot] {
        (shots ?? []).filter { $0.kind == kind }.sorted { $0.on > $1.on }
    }
}

enum DogSex: String, CaseIterable, Identifiable {
    case boy, girl, unknown
    var id: String { rawValue }
    var label: String {
        switch self {
        case .boy: "男の子"
        case .girl: "女の子"
        case .unknown: "ないしょ"
        }
    }
}

/// トイプードルの毛色。似顔絵（PoodleFace）の色にも使う。
enum CoatColor: String, CaseIterable, Identifiable {
    case apricot, red, cream, white, brown, cafeAuLait, silver, black, silverBeige
    var id: String { rawValue }
    var label: String {
        switch self {
        case .apricot: "アプリコット"
        case .red: "レッド"
        case .cream: "クリーム"
        case .white: "ホワイト"
        case .brown: "ブラウン"
        case .cafeAuLait: "カフェオレ"
        case .silver: "シルバー"
        case .black: "ブラック"
        case .silverBeige: "シルバーベージュ"
        }
    }

    /// 毛の色（16進）。
    var hex: UInt32 {
        switch self {
        case .apricot: 0xE7B07A
        case .red: 0xB9603A
        case .cream: 0xF1DDBA
        case .white: 0xF7F3EC
        case .brown: 0x6E4630
        case .cafeAuLait: 0xB89272
        case .silver: 0xA9AAAD
        case .black: 0x2E2A29
        case .silverBeige: 0xD3C6B4
        }
    }
}
