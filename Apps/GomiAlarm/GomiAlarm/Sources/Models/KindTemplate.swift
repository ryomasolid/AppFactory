import Foundation

/// オンボーディングで投入する「よくある構成」。
///
/// 白紙から登録させると確実に離脱するので、最初にひな形を選ばせて登録ゼロの状態を作らない。
/// 曜日は地域で違うため、あくまで出発点（登録後に「予定」タブで直す前提）。
struct KindTemplate: Identifiable, Equatable, Sendable {
    var id: String { name }
    var name: String
    var colorHex: String
    var symbolName: String
    var note: String
    var specs: [RuleSpec]

    static let all: [KindTemplate] = [
        KindTemplate(
            name: String(localized: "燃えるゴミ"),
            colorHex: KindPalette.colors[0],
            symbolName: KindPalette.symbols[0],
            note: "",
            specs: [RuleSpec(frequency: .weekly, weekdays: [.monday, .thursday])]
        ),
        KindTemplate(
            name: String(localized: "資源ごみ"),
            colorHex: KindPalette.colors[3],
            symbolName: KindPalette.symbols[1],
            note: "",
            specs: [RuleSpec(frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth])]
        ),
        KindTemplate(
            name: String(localized: "プラスチック"),
            colorHex: KindPalette.colors[1],
            symbolName: KindPalette.symbols[2],
            note: "",
            specs: [RuleSpec(frequency: .weekly, weekdays: [.friday])]
        ),
        KindTemplate(
            name: String(localized: "缶・瓶"),
            colorHex: KindPalette.colors[2],
            symbolName: KindPalette.symbols[3],
            note: "",
            specs: [RuleSpec(frequency: .weekly, weekdays: [.tuesday])]
        ),
    ]

    /// 最初からチェックしておく構成。無料枠にちょうど収まる数だけ選んでおき、
    /// 初回から課金の壁に当たらないようにする。
    static var defaultSelection: Set<String> {
        Set(all.prefix(ProLimits.freeKinds).map(\.id))
    }

    var draft: KindDraft {
        var draft = KindDraft()
        draft.name = name
        draft.colorHex = colorHex
        draft.symbolName = symbolName
        draft.note = note
        draft.specs = specs
        return draft
    }
}
