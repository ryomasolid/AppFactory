import UIKit

/// アプリに同梱した記事とデータ（content.json）。通信なしで全部読める。
struct Library: Decodable {
    let categories: [GuideCategory]
    let columns: [Guide]
    let reports: [Report]
    let regions: [String]
    let stations: [Station]
    let mapSearches: [MapSearch]
    let quantityBlocks: [Block]
    let chains: [Chain]
    let daily: NutritionFacts
    let nutritionCheckedAt: String
    let buffets: [Buffet]
    let queueGenres: [QueueGenre]
    let seatPresets: [SeatPreset]

    static let shared: Library = {
        guard let url = Bundle.main.url(forResource: "content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let library = try? JSONDecoder().decode(Library.self, from: data)
        else { fatalError("content.json を読めません。Scripts/export_content.mjs を流し直してください") }
        return library
    }()

    func guide(_ slug: String) -> Guide? { columns.first { $0.slug == slug } }
    func report(_ slug: String) -> Report? { reports.first { $0.slug == slug } }
    func station(_ name: String) -> Station? { stations.first { $0.name == name } }

    /// 日付ごとに変わる「きょうの1本」。同じ日なら何度開いても同じ記事。
    func guideOfTheDay(_ date: Date = .now, calendar: Calendar = .current) -> Guide {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return columns[day % columns.count]
    }
}

enum Photos {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(_ name: String) -> UIImage? {
        if let hit = cache.object(forKey: name as NSString) { return hit }
        guard let path = Bundle.main.path(forResource: name, ofType: "jpg"),
              let image = UIImage(contentsOfFile: path) else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}

enum DateText {
    /// "2026-10-31" → "2026年10月31日"
    static func japanese(_ iso: String) -> String {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return iso }
        return "\(parts[0])年\(parts[1])月\(parts[2])日"
    }
}
