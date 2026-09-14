import Foundation
import SwiftData
import UIKit

/// 起動引数（スクリーンショット撮影・デモ用）。
/// すべてローカルの起動引数で制御し、通常のユーザー利用時には一切影響しない。
enum Launch {
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    /// 広告バナーと同意/ATT フローを止める（スクショ撮影用）。
    static var hideAds: Bool { args.contains("-hideAds") }
    /// デモの商品と写真を投入する。
    static var isDemo: Bool { args.contains("-demo") }
    /// 起動時にペイウォールを表示（既存アプリと引数名を揃える）。
    static var showPaywall: Bool { args.contains("-showPaywall") }
    /// オンボーディングを強制表示（スクショ撮影用）。
    static var forceOnboarding: Bool { args.contains("-forceOnboarding") }
    /// デモのレシートを読み取った状態の追加画面を開く。
    static var showScanResult: Bool { args.contains("-showScanResult") }
    /// デモの商品（`demoDetailName`）の詳細を開く。
    static var showDetail: Bool { args.contains("-showDetail") }

    /// オンボーディングの開始ページ（"scan" / "notifications"）。
    static var onboardingStep: String? { value(after: "-onboardingStep") }
    /// 起動時に選択するタブ（"timeline" / "settings"）。
    static var startTab: String? { value(after: "-startTab") }
    /// 一覧の検索欄に入れておく文字。
    static var searchText: String? { value(after: "-searchText") }

    static let demoDetailName = "冷蔵庫"
    static let demoStore = "サンプル電機 駅前店"

