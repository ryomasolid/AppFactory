import Foundation
import Observation

/// 保存した記事と、いつもの駅。
@MainActor
@Observable
final class Shelf {
    private(set) var stations: [String]
    private(set) var guides: [String]
    private(set) var reports: [String]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        stations = defaults.stringArray(forKey: "shelf.stations") ?? []
        guides = defaults.stringArray(forKey: "shelf.guides") ?? []
        reports = defaults.stringArray(forKey: "shelf.reports") ?? []
    }

    func toggleStation(_ name: String) {
        Self.flip(name, in: &stations)
        defaults.set(stations, forKey: "shelf.stations")
    }

    func toggleGuide(_ slug: String) {
        Self.flip(slug, in: &guides)
        defaults.set(guides, forKey: "shelf.guides")
    }

    func toggleReport(_ slug: String) {
        Self.flip(slug, in: &reports)
        defaults.set(reports, forKey: "shelf.reports")
    }

    private static func flip(_ value: String, in list: inout [String]) {
        if let index = list.firstIndex(of: value) { list.remove(at: index) } else { list.insert(value, at: 0) }
    }
}
