import UIKit

/// PDF 書き出しの商品1件（情報と写真）。
struct PDFEntry {
    var row: ItemExportRow
    var images: [(label: String, data: Data)]
}

/// 商品の一覧と、商品ごとの写真付きページを A4 の PDF にする（Pro）。
/// 用途は引越し・火災保険の請求・家族への共有。
enum PDFExport {
    static let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    private static let margin: CGFloat = 40
    private static let rowsPerPage = 28

    static func make(entries: [PDFEntry], generatedAt: Date = Date()) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let sorted = entries.sorted { $0.row.purchaseDate < $1.row.purchaseDate }
        return renderer.pdfData { context in
            drawSummaryPages(sorted, generatedAt: generatedAt, context: context)
            for entry in sorted {
                context.beginPage()
                drawDetailPage(entry)
            }
        }
    }

    // MARK: - 一覧

    private static func drawSummaryPages(
        _ entries: [PDFEntry], generatedAt: Date, context: UIGraphicsPDFRendererContext
    ) {
        let width = pageRect.width - margin * 2
        let columns: [(title: String, ratio: CGFloat)] = [
            (String(localized: "商品名"), 0.34),
            (String(localized: "購入日"), 0.16),
            (String(localized: "メーカー保証"), 0.17),
            (String(localized: "延長保証"), 0.17),
            (String(localized: "金額"), 0.16),
        ]
        var start = 0
        repeat {
            context.beginPage()
            var y = margin
            if start == 0 {
                draw(String(localized: "保証書ポケット 商品一覧"), at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 20))
                y += 30
                draw(
                    String(localized: "\(Formatting.date(generatedAt)) 作成・\(entries.count)件"),
                    at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 10), color: .darkGray
                )
                y += 26
            }
            var x = margin
            for column in columns {
                draw(column.title, in: CGRect(x: x, y: y, width: width * column.ratio - 6, height: 16), font: .boldSystemFont(ofSize: 10))
                x += width * column.ratio
            }
            y += 18
            line(from: CGPoint(x: margin, y: y), to: CGPoint(x: pageRect.width - margin, y: y))
            y += 6

            let end = min(start + rowsPerPage, entries.count)
            for entry in entries[start..<end] {
                let row = entry.row
                let values = [
                    row.name,
                    Formatting.date(row.purchaseDate),
                    row.warrantyLastDay.map { Formatting.date($0) } ?? "—",
                    row.extendedLastDay.map { Formatting.date($0) } ?? "—",
                    row.price.map(Formatting.yen) ?? "—",
                ]
                x = margin
                for (column, value) in zip(columns, values) {
                    draw(value, in: CGRect(x: x, y: y, width: width * column.ratio - 6, height: 16), font: .systemFont(ofSize: 10))
                    x += width * column.ratio
                }
                y += 22
            }
            if entries.isEmpty {
                draw(String(localized: "登録された商品はありません"), at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 11))
            }
            start = end
        } while start < entries.count
    }

    // MARK: - 商品ごと

    private static func drawDetailPage(_ entry: PDFEntry) {
        let row = entry.row
        var y = margin
        draw(row.name, in: CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: 28), font: .boldSystemFont(ofSize: 20))
        y += 34

        var fields: [(String, String)] = [
            (String(localized: "カテゴリ"), row.category),
            (String(localized: "購入日"), Formatting.date(row.purchaseDate)),
        ]
        if let price = row.price { fields.append((String(localized: "金額"), Formatting.yen(price))) }
        if !row.storeName.isEmpty { fields.append((String(localized: "購入店"), row.storeName)) }
        if !row.maker.isEmpty { fields.append((String(localized: "メーカー"), row.maker)) }
        if !row.modelNumber.isEmpty { fields.append((String(localized: "型番"), row.modelNumber)) }
        if !row.serialNumber.isEmpty { fields.append((String(localized: "シリアル番号"), row.serialNumber)) }
        fields.append((String(localized: "メーカー保証"), row.warrantyLastDay.map { String(localized: "\(Formatting.date($0)) まで") } ?? "—"))
        if let extended = row.extendedLastDay {
            let provider = row.extendedProvider.isEmpty ? "" : "（\(row.extendedProvider)）"
            fields.append((String(localized: "延長保証"), String(localized: "\(Formatting.date(extended)) まで\(provider)")))
        }
        if !row.note.isEmpty { fields.append((String(localized: "メモ"), row.note)) }

        for (title, value) in fields {
            draw(title, in: CGRect(x: margin, y: y, width: 90, height: 16), font: .systemFont(ofSize: 11), color: .darkGray)
            draw(value, in: CGRect(x: margin + 96, y: y, width: pageRect.width - margin * 2 - 96, height: 16), font: .systemFont(ofSize: 11))
            y += 20
        }
        y += 12

        // 写真は2列×2段まで。
        let images = entry.images.prefix(4)
        guard !images.isEmpty else { return }
        let gap: CGFloat = 14
        let cellWidth = (pageRect.width - margin * 2 - gap) / 2
        let rows = CGFloat((images.count + 1) / 2)
        let cellHeight = min(320, (pageRect.height - margin - y - gap * (rows - 1)) / rows)
        for (index, image) in images.enumerated() {
            let column = CGFloat(index % 2)
            let rowIndex = CGFloat(index / 2)
            let cell = CGRect(
                x: margin + column * (cellWidth + gap),
                y: y + rowIndex * (cellHeight + gap),
                width: cellWidth,
                height: cellHeight
            )
            let imageRect = cell.insetBy(dx: 0, dy: 9).offsetBy(dx: 0, dy: 9)
            draw(image.label, in: CGRect(x: cell.minX, y: cell.minY, width: cell.width, height: 14), font: .systemFont(ofSize: 9), color: .darkGray)
            if let uiImage = UIImage(data: image.data) {
                uiImage.draw(in: aspectFit(uiImage.size, in: imageRect))
            }
        }
    }

    // MARK: - 描画ヘルパー

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .black) {
        (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    private static func draw(_ text: String, in rect: CGRect, font: UIFont, color: UIColor = .black) {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        (text as NSString).draw(
            in: rect, withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: style]
        )
    }

    private static func line(from start: CGPoint, to end: CGPoint) {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private static func aspectFit(_ size: CGSize, in rect: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return rect }
        let scale = min(rect.width / size.width, rect.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(
            x: rect.midX - fitted.width / 2, y: rect.minY, width: fitted.width, height: fitted.height
        )
    }
}
