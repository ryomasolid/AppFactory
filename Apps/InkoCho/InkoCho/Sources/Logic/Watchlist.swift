import Foundation

/// 「きょうの見守り」に出す注意。体重・様子・フン・室温・卵をまとめて見る。
enum Watchlist {
    enum Severity: Int, Comparable {
        case note = 0, caution, urgent
        static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    struct Item: Equatable, Identifiable {
        var id: String
        var severity: Severity
        var title: String
        var detail: String
    }

    struct Facts {
        var weight: GramWatch.Reading?
        var lastLook: Look?
        /// 直近2日のフン（新しい順）。
        var recentDroppings: [Dropping?]
        var warmth: Warmth.Verdict?
        var eggsIn14Days: Int
        var isFemale: Bool
        var moltDays: Int
    }

    static func items(_ f: Facts) -> [Item] {
        var list: [Item] = []
        if let w = f.weight {
            switch w.level {
            case .falling(let p):
                list.append(Item(id: "weight", severity: .urgent, title: "体重が\(p)%へっています", detail: "ふだんより大きく減っています。小鳥は具合の悪さを隠すので、早めに鳥をみられる病院に相談してください。"))
            case .dipping(let p):
                list.append(Item(id: "weight", severity: .caution, title: "体重がすこしへっています（\(p)%）", detail: "ごはんを食べているか、フンの量が減っていないか見てあげてください。"))
            case .rising(let p):
                list.append(Item(id: "weight", severity: .note, title: "体重がふえています（\(p)%）", detail: f.isFemale ? "発情やお腹の卵でふえることがあります。お腹のふくらみも見てあげてください。" : "シードやおやつの量を見なおしてみましょう。"))
            case .steady:
                if w.slidingDown {
                    list.append(Item(id: "weight", severity: .caution, title: "体重が3回つづけてへっています", detail: "少しずつでも減りつづけるときは、ごはんの量と様子を気にかけてください。"))
                }
            }
        }
        if f.lastLook == .fluffed {
            // 体重も減っていれば、より急ぐ。
            let weightDown: Bool = switch f.weight?.level {
            case .dipping, .falling: true
            default: false
            }
            list.append(Item(id: "look", severity: weightDown ? .urgent : .caution,
                             title: "羽をふくらませています", detail: "寒いか、具合が悪いサインです。まず保温して、じっと動かない・ごはんを食べないときは病院へ。"))
        }
        let bad = f.recentDroppings.prefix(2).compactMap { $0 }.filter(\.worrying)
        if bad.count >= 2 {
            list.append(Item(id: "dropping", severity: .caution, title: "フンがいつもと違う日がつづいています", detail: "「\(bad[0].label)」。写真を撮っておくと、病院で説明しやすくなります。"))
        }
        if let warmth = f.warmth, warmth.needsCare {
            list.append(Item(id: "warmth", severity: warmth == .cold || warmth == .hot ? .caution : .note, title: "室温が\(warmth.label)", detail: warmth == .cold || warmth == .chilly ? "ヒーターやカバーで保温してあげましょう。" : "直射日光やエアコンの風に気をつけて、水を切らさないように。"))
        }
        if f.isFemale, f.eggsIn14Days >= Seasons.eggWarnCount {
            list.append(Item(id: "eggs", severity: .caution, title: "2週間で卵を\(f.eggsIn14Days)こ産んでいます", detail: "産みつづけると体の負担が大きくなります。発情をおさえる工夫と、獣医さんへの相談を。"))
        }
        if f.moltDays >= 1 {
            list.append(Item(id: "molt", severity: .note, title: "換羽\(f.moltDays)日目", detail: "体力を使う時期です。保温と、栄養のあるごはんを。"))
        }
        return list.sorted { $0.severity > $1.severity }
    }
}
