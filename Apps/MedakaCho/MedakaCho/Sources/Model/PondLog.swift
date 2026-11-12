import Foundation
import SwiftData

/// 容器ごとの出来事1件。
@Model
final class PondLog {
    /// `LogKind` の rawValue。
    var kindCode: String = LogKind.memo.rawValue
    var at: Date = Date()
    var vessel: Vessel?
    /// 水換えで替えた割合（%）。
    var percent: Int?
    /// 水温（℃）。水温の記録以外にも、ついでに測ったときに入る。
    var celsius: Double?
    /// 落ちた・移した・入れた・採った卵 の数。
    var count: Int?
    /// 移した先の容器の名前（消されても記録が読めるよう文字で持つ）。
    var destination: String = ""
    var note: String = ""

    init(kind: LogKind, at: Date = Date(), vessel: Vessel?) {
        self.kindCode = kind.rawValue
        self.at = at
        self.vessel = vessel
    }

    var kind: LogKind { LogKind(rawValue: kindCode) ?? .memo }

    /// 一覧に出す一言。
    var summary: String {
        var parts: [String] = []
        switch kind {
        case .waterChange: if let percent { parts.append("\(percent)%") }
        case .loss, .moveOut, .addIn: if let count { parts.append("\(count)匹") }
        case .eggs: if let count { parts.append("\(count)個") }
        default: break
        }
        if kind == .moveOut, !destination.isEmpty { parts.append("→ \(destination)") }
        if let celsius { parts.append(String(format: "%.1f℃", celsius)) }
        if !note.isEmpty { parts.append(note) }
        return parts.joined(separator: "　")
    }
}

enum LogKind: String, CaseIterable, Identifiable {
    case feed, waterChange, topUp, clean, temperature, eggs, loss, moveOut, addIn, treatment, memo
    var id: String { rawValue }

    var label: String {
        switch self {
        case .feed: "えさ"
        case .waterChange: "水換え"
        case .topUp: "足し水"
        case .clean: "底掃除"
        case .temperature: "水温"
        case .eggs: "採卵"
        case .loss: "★になった"
        case .moveOut: "移した"
        case .addIn: "入れた"
        case .treatment: "塩水浴・薬"
        case .memo: "メモ"
        }
    }

    var symbol: String {
        switch self {
        case .feed: "leaf"
        case .waterChange: "arrow.triangle.2.circlepath"
        case .topUp: "drop"
        case .clean: "sparkles"
        case .temperature: "thermometer.medium"
        case .eggs: "circle.grid.2x2"
        case .loss: "star"
        case .moveOut: "arrow.right.circle"
        case .addIn: "plus.circle"
        case .treatment: "cross.case"
        case .memo: "square.and.pencil"
        }
    }

    /// 数を入れる記録か。
    var takesCount: Bool { [.eggs, .loss, .moveOut, .addIn].contains(self) }

    /// 容器の数を何匹ぶん動かすか（符号）。
    var headcountSign: Int {
        switch self {
        case .loss, .moveOut: -1
        case .addIn: 1
        default: 0
        }
    }

    /// 詳細画面のワンタップ欄に並べるもの（数を入れるものはシートで）。
    static let quick: [LogKind] = [.feed, .waterChange, .topUp, .clean, .temperature, .eggs, .loss, .moveOut, .addIn, .treatment, .memo]
}
