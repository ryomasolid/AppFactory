import Foundation
import SwiftData

/// 採った卵のひとまとまり（産卵床から外した日ごと）。
@Model
final class EggBatch {
    var collectedOn: Date = Date()
    var eggs: Int = 0
    var breed: String = ""
    /// 卵を置いている場所（容器名や「キッチンのタッパー」など）。
    var keptIn: String = ""
    /// 見込みに使う水温。測るたびに上書きできる。
    var celsius: Double = 25
    /// 孵った数。nil ならまだ見守り中。
    var hatched: Int?
    var hatchedOn: Date?
    var note: String = ""

    init(collectedOn: Date, eggs: Int, breed: String, keptIn: String, celsius: Double) {
        self.collectedOn = collectedOn
        self.eggs = eggs
        self.breed = breed
        self.keptIn = keptIn
        self.celsius = celsius
    }

    var isOpen: Bool { hatched == nil }
}

enum StoreModels {
    static let all: [any PersistentModel.Type] = [Vessel.self, PondLog.self, EggBatch.self]
}
