import Foundation

enum SearchHit: Identifiable, Hashable {
    case station(String)
    case report(String)
    case guide(String)

    var id: String {
        switch self {
        case .station(let key): "s:\(key)"
        case .report(let key): "r:\(key)"
        case .guide(let key): "g:\(key)"
        }
    }
}

/// 同梱の記事を端末の中だけで探す。「らーめん」でも「ラーメン」が見つかるよう、かなをそろえて比べる。
enum ContentSearch {
    static func fold(_ text: String) -> String {
        (text.applyingTransform(.hiraganaToKatakana, reverse: false) ?? text)
            .folding(options: [.caseInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
    }

    static func run(_ query: String, in library: Library) -> [SearchHit] {
        let words = fold(query).split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }

        func score(primary: String, secondary: String) -> Int? {
            let head = fold(primary), body = fold(secondary)
            var total = 0
            for word in words {
                if head.contains(word) { total += 10 } else if body.contains(word) { total += 1 } else { return nil }
            }
            return total
        }

        var hits: [(SearchHit, Int)] = []
        for s in library.stations {
            let body = [s.hook, s.lead, s.shops.map(\.name).joined(separator: " "), s.sections.map(\.body).joined(separator: " ")]
            if let v = score(primary: s.name + "駅", secondary: body.joined(separator: " ")) { hits.append((.station(s.name), v)) }
        }
        for r in library.reports {
            if let v = score(primary: "\(r.shopName) \(r.cardTitle) \(r.station)", secondary: "\(r.genre) \(r.orderedItem) \(r.lead)") {
                hits.append((.report(r.slug), v))
            }
        }
        for g in library.columns {
            if let v = score(primary: g.cardTitle + g.title, secondary: "\(g.description) \(g.lead)") { hits.append((.guide(g.slug), v)) }
        }
        // 同点なら元の並び（駅→レポート→ガイド）を保つ。
        return hits.enumerated()
            .sorted { $0.element.1 != $1.element.1 ? $0.element.1 > $1.element.1 : $0.offset < $1.offset }
            .map(\.element.0)
    }
}
