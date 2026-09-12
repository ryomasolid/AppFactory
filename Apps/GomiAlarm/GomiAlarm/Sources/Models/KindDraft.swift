import Foundation
import SwiftData

/// ゴミの種類の編集内容（値型）。
///
/// SwiftData のモデルを直接編集すると、キャンセルしたつもりの変更や
/// 作りかけの空データがそのまま保存されてしまう。編集は必ずこの下書きの上で行い、
/// 「保存」を押したときだけモデルへ書き戻す。
struct KindDraft: Equatable, Sendable {
    var name: String = ""
    var colorHex: String = KindPalette.defaultColor
    var symbolName: String = KindPalette.defaultSymbol
    var note: String = ""
    /// nil なら設定の既定時刻を使う。
    var eveningTime: TimeOfDay?
    var morningTime: TimeOfDay?
    var specs: [RuleSpec] = []

    init() {}

    @MainActor
    init(_ kind: GarbageKind) {
        name = kind.name
        colorHex = kind.colorHex
        symbolName = kind.symbolName
        note = kind.note
        eveningTime = kind.eveningTime
        morningTime = kind.morningTime
        specs = kind.rules.map(\.spec)
    }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// 設定として成立しているルールだけ。作りかけ（曜日未選択など）は保存しない。
    var validSpecs: [RuleSpec] { specs.filter(\.isValid) }

    /// 保存できるか。名前と、成立している収集の周期が1つ以上必要。
    /// 周期の無い種類を作れてしまうと「登録したのに通知が来ない」になる。
    var isValid: Bool { !trimmedName.isEmpty && !validSpecs.isEmpty }

    /// モデルへ書き戻す。
    @MainActor
    func apply(to kind: GarbageKind, in context: ModelContext) {
        kind.name = trimmedName
        kind.colorHex = colorHex
        kind.symbolName = symbolName
        kind.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        kind.eveningTime = eveningTime
        kind.morningTime = morningTime

        // ルールは数が少ないので差分を取らず作り直す。取りこぼしや順序ずれが起きない。
        let old = kind.rules
        kind.rules = validSpecs.map(CollectionRule.init(spec:))
        for rule in old { context.delete(rule) }
    }
}
