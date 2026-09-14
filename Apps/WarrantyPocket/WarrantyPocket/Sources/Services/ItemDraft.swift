import UIKit

/// 読み取りで入れた項目。
enum ReadField: Hashable, Sendable {
    case purchaseDate
    case price
    case storeName
}

/// まだ保存していない写真。
struct DraftImage: Identifiable, Sendable {
    let id = UUID()
    var imageData: Data
    var thumbnailData: Data
    var kind: AttachmentKind
}

/// 追加画面に渡す下書き（撮影・写真の読み取り結果）。
struct ItemDraft: Identifiable, Sendable {
    let id = UUID()
    var name = ""
    var category: ItemCategory = .other
    var purchaseDate: Date?
    var price: Int?
    var storeName = ""
    var images: [DraftImage] = []
    var readFields: Set<ReadField> = []

    /// 読み取った値を、まだ入っていない項目にだけ入れる。
    mutating func apply(_ fields: ReceiptFields) {
        if purchaseDate == nil, let date = fields.purchaseDate {
            purchaseDate = date
            readFields.insert(.purchaseDate)
        }
        if price == nil, let price = fields.price {
            self.price = price
            readFields.insert(.price)
        }
        if storeName.isEmpty, let store = fields.storeName {
            storeName = store
            readFields.insert(.storeName)
        }
    }
}

enum DraftBuilder {
    /// 文字認識にかけるのは先頭3枚まで（保証書が何ページもあっても、日付と金額は最初の数枚にある）。
    static let maxReadPages = 3

    /// 写真を保存用に縮小し、文字を読み取って下書きを作る。
    @MainActor
    static func make(from images: [UIImage]) async -> ItemDraft {
        var draft = ItemDraft()
        let result = await read(images)
        draft.images = result.images
        draft.apply(result.fields)
        return draft
    }

    @MainActor
    static func read(_ images: [UIImage]) async -> (images: [DraftImage], fields: ReceiptFields) {
        var drafts: [DraftImage] = []
        var fields = ReceiptFields()
        for (index, image) in images.enumerated() {
            guard let prepared = ImageProcessing.prepare(image) else { continue }
            var kind: AttachmentKind = .warranty
            if index < maxReadPages {
                let lines = await TextRecognizer.lines(fromImageData: prepared.full)
                kind = ReceiptParser.documentKind(lines: lines)
                fields.fillMissing(from: ReceiptParser.parse(lines: lines))
            }
            drafts.append(DraftImage(imageData: prepared.full, thumbnailData: prepared.thumbnail, kind: kind))
        }
        return (drafts, fields)
    }
}
