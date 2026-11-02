import SwiftUI

struct HomeScreen: View {
    @Environment(BiteLog.self) private var log
    @Environment(Shelf.self) private var shelf
    @Environment(Navigator.self) private var navigator
    private let library = Library.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                todayCard
                myStations
                reports
                SponsoredCard(slot: "home-top", path: "/")
                guideOfTheDay
                tools
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("ガツガツグルメ")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(value: Route.search) { Image(systemName: "magnifyingglass").accessibilityLabel("検索") }
                NavigationLink(value: Route.settings) { Image(systemName: "gearshape").accessibilityLabel("設定") }
            }
        }
    }

    private var todayCard: some View {
        let today = log.stats.summary(of: log.stats.onDay(.now))
        return Button { navigator.tab = .log } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("きょうのガツログ").font(.subheadline.weight(.black))
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.bold))
                }
                HStack(alignment: .firstTextBaseline) {
                    BigNumber(value: today.kcal.whole, unit: "kcal", size: 44)
                    Spacer()
                    Text("茶碗 \(today.riceBowls.oneDecimal)杯ぶん").font(.subheadline.weight(.bold))
                }
                ProgressView(value: min(today.kcal / library.daily.calories, 1)).tint(Color.ink)
                Text(today.count == 0 ? "何を食べたか記録すると、ここに積み上がります" : "\(today.count)品を記録・1日の目安 \(library.daily.calories.whole)kcal")
                    .font(.caption)
            }
            .padding(14)
            .foregroundStyle(Color(red: 0.11, green: 0.1, blue: 0.09))
            .sticker(fill: .mustard)
        }
        .buttonStyle(.plain)
    }

    private var myStations: some View {
        VStack(spacing: 10) {
            SectionTitle(text: "いつもの駅")
            if shelf.stations.isEmpty {
                NavigationLink(value: Route.stationIndex) {
                    Label("よく行く駅に★を付けると、ここからすぐ開けます", systemImage: "star")
                        .font(.footnote.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .sticker()
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(shelf.stations, id: \.self) { name in
                            NavigationLink(value: Route.station(name)) {
                                Text("\(name)駅").font(.subheadline.weight(.heavy)).padding(.horizontal, 14).padding(.vertical, 10).sticker(radius: 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4).padding(.trailing, 4).padding(.leading, 1)
                }
            }
        }
    }

    private var reports: some View {
        VStack(spacing: 10) {
            SectionTitle(text: "運営者の実食レポート")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(library.reports) { ReportCard(report: $0, width: 210) }
                }
                .padding(.vertical, 4).padding(.trailing, 4).padding(.leading, 1)
            }
        }
    }

    private var guideOfTheDay: some View {
        VStack(spacing: 10) {
            SectionTitle(text: "きょうの1本")
            GuideRow(guide: library.guideOfTheDay())
        }
    }

    private var tools: some View {
        VStack(spacing: 10) {
            SectionTitle(text: "店の前で使うツール")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                ForEach(ToolKind.allCases) { kind in
                    NavigationLink(value: Route.tool(kind)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Image(systemName: kind.icon).font(.title3).foregroundStyle(.tint)
                            Text(kind.title).font(.footnote.weight(.heavy)).multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
                        .sticker()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
