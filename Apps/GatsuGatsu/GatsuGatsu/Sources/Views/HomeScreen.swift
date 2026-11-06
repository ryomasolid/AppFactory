import SwiftUI

struct HomeScreen: View {
    @Environment(BiteLog.self) private var log
    @Environment(Shelf.self) private var shelf
    @Environment(Navigator.self) private var navigator
    @State private var query = ""
    @FocusState private var searching: Bool
    private let library = Library.shared
    private static let popular = ["新宿", "渋谷", "池袋", "東京", "横浜", "秋葉原"]
    private static let fieldHint = Color(white: 0.42)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                hero
                if query.isEmpty {
                    mainActions
                    todayCard
                    reports
                    SponsoredCard(slot: "home-top", path: "/")
                    guideOfTheDay
                    tools
                } else {
                    StationSearchResults(query: query)
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.immediately)
        .paperBackground()
        .navigationTitle("ガツガツグルメ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(value: Route.search) { Image(systemName: "text.magnifyingglass").accessibilityLabel("記事を検索") }
                NavigationLink(value: Route.settings) { Image(systemName: "gearshape").accessibilityLabel("設定") }
            }
        }
    }

    /// 一番の目的「この駅でがっつり食べたい」をホームの最初に置く。
    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("どの駅で、がっつり食べる？").font(.system(size: 24, weight: .heavy)).foregroundStyle(.white)
            Text("全国\(JapanStations.shared.all.count.formatted())駅から、大盛り・デカ盛りの店を探せます")
                .font(.footnote.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Self.fieldHint)
                // 入力欄はダークモードでも白なので、説明の文字と記号の色を固定する（システムの色だと白に溶ける）。
                TextField("駅名", text: $query, prompt: Text("駅名を入れる（例: 新宿、梅田）").foregroundStyle(Self.fieldHint))
                    .focused($searching)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color(white: 0.1))
                    .tint(Color.accentColor)
                if !query.isEmpty {
                    Button { query = ""; searching = false } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Self.fieldHint) }
                        .accessibilityLabel("入力を消す")
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.white, in: .rect(cornerRadius: 14))
            .accessibilityElement(children: .contain)
            if query.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(shelf.stations.isEmpty ? Self.popular : shelf.stations, id: \.self) { key in
                            if let saved = JapanStations.shared.savedStation(key) {
                            NavigationLink(value: saved.route) {
                                Label(saved.name, systemImage: shelf.stations.isEmpty ? "tram.fill" : "star.fill")
                                    .font(.footnote.weight(.bold)).foregroundStyle(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(.white.opacity(0.2), in: .capsule)
                            }
                            .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Text(shelf.stations.isEmpty ? "よく行く駅は、駅のページの★で登録できます" : "いつもの駅")
                    .font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(18)
        // ダークモードの朱色は明るく、白い文字が沈むので、この枠だけは濃い朱色に固定する。
        .background(Color(red: 0.85, green: 0.28, blue: 0.06).gradient, in: .rect(cornerRadius: 22))
    }

    /// よく使う3つ。何ができるアプリか、ここで分かるようにする。
    private var mainActions: some View {
        VStack(spacing: 10) {
            action(icon: "scalemass.fill", title: "大盛りは何グラム？", detail: "麺・ご飯の量を店ごとに早見表で", route: .tool(.quantity))
            action(icon: "flame.fill", title: "カロリーを計算して記録", detail: "チェーンの公式値で、そのままガツログへ", route: .tool(.calorie))
            action(icon: "person.3.sequence.fill", title: "行列の待ち時間", detail: "入店時刻の目安と、5分前の通知", route: .tool(.queue))
        }
    }

    private func action(icon: String, title: String, detail: String, route: Route) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.title3).foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(Color.softOrange, in: .rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .padding(12)
            .sticker()
        }
        .buttonStyle(.plain)
    }

    private var todayCard: some View {
        let today = log.stats.summary(of: log.stats.onDay(.now))
        return Button { navigator.tab = .log } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("きょうのガツログ", systemImage: "chart.bar.fill").font(.subheadline.weight(.bold))
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.bold))
                }
                HStack(alignment: .firstTextBaseline) {
                    BigNumber(value: today.kcal.whole, unit: "kcal", size: 36)
                    Spacer()
                    Text("茶碗 \(today.riceBowls.oneDecimal)杯ぶん").font(.subheadline.weight(.bold))
                }
                ProgressView(value: min(today.kcal / library.daily.calories, 1)).tint(Color.accentColor)
                Text(today.count == 0 ? "何を食べたか記録すると、ここに積み上がります" : "\(today.count)品を記録・1日の目安 \(library.daily.calories.whole)kcal")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(14)
            .foregroundStyle(Color.primary)
            .sticker()
        }
        .buttonStyle(.plain)
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
            SectionTitle(text: "ほかのツール")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                ForEach([ToolKind.buffet, .split]) { kind in
                    NavigationLink(value: Route.tool(kind)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Image(systemName: kind.icon).font(.title3).foregroundStyle(.tint)
                            Text(kind.title).font(.footnote.weight(.semibold)).multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
                        .sticker()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
