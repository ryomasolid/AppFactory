import Foundation
import SwiftData

/// 甲羅の長さと体重。毎日ではなく、ときどき計る。
@Model
final class Measure {
    var on: Date = Date()
    /// 背甲の長さ（mm）。
    var shellMM: Double?
    var grams: Double?
    var turtle: Turtle?

    init(on: Date, shellMM: Double?, grams: Double?, turtle: Turtle) {
        self.on = on
        self.shellMM = shellMM
        self.grams = grams
        self.turtle = turtle
    }
}

/// 世話をした記録（ごはん・水換え・温浴など）。
@Model
final class Care {
    var at: Date = Date()
    var kindRaw: String = CareKind.feed.rawValue
    var foodRaw: String?
    var appetiteRaw: String?
    var turtle: Turtle?

    init(kind: CareKind, at: Date, turtle: Turtle) {
        self.kindRaw = kind.rawValue
        self.at = at
        self.turtle = turtle
    }

    var kind: CareKind { CareKind(rawValue: kindRaw) ?? .feed }

    var food: Food? {
        get { foodRaw.flatMap(Food.init(rawValue:)) }
        set { foodRaw = newValue?.rawValue }
    }

    var appetite: Appetite? {
        get { appetiteRaw.flatMap(Appetite.init(rawValue:)) }
        set { appetiteRaw = newValue?.rawValue }
    }
}

enum CareKind: String, CaseIterable, Identifiable {
    case feed, water, soak, bedding, sun
    var id: Self { self }

    var label: String {
        switch self {
        case .feed: "ごはん"
        case .water: "水換え"
        case .soak: "温浴"
        case .bedding: "床材の交換"
        case .sun: "日光浴"
        }
    }

    var symbol: String {
        switch self {
        case .feed: "fork.knife"
        case .water: "drop.fill"
        case .soak: "bathtub.fill"
        case .bedding: "square.stack.3d.down.forward.fill"
        case .sun: "sun.max.fill"
        }
    }

    /// その暮らし方のカメにある世話。
    static func kinds(for habitat: Habitat) -> [CareKind] {
        habitat == .water ? [.feed, .water, .sun] : [.feed, .soak, .bedding, .sun]
    }
}

enum Food: String, CaseIterable, Identifiable {
    case pellet, greens, fruit, prey, calcium
    var id: Self { self }
    var label: String {
        switch self {
        case .pellet: "人工フード"
        case .greens: "野菜・野草"
        case .fruit: "くだもの"
        case .prey: "虫・小魚"
        case .calcium: "カルシウム"
        }
    }
}

enum Appetite: String, CaseIterable, Identifiable {
    case all, some, none
    var id: Self { self }
    var label: String {
        switch self {
        case .all: "完食"
        case .some: "少し残した"
        case .none: "食べない"
        }
    }
}

/// 体のようすのチェック。気になるところだけ付ける。
@Model
final class Checkup {
    var on: Date = Date()
    var signsRaw: [String] = []
    var memo: String = ""
    @Attribute(.externalStorage) var photo: Data?
    var turtle: Turtle?

    init(on: Date, turtle: Turtle) {
        self.on = on
        self.turtle = turtle
    }

    var signs: Set<Sign> {
        get { Set(signsRaw.compactMap(Sign.init(rawValue:))) }
        set { signsRaw = newValue.map(\.rawValue).sorted() }
    }
}

/// カメの不調でよく見るサイン。
enum Sign: String, CaseIterable, Identifiable {
    case swollenEyes, runnyNose, softShell, shellSpots, gaping, looseStool, notBasking
    var id: Self { self }
    var label: String {
        switch self {
        case .swollenEyes: "目が腫れている・開かない"
        case .runnyNose: "鼻水・鼻ちょうちん"
        case .softShell: "甲羅がやわらかい"
        case .shellSpots: "甲羅に白い・赤い斑点"
        case .gaping: "口を開けて息をする"
        case .looseStool: "フンがゆるい"
        case .notBasking: "甲羅干しをしない"
        }
    }

