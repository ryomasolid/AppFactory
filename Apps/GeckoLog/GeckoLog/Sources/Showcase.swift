import Foundation
import SwiftData

/// ストアのスクショ用の見本データ。起動引数 `-showcase` で入る（`-tab 1` で最初のタブも選べる）。
enum Showcase {
    static var isOn: Bool { ProcessInfo.processInfo.arguments.contains("-showcase") }

    static var startTab: Int {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-tab"), args.indices.contains(index + 1) else { return 0 }
        return Int(args[index + 1]) ?? 0
    }

    /// 起動直後に1匹目の詳細を開く（詳細画面のスクショ用）。
    static var opensFirstGecko: Bool { isOn && ProcessInfo.processInfo.arguments.contains("-openGecko") }

    @MainActor
    static func fill(_ context: ModelContext, now: Date = Date()) {
        let calendar = Calendar.current
        func daysAgo(_ days: Int, hour: Int = 20) -> Date {
            let day = calendar.date(byAdding: .day, value: -days, to: now)!
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        }

        let mochi = Gecko(name: "もち", morph: "マックスノー", sex: .female, hatchedOn: daysAgo(700), arrivedOn: daysAgo(620), position: 0)
        let kinako = Gecko(name: "きなこ", morph: "ハイイエロー", sex: .male, hatchedOn: daysAgo(240), arrivedOn: daysAgo(180), position: 1)
        let sora = Gecko(name: "そら", morph: "トレンパーアルビノ", sex: .unknown, hatchedOn: daysAgo(75), arrivedOn: daysAgo(30), position: 2)
        [mochi, kinako, sora].forEach(context.insert)

        func add(_ kind: CareKind, _ gecko: Gecko, _ at: Date, _ fill: (CareEntry) -> Void = { _ in }) {
            let entry = CareEntry(kind: kind, occurredAt: at, gecko: gecko)
            fill(entry)
            context.insert(entry)
        }

        // もち: アダルト。4日おき。最近2回食べていない（拒食の見守り）。
        for (index, day) in [36, 32, 28, 24, 20, 16, 12].enumerated() {
            add(.feeding, mochi, daysAgo(day)) { $0.feederCode = Feeder.dubia.rawValue; $0.feederCount = 4; $0.dusted = index.isMultiple(of: 2) }
        }
        add(.feeding, mochi, daysAgo(8)) { $0.accepted = false }
        add(.feeding, mochi, daysAgo(4)) { $0.accepted = false }
        for (day, grams) in [(90, 62.0), (60, 63.5), (30, 63.0), (3, 60.5)] {
            add(.weight, mochi, daysAgo(day)) { $0.grams = grams }
        }
        for day in [80, 46, 12] { add(.shed, mochi, daysAgo(day)) }
        add(.climate, mochi, daysAgo(1)) { $0.warmSideC = 31.5; $0.humidityPercent = 55 }

        // きなこ: ヤング。よく食べて順調に増えている。今日がごはんの日。
        for day in stride(from: 29, through: 1, by: -2) {
            add(.feeding, kinako, daysAgo(day)) { $0.feederCode = Feeder.cricket.rawValue; $0.feederCount = 6; $0.dusted = true }
        }
        for (day, grams) in [(120, 22.0), (90, 28.5), (60, 33.0), (30, 38.5), (2, 43.0)] {
            add(.weight, kinako, daysAgo(day)) { $0.grams = grams }
        }
        for day in [61, 40, 20] { add(.shed, kinako, daysAgo(day)) }
        add(.dropping, kinako, daysAgo(1)) { $0.droppingCode = Dropping.normal.rawValue }

        // そら: ベビー。毎日。脱皮がもうすぐ。
        for day in stride(from: 20, through: 1, by: -1) {
            add(.feeding, sora, daysAgo(day)) { $0.feederCode = Feeder.cricket.rawValue; $0.feederCount = 3 }
        }
        for (day, grams) in [(28, 6.5), (14, 8.0), (1, 10.5)] {
            add(.weight, sora, daysAgo(day)) { $0.grams = grams }
        }
        for day in [19, 9] { add(.shed, sora, daysAgo(day)) { $0.skinLeftover = day == 19 } }
        add(.memo, sora, daysAgo(0, hour: 9)) { $0.note = "シェルターから顔を出してこっちを見てた" }

        let clutch = Clutch(laidOn: daysAgo(38), eggCount: 2, incubationC: 28, motherName: "もち")
        context.insert(clutch)
        let older = Clutch(laidOn: daysAgo(80), eggCount: 2, incubationC: 31, motherName: "もち")
        older.hatchedCount = 2
        context.insert(older)

        try? context.save()
    }
}
