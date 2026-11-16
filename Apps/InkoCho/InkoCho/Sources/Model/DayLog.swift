import Foundation
import SwiftData

/// 1羽の1日の記録。体重（g）を毎日はかるのが中心。
@Model
final class DayLog {
    var day: Date = Date()
    /// 体重（グラム）。はかっていなければ nil。
    var grams: Double?
    /// 放鳥（ケージの外で遊んだ）時間・分。
    var outsideMinutes: Int = 0
    var droppingRaw: String?
    var lookRaw: String?
    /// 室温（℃）。
    var roomCelsius: Double?
    var molting: Bool = false
    var laidEgg: Bool = false
    var memo: String = ""
    @Attribute(.externalStorage) var picture: Data?
    var bird: Bird?

    init(day: Date, bird: Bird, calendar: Calendar = .current) {
        self.day = calendar.startOfDay(for: day)
        self.bird = bird
    }

    var dropping: Dropping? {
        get { droppingRaw.flatMap(Dropping.init(rawValue:)) }
        set { droppingRaw = newValue?.rawValue }
    }

    var look: Look? {
        get { lookRaw.flatMap(Look.init(rawValue:)) }
        set { lookRaw = newValue?.rawValue }
    }

    var isEmpty: Bool {
        grams == nil && outsideMinutes == 0 && dropping == nil && look == nil && roomCelsius == nil
            && !molting && !laidEgg && memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && picture == nil
    }
}

/// フンの様子。小鳥は体調がフンに出やすい。
enum Dropping: String, CaseIterable, Identifiable {
    case normal, watery, green, dark, seeds
    var id: Self { self }
    var label: String {
        switch self {
        case .normal: "いつもどおり"
        case .watery: "水っぽい"
        case .green: "緑っぽい"
        case .dark: "黒っぽい"
        case .seeds: "シードがそのまま"
        }
    }

    var worrying: Bool { self != .normal }
}

/// きょうの様子。
enum Look: String, CaseIterable, Identifiable {
    case chatty, lively, calm, sleepy, fluffed
    var id: Self { self }
    var label: String {
        switch self {
        case .chatty: "おしゃべり"
        case .lively: "げんき"
        case .calm: "おっとり"
        case .sleepy: "ねむそう"
        case .fluffed: "ふくらんでる"
        }
    }

    var symbol: String {
        switch self {
        case .chatty: "bubble.left.and.bubble.right.fill"
        case .lively: "sun.max.fill"
        case .calm: "leaf.fill"
        case .sleepy: "moon.zzz.fill"
        case .fluffed: "cloud.fill"
        }
    }

    /// 羽をふくらませてじっとしているのは、寒いか具合が悪いサイン。
    var warning: Bool { self == .fluffed }
}
