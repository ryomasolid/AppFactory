import Foundation
import SwiftData

/// ストアのスクショ用の見本。起動引数 `-sample`（`-tab N` で最初のタブ、`-openVessel` で1つ目の容器を開く）。
enum Sample {
    private static var args: [String] { ProcessInfo.processInfo.arguments }
    static var isOn: Bool { args.contains("-sample") }
    static var opensFirstVessel: Bool { isOn && args.contains("-openVessel") }

    static var firstTab: Int {
        guard let i = args.firstIndex(of: "-tab"), i + 1 < args.count else { return 0 }
        return Int(args[i + 1]) ?? 0
    }

    @MainActor
    static func plant(in context: ModelContext, now: Date = Date()) {
        let calendar = Calendar.current
        func ago(_ days: Int, _ hour: Int = 8) -> Date {
            calendar.date(bySettingHour: hour, minute: 10, second: 0, of: calendar.date(byAdding: .day, value: -days, to: now)!)!
        }

        let porch = Vessel(name: "玄関の睡蓮鉢", style: .bowl, outdoors: true, liters: 40, breed: "楊貴妃", stage: .adult, headcount: 12, setUpOn: ago(400), order: 0)
        let balcony = Vessel(name: "ベランダの発泡", style: .styrofoam, outdoors: true, liters: 30, breed: "幹之", stage: .adult, headcount: 9, setUpOn: ago(300), order: 1)
        let nursery = Vessel(name: "針子用プラケ", style: .case_, outdoors: false, liters: 8, breed: "楊貴妃", stage: .fry, headcount: 26, setUpOn: ago(20), order: 2)
        let tank = Vessel(name: "リビング水槽", style: .tank, outdoors: false, liters: 35, breed: "オーロラ", stage: .young, headcount: 15, setUpOn: ago(150), order: 3)
        nursery.hasHeater = true
        [porch, balcony, nursery, tank].forEach(context.insert)

        func log(_ kind: LogKind, _ vessel: Vessel, _ at: Date, _ edit: (PondLog) -> Void = { _ in }) {
            let entry = PondLog(kind: kind, at: at, vessel: vessel)
            edit(entry)
            context.insert(entry)
        }

        log(.waterChange, porch, ago(26)) { $0.percent = 30 }
        log(.temperature, porch, ago(0, 7)) { $0.celsius = 16.5 }
        log(.feed, porch, ago(0, 9))
        log(.eggs, porch, ago(6)) { $0.count = 24 }
        log(.topUp, porch, ago(3))
        log(.memo, porch, ago(2, 17)) { $0.note = "ホテイ草の根に卵がたくさん" }

        log(.waterChange, balcony, ago(5)) { $0.percent = 30; $0.celsius = 17 }
        log(.feed, balcony, ago(1))
        log(.loss, balcony, ago(9)) { $0.count = 1; $0.note = "いちばんの年長さん" }

        log(.waterChange, nursery, ago(3)) { $0.percent = 20 }
        log(.temperature, nursery, ago(0, 7)) { $0.celsius = 24 }
        log(.feed, nursery, ago(0, 8)) { $0.note = "PSB とパウダーフード" }

        log(.waterChange, tank, ago(9)) { $0.percent = 30 }
        log(.temperature, tank, ago(1)) { $0.celsius = 22.5 }
        log(.treatment, tank, ago(12)) { $0.note = "0.5%塩水浴 3日" }

        let fresh = EggBatch(collectedOn: ago(6), eggs: 24, breed: "楊貴妃", keptIn: "玄関の睡蓮鉢", celsius: 24)
        let almost = EggBatch(collectedOn: ago(10), eggs: 18, breed: "幹之", keptIn: "キッチンのタッパー", celsius: 24)
        let done = EggBatch(collectedOn: ago(32), eggs: 30, breed: "楊貴妃", keptIn: "針子用プラケ", celsius: 25)
        done.hatched = 26
        done.hatchedOn = ago(21)
        let older = EggBatch(collectedOn: ago(60), eggs: 20, breed: "オーロラ", keptIn: "リビング水槽", celsius: 23)
        older.hatched = 15
        older.hatchedOn = ago(49)
        [fresh, almost, done, older].forEach(context.insert)

        try? context.save()
    }
}
