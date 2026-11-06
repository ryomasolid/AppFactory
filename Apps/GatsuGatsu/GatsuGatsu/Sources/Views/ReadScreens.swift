import SwiftUI

struct ReadScreen: View {
    private enum Pane: String, CaseIterable { case reports = "実食レポート", guides = "ガイド", saved = "保存" }

    @State private var pane: Pane = .reports
    @Environment(Shelf.self) private var shelf
    private let library = Library.shared

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Picker("種類", selection: $pane) {
                    ForEach(Pane.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 4)

                switch pane {
                case .reports: reports
                case .guides: guides
                case .saved: saved
                }
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("記事")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: Route.search) { Image(systemName: "magnifyingglass").accessibilityLabel("検索") }
            }
        }
    }

    @ViewBuilder private var reports: some View {
        Text("運営者が自分で注文して、自分で撮った記録です。").font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
        ForEach(Array(library.reports.enumerated()), id: \.element.id) { index, report in
            ReportCard(report: report)
            // 記事4本につき1枠。
            if (index + 1).isMultiple(of: 4) { SponsoredCard(slot: "reports-\(index)", path: "/report") }
        }
    }

    @ViewBuilder private var guides: some View {
        ForEach(library.categories) { category in
            let list = library.columns.filter { $0.category == category.id }
            if !list.isEmpty {
                SectionTitle(text: category.id).padding(.top, 6)
                Text(category.description).font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                ForEach(list) { GuideRow(guide: $0) }
                if category.id == library.categories.first?.id || category.id == library.categories.dropFirst(2).first?.id {
                    SponsoredCard(slot: "guides-\(category.id)", path: "/column")
                }
            }
        }
    }

    @ViewBuilder private var saved: some View {
        if shelf.reports.isEmpty && shelf.guides.isEmpty {
            ContentUnavailableView("保存した記事はありません", systemImage: "bookmark", description: Text("記事の右上の栞を押すと、ここに入ります。"))
        }
        ForEach(shelf.reports.compactMap(library.report)) { ReportCard(report: $0) }
        ForEach(shelf.guides.compactMap(library.guide)) { GuideRow(guide: $0) }
    }
}

struct GuideScreen: View {
    let slug: String
    @Environment(Shelf.self) private var shelf
    private let library = Library.shared

    var body: some View {
        if let guide = library.guide(slug) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(guide.category).font(.caption.weight(.bold)).foregroundStyle(.tint)
                    Text(guide.title).font(.system(size: 24, weight: .black))
                    Text("更新 \(DateText.japanese(guide.updatedAt))").font(.caption).foregroundStyle(.secondary)
                    Text(guide.lead).font(.body.weight(.semibold)).lineSpacing(6)
                        .padding(12).sticker(fill: .softOrange, radius: 10)
                    BlocksView(blocks: guide.blocks, adSlot: "guide-mid:\(slug)", adPath: "/column/\(slug)")
                    if let link = guide.toolLink, let route = Route(href: link.href) {
                        NavigationLink(value: route) { PrimaryButtonLabel(text: link.label, systemImage: "plusminus.circle.fill") }.buttonStyle(.plain)
                    }
                    SponsoredCard(slot: "guide-end:\(slug)", path: "/column/\(slug)")
                    let related = guide.related.compactMap(library.guide)
                    if !related.isEmpty {
                        SectionTitle(text: "続けて読む")
                        ForEach(related) { GuideRow(guide: $0) }
                    }
                }
                .padding(16)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ArticleToolbar(saved: shelf.guides.contains(slug), webPath: "/column/\(slug)") { shelf.toggleGuide(slug) } }
        } else {
            ContentUnavailableView("この記事は見つかりません", systemImage: "book")
        }
    }
}

struct ReportScreen: View {
    let slug: String
    @Environment(Shelf.self) private var shelf
    private let library = Library.shared

    var body: some View {
        if let report = library.report(slug) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let hero = report.heroImage {
                        VStack(alignment: .leading, spacing: 6) {
                            Color.clear.aspectRatio(4 / 3, contentMode: .fit)
                                .overlay { PhotoView(name: hero.src, alt: hero.alt) }
                                .clipShape(.rect(cornerRadius: 14))
                                .sticker()
                            if let caption = hero.caption { Text(caption).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    Text("運営者の実食記録・\(report.genre)").font(.caption.weight(.bold)).foregroundStyle(.tint)
                    Text(report.title).font(.system(size: 23, weight: .black))
                    facts(report)
                    Text(report.lead).lineSpacing(6)
                    BlocksView(blocks: report.blocks, adSlot: "report-mid:\(slug)", adPath: "/report/\(slug)")
                    SponsoredCard(slot: "report-end:\(slug)", path: "/report/\(slug)")
                    let related = report.relatedColumns.compactMap(library.guide)
                    if !related.isEmpty {
                        SectionTitle(text: "関連ガイド")
                        ForEach(related) { GuideRow(guide: $0) }
                    }
                }
                .padding(16)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ArticleToolbar(saved: shelf.reports.contains(slug), webPath: "/report/\(slug)") { shelf.toggleReport(slug) } }
        } else {
            ContentUnavailableView("このレポートは見つかりません", systemImage: "book")
        }
    }

    private func facts(_ report: Report) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            row("店", report.shopName)
            row("駅", "\(report.station)駅")
            row("注文", report.orderedItem)
            if let price = report.price { row("支払い", "\(price)（訪問時点）") }
            row("訪問", DateText.japanese(report.visitedAt))
            NavigationLink(value: Route.station(report.station)) {
                Label("\(report.station)駅のガイドを見る", systemImage: "tram.fill").font(.caption.weight(.bold))
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sticker()
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(.secondary).frame(width: 44, alignment: .leading)
            Text(value).font(.footnote.weight(.semibold))
        }
    }
}

private struct ArticleToolbar: ToolbarContent {
    let saved: Bool
    let webPath: String
    let toggle: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if let url = URL(string: "https://gatsugatsu-gurume.com\(webPath)") {
                ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }.accessibilityLabel("共有")
            }
            Button(action: toggle) { Image(systemName: saved ? "bookmark.fill" : "bookmark") }
                .accessibilityLabel(saved ? "保存をやめる" : "保存する")
        }
    }
}

struct SearchScreen: View {
    @State private var query = ""
    private let library = Library.shared

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let hits = ContentSearch.run(query, in: library)
                if query.isEmpty {
                    ContentUnavailableView("駅・店・料理で探す", systemImage: "magnifyingglass", description: Text("「家系」「つけ麺 量」「渋谷」など。端末の中の記事から探すので、電波がなくても使えます。"))
                } else if hits.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
                ForEach(hits) { hit in
                    switch hit {
                    case .station(let name): if let s = library.station(name) { StationRow(station: s) }
                    case .report(let slug): if let r = library.report(slug) { ReportCard(report: r) }
                    case .guide(let slug): if let g = library.guide(slug) { GuideRow(guide: g) }
                    }
                }
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("検索")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "駅・店・料理")
    }
}
