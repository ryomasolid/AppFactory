import Foundation
import SwiftData
import UIKit

/// 起動引数（スクリーンショット撮影・デモ用）。通常の利用には一切影響しない。
enum Launch {
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    /// 広告バナーと同意/ATT フローを止める（スクショ撮影用）。
    static var hideAds: Bool { args.contains("-hideAds") }
    /// デモのプロフィールと記録を投入する（旧版の引き継ぎより先に入るので、撮影用シミュレーター専用）。
    static var isDemo: Bool { args.contains("-demo") }
    /// 記録の入力画面を開いた状態で起動する。
    static var showRecordEntry: Bool { args.contains("-showRecordEntry") }
    /// 最新の記録のシェアカードを開いた状態で起動する。
    static var showShareCard: Bool { args.contains("-showShareCard") }
    /// 起動時に選択するタブ（"home" / "diary" / "profile" / "settings"）。
    static var startTab: String? { value(after: "-startTab") }
    /// デモ写真に使う本物の写真のフォルダ（Mac 側のパス。`Store/screenshots/photos`）。無ければ絵文字の画像で代用する。
    static var demoPhotos: String? { value(after: "-demoPhotos") }

    /// デモの今日の体重を1割ほど減らし、ホームの「体重が減っています」を出す（スクショ撮影用）。
    static var demoWeightDrop: Bool { args.contains("-demoWeightDrop") }

    private static func value(after flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    // MARK: - デモデータ

    private static let memos = [
        "回し車でずっと走ってた🎡",
        "ひまわりの種をほっぺにぱんぱんに詰めてた",
        "手のひらでお昼寝してくれた😴",
        "はじめて名前を呼んだら出てきた！",
        "", "",
    ]
    /// 写真のある日のメモ（`Store/screenshots/photos/memory-N.jpg` の中身に合わせてある）。
    private static let photoMemos = [
        0: "いちごをもらってごきげん🍓",
        4: "ブランケットからひょっこり",
        9: "おうちでぐっすりお昼寝😴",
        15: "たまごハウスがお気に入り🥚",
    ]
    private static let foods = ["いつものペレット 4g", "ペレット 4g\nブロッコリー", "シードミックス 5g", "ペレット 4g\nにんじん"]
    private static let cleanings: [[String]] = [["partial"], ["toilet_sand"], [], ["partial", "water_bottle"], [], ["full_wash", "bedding"]]

    /// 記録が無いときだけデモデータを入れる。日付は実行日から逆算し、いつ撮っても「今日の記録」がある状態にする。
    @MainActor
    static func seedIfNeeded(_ context: ModelContext, calendar: Calendar = .current) {
        let count = (try? context.fetchCount(FetchDescriptor<DiaryRecord>())) ?? 0
        guard count == 0 else { return }

        let today = calendar.startOfDay(for: Date())
        func daysAgo(_ n: Int) -> Date { calendar.date(byAdding: .day, value: -n, to: today) ?? today }

        for old in (try? context.fetch(FetchDescriptor<HamsterProfile>())) ?? [] { context.delete(old) }
        context.insert(HamsterProfile(
            name: String(localized: "もち"), species: "ジャンガリアンハムスター",
            birthDate: daysAgo(290), welcomeDate: daysAgo(230),
            photoPath: demoPhoto(named: "demo-avatar", real: "avatar", hue: 0.07)
        ))

        for i in 0..<80 {
            // 少しずつ増えて落ち着く体重カーブ＋小さな揺らぎ。
            let base = 34 + 6 * (1 - exp(-Double(80 - i) / 30))
            let weight = demoWeightDrop && i == 0 ? 35.4 : ((base + sin(Double(i) * 0.9) * 0.35) * 10).rounded() / 10
            let date = daysAgo(i)
            let created = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: date) ?? date
            context.insert(DiaryRecord(
                key: "demo-\(i)", date: date, weight: i % 3 == 2 ? nil : weight,
                food: foods[i % foods.count], cleaningKeys: cleanings[i % cleanings.count],
                memo: photoMemos[i] ?? memos[i % memos.count],
                photoPath: photoMemos[i] == nil ? nil : demoPhoto(named: "demo-\(i)", real: "memory-\(i)", hue: 0.05 + Double(i) * 0.01),
                createdAt: created, updatedAt: created
            ))
        }

        let lastDays = ["pellet_open": 22, "bedding_change": 11, "water_filter": 2, "wheel_clean": 9]
        for reminder in (try? context.fetch(FetchDescriptor<SupplyReminder>())) ?? [] {
            reminder.lastDate = lastDays[reminder.key].map(daysAgo)
        }
        try? context.save()
    }

    /// デモの写真。`-demoPhotos` のフォルダに `<real>.jpg` があればそれを、無ければやわらかいグラデーション画像を使う。
    private static func demoPhoto(named name: String, real: String, hue: Double) -> String? {
        if let dir = demoPhotos, let data = try? Data(contentsOf: URL(filePath: dir).appending(path: "\(real).jpg")) {
            return save(data, named: name)
        }
        let size = CGSize(width: 1200, height: 900)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [
                UIColor(hue: hue, saturation: 0.25, brightness: 1, alpha: 1).cgColor,
                UIColor(hue: hue + 0.04, saturation: 0.45, brightness: 0.95, alpha: 1).cgColor,
            ] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            }
            let text = "🐹" as NSString
            let font = UIFont.systemFont(ofSize: 420)
            let textSize = text.size(withAttributes: [.font: font])
            text.draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2), withAttributes: [.font: font])
        }
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        return save(data, named: name)
    }

    private static func save(_ data: Data, named name: String) -> String? {
        let dir = PhotoStore.documents.appending(path: PhotoStore.folder)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: dir.appending(path: "\(name).jpg"))
        return "\(PhotoStore.folder)/\(name).jpg"
    }
}
