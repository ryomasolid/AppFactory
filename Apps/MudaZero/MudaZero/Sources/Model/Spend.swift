import Foundation
import SwiftData

/// 使ったお金1件。「ついつい（ムダ）」か「必要」かで分ける。
@Model
final class Spend {
    var day: Date = Date()
    var yen: Int = 0
    var isWant: Bool = true
    var categoryRaw: String = SpendType.otherWant.rawValue
    var memo: String = ""
    var createdAt: Date = Date()

    init(day: Date, yen: Int, category: SpendType, memo: String = "", calendar: Calendar = .current) {
        self.day = calendar.startOfDay(for: day)
        self.yen = yen
        self.isWant = category.isWant
        self.categoryRaw = category.rawValue
        self.memo = memo
    }

    var category: SpendType {
        SpendType(rawValue: categoryRaw) ?? (isWant ? .otherWant : .otherNeed)
    }

    var entry: Entry { Entry(day: day, yen: yen, category: category) }
}

/// 「この日はムダ遣いしなかった」としめた日。
@Model
final class DayMark {
    var day: Date = Date()

    init(day: Date, calendar: Calendar = .current) {
        self.day = calendar.startOfDay(for: day)
    }
}

enum Schema1 {
    static let all: [any PersistentModel.Type] = [Spend.self, DayMark.self]
}

/// お金の使いみち。前半が「ついつい」、後半が「必要」。
enum SpendType: String, CaseIterable, Identifiable {
    case konbini, cafe, sweets, online, fashion, hobby, eatOut, drinks, otherWant
    case groceries, daily, transport, medical, bills, otherNeed

    var id: Self { self }

    var isWant: Bool {
        switch self {
        case .konbini, .cafe, .sweets, .online, .fashion, .hobby, .eatOut, .drinks, .otherWant: true
        default: false
        }
    }

    var label: String {
        switch self {
        case .konbini: "コンビニ"
        case .cafe: "カフェ"
        case .sweets: "おやつ"
        case .online: "ネット通販"
        case .fashion: "服・コスメ"
        case .hobby: "趣味・ゲーム"
        case .eatOut: "外食"
        case .drinks: "飲み会"
        case .otherWant: "そのほか"
        case .groceries: "食材"
        case .daily: "日用品"
        case .transport: "交通"
        case .medical: "病院・薬"
        case .bills: "支払い・固定費"
        case .otherNeed: "そのほか"
        }
    }

    var symbol: String {
        switch self {
        case .konbini: "storefront"
        case .cafe: "cup.and.saucer"
        case .sweets: "birthday.cake"
        case .online: "shippingbox"
        case .fashion: "tshirt"
        case .hobby: "gamecontroller"
        case .eatOut: "fork.knife"
        case .drinks: "wineglass"
        case .otherWant: "sparkles"
        case .groceries: "carrot"
        case .daily: "basket"
        case .transport: "tram"
        case .medical: "cross.case"
        case .bills: "doc.text"
        case .otherNeed: "ellipsis.circle"
        }
    }

    static func choices(want: Bool) -> [SpendType] {
        allCases.filter { $0.isWant == want }
    }
}

/// 設定（UserDefaults）。
enum Plan {
    static let startedKey = "plan.started"
    /// ふだん1日にしてしまうムダ（円）。がまんした日はこの分が浮く。
    static let usualKey = "plan.usual"
    static let usualDefault = 500
    /// 1か月の「ついつい」予算（円）。
    static let budgetKey = "plan.budget"
    static let budgetDefault = 10000
    static let goalNameKey = "goal.name"
    static let goalYenKey = "goal.yen"
    /// もくひょうを数えはじめた日（timeIntervalSinceReferenceDate）。
    static let goalStartKey = "goal.start"
}
