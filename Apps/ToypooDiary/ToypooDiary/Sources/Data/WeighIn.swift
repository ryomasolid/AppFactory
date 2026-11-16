import Foundation
import SwiftData

/// 体重の記録（kg）。
@Model
final class WeighIn {
    var on: Date = Date()
    var kg: Double = 0
    var dog: Dog?

    init(on: Date, kg: Double, dog: Dog) {
        self.on = on
        self.kg = kg
        self.dog = dog
    }
}

enum Stored {
    static let models: [any PersistentModel.Type] = [Dog.self, DayPage.self, Trim.self, CareShot.self, WeighIn.self]
}