    private static func value(after flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    // MARK: - デモデータ

    private struct DemoItem {
        var name: String
        var category: ItemCategory
        var modelNumber: String
        /// 何か月前に買ったか（+ 日数の補正。正なら新しくなる）。
        var monthsAgo: Int
        var dayOffset: Int = 0
        var price: Int
        var store: String = Launch.demoStore
        var warranty: Int? = 12
        var extended: Int?
        var provider: String = ""
        var hasReceipt: Bool = false
    }

    /// いつ撮っても「まもなく終了」が2件出るよう、購入日は実行日から逆算する。
    private static let demoItems: [DemoItem] = [
        DemoItem(name: "ワイヤレスイヤホン", category: .av, modelNumber: "WE-3", monthsAgo: 14, price: 19800, store: "オンラインストア"),
        DemoItem(name: "ロボット掃除機", category: .living, modelNumber: "RB-S8", monthsAgo: 15, price: 59800),
        DemoItem(name: "テレビ 55V型", category: .av, modelNumber: "TV-55Q9", monthsAgo: 30, price: 139800, extended: 60, provider: "サンプル電機", hasReceipt: true),
        DemoItem(name: "エアコン（リビング）", category: .climate, modelNumber: "AC-4026R", monthsAgo: 22, price: 158000, extended: 60, provider: "サンプル電機"),
        DemoItem(name: "電子レンジ", category: .kitchen, modelNumber: "MR-30F", monthsAgo: 12, dayOffset: 12, price: 32800),
        DemoItem(name: "ドラム式洗濯乾燥機", category: .living, modelNumber: "WD-120X", monthsAgo: 12, dayOffset: 26, price: 219800, hasReceipt: true),
        DemoItem(name: "ソファ", category: .furniture, modelNumber: "3人掛け", monthsAgo: 10, price: 89000, store: "家具のサンプル", warranty: 60),
        DemoItem(name: "空気清浄機", category: .climate, modelNumber: "AP-70", monthsAgo: 9, price: 42800),
        DemoItem(name: "ノートパソコン", category: .digital, modelNumber: "NB-14", monthsAgo: 8, price: 198000, store: "オンラインストア", hasReceipt: true),
        DemoItem(name: "冷蔵庫", category: .kitchen, modelNumber: "RF-501W", monthsAgo: 5, price: 248000, extended: 60, provider: "サンプル電機", hasReceipt: true),
        DemoItem(name: "ミラーレスカメラ", category: .camera, modelNumber: "MC-Z50", monthsAgo: 3, price: 118000, hasReceipt: true),
        DemoItem(name: "炊飯器", category: .kitchen, modelNumber: "RC-10VS", monthsAgo: 0, dayOffset: -13, price: 24800, extended: 60, provider: "サンプル電機", hasReceipt: true),
    ]

    private static func purchaseDate(_ demo: DemoItem, today: Date, calendar: Calendar) -> Date {
        let month = calendar.date(byAdding: .month, value: -demo.monthsAgo, to: today) ?? today
        return calendar.date(byAdding: .day, value: demo.dayOffset, to: month) ?? month
    }

    /// 商品が未登録のときだけデモデータを投入する。
    @MainActor
    static func seedIfNeeded(_ context: ModelContext, calendar: Calendar = .current) {
        let count = (try? context.fetchCount(FetchDescriptor<Item>())) ?? 0
        guard count == 0 else { return }

        let today = calendar.startOfDay(for: Date())
        for demo in demoItems {
            let date = purchaseDate(demo, today: today, calendar: calendar)
            let item = Item(
                name: demo.name,
                modelNumber: demo.modelNumber,
                category: demo.category,
                purchaseDate: date,
                price: demo.price,
                storeName: demo.store,
                warrantyMonths: demo.warranty,
                extendedWarrantyMonths: demo.extended,
                extendedWarrantyProvider: demo.provider,
                createdAt: date
            )
            context.insert(item)

            var images: [(AttachmentKind, UIImage)] = [
                (.warranty, DemoImages.warrantyCard(
                    product: demo.name, model: demo.modelNumber, date: date,
                    months: demo.warranty ?? 12, store: demo.store, calendar: calendar
                )),
            ]
            if demo.hasReceipt {
                let lines = DemoImages.receiptLines(
                    store: demo.store, date: date, product: demo.name, model: demo.modelNumber,
                    price: demo.price, calendar: calendar
                )
                images.append((.receipt, DemoImages.receipt(lines: lines)))
            }
            for (order, (kind, image)) in images.enumerated() {
                guard let prepared = ImageProcessing.prepare(image) else { continue }
                let attachment = Attachment(
                    kind: kind, imageData: prepared.full, thumbnailData: prepared.thumbnail, sortOrder: order
                )
                context.insert(attachment)
                attachment.item = item
            }
        }
        try? context.save()
    }

    /// 「撮影して追加」で読み取った直後の下書き（スクショ撮影用）。
    /// 文字認識の結果の代わりにデモのレシートの文字列を ReceiptParser に通すので、読み取りの結果は本物と同じ。
    @MainActor
    static func demoScanDraft(calendar: Calendar = .current) -> ItemDraft {
        let today = calendar.startOfDay(for: Date())
        let date = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        let lines = DemoImages.receiptLines(
            store: demoStore, date: date, product: "コーヒーメーカー", model: "CM-5", price: 12980, calendar: calendar
        )
        var draft = ItemDraft()
        draft.name = "コーヒーメーカー"
        draft.category = .kitchen
        if let prepared = ImageProcessing.prepare(DemoImages.receipt(lines: lines)) {
            draft.images = [DraftImage(imageData: prepared.full, thumbnailData: prepared.thumbnail, kind: .receipt)]
        }
        let card = DemoImages.warrantyCard(
            product: "コーヒーメーカー", model: "CM-5", date: date, months: 12, store: demoStore, calendar: calendar
        )
        if let prepared = ImageProcessing.prepare(card) {
            draft.images.append(DraftImage(imageData: prepared.full, thumbnailData: prepared.thumbnail, kind: .warranty))
        }
        draft.apply(ReceiptParser.parse(lines: lines.map(\.recognizedText), calendar: calendar))
        return draft
    }
}

/// デモ用の画像（レシート・保証書）をコードで描く。実在の店舗名・ロゴは使わない。
enum DemoImages {
    /// レシートの1行。amount があれば右寄せで描く。
    struct ReceiptLine {
        var text: String
        var amount: String?
        var bold = false

        /// 文字認識で1行にまとめたときの文字列（左の文字と右寄せの金額がスペースでつながる）。
        var recognizedText: String {
            [text, amount].compactMap { $0 }.joined(separator: " ")
        }
    }

