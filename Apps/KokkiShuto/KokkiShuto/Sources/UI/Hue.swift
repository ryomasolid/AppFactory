import SwiftUI

enum Hue {
    static let navy = Color(red: 0.12, green: 0.27, blue: 0.62)
    static let sky = Color(red: 0.30, green: 0.58, blue: 0.95)
    static let correct = Color(red: 0.16, green: 0.66, blue: 0.40)
    static let wrong = Color(red: 0.88, green: 0.26, blue: 0.26)
    static let gold = Color(red: 0.95, green: 0.68, blue: 0.16)
    static let card = Color(.secondarySystemGroupedBackground)
    static let page = Color(.systemGroupedBackground)

    static func color(_ topic: Topic) -> Color { topic == .flag ? navy : Color(red: 0.55, green: 0.30, blue: 0.80) }
}
