import Foundation
import SwiftData

/// 商品に添付する写真（保証書・レシート・取扱説明書など）。
///
/// 画像は SwiftData の外部ストレージに持つ。ファイルパスを自前で管理しないので、
/// 商品を消したときに写真だけ残る（削除漏れ）ことが起きない。
@Model
final class Attachment {
    var id: UUID = UUID()
    var kindRaw: String = AttachmentKind.warranty.rawValue
    /// 長辺2000pxの JPEG。詳細と全画面表示・PDF に使う。
    @Attribute(.externalStorage) var imageData: Data?
    /// 長辺300pxの JPEG。一覧ではこちらだけを読む。
    @Attribute(.externalStorage) var thumbnailData: Data?
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    var item: Item?

    init(
        id: UUID = UUID(),
        kind: AttachmentKind,
        imageData: Data?,
        thumbnailData: Data?,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var kind: AttachmentKind {
        get { AttachmentKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }
}
