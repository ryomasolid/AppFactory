import SwiftData
import SwiftUI

@main
struct ToypooDiaryApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer

    init() {
        // スクショ用の見本は端末の日記にさわらないよう、メモリの中だけで動かす。
        let config = ModelConfiguration(isStoredInMemoryOnly: Showcase.isOn)
        do {
            container = try ModelContainer(for: Schema(Stored.models), configurations: [config])
        } catch {
            fatalError("日記の保存場所を開けませんでした: \(error)")
        }
        if Showcase.isOn { Showcase.fill(container.mainContext) }
    }

    var body: some Scene {
        WindowGroup {
            RootTabs()
                .tint(Tone.cocoa)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            // 開いたとき（日付が変わる）と閉じたとき（日記を書いた）に、お知らせを組みなおす。
            guard phase != .inactive else { return }
            let context = container.mainContext
            Task { await Reminders.rebuild(context) }
        }
    }
}
