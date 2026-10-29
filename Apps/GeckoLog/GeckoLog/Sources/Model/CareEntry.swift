import Foundation
import SwiftData

/// お世話の1回ぶん。1日に何件でもつけられる（ごはんと脱皮が同じ日、など）。
/// 種類ごとに使う項目だけが入る。
@Model
final class CareEntry {
    var uid: UUID = UUID()
    var kindCode: String = CareKind.memo.rawValue
    var occurredAt: Date = Date()
    var gecko: Gecko?

    // ごはん
    var feederCode: String = ""
    var feederCount: Int = 0
    /// 食べなかった（拒食）なら false。
    var accepted: Bool = true
    /// カルシウム・ビタミンのダスティング。
    var dusted: Bool = false

    // 脱皮
    /// 指先やしっぽの先に皮が残った。
    var skinLeftover: Bool = false

    // 体重
    var grams: Double?

    // うんち
    var droppingCode: String = ""

    // 温湿度
    var warmSideC: Double?
    var humidityPercent: Double?

    var note: String = ""

    init(kind: CareKind, occurredAt: Date = Date(), gecko: Gecko?) {
        self.kindCode = kind.rawValue
        self.occurredAt = occurredAt
        self.gecko = gecko
    }

    var kind: CareKind { CareKind(rawValue: kindCode) ?? .memo }
    var feeder: Feeder? { Feeder(rawValue: feederCode) }
    var dropping: Dropping? { Dropping(rawValue: droppingCode) }

    /// 一覧に出す1行の要約。
    var summary: String {
        switch kind {
        case .feeding:
            guard accepted else { return "食べなかった" }
            var parts: [String] = []
            if let feeder { parts.append(feederCount > 0 ? "\(feeder.label) ×\(feederCount)" : feeder.label) }
            if dusted { parts.append("ダスティング") }
            return parts.isEmpty ? "食べた" : parts.joined(separator: "・")
        case .shed:
            return skinLeftover ? "皮が残った" : "きれいに脱げた"
        case .weight:
            return grams.map { Self.gramText($0) } ?? "—"
        case .dropping:
            return dropping?.label ?? "うんち"
        case .climate:
            var parts: [String] = []
            if let warmSideC { parts.append(String(format: "%.1f℃", warmSideC)) }
            if let humidityPercent { parts.append(String(format: "%.0f%%", humidityPercent)) }
            return parts.isEmpty ? "—" : parts.joined(separator: " / ")
        case .cleaning, .vet, .memo:
            return note.isEmpty ? kind.label : note
        }
    }

    static func gramText(_ grams: Double) -> String {
        grams.rounded() == grams ? String(format: "%.0fg", grams) : String(format: "%.1fg", grams)
    }
}

enum CareKind: String, CaseIterable, Identifiable {
    case feeding, shed, weight, dropping, climate, cleaning, vet, memo
    var id: String { rawValue }

    var label: String {
        switch self {
        case .feeding: "ごはん"
        case .shed: "脱皮"
        case .weight: "体重"
        case .dropping: "うんち"
        case .climate: "温湿度"
        case .cleaning: "そうじ"
        case .vet: "通院"
        case .memo: "メモ"
        }
    }

    var symbol: String {
        switch self {
        case .feeding: "fork.knife"
        case .shed: "sparkles"
        case .weight: "scalemass"
        case .dropping: "leaf"
        case .climate: "thermometer.medium"
        case .cleaning: "bubbles.and.sparkles"
        case .vet: "cross.case"
        case .memo: "square.and.pencil"
        }
    }
}

/// 生き餌・人工フード。
enum Feeder: String, CaseIterable, Identifiable {
    case cricket, dubia, redRoach, mealworm, superworm, honeyworm, silkworm, gel, pellet
    var id: String { rawValue }

    var label: String {
        switch self {
        case .cricket: "コオロギ"
        case .dubia: "デュビア"
        case .redRoach: "レッドローチ"
        case .mealworm: "ミルワーム"
        case .superworm: "ジャイアントミル"
        case .honeyworm: "ハニーワーム"
        case .silkworm: "シルクワーム"
        case .gel: "レオパゲル"
        case .pellet: "人工フード"
        }
    }

    /// 人工フードは「匹」ではなく「粒・回」で数える。
    var counter: String {
        switch self {
        case .gel: "回"
        case .pellet: "粒"
        default: "匹"
        }
    }
}

enum Dropping: String, CaseIterable, Identifiable {
    case normal, soft, urateOnly, unusual
    var id: String { rawValue }

    var label: String {
        switch self {
        case .normal: "ふつう"
        case .soft: "ゆるい"
        case .urateOnly: "尿酸だけ"
        case .unusual: "いつもと違う"
        }
    }
}
