import Foundation
import SwiftData

/// スクリーンショット用の見本。起動引数 `-sample`、`-tab N`、`-samplePhotos <フォルダ>`。
enum Sample {
    private static var arguments: [String] { ProcessInfo.processInfo.arguments }
    static var isOn: Bool { arguments.contains("-sample") }

    static var startTab: Int {
        guard let i = arguments.firstIndex(of: "-tab"), i + 1 < arguments.count else { return 0 }
        return Int(arguments[i + 1]) ?? 0
    }

    static func photo(_ name: String) -> Data? {
        guard let i = arguments.firstIndex(of: "-samplePhotos"), i + 1 < arguments.count else { return nil }
        return try? Data(contentsOf: URL(fileURLWithPath: arguments[i + 1]).appending(path: "\(name).jpg"))
    }

    @MainActor
    static func fill(_ context: ModelContext, now: Date = Date()) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        func daysAgo(_ n: Int, hour: Int = 9) -> Date {
            let d = cal.date(byAdding: .day, value: -n, to: today)!
            return cal.date(bySettingHour: hour, minute: 0, second: 0, of: d)!
        }

        let kame = Turtle(name: "かめきち", species: .reeves, sex: .male, hatchedOn: cal.date(byAdding: .year, value: -3, to: today), arrivedOn: cal.date(byAdding: .month, value: -34, to: today)!, order: 0)
        kame.photo = photo("portrait")
        let pon = Turtle(name: "ぽんず", species: .russian, sex: .female, hatchedOn: cal.date(byAdding: .month, value: -20, to: today), arrivedOn: cal.date(byAdding: .month, value: -14, to: today)!, order: 1)
        context.insert(kame)
        context.insert(pon)
        UserDefaults.standard.set(kame.key.uuidString, forKey: Selection.storageKey)

        // 2年ぶんの成長（月に1回）。冬は伸びない。
        var shell = 62.0
        var grams = 48.0
        for m in stride(from: 24, through: 0, by: -1) {
            let on = cal.date(byAdding: .month, value: -m, to: today)!
            let month = cal.component(.month, from: on)
            let winter = [12, 1, 2].contains(month)
            shell += winter ? 0 : 2.6
            grams += winter ? -1.5 : 9.5
            context.insert(Measure(on: on, shellMM: (shell * 10).rounded() / 10, grams: grams.rounded(), turtle: kame))
        }

        for n in 0..<10 {
            if n % 2 == 0, n > 0 {
                let c = Care(kind: .feed, at: daysAgo(n, hour: 18), turtle: kame)
                c.food = n % 4 == 1 ? .pellet : .prey
                c.appetite = .all
                context.insert(c)
            }
        }
        for n in [1, 4, 7] { context.insert(Care(kind: .water, at: daysAgo(n, hour: 8), turtle: kame)) }
        for n in [0, 3, 6] { context.insert(Care(kind: .sun, at: daysAgo(n, hour: 11), turtle: kame)) }
        context.insert(Reading(at: daysAgo(0, hour: 8), baseC: 25.5, spotC: 32, turtle: kame))
        let check = Checkup(on: daysAgo(2, hour: 20), turtle: kame)
        check.memo = "甲羅干しのあと、ずっと首をのばしていた。"
        check.photo = photo("check")
        context.insert(check)

        // ぽんず（リクガメ）
        var pShell = 70.0
        var pGrams = 120.0
        for m in stride(from: 12, through: 0, by: -1) {
            let on = cal.date(byAdding: .month, value: -m, to: today)!
            pShell += 1.4
            pGrams += 6
            context.insert(Measure(on: on, shellMM: pShell, grams: pGrams, turtle: pon))
        }
        for n in 0..<6 {
            let c = Care(kind: .feed, at: daysAgo(n, hour: 10), turtle: pon)
            c.food = .greens
            c.appetite = n == 0 ? .some : .all
            context.insert(c)
        }
        context.insert(Care(kind: .soak, at: daysAgo(2), turtle: pon))
        context.insert(Care(kind: .bedding, at: daysAgo(12), turtle: pon))

        let gears: [(GearKind, String, String, Int)] = [
            (.uvb, "UVB 蛍光灯 10.0", "90cm 水槽", 171),
            (.basking, "バスキングライト 75W", "90cm 水槽", 60),
            (.waterHeater, "オートヒーター 200W", "90cm 水槽", 210),
            (.filterMedia, "外部フィルターのろ材", "90cm 水槽", 18),
            (.metalHalide, "メタハラ 35W", "リクガメのケージ", 120),
        ]
        for (kind, name, place, ago) in gears {
            context.insert(Gear(kind: kind, name: name, place: place, installedOn: daysAgo(ago)))
        }
    }
}
