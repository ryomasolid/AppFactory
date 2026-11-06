import SwiftUI

struct StationIndexScreen: View {
    @State private var query = ""
    private let library = Library.shared
    private let japan = JapanStations.shared

    private func stations(in region: String) -> [Station] {
        let all = library.stations.filter { $0.region == region }
        let words = ContentSearch.fold(query).split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return all }
        return all.filter { station in
            let text = ContentSearch.fold(station.name + station.hook + station.lines.joined())
            return words.allSatisfy(text.contains)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if query.isEmpty {
                    Text("記事があるのは下の\(library.stations.count)駅です。ほかの駅も、上の検索から全国\(japan.all.count.formatted())駅を探して、周りの店を地図で探せます。")
                        .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(Array(library.regions.enumerated()), id: \.element) { index, region in
                    let list = stations(in: region)
                    if !list.isEmpty {
                        SectionTitle(text: region).padding(.top, 6)
                        ForEach(list) { StationRow(station: $0) }
                        if index == 0 && query.isEmpty { SponsoredCard(slot: "stations") }
                    }
                }
                if !query.isEmpty { nationwide }
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("駅から探す")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "全国の駅名・路線")
    }

    /// 記事のない駅。記事の駅は上に出ているので省く。
    @ViewBuilder private var nationwide: some View {
        let result = japan.search(query)
        let others = result.hits.filter { japan.articleName(for: $0) == nil }
        if !others.isEmpty {
            SectionTitle(text: "全国の駅（記事はまだありません）").padding(.top, 6)
            ForEach(others) { station in
                NavigationLink(value: Route.japanStation(station.id)) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(station.name)駅").font(.subheadline.weight(.heavy))
                            Text(station.linesText).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "map").foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .sticker()
                }
                .buttonStyle(.plain)
            }
            if result.total > result.hits.count {
                Text("ほかにも\(result.total - result.hits.count)駅あります。駅名をもう少し入れると絞り込めます。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        } else if result.hits.isEmpty, library.regions.allSatisfy({ stations(in: $0).isEmpty }) {
            ContentUnavailableView.search(text: query)
        }
    }
}

/// 記事のない駅。お店の情報は持っていないので、地図で探す入口と、近くの記事の駅だけを出す。
struct JapanStationScreen: View {
    let id: Int
    private let japan = JapanStations.shared

