import SwiftUI

struct ReportCard: View {
    let report: Report
    var width: CGFloat? = nil

    var body: some View {
        NavigationLink(value: Route.report(report.slug)) {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    .overlay {
                        if let hero = report.heroImage { PhotoView(name: hero.src, alt: hero.alt) }
                    }
                    .clipped()
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(report.station)駅・\(report.genre)").font(.caption2.weight(.bold)).foregroundStyle(.tint)
                    Text(report.shopName).font(.subheadline.weight(.heavy)).lineLimit(1)
                    Text(report.orderedItem).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: width)
            .clipShape(.rect(cornerRadius: 14))
            .sticker()
        }
        .buttonStyle(.plain)
    }
}

struct GuideRow: View {
    let guide: Guide

    var body: some View {
        NavigationLink(value: Route.guide(guide.slug)) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(guide.category).font(.caption2.weight(.black)).foregroundStyle(.tint)
                    Text(guide.cardTitle).font(.subheadline.weight(.heavy)).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sticker()
        }
        .buttonStyle(.plain)
    }
}

struct StationRow: View {
    let station: Station
    @Environment(Shelf.self) private var shelf

    var body: some View {
        NavigationLink(value: Route.station(station.name)) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(station.name).font(.headline.weight(.black))
                        if !station.reportSlugs.isEmpty {
                            Text("実食\(station.reportSlugs.count)").font(.caption2.weight(.black))
                                .foregroundStyle(.white).padding(.horizontal, 6).padding(.vertical, 2)
                                .background(.tint, in: .capsule)
                        }
                    }
                    Text(station.hook).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if shelf.stations.contains(station.name) {
                    Image(systemName: "star.fill").foregroundStyle(Color.mustard).accessibilityLabel("いつもの駅")
                }
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sticker()
        }
        .buttonStyle(.plain)
    }
}
