import SwiftUI

struct StationIndexScreen: View {
    @State private var query = ""
    private let library = Library.shared

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
                ForEach(Array(library.regions.enumerated()), id: \.element) { index, region in
                    let list = stations(in: region)
                    if !list.isEmpty {
                        SectionTitle(text: region).padding(.top, 6)
                        ForEach(list) { StationRow(station: $0) }
                        if index == 0 && query.isEmpty { SponsoredCard(slot: "stations") }
                    }
                }
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("駅から探す")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "駅名・路線・街の特徴")
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

    private func mapURL(_ query: String) -> URL? {
        var parts = URLComponents(string: "https://www.google.com/maps/search/")
        parts?.queryItems = [URLQueryItem(name: "api", value: "1"), URLQueryItem(name: "query", value: query)]
        return parts?.url
    }

    private func content(_ station: Station) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(station.name)駅のがっつり飯").font(.system(size: 26, weight: .black))
                Text(station.hook).font(.subheadline.weight(.bold)).foregroundStyle(.tint)
                Text(station.lead).lineSpacing(6)

                mapSearches(station)

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
                            if let url = mapURL("\(shop.name) \(station.name)") {
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

    private func mapSearches(_ station: Station) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("周辺を条件でマップ検索").font(.subheadline.weight(.black))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(library.mapSearches) { search in
                    if let url = mapURL("\(station.name)駅 \(search.keyword)") {
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
