import Foundation

/// きょう気にしておきたいこと（見守りカード）。
struct Concern: Equatable, Identifiable {
    enum Level: Int, Comparable {
        case note, careful, urgent
        static func < (a: Level, b: Level) -> Bool { a.rawValue < b.rawValue }
    }

    let level: Level
    let text: String
    var id: String { text }
}

enum Concerns {
    struct Input {
        var species: Species
        var resting: Bool
        /// 新しい順の食べ具合（冬眠中のぶんは除いて渡す）。
        var appetites: [Appetite]
        /// 3日以内のチェックで付いたサイン。
        var recentSigns: Set<Sign>
        var baseC: Double?
        var spotC: Double?
        var hibernation: HibernationWatch.Result?
        var month: Int
    }

    static func list(_ i: Input) -> [Concern] {
        var out: [Concern] = []

        if let h = i.hibernation {
            let pct = String(format: "%.1f", h.lostPercent)
            switch h.level {
            case .wake: out.append(Concern(level: .urgent, text: "冬眠を始めてから体重が \(pct)% 減っています。起こして温め、病院に相談を。"))
            case .careful: out.append(Concern(level: .careful, text: "冬眠中の体重の減りが早めです（ひと月あたり \(String(format: "%.1f", h.perMonth))%）。"))
            case .fine: break
            }
        }

        if !i.resting, i.appetites.count >= 3, i.appetites.prefix(3).allSatisfy({ $0 == .none }) {
            out.append(Concern(level: .careful, text: "3回つづけてごはんを食べていません。温度と体のようすを確かめましょう。"))
        }

        let serious = i.recentSigns.filter(\.serious).sorted { $0.rawValue < $1.rawValue }
        if !serious.isEmpty {
            out.append(Concern(level: .urgent, text: "「\(serious.map(\.label).joined(separator: "」「"))」は早めに爬虫類を診られる病院へ。"))
        } else if !i.recentSigns.isEmpty {
            out.append(Concern(level: .careful, text: "気になるサインがあります。2〜3日ようすを見て、つづくなら病院へ。"))
        }

        if !i.resting {
            let band = Heat.band(for: i.species)
            let habitat = i.species.habitat
            if let b = i.baseC, Heat.judge(b, in: band.base) != .ok {
                let low = Heat.judge(b, in: band.base) == .low
                out.append(Concern(level: .careful, text: "\(Heat.baseName(habitat))が\(low ? "低め" : "高め")です（目安 \(Int(band.base.lowerBound))〜\(Int(band.base.upperBound))℃）。"))
            }
            if let s = i.spotC, Heat.judge(s, in: band.spot) != .ok {
                let low = Heat.judge(s, in: band.spot) == .low
                out.append(Concern(level: .careful, text: "\(Heat.spotName(habitat))が\(low ? "低め" : "高め")です（目安 \(Int(band.spot.lowerBound))〜\(Int(band.spot.upperBound))℃）。"))
            }
        }

        if i.species.tropical, [11, 12, 1, 2].contains(i.month), !i.resting {
            out.append(Concern(level: .note, text: "\(i.species.label)は冬眠させない種類です。夜も保温を切らさないように。"))
        }
        if i.resting, i.species.tropical {
            out.append(Concern(level: .urgent, text: "\(i.species.label)は冬眠させない種類です。温かくしてください。"))
        }

        return out.sorted { $0.level > $1.level }
    }

    @MainActor
    static func list(for turtle: Turtle, now: Date = Date(), calendar: Calendar = .current) -> [Concern] {
        let rest = turtle.currentRest
        let feeds = turtle.careLog.filter { care in
            guard care.kind == .feed, care.appetite != nil else { return false }
            return rest.map { care.at < $0.startedOn } ?? true
        }
        let since = calendar.date(byAdding: .day, value: -3, to: calendar.startOfDay(for: now)) ?? now
        let signs = (turtle.checkups ?? []).filter { $0.on >= since }.reduce(into: Set<Sign>()) { $0.formUnion($1.signs) }
        let dayAgo = calendar.date(byAdding: .day, value: -2, to: now) ?? now
        let reading = turtle.latestReading.flatMap { $0.at >= dayAgo ? $0 : nil }
        return list(Input(
            species: turtle.species,
            resting: rest != nil,
            appetites: feeds.compactMap(\.appetite),
            recentSigns: signs,
            baseC: reading?.baseC,
            spotC: reading?.spotC,
            hibernation: rest.flatMap { HibernationWatch.check($0, measures: turtle.measures ?? [], calendar: calendar) },
            month: calendar.component(.month, from: now)
        ))
    }
}
