import Foundation

/// 全国の駅（stations-japan.json）。国土数値情報（鉄道データ）から Scripts/export_stations.py で作る。
/// 記事があるのは一部の駅だけ。ほかの駅は地図で探す入口として使い、記事があるようには見せない。
struct JapanStation: Identifiable, Hashable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let lines: [String]

    /// 同じ名前の駅を見分けるための一行（例: 「JR山陰線」）。
    var linesText: String {
        lines.count <= 3 ? lines.joined(separator: "・") : lines.prefix(3).joined(separator: "・") + " ほか"
    }

    /// 「いつもの駅」に保存するときの鍵。並び順の番号はデータを作り直すと変わるので、駅名と路線で持つ。
    /// 記事の駅は駅名だけで保存しているので、「|」の有無で見分けられる。
    var shelfKey: String { "\(name)|\(lines.first ?? "")" }

    func kilometers(to other: JapanStation) -> Double {
        let lat = (latitude + other.latitude) / 2 * .pi / 180
        let dy = (latitude - other.latitude) * 111.0
        let dx = (longitude - other.longitude) * 111.0 * cos(lat)
        return (dx * dx + dy * dy).squareRoot()
    }
}

struct JapanStations {
    /// 記事のある駅で、近いものとして出す範囲。
    static let nearbyArticleKilometers = 30.0

    let source: String
    let all: [JapanStation]
    /// 記事のある駅の id → 記事の駅名。
    let articleByID: [Int: String]
    private let foldedNames: [String]
    private let foldedLines: [String]

    static let shared = JapanStations(library: .shared)

    init(library: Library) {
        guard let url = Bundle.main.url(forResource: "stations-japan", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data)
        else { fatalError("stations-japan.json を読めません。Scripts/export_stations.py を流し直してください") }
        self.init(source: file.source, rows: file.stations, articles: library.stations)
    }

    init(source: String, rows: [Row], articles: [Station]) {
        self.source = source
        all = rows.enumerated().map { index, row in
            JapanStation(id: index, name: row.name, latitude: row.latitude, longitude: row.longitude, lines: row.lines)
        }
        foldedNames = all.map { ContentSearch.fold($0.name) }
        foldedLines = all.map { ContentSearch.fold($0.lines.joined(separator: " ")) }

        // 記事の駅は首都圏だけなので、同じ名前が全国にあっても首都圏の駅に結びつける。
        var map: [Int: String] = [:]
        for article in articles {
            let candidates = all.filter { $0.name == article.name && Self.isKanto($0) }
            if let match = candidates.first { map[match.id] = article.name }
        }
        articleByID = map
    }

    static func isKanto(_ station: JapanStation) -> Bool {
        (34.8...37.3).contains(station.latitude) && (138.3...141.0).contains(station.longitude)
    }

    func station(_ id: Int) -> JapanStation? { all.indices.contains(id) ? all[id] : nil }

    func articleName(for station: JapanStation) -> String? { articleByID[station.id] }

    func station(shelfKey key: String) -> JapanStation? {
        let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        return all.first { $0.name == parts[0] && $0.lines.contains(parts[1]) }
            ?? all.first { $0.name == parts[0] && $0.lines.first == parts[1] }
    }

    /// 「いつもの駅」の鍵から、表示名と開く画面を決める。記事の駅は駅名、ほかは「駅名|路線」。
    func savedStation(_ key: String) -> (name: String, route: Route)? {
        guard key.contains("|") else { return (key, .station(key)) }
        guard let station = station(shelfKey: key) else { return nil }
        return (station.name, .japanStation(station.id))
    }

    /// 駅名で探す。名前が同じ駅 → 名前の頭が合う駅 → 名前に含む駅 → 路線名に含む駅 の順。
    func search(_ query: String, limit: Int = 40) -> (hits: [JapanStation], total: Int) {
        var text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 1, text.hasSuffix("駅") { text.removeLast() }
        let word = ContentSearch.fold(text)
        guard !word.isEmpty else { return ([], 0) }

        var ranked: [(rank: Int, station: JapanStation)] = []
        for (index, station) in all.enumerated() {
            let name = foldedNames[index]
            let rank: Int
            if name == word { rank = 0 }
            else if name.hasPrefix(word) { rank = 1 }
            else if name.contains(word) { rank = 2 }
            else if word.count >= 2, foldedLines[index].contains(word) { rank = 3 }
            else { continue }
            ranked.append((rank, station))
        }
        ranked.sort { ($0.rank, $0.station.name.count, $0.station.id) < ($1.rank, $1.station.name.count, $1.station.id) }
        return (ranked.prefix(limit).map(\.station), ranked.count)
    }

    /// 近くにある記事の駅（近い順・最大3駅）。
    func nearbyArticles(to station: JapanStation) -> [(name: String, kilometers: Double)] {
        articleByID.compactMap { id, name -> (String, Double)? in
            guard id != station.id, let other = self.station(id) else { return nil }
            let distance = station.kilometers(to: other)
            return distance <= Self.nearbyArticleKilometers ? (name, distance) : nil
        }
        .sorted { $0.1 < $1.1 }
        .prefix(3)
        .map { (name: $0.0, kilometers: $0.1) }
    }

    struct File: Decodable {
        let source: String
        let stations: [Row]
    }

    /// ["駅名", 緯度, 経度, ["路線", ...]]
    struct Row: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
        let lines: [String]

        init(name: String, latitude: Double, longitude: Double, lines: [String]) {
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.lines = lines
        }

        init(from decoder: Decoder) throws {
            var row = try decoder.unkeyedContainer()
            name = try row.decode(String.self)
            latitude = try row.decode(Double.self)
            longitude = try row.decode(Double.self)
            lines = try row.decode([String].self)
        }
    }
}
