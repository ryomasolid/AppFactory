import Foundation
import SwiftData

/// スクショ用の見本。起動引数 `-demo`（`-tab N` で最初のタブ・`-demoPhotos <フォルダ>` で写真）。
enum Demo {
    private static var args: [String] { ProcessInfo.processInfo.arguments }
    static var on: Bool { args.contains("-demo") }

    static var firstTab: Int {
        guard let i = args.firstIndex(of: "-tab"), args.indices.contains(i + 1) else { return 0 }
        return Int(args[i + 1]) ?? 0
    }

    static func photo(_ name: String) -> Data? {
        guard let i = args.firstIndex(of: "-demoPhotos"), args.indices.contains(i + 1) else { return nil }
        return try? Data(contentsOf: URL(fileURLWithPath: args[i + 1]).appendingPathComponent("\(name).jpg"))
    }

    @MainActor
    static func seed(_ context: ModelContext, now: Date = Date()) {
        let cal = Calendar.current
        func ago(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: cal.startOfDay(for: now))! }

        let sora = Bird(name: "ソラ", sex: .male, plumage: .blue, hatchedOn: cal.date(byAdding: .month, value: -26, to: now), cameHomeOn: cal.date(byAdding: .month, value: -24, to: now), sortIndex: 0)
        let kiwi = Bird(name: "キウイ", sex: .female, plumage: .green, hatchedOn: cal.date(byAdding: .month, value: -9, to: now), cameHomeOn: cal.date(byAdding: .month, value: -7, to: now), sortIndex: 1)
        sora.picture = photo("portrait")
        context.insert(sora)
        context.insert(kiwi)
        UserDefaults.standard.set(sora.tag.uuidString, forKey: Picked.key)

        let grams: [Double] = [35.2, 35.0, 35.4, 35.1, 34.9, 35.3, 35.2, 35.0, 34.8, 35.1, 35.3, 35.2, 35.0, 35.4, 35.1, 34.9, 35.2, 35.3, 35.0, 34.6, 34.7, 34.8, 34.9, 35.0, 35.1, 35.2, 34.9, 35.0]
        let looks: [Look] = [.chatty, .lively, .chatty, .calm, .lively, .sleepy, .chatty]
        let memos = ["「ソラくんかわいい」を3回も言った！", "放鳥中ずっと肩の上。", "新しいブランコを警戒中。", "水浴びで大はしゃぎ。", "", "朝からごきげんに歌っている。", "おやつの粟穂をあげた。"]
        let shots = ["today", "day1", "day2", "day3"]
        for (i, g) in grams.enumerated() {
            let n = grams.count - 1 - i
            let log = DayLog(day: ago(n), bird: sora)
            log.grams = g
            log.outsideMinutes = [40, 60, 30, 45, 0, 50, 35][n % 7]
            log.dropping = .normal
            log.look = looks[n % looks.count]
            log.roomCelsius = [24.5, 23.8, 25.0, 24.2][n % 4]
            log.molting = n <= 4 || (40...46).contains(n)
            log.memo = memos[n % memos.count]
            if n < shots.count { log.picture = photo(shots[n]) }
            context.insert(log)
        }
        for (text, days) in [("ソラくんかわいい", 3), ("おはよう", 40), ("ピッピッ（電子レンジ）", 75), ("ただいま", 120), ("いいこ", 160), ("おいで", 200), ("ちゅっ", 230)] {
            context.insert(Word(text: text, heardOn: ago(days), bird: sora))
        }
        for (kind, days) in [(ChoreKind.cage, 5), (.perch, 15), (.nail, 30), (.bath, 1), (.checkup, 150)] {
            context.insert(Chore(kind: kind, doneOn: ago(days), bird: sora))
        }

        for n in 0..<5 {
            let log = DayLog(day: ago(n), bird: kiwi)
            log.grams = [31.2, 31.0, 30.8, 31.1, 30.9][n]
            log.look = .lively
            context.insert(log)
        }
        context.insert(Word(text: "ピーちゃん", heardOn: ago(10), bird: kiwi))
    }
}
