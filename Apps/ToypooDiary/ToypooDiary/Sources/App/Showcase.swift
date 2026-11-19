import Foundation
import SwiftData

/// ストアのスクショ用の見本。起動引数 `-sample`（`-tab N` で最初のタブ・`-openToday` で今日のページ）。
enum Showcase {
    private static var args: [String] { ProcessInfo.processInfo.arguments }
    static var isOn: Bool { args.contains("-sample") }
    static var opensToday: Bool { isOn && args.contains("-openToday") }

    /// スクショ用の本物の写真のフォルダ（`-demoPhotos <絶対パス>`）。無ければ写真なしの見本になる。
    static func photo(_ name: String) -> Data? {
        guard let i = args.firstIndex(of: "-demoPhotos"), args.indices.contains(i + 1) else { return nil }
        return try? Data(contentsOf: URL(fileURLWithPath: args[i + 1]).appendingPathComponent("\(name).jpg"))
    }

    static var startTab: Int {
        guard let i = args.firstIndex(of: "-tab"), args.indices.contains(i + 1) else { return 0 }
        return Int(args[i + 1]) ?? 0
    }

    @MainActor
    static func fill(_ context: ModelContext, now: Date = Date()) {
        let calendar = Calendar.current
        func daysAgo(_ n: Int) -> Date { calendar.date(byAdding: .day, value: -n, to: calendar.startOfDay(for: now))! }

        // 主役は写真の子（レッド）。2頭目は多頭飼いの切りかえを見せるための子。
        let star = Dog(name: "そら", birthday: calendar.date(byAdding: .month, value: -40, to: now), homeDay: calendar.date(byAdding: .month, value: -37, to: now), sex: .girl, coat: .red, order: 0)
        let buddy = Dog(name: "むぎ", birthday: calendar.date(byAdding: .month, value: -14, to: now), homeDay: calendar.date(byAdding: .month, value: -12, to: now), sex: .boy, coat: .apricot, order: 1)
        star.portrait = photo("portrait")
        context.insert(star)
        context.insert(buddy)
        UserDefaults.standard.set(star.key.uuidString, forKey: CurrentDog.storageKey)

        let notes = [
            "クリスマスの服を試着。まんざらでもない顔で家じゅうをパトロール。",
            "お気に入りのトゲトゲボールを抱えてごろん。そのまま寝そう。",
            "ごはんを一気に完食。おかわりの目でじっと見てくる。",
            "ベッドでまったり。呼んでも目だけこっちを見る。",
            "公園でボールを3回も持ってきた！帰りはだっこで帰宅。",
            "トリミング帰りでふわふわ。においをかがれまくっていた。",
            "ドッグカフェデビュー。お店の人にほめられてドヤ顔。",
            "",
            "ひなたぼっこしながら寝落ち。",
        ]
        let moods: [Mood] = [.happy, .calm, .hyper, .calm, .hyper, .happy, .sleepy, .happy]
        let shots = ["today", "day1", "day2", "day3"]
        for n in 0..<24 {
            let page = DayPage(day: daysAgo(n), dog: star)
            page.mood = moods[n % moods.count]
            page.walkCount = n % 6 == 1 ? 1 : 2
            page.walkMinutes = n % 6 == 1 ? 15 : 30 + (n % 3) * 10
            page.meals = 2
            page.brushed = n % 3 != 2
            page.poop = n == 3 ? .soft : .good
            page.tear = n % 4 == 0 ? .little : .clear
            page.note = notes[n % notes.count]
            if n < shots.count { page.photo = photo(shots[n]) }
            context.insert(page)
        }

        let styles = [("テディベアカット", 0), ("テディベアカット", 33), ("サマーカット", 61), ("アフロカット", 92), ("テディベアカット", 120)]
        // ギャラリーは新しい順に trim0, trim1, … の写真。
        let partial = Trim(on: daysAgo(18), menu: .partial, style: "顔まわり・足先", salon: "トリミングサロン ふわり", price: 1650, dog: star)
        partial.photo = photo("trim1")
        context.insert(partial)
        for (i, (style, ago)) in styles.enumerated() {
            let trim = Trim(on: daysAgo(ago + 4), menu: .full, style: style, salon: "トリミングサロン ふわり", price: 7700, dog: star)
            trim.photo = photo("trim\(i == 0 ? 0 : i + 1)")
            context.insert(trim)
        }

        let kg = [3.42, 3.40, 3.45, 3.38, 3.36, 3.41, 3.44]
        for (i, value) in kg.enumerated() {
            context.insert(WeighIn(on: daysAgo((kg.count - 1 - i) * 14), kg: value, dog: star))
        }

        context.insert(CareShot(kind: .rabies, on: daysAgo(190), clinic: "あおば動物病院", dog: star))
        context.insert(CareShot(kind: .combo, on: daysAgo(300), clinic: "あおば動物病院", dog: star))
        context.insert(CareShot(kind: .heartworm, on: daysAgo(27), dog: star))
        context.insert(CareShot(kind: .fleaTick, on: daysAgo(29), dog: star))
        context.insert(CareShot(kind: .checkup, on: daysAgo(200), clinic: "あおば動物病院", dog: star))

        let page = DayPage(day: daysAgo(0), dog: buddy)
        page.mood = .hyper
        page.walkCount = 2
        page.walkMinutes = 40
        context.insert(page)
        context.insert(WeighIn(on: daysAgo(3), kg: 2.8, dog: buddy))
    }
}
