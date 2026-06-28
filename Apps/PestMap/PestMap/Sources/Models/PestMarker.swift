import Foundation
import SwiftData

/// 対策・設置場所のマーカー。位置はキャンバスに対する 0...1 の正規化座標で持ち、
/// 画像サイズや表示倍率に依らず同じ位置を指せるようにする。
@Model
final class PestMarker {
    var x: Double
    var y: Double
    var kindRaw: String
    var note: String
    /// 次回の対策・設置の予定日時。設定すると通知をスケジュールする。
    var nextActionDate: Date?
    /// スケジュール済みローカル通知の識別子（キャンセル用）。
    var notificationID: String?
    var plan: FloorPlan?

    init(x: Double, y: Double, kind: MarkerKind = .blackCap, note: String = "") {
        self.x = x
        self.y = y
        self.kindRaw = kind.rawValue
        self.note = note
    }

    var kind: MarkerKind {
        get { MarkerKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }
}
