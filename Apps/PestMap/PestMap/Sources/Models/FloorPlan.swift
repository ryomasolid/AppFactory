import Foundation
import SwiftData

/// 間取り。背景に間取り図の写真を持つことも、写真なし（一から作成）も可能。
@Model
final class FloorPlan {
    var name: String
    var createdAt: Date
    /// 間取り図の背景写真。一から作る場合は nil。大きいので外部ストレージに保存。
    @Attribute(.externalStorage) var imageData: Data?
    /// 配置されたマーカー。間取り削除時に一緒に削除する。
    @Relationship(deleteRule: .cascade, inverse: \PestMarker.plan)
    var markers: [PestMarker]

    init(name: String, imageData: Data? = nil) {
        self.name = name
        self.createdAt = Date()
        self.imageData = imageData
        self.markers = []
    }
}
