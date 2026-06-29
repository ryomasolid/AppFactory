import Foundation
import SwiftData

/// 対策・設置を「実施した」記録。完了するたびに1件追加され、履歴になる。
@Model
final class DoneRecord {
    var date: Date
    var marker: PestMarker?

    init(date: Date = Date()) {
        self.date = date
    }
}
