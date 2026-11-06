import Foundation
import Testing
@testable import GatsuGatsu

/// 全国の駅一覧（stations-japan.json）と、記事の駅との結びつき。
struct JapanStationsTests {
    private let japan = JapanStations.shared
    private let library = Library.shared

    @Test func 全国の駅が読める() {
        #expect(japan.all.count > 8000)
        #expect(japan.source.contains("国土数値情報"))
        #expect(japan.all.allSatisfy { !$0.name.isEmpty && !$0.lines.isEmpty })
    }

    @Test func 記事の駅が全部首都圏の駅に結びつく() {
        #expect(japan.articleByID.count == library.stations.count)
        for (id, name) in japan.articleByID {
            let station = japan.station(id)
            #expect(station?.name == name)
            #expect(station.map(JapanStations.isKanto) == true)
        }
    }

    @Test func 同じ名前でも埼玉の大宮が記事の駅になる() {
        let omiya = japan.all.filter { $0.name == "大宮" }
        #expect(omiya.count >= 2)
        let linked = omiya.filter { japan.articleName(for: $0) != nil }
        #expect(linked.count == 1)
        #expect(linked.first?.lines.contains("東北新幹線") == true)
    }

    @Test func 駅名がそのまま一番上に出る() {
        let result = japan.search("梅田")
        #expect(result.hits.first?.name == "梅田")
        #expect(japan.search("梅田駅").hits.first?.name == "梅田")
    }

    @Test func 同じ名前の駅は路線で見分けられる() {
        let fuchu = japan.search("府中").hits.filter { $0.name == "府中" }
        #expect(fuchu.count >= 3)
        #expect(Set(fuchu.map(\.linesText)).count == fuchu.count)
    }

    @Test func 路線名でも探せる() {
        let result = japan.search("御堂筋線")
        #expect(result.total >= 15)
        #expect(result.hits.allSatisfy { station in station.lines.contains { $0.contains("御堂筋線") } })
    }

    @Test func 件数が多いときは上限で切る() {
        let result = japan.search("田", limit: 40)
        #expect(result.hits.count == 40)
        #expect(result.total > 40)
    }

    @Test func 空の検索は何も返さない() {
        #expect(japan.search("  ").total == 0)
        #expect(japan.search("駅").total >= 0)
    }

    @Test func 記事のない駅には近くの記事の駅を出す() {
        guard let kichijoji = japan.all.first(where: { $0.name == "吉祥寺" }) else {
            Issue.record("吉祥寺がない")
            return
        }
        let nearby = japan.nearbyArticles(to: kichijoji)
        #expect(!nearby.isEmpty)
        #expect(nearby.map(\.kilometers) == nearby.map(\.kilometers).sorted())
        #expect(nearby.allSatisfy { $0.kilometers <= JapanStations.nearbyArticleKilometers })
    }

    @Test func 遠い地方の駅には近くの記事の駅を出さない() {
        guard let sapporo = japan.all.first(where: { $0.name == "札幌" }) else {
            Issue.record("札幌がない")
            return
        }
        #expect(japan.nearbyArticles(to: sapporo).isEmpty)
    }

    @Test func 地図の検索は駅の位置を中心にする() {
        let url = MapLink.search("府中駅 デカ盛り", near: (34.57153, 133.23647))
        #expect(url?.absoluteString.hasSuffix("/@34.57153,133.23647,15z") == true)
        #expect(url?.absoluteString.contains("%20") == true)
    }

    @Test func 記事のない駅もいつもの駅に保存して開き直せる() {
        let fuchu = japan.all.filter { $0.name == "府中" }
        #expect(Set(fuchu.map(\.shelfKey)).count == fuchu.count)
        for station in fuchu {
            #expect(japan.station(shelfKey: station.shelfKey)?.id == station.id)
            let saved = japan.savedStation(station.shelfKey)
            #expect(saved?.name == "府中")
            #expect(saved?.route == .japanStation(station.id))
        }
    }

    @Test func 記事の駅は駅名のまま保存する() {
        let saved = japan.savedStation("新宿")
        #expect(saved?.name == "新宿")
        #expect(saved?.route == .station("新宿"))
    }

    @Test func 消えた駅の鍵は無視する() {
        #expect(japan.savedStation("存在しない駅|謎線") == nil)
    }
}
