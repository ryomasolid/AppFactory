import SwiftData
import SwiftUI

struct RootTabs: View {
    @Query(sort: \Dog.order) private var dogs: [Dog]
    @State private var tab = Showcase.startTab
    @State private var ads = AdGate()

    var body: some View {
        if dogs.isEmpty {
            WelcomeScreen()
        } else {
            // バナーはタブごとに下へ敷く（TabView ごと包むと iOS 26 のタブバーが隠れる）。
            TabView(selection: $tab) {
                DiaryScreen()
                    .bannerBelow(ads)
                    .tabItem { Label("日記", systemImage: "book.closed") }
                    .tag(0)
                TrimScreen()
                    .bannerBelow(ads)
                    .tabItem { Label("トリミング", systemImage: "scissors") }
                    .tag(1)
                HealthScreen()
                    .bannerBelow(ads)
                    .tabItem { Label("けんこう", systemImage: "heart.text.square") }
                    .tag(2)
                SettingsScreen()
                    .bannerBelow(ads)
                    .tabItem { Label("設定", systemImage: "gearshape") }
                    .tag(3)
            }
            .task { await ads.prepare() }
        }
    }
}

/// いま見ている子。多頭飼いのときは画面上のメニューで切りかえる。
struct CurrentDog {
    static let storageKey = "dog.current"

    static func pick(_ dogs: [Dog], key: String) -> Dog? {
        dogs.first { $0.key.uuidString == key } ?? dogs.first
    }
}
