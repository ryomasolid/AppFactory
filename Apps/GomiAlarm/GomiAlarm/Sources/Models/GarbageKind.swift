import Foundation
import SwiftData

/// ゴミの種類（燃えるゴミ／資源ごみ など）。収集ルールを複数持てる。
@Model
final class GarbageKind {
    var id: UUID = UUID()
    var name: String = ""
    /// カード・カレンダーの色（"#RRGGBB"）。
    var colorHex: String = "#E8543F"
    /// SF Symbols 名。
    var symbolName: String = "trash.fill"
    /// 分別メモ（「キャップは外す」など）。通知本文にも添える。
    var note: String = ""
    /// 前夜通知の時刻。nil なら設定の既定値を使う。
    var eveningMinutes: Int?
    /// 当日朝の通知時刻。nil なら設定の既定値を使う。
    var morningMinutes: Int?
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \CollectionRule.kind)
    var rules: [CollectionRule] = []

    init(
        name: String,
        colorHex: String = "#E8543F",
        symbolName: String = "trash.fill",
        note: String = "",
        eveningMinutes: Int? = nil,
        morningMinutes: Int? = nil,
        sortOrder: Int = 0,
        rules: [CollectionRule] = []
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.note = note
        self.eveningMinutes = eveningMinutes
        self.morningMinutes = morningMinutes
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.rules = rules
    }

    var eveningTime: TimeOfDay? {
        get { eveningMinutes.map(TimeOfDay.init(minutesFromMidnight:)) }
        set { eveningMinutes = newValue?.minutesFromMidnight }
    }

    var morningTime: TimeOfDay? {
        get { morningMinutes.map(TimeOfDay.init(minutesFromMidnight:)) }
        set { morningMinutes = newValue?.minutesFromMidnight }
    }

    /// 有効なルールだけを値型で取り出す。
    var specs: [RuleSpec] { rules.map(\.spec).filter(\.isValid) }
}
