import SwiftData
import SwiftUI

@main
struct PestMapApp: App {
    var body: some Scene {
        WindowGroup {
            FloorPlanListView()
        }
        .modelContainer(for: [FloorPlan.self, PestMarker.self])
    }
}
