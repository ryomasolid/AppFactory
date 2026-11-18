import SwiftUI

@main
struct KokkiShutoApp: App {
    @State private var progress = Demo.on ? Demo.progress() : Learned()

    var body: some Scene {
        WindowGroup {
            Root()
                .environment(progress)
                .tint(Hue.navy)
        }
    }
}

struct Root: View {
    @State private var tab = Demo.firstTab

    var body: some View {
        TabView(selection: $tab) {
            HomeTab()
                .tabItem { Label("クイズ", systemImage: "questionmark.bubble") }
                .tag(0)
            DexTab()
                .tabItem { Label("ずかん", systemImage: "globe.asia.australia") }
                .tag(1)
        }
    }
}

/// スクショ用の起動引数。-demo（記録の見本・保存しない）、-tab N、-quiz <Mode>（起動してすぐ出題）、-answered（1問目を答えた形）。
enum Demo {
    static let args = ProcessInfo.processInfo.arguments
    static let on = args.contains("-demo")

    static var firstTab: Int {
        guard let i = args.firstIndex(of: "-tab"), i + 1 < args.count else { return 0 }
        return Int(args[i + 1]) ?? 0
    }

    static var quizMode: Mode? {
        guard let i = args.firstIndex(of: "-quiz"), i + 1 < args.count else { return nil }
        return Mode(rawValue: args[i + 1])
    }

    static let answered = args.contains("-answered")

    static func progress() -> Learned {
        let p = Learned(defaults: nil)
        var marks: [String: Mark] = [:]
        var rng = SystemRandomNumberGenerator()
        for (i, c) in Country.all.enumerated() {
            let flagStreak = i % 5 == 4 ? 0 : (i < 120 ? 3 : Int.random(in: 0...2, using: &rng))
            marks[Learned.slot(c.code, .flag)] = Mark(streak: flagStreak, corrects: flagStreak + 1, misses: flagStreak == 0 ? 1 : 0)
            let capStreak = i < 74 ? 3 : (i % 3 == 0 ? 0 : 1)
            marks[Learned.slot(c.code, .capital)] = Mark(streak: capStreak, corrects: capStreak, misses: capStreak == 0 ? 1 : 0)
        }
        p.load(marks)
        return p
    }
}