    static func receiptLines(
        store: String, date: Date, product: String, model: String, price: Int, calendar: Calendar
    ) -> [ReceiptLine] {
        let c = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        let weekday = weekdays[((c.weekday ?? 1) - 1) % 7]
        let paid = ((price / 10000) + 1) * 10000
        return [
            ReceiptLine(text: store, bold: true),
            ReceiptLine(text: "TEL 00-0000-0000"),
            ReceiptLine(text: "\(c.year ?? 0)年\(c.month ?? 0)月\(c.day ?? 0)日(\(weekday)) 14:32"),
            ReceiptLine(text: "--------------------------------"),
            ReceiptLine(text: product, amount: Formatting.yen(price)),
            ReceiptLine(text: "  \(model)"),
            ReceiptLine(text: "--------------------------------"),
            ReceiptLine(text: "小計", amount: Formatting.yen(price)),
            ReceiptLine(text: "(内消費税等", amount: Formatting.yen(price / 11) + ")"),
            ReceiptLine(text: "合計", amount: Formatting.yen(price), bold: true),
            ReceiptLine(text: "お預り", amount: Formatting.yen(paid)),
            ReceiptLine(text: "お釣り", amount: Formatting.yen(paid - price)),
            ReceiptLine(text: ""),
            ReceiptLine(text: "お買い上げありがとうございました"),
        ]
    }

    static func receipt(lines: [ReceiptLine]) -> UIImage {
        let size = CGSize(width: 720, height: 1040)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 0.985, green: 0.98, blue: 0.965, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            var y: CGFloat = 70
            for line in lines {
                let font = UIFont.monospacedSystemFont(ofSize: 30, weight: line.bold ? .bold : .regular)
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor(white: 0.15, alpha: 1)]
                (line.text as NSString).draw(at: CGPoint(x: 60, y: y), withAttributes: attributes)
                if let amount = line.amount {
                    let width = (amount as NSString).size(withAttributes: attributes).width
                    (amount as NSString).draw(at: CGPoint(x: size.width - 60 - width, y: y), withAttributes: attributes)
                }
                y += 56
            }
        }
    }

    static func warrantyCard(
        product: String, model: String, date: Date, months: Int, store: String, calendar: Calendar
    ) -> UIImage {
        let size = CGSize(width: 1040, height: 720)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 0.99, green: 0.985, blue: 0.97, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let border = UIBezierPath(rect: CGRect(x: 30, y: 30, width: size.width - 60, height: size.height - 60))
            UIColor(red: 0.29, green: 0.33, blue: 0.64, alpha: 1).setStroke()
            border.lineWidth = 6
            border.stroke()

            let ink = UIColor(white: 0.15, alpha: 1)
            let title: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 60), .foregroundColor: ink]
            let label: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 30), .foregroundColor: UIColor.darkGray]
            let value: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 34), .foregroundColor: ink]
            let small: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 22), .foregroundColor: UIColor.gray]

            let heading = "保 証 書" as NSString
            let headingWidth = heading.size(withAttributes: title).width
            heading.draw(at: CGPoint(x: (size.width - headingWidth) / 2, y: 70), withAttributes: title)

            let c = calendar.dateComponents([.year, .month, .day], from: date)
            let rows: [(String, String)] = [
                ("品名", product),
                ("型式", model),
                ("お買い上げ日", "\(c.year ?? 0)年 \(c.month ?? 0)月 \(c.day ?? 0)日"),
                ("保証期間", "お買い上げ日から \(Formatting.term(months: months))"),
                ("販売店", store),
            ]
            var y: CGFloat = 190
            for (name, text) in rows {
                (name as NSString).draw(at: CGPoint(x: 90, y: y + 4), withAttributes: label)
                (text as NSString).draw(at: CGPoint(x: 330, y: y), withAttributes: value)
                let rule = UIBezierPath()
                rule.move(to: CGPoint(x: 90, y: y + 52))
                rule.addLine(to: CGPoint(x: size.width - 90, y: y + 52))
                UIColor(white: 0.8, alpha: 1).setStroke()
                rule.lineWidth = 2
                rule.stroke()
                y += 80
            }
            ("本書は記載内容で無料修理を行うことをお約束するものです。本書は再発行いたしませんので大切に保管してください。" as NSString)
                .draw(in: CGRect(x: 90, y: y + 10, width: size.width - 180, height: 80), withAttributes: small)
        }
    }
}
