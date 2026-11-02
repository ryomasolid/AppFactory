import Foundation
import Testing
@testable import GatsuGatsu

/// サイトから書き出した content.json が、アプリの中で全部たどれること。
struct ContentTests {
    private let library = Library.shared

    @Test func 全データが読める() {
        #expect(library.columns.count >= 20)
        #expect(library.reports.count >= 8)
        #expect(library.stations.count == 24)
        #expect(library.chains.count >= 5)
        #expect(library.buffets.count >= 3)
        #expect(!library.quantityBlocks.isEmpty)
    }

    @Test func 下書きのテンプレートが混ざっていない() {
        #expect(!library.reports.contains { $0.slug == "_template" || $0.title.contains("【駅名】") })
    }

    @Test func 知らない種類のブロックがない() {
        let all = library.columns.flatMap(\.blocks) + library.reports.flatMap(\.blocks) + library.quantityBlocks
        let unknown = all.filter { if case .unknown = $0 { true } else { false } }
        #expect(unknown.isEmpty)
    }

    @Test func 本文のリンクと写真が全部たどれる() {
        let all = library.columns.flatMap(\.blocks) + library.reports.flatMap(\.blocks) + library.quantityBlocks
        for block in all {
            switch block {
            case .link(let href, _, _):
                #expect(route(href) != nil, "開けないリンク: \(href)")
            case .photo(let name, _, _):
                #expect(Photos.image(name) != nil, "写真がない: \(name)")
            default:
                break
            }
        }
        for report in library.reports {
            if let hero = report.heroImage { #expect(Photos.image(hero.src) != nil, "写真がない: \(hero.src)") }
        }
    }

    @Test func 駅の参照先がすべて存在する() {
        for station in library.stations {
            for nearby in station.nearby { #expect(library.station(nearby) != nil, "\(station.name) → \(nearby)") }
            for slug in station.reportSlugs { #expect(library.report(slug) != nil, "\(station.name) → \(slug)") }
            for slug in station.guideSlugs { #expect(library.guide(slug) != nil, "\(station.name) → \(slug)") }
            #expect(station.sections.allSatisfy { !$0.heading.isEmpty }, "見出しが足りない: \(station.name)")
        }
        for guide in library.columns {
            for slug in guide.related { #expect(library.guide(slug) != nil, "\(guide.slug) → \(slug)") }
            if let link = guide.toolLink { #expect(route(link.href) != nil, "\(guide.slug) → \(link.href)") }
        }
    }

    @Test func リンクを画面に変換できる() {
        #expect(route("/column/gohan-gram") == .guide("gohan-gram"))
        #expect(route("/ryou") == .tool(.quantity))
        #expect(route("/station") == .stationIndex)
        #expect(route("/station/%E6%B8%8B%E8%B0%B7") == .station("渋谷"))
        #expect(route("/unknown") == nil)
    }

    private func route(_ href: String) -> Route? { Route(href: href) }

    @Test func きょうの1本は同じ日なら同じ() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(library.guideOfTheDay(date).slug == library.guideOfTheDay(date.addingTimeInterval(1)).slug)
    }

    @Test func 検索はかなの違いを吸収する() {
        let hits = ContentSearch.run("らーめん", in: library)
        #expect(!hits.isEmpty)
        #expect(ContentSearch.run("　", in: library).isEmpty)
    }

    @Test func 検索は名前の一致を先に出す() {
        #expect(ContentSearch.run("渋谷", in: library).first == .station("渋谷"))
    }

    @Test func 検索は全部の語を含むものだけ返す() {
        #expect(ContentSearch.run("渋谷 存在しない語あいう", in: library).isEmpty)
    }
}

@MainActor
struct BiteLogTests {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "bites-\(UUID().uuidString).json")
    }

    @Test func 保存して読み直せる() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let log = BiteLog(fileURL: url)
        log.add(Bite(eatenAt: .now, name: "牛丼", kcal: 633))
        #expect(BiteLog(fileURL: url).bites.first?.name == "牛丼")
    }

    @Test func 新しい順に並び_消せる() {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let log = BiteLog(fileURL: url)
        let old = Bite(eatenAt: .now.addingTimeInterval(-3600), name: "古い", kcal: 1)
        log.add(old)
        log.add(Bite(eatenAt: .now, name: "新しい", kcal: 2))
        #expect(log.bites.first?.name == "新しい")
        log.remove(old)
        #expect(log.bites.count == 1)
        #expect(BiteLog(fileURL: url).bites.count == 1)
    }

    @Test func 壊れたファイルでも落ちない() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not json".utf8).write(to: url)
        #expect(BiteLog(fileURL: url).bites.isEmpty)
    }
}

@MainActor
struct ShelfTests {
    @Test func 押すたびに入れ外しでき_残る() throws {
        let name = "shelf-test-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let shelf = Shelf(defaults: defaults)
        shelf.toggleStation("渋谷")
        shelf.toggleStation("横浜")
        #expect(Shelf(defaults: defaults).stations == ["横浜", "渋谷"])
        shelf.toggleStation("渋谷")
        #expect(Shelf(defaults: defaults).stations == ["横浜"])
    }
}
