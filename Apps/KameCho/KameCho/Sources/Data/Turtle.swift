import Foundation
import SwiftData

/// 1匹のカメ。記録はすべて、どのカメのものかを持つ。
@Model
final class Turtle {
    var key: UUID = UUID()
    var name: String = ""
    var speciesRaw: String = Species.redEared.rawValue
    var sexRaw: String = Sex.unknown.rawValue
    /// 生まれた日（ふ化日）。わからなければ nil。
    var hatchedOn: Date?
    var arrivedOn: Date = Date()
    @Attribute(.externalStorage) var photo: Data?
    var order: Int = 0
    /// 世話の間隔（日）の上書き。nil は種類と年齢から決まる目安。
    var feedEvery: Int?
    var tidyEvery: Int?
    var soakEvery: Int?

    @Relationship(deleteRule: .cascade, inverse: \Measure.turtle) var measures: [Measure]? = []
    @Relationship(deleteRule: .cascade, inverse: \Care.turtle) var cares: [Care]? = []
    @Relationship(deleteRule: .cascade, inverse: \Checkup.turtle) var checkups: [Checkup]? = []
    @Relationship(deleteRule: .cascade, inverse: \Reading.turtle) var readings: [Reading]? = []
    @Relationship(deleteRule: .cascade, inverse: \Rest.turtle) var rests: [Rest]? = []

    init(name: String, species: Species, sex: Sex = .unknown, hatchedOn: Date? = nil, arrivedOn: Date = Date(), order: Int = 0) {
        self.name = name
        self.speciesRaw = species.rawValue
        self.sexRaw = sex.rawValue
        self.hatchedOn = hatchedOn
        self.arrivedOn = arrivedOn
        self.order = order
    }

    var species: Species {
        get { Species(rawValue: speciesRaw) ?? .otherWater }
        set { speciesRaw = newValue.rawValue }
    }

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .unknown }
        set { sexRaw = newValue.rawValue }
    }

    /// 計測は古い順。
    var growth: [Measure] { (measures ?? []).sorted { $0.on < $1.on } }

    /// 世話の記録は新しい順。
    var careLog: [Care] { (cares ?? []).sorted { $0.at > $1.at } }

    var latestReading: Reading? { (readings ?? []).max { $0.at < $1.at } }

    /// いま冬眠中なら、その記録。
    var currentRest: Rest? { (rests ?? []).first { $0.endedOn == nil } }

    /// 年齢の目安に使う日（ふ化日がなければ、うちに来た日）。
    var ageBase: Date { hatchedOn ?? arrivedOn }
}
