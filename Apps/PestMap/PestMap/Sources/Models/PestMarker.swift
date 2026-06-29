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
    /// 繰り返し周期（「完了」時に次回を自動算出）。
    var repeatRaw: String = RepeatInterval.none.rawValue
    /// 対象の害虫の種類タグ。
    var pestTypeRaw: String = PestType.none.rawValue
    /// 設置場所の実物写真（任意）。
    @Attribute(.externalStorage) var photoData: Data?
    /// 最後に実施した日時（履歴の要約）。
    var lastDoneDate: Date?
    /// 実施履歴。マーカー削除時に一緒に削除する。
    @Relationship(deleteRule: .cascade, inverse: \DoneRecord.marker)
    var records: [DoneRecord] = []
    var plan: FloorPlan?

    init(x: Double, y: Double, kind: MarkerKind = .blackCap, note: String = "") {
        self.x = x
        self.y = y
        self.kindRaw = kind.rawValue
        self.note = note
        self.repeatRaw = kind.defaultRepeat.rawValue
    }

    var kind: MarkerKind {
        get { MarkerKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var repeatInterval: RepeatInterval {
        get { RepeatInterval(rawValue: repeatRaw) ?? .none }
        set { repeatRaw = newValue.rawValue }
    }

    var pestType: PestType {
        get { PestType(rawValue: pestTypeRaw) ?? .none }
        set { pestTypeRaw = newValue.rawValue }
    }
}