    /// 早めに病院へ行きたいもの。
    var serious: Bool { self == .gaping || self == .swollenEyes || self == .softShell }
}

/// 飼育ケースの温度。ミズガメは水温とバスキング、リクガメはケージとホットスポット。
@Model
final class Reading {
    var at: Date = Date()
    var baseC: Double?
    var spotC: Double?
    var turtle: Turtle?

    init(at: Date, baseC: Double?, spotC: Double?, turtle: Turtle) {
        self.at = at
        self.baseC = baseC
        self.spotC = spotC
        self.turtle = turtle
    }
}

/// 冬眠の期間。始めたときの体重からの減りを見る。
@Model
final class Rest {
    var startedOn: Date = Date()
    var endedOn: Date?
    var startGrams: Double?
    var turtle: Turtle?

    init(startedOn: Date, startGrams: Double?, turtle: Turtle) {
        self.startedOn = startedOn
        self.startGrams = startGrams
        self.turtle = turtle
    }
}

/// 器具（UVB ライト・ヒーター・ろ材など）。どのカメにも共通で、置き場所で分ける。
@Model
final class Gear {
    var key: UUID = UUID()
    var kindRaw: String = GearKind.uvb.rawValue
    var name: String = ""
    var place: String = ""
    var installedOn: Date = Date()
    var lifeDays: Int = 180
    var swaps: Int = 0

    init(kind: GearKind, name: String, place: String = "", installedOn: Date, lifeDays: Int? = nil) {
        self.kindRaw = kind.rawValue
        self.name = name
        self.place = place
        self.installedOn = installedOn
        self.lifeDays = lifeDays ?? kind.lifeDays
    }

    var kind: GearKind {
        get { GearKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }
}

enum GearKind: String, CaseIterable, Identifiable {
    case uvb, metalHalide, basking, waterHeater, filterMedia, panelHeater, other
    var id: Self { self }

    var label: String {
        switch self {
        case .uvb: "紫外線ライト（UVB）"
        case .metalHalide: "メタルハライドランプ"
        case .basking: "バスキングライト・保温球"
        case .waterHeater: "水中ヒーター"
        case .filterMedia: "ろ材・フィルター"
        case .panelHeater: "パネルヒーター"
        case .other: "その他"
        }
    }

    /// 交換の目安（日）。光っていても紫外線は弱まっていく。
    var lifeDays: Int {
        switch self {
        case .uvb: 180
        case .metalHalide: 365
        case .basking: 180
        case .waterHeater: 365
        case .filterMedia: 30
        case .panelHeater: 730
        case .other: 90
        }
    }

    var symbol: String {
        switch self {
        case .uvb: "sun.haze.fill"
        case .metalHalide: "light.max"
        case .basking: "lightbulb.fill"
        case .waterHeater: "thermometer.medium"
        case .filterMedia: "line.3.horizontal.decrease.circle.fill"
        case .panelHeater: "square.grid.3x3.fill"
        case .other: "wrench.and.screwdriver.fill"
        }
    }

    var why: String {
        switch self {
        case .uvb: "光って見えても、紫外線は半年ほどで弱くなります。甲羅と骨のために定期的に交換を。"
        case .metalHalide: "紫外線の強さが落ちてくるので、1年を目安に交換します。"
        case .basking: "切れる前に予備を用意しておくと安心です。"
        case .waterHeater: "故障すると水温が上がりすぎることも。1年を目安に交換します。"
        case .filterMedia: "目詰まりすると水が汚れやすくなります。"
        case .panelHeater: "コードの傷みや温度のムラを確かめましょう。"
        case .other: ""
        }
    }
}

enum Schema1 {
    static let models: [any PersistentModel.Type] = [Turtle.self, Measure.self, Care.self, Checkup.self, Reading.self, Rest.self, Gear.self]
}