    var body: some View {
        if let station = japan.station(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("\(station.name)駅").font(.system(size: 26, weight: .black))
                    Text(station.lines.joined(separator: "、")).font(.footnote).foregroundStyle(.secondary)
                    Text("この駅の記事はまだありません。下のボタンで、駅のまわりの大盛り・デカ盛りの店を Google マップで探せます。")
                        .font(.subheadline).lineSpacing(5)
                    MapSearchPanel(stationName: station.name, coordinate: (station.latitude, station.longitude))
                    let nearby = japan.nearbyArticles(to: station)
                    if !nearby.isEmpty {
                        SectionTitle(text: "近くの記事がある駅")
                        ForEach(nearby, id: \.name) { item in
                            NavigationLink(value: Route.station(item.name)) {
                                HStack {
                                    Text("\(item.name)駅").font(.subheadline.weight(.heavy))
                                    Spacer()
                                    Text("約\(Int(item.kilometers.rounded()))km").font(.caption).foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .sticker()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("駅の名前と位置: \(japan.source)（CC BY 4.0）をもとに作成")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .paperBackground()
            .navigationTitle("\(station.name)駅")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("この駅は見つかりません", systemImage: "tram")
        }
    }
}

struct StationScreen: View {
    let name: String
    @Environment(Shelf.self) private var shelf
    private let library = Library.shared

    var body: some View {
        if let station = library.station(name) {
            content(station)
        } else {
            ContentUnavailableView("この駅は見つかりません", systemImage: "tram")
        }
    }

    private func content(_ station: Station) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(station.name)駅のがっつり飯").font(.system(size: 26, weight: .black))
                Text(station.hook).font(.subheadline.weight(.bold)).foregroundStyle(.tint)
                Text(station.lead).lineSpacing(6)

                MapSearchPanel(stationName: station.name)

                if !station.reportSlugs.isEmpty {
                    SectionTitle(text: "\(station.name)駅で実際に食べた店")
                    ForEach(station.reportSlugs.compactMap(library.report)) { ReportCard(report: $0) }
                }

                if !station.shops.isEmpty {
                    SectionTitle(text: "知っておきたい店")
                    Text("運営者は未訪問で、公式情報や広く知られた事実をもとに紹介しています。行く前に営業状況を確認してください。")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(station.shops, id: \.name) { shop in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(shop.name).font(.subheadline.weight(.heavy))
                            Text(shop.note).font(.footnote).lineSpacing(3)
                            if let url = MapLink.search("\(shop.name) \(station.name)") {
                                Link(destination: url) { Label("マップで場所と営業状況を見る", systemImage: "map").font(.caption.weight(.bold)) }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .sticker()
                    }
                }

                SponsoredCard(slot: "station:\(station.name)", path: "/station")

                ForEach(station.sections, id: \.heading) { section in
                    SectionTitle(text: section.heading)
                    Text(section.body).lineSpacing(6)
                }

                SectionTitle(text: "お店で迷わないためのガイド")
                ForEach(station.guideSlugs.compactMap(library.guide)) { GuideRow(guide: $0) }

                SectionTitle(text: "路線と近くの駅")
                Text(station.lines.joined(separator: "、")).font(.footnote).foregroundStyle(.secondary)
                FlowChips(items: station.nearby)
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("\(station.name)駅")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let saved = shelf.stations.contains(station.name)
                Button { shelf.toggleStation(station.name) } label: {
                    Image(systemName: saved ? "star.fill" : "star")
                }
                .accessibilityLabel(saved ? "いつもの駅から外す" : "いつもの駅にする")
            }
        }
    }

}

/// 駅のまわりを条件で Google マップ検索するボタン。
struct MapSearchPanel: View {
    let stationName: String
    /// 同じ名前の駅が全国にあるとき、検索がその駅のまわりになるように位置も渡す。
    var coordinate: (latitude: Double, longitude: Double)?
    private let library = Library.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("周辺を条件でマップ検索").font(.subheadline.weight(.black))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(library.mapSearches) { search in
                    if let url = MapLink.search("\(stationName)駅 \(search.keyword)", near: coordinate) {
                        Link(destination: url) {
                            Text(search.label).font(.caption.weight(.heavy)).foregroundStyle(Color.primary).lineLimit(1).minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                .background(Color.card, in: .capsule)
                                .overlay { Capsule().stroke(Color.ink, lineWidth: 1.5) }
                        }
                    }
                }
            }
            Text("お店のデータは持っていません。Googleマップの検索結果が開きます。").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.softOrange, in: .rect(cornerRadius: 12))
    }
}

enum MapLink {
    /// Google マップの検索。位置があれば、そのまわりを優先して探す。
    static func search(_ query: String, near coordinate: (latitude: Double, longitude: Double)? = nil) -> URL? {
        if let coordinate {
            // 同じ名前の駅が全国にあるので、地図の中心をその駅にした検索にする。
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) ?? query
            return URL(string: "https://www.google.com/maps/search/\(encoded)/@\(coordinate.latitude),\(coordinate.longitude),15z")
        }
        var parts = URLComponents(string: "https://www.google.com/maps/search/")
        parts?.queryItems = [URLQueryItem(name: "api", value: "1"), URLQueryItem(name: "query", value: query)]
        return parts?.url
    }
}

/// 近くの駅のリンク。
private struct FlowChips: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { name in
                NavigationLink(value: Route.station(name)) {
                    Text(name).font(.footnote.weight(.heavy)).lineLimit(1).minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(Color.card, in: .capsule)
                        .overlay { Capsule().stroke(Color.ink, lineWidth: 1.5) }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
