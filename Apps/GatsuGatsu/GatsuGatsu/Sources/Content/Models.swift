import Foundation

/// 記事の本文を組み立てる部品。サイトの ColumnBlock と同じ形（Scripts/export_content.mjs が書き出す）。
enum Block: Decodable {
    struct Step: Decodable { let title: String; let body: String }
    struct QA: Decodable { let q: String; let a: String }
    struct Bar: Decodable { let label: String; let value: Double }
    struct Source: Decodable { let label: String; let url: String?; let checkedAt: String? }

    case heading(String)
    case subheading(String)
    case paragraph(String)
    case bullets([String])
    case steps([Step])
    case note(String)
    case faq([QA])
    case photo(name: String, alt: String, caption: String?)
    case table(caption: String?, headers: [String], rows: [[String]], note: String?)
    case bars(title: String, unit: String, items: [Bar], note: String?)
    case reportLink(slug: String, text: String)
    case link(href: String, label: String, text: String?)
    case sources([Source])
    /// 新しい種類がサイトに増えても、アプリを落とさず読み飛ばす。
    case unknown

    private enum Key: String, CodingKey {
        case type, text, items, steps, faqs, src, alt, caption, headers, rows, note, title, unit, slug, href, label
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        func text(_ key: Key = .text) throws -> String { try c.decode(String.self, forKey: key) }
        func optional(_ key: Key) throws -> String? { try c.decodeIfPresent(String.self, forKey: key) }
        switch try text(.type) {
        case "heading": self = .heading(try text())
        case "subheading": self = .subheading(try text())
        case "p": self = .paragraph(try text())
        case "list": self = .bullets(try c.decode([String].self, forKey: .items))
        case "steps": self = .steps(try c.decode([Step].self, forKey: .steps))
        case "note": self = .note(try text())
        case "faq": self = .faq(try c.decode([QA].self, forKey: .faqs))
        case "photo": self = .photo(name: try text(.src), alt: try text(.alt), caption: try optional(.caption))
        case "table":
            self = .table(caption: try optional(.caption),
                          headers: try c.decode([String].self, forKey: .headers),
                          rows: try c.decode([[String]].self, forKey: .rows),
                          note: try optional(.note))
        case "bars":
            self = .bars(title: try text(.title), unit: try text(.unit),
                         items: try c.decode([Bar].self, forKey: .items), note: try optional(.note))
        case "reportLink": self = .reportLink(slug: try text(.slug), text: try text())
        case "link": self = .link(href: try text(.href), label: try text(.label), text: try optional(.text))
        case "sources": self = .sources(try c.decode([Source].self, forKey: .items))
        default: self = .unknown
        }
    }

    var isHeading: Bool {
        switch self {
        case .heading, .faq: true
        default: false
        }
    }
}

/// がっつり飯ガイドの1本。
struct Guide: Decodable, Identifiable {
    struct ToolLink: Decodable { let href: String; let label: String }
    let slug: String
    let title: String
    let cardTitle: String
    let description: String
    let category: String
    let updatedAt: String
    let lead: String
    let blocks: [Block]
    let related: [String]
    let toolLink: ToolLink?
    var id: String { slug }
}

struct GuideCategory: Decodable, Identifiable {
    let id: String
    let description: String
}

/// 運営者の実食レポート。
struct Report: Decodable, Identifiable {
    struct Hero: Decodable { let src: String; let alt: String; let caption: String? }
    let slug: String
    let title: String
    let cardTitle: String
    let description: String
    let station: String
    let shopName: String
    let genre: String
    let orderedItem: String
    let price: String?
    let visitedAt: String
    let lead: String
    let heroImage: Hero?
    let blocks: [Block]
    let relatedColumns: [String]
    var id: String { slug }
}

struct Station: Decodable, Identifiable {
    struct Section: Decodable { let heading: String; let body: String }
    struct Shop: Decodable { let name: String; let note: String }
    let name: String
    let region: String
    let hook: String
    let lines: [String]
    let nearby: [String]
    let lead: String
    let sections: [Section]
    let shops: [Shop]
    let guideSlugs: [String]
    let reportSlugs: [String]
    var id: String { name }
}

struct MapSearch: Decodable, Identifiable {
    let label: String
    let keyword: String
    var id: String { label }
}

struct NutritionFacts: Decodable, Hashable {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
}

/// 栄養成分を公表している外食チェーン。
struct Chain: Decodable, Identifiable {
    struct Item: Decodable, Identifiable, Hashable {
        let name: String
        let calories: Double
        let protein: Double
        let fat: Double
        let carbs: Double
        var id: String { name }
        var facts: NutritionFacts { .init(calories: calories, protein: protein, fat: fat, carbs: carbs) }
    }
    struct Citation: Decodable { let label: String; let url: String }
    let id: String
    let name: String
    let emoji: String
    let genre: String
    let source: Citation
    let menu: [Item]
}

/// 食べ放題の業態。料金は実在の店ではなく、よくある価格帯の例。
struct Buffet: Decodable, Identifiable {
    struct Course: Decodable, Identifiable, Hashable { let id: String; let name: String; let price: Int; let note: String }
    struct Dish: Decodable, Identifiable, Hashable {
        let name: String
        let unitPrice: Int
        let category: String
        var id: String { name }
    }
    let id: String
    let name: String
    let emoji: String
    let genre: String
    let catchcopy: String
    let courses: [Course]
    let menu: [Dish]
}

struct QueueGenre: Decodable, Identifiable, Hashable {
    let id: String
    let label: String
    let emoji: String
    let avgStayMin: Int
    let examples: String
}

struct SeatPreset: Decodable, Identifiable {
    let label: String
    let seats: Int
    var id: String { label }
}
