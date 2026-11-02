import SwiftUI

/// 記事本文の描画。見出しが3つ以上ある長い記事だけ、3つ目の見出しの前に広告を1枠入れる。
struct BlocksView: View {
    let blocks: [Block]
    var adSlot: String? = nil
    var adPath: String? = nil

    private var adIndex: Int? {
        guard adSlot != nil else { return nil }
        let headings = blocks.indices.filter { blocks[$0].isHeading }
        return headings.count >= 3 ? headings[2] : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                if index == adIndex, let adSlot {
                    SponsoredCard(slot: adSlot, path: adPath)
                }
                BlockView(block: block)
            }
        }
    }
}

private struct BlockView: View {
    let block: Block

    var body: some View {
        switch block {
        case .heading(let text):
            SectionTitle(text: text).padding(.top, 10)
        case .subheading(let text):
            Text(text).font(.headline.weight(.heavy))
        case .paragraph(let text):
            Text(text).lineSpacing(6)
        case .bullets(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("●").font(.caption2).foregroundStyle(.tint)
                        Text(item).lineSpacing(4)
                    }
                }
            }
        case .steps(let steps):
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.black)).foregroundStyle(.white)
                            .frame(width: 26, height: 26).background(.tint, in: .circle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title).font(.subheadline.weight(.heavy))
                            Text(step.body).lineSpacing(4)
                        }
                    }
                }
            }
        case .note(let text):
            Text(text).font(.subheadline).lineSpacing(4).padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.softOrange, in: .rect(cornerRadius: 10))
        case .faq(let items):
            SectionTitle(text: "よくある質問").padding(.top, 10)
            ForEach(items, id: \.q) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Q. \(item.q)").font(.subheadline.weight(.heavy))
                    Text(item.a).lineSpacing(4)
                }
            }
        case .photo(let name, let alt, let caption):
            VStack(alignment: .leading, spacing: 6) {
                Color.clear.aspectRatio(4 / 3, contentMode: .fit)
                    .overlay { PhotoView(name: name, alt: alt) }
                    .clipShape(.rect(cornerRadius: 12))
                if let caption { Text(caption).font(.caption).foregroundStyle(.secondary) }
            }
        case .table(let caption, let headers, let rows, let note):
            DataTable(caption: caption, headers: headers, rows: rows, note: note)
        case .bars(let title, let unit, let items, let note):
            BarsBlock(title: title, unit: unit, items: items, note: note)
        case .reportLink(let slug, let text):
            if let report = Library.shared.report(slug) { FirstHandLink(report: report, text: text) }
        case .link(let href, let label, let text):
            if let route = Route(href: href) {
                NavigationLink(value: route) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(label, systemImage: "arrow.right.circle.fill").font(.subheadline.weight(.heavy)).foregroundStyle(.tint)
                        if let text { Text(text).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.leading) }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.softOrange, in: .rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        case .sources(let items):
            SourcesList(items: items)
        case .unknown:
            EmptyView()
        }
    }
}

private struct DataTable: View {
    let caption: String?
    let headers: [String]
    let rows: [[String]]
    let note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let caption { Text(caption).font(.subheadline.weight(.heavy)) }
            ScrollView(.horizontal, showsIndicators: false) {
                Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                            cell(header).font(.caption.weight(.black)).background(Color.softOrange)
                        }
                    }
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        GridRow {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, value in
                                cell(value).font(.footnote).background(index.isMultiple(of: 2) ? Color.card : Color.paper)
                            }
                        }
                    }
                }
                .overlay { RoundedRectangle(cornerRadius: 8).stroke(Color.ink.opacity(0.4)) }
                .clipShape(.rect(cornerRadius: 8))
            }
            if let note { Text(note).font(.caption).foregroundStyle(.secondary) }
        }
    }

    private func cell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: text.count > 14 ? 210 : nil, maxHeight: .infinity, alignment: .leading)
            .fixedSize(horizontal: text.count <= 14, vertical: text.count > 14)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct BarsBlock: View {
    let title: String
    let unit: String
    let items: [Block.Bar]
    let note: String?

    private var peak: Double { items.map(\.value).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.heavy))
            ForEach(items, id: \.label) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label).font(.caption)
                    HStack(spacing: 6) {
                        GeometryReader { proxy in
                            RoundedRectangle(cornerRadius: 4).fill(.tint)
                                .frame(width: max(proxy.size.width * item.value / peak, 3))
                        }
                        .frame(height: 16)
                        Text("\(item.value.formatted(.number.locale(Locale(identifier: "ja_JP"))))\(unit)")
                            .font(.caption.weight(.heavy)).monospacedDigit().frame(width: 84, alignment: .trailing)
                    }
                }
            }
            if let note { Text(note).font(.caption).foregroundStyle(.secondary) }
        }
        .padding(12)
        .background(Color.card, in: .rect(cornerRadius: 10))
    }
}

/// 記事の中から実食レポートへ。
private struct FirstHandLink: View {
    let report: Report
    let text: String

    var body: some View {
        NavigationLink(value: Route.report(report.slug)) {
            HStack(alignment: .top, spacing: 10) {
                if let hero = report.heroImage {
                    PhotoView(name: hero.src, alt: hero.alt).frame(width: 84, height: 84).clipShape(.rect(cornerRadius: 8))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("運営者の実食記録").font(.caption2.weight(.black)).foregroundStyle(.tint)
                    Text("\(report.shopName)（\(report.station)）").font(.subheadline.weight(.heavy))
                    Text(text).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.softOrange, in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct SourcesList: View {
    let items: [Block.Source]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("出典・確認日").font(.caption.weight(.black))
            ForEach(items, id: \.label) { item in
                let line = item.label + (item.checkedAt.map { "（\($0) 確認）" } ?? "")
                if let raw = item.url, let url = URL(string: raw) {
                    Link(line, destination: url).font(.caption)
                } else {
                    Text(line).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card, in: .rect(cornerRadius: 10))
    }
}
