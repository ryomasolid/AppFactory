import Foundation
import SwiftData

/// 1回の産卵（クラッチ）。レオパは1回に2個ずつ産むのがふつう。
@Model
final class Clutch {
    var uid: UUID = UUID()
    var laidOn: Date = Date()
    var eggCount: Int = 2
    /// インキュベーターの設定温度。孵化までの日数と性別の傾向がこれで決まる。
    var incubationC: Double = 28
    var hatchedCount: Int = 0
    /// 無精卵・中止などで見守りをやめた。
    var closed: Bool = false
    /// 母親の名前（登録している個体を消しても残るように文字で持つ）。
    var motherName: String = ""
    var note: String = ""

    init(laidOn: Date, eggCount: Int = 2, incubationC: Double = 28, motherName: String = "") {
        self.laidOn = laidOn
        self.eggCount = eggCount
        self.incubationC = incubationC
        self.motherName = motherName
    }

    /// すべて孵化した、または見守りをやめた。
    var isFinished: Bool { closed || hatchedCount >= eggCount }
}

enum StoreSchema {
    static let models: [any PersistentModel.Type] = [Gecko.self, CareEntry.self, Clutch.self]
}
