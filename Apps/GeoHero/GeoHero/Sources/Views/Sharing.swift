import SwiftUI
import UIKit

/// 冒険の きろくカード。SNS に シェアする画像にする。
struct AdventureCard: View {
    let summary: AdventureSummary

    var body: some View {
        VStack(spacing: 14) {
            Text("地理の勇者 RPG")
                .font(Retro.font(30))
                .foregroundStyle(Retro.accent)
            Text("〜 北海道・東北 編 〜")
                .font(Retro.font(14))
                .foregroundStyle(Retro.dim)
            HStack(spacing: 18) {
                SpriteCache.image(.hero1).resizable().interpolation(.none).frame(width: 96, height: 96)
                if let boss = summary.lastBoss {
                    SpriteCache.image(SpriteID(enemy: boss)).resizable().interpolation(.none).frame(width: 96, height: 96)
                }
            }
            RetroWindow {
                Text("\(summary.name)  LV \(summary.level)")
                Text("いま: \(summary.regionName)")
                Text("もどった まつり: \(summary.festivals) / \(Region.tohoku.count)")
                Text("たおした ぬし: \(summary.bosses) / \(summary.bossTotal)")
                Text("まもの ずかん: \(summary.book) / \(summary.bookTotal)")
                Text("めいしょスタンプ: \(summary.stamps) / \(summary.stampTotal)")
            }
            Text(summary.headline)
                .font(Retro.font(18))
                .foregroundStyle(.white)
            Text("#地理の勇者")
                .font(Retro.font(14))
                .foregroundStyle(Retro.dim)
        }
        .padding(28)
        .frame(width: 540)
        .background(Color.black)
    }
}

/// きろくカードに 出す中身。
struct AdventureSummary: Equatable {
    let name: String
    let level: Int
    let regionName: String
    let festivals: Int
    let bosses: Int
    let bossTotal: Int
    let stamps: Int
    let stampTotal: Int
    let book: Int
    let bookTotal: Int
    let lastBoss: EnemyKind?
    let cleared: Bool
    /// 恐山の 裏ボスまで 倒した。
    let mastered: Bool

    var headline: String {
        if mastered { return "しんの ちりの ゆうしゃに なった！" }
        if cleared { return "東北の まつりを ぜんぶ とりもどした！" }
        return Region.tohoku.contains { $0.banner.name == regionName } ? "東北を 冒険中！" : "北海道を 冒険中！"
    }

    /// シェアに そえる 文。
    var message: String {
        "「地理の勇者 RPG」で \(headline) LV\(level)・ぬし \(bosses)/\(bossTotal)・ずかん \(book)/\(bookTotal) #地理の勇者 \(Self.storeURL)"
    }

    /// App Store の ページ（地理の勇者 RPG）。
    static let storeURL = "https://apps.apple.com/jp/app/id6813561253"
}

/// シェアの 画面を 出す（ChoiceList の 行から 呼べるよう、UIKit で 上に かぶせる）。
@MainActor
enum ShareSheet {
    static func present(_ summary: AdventureSummary) {
        let renderer = ImageRenderer(content: AdventureCard(summary: summary))
        renderer.scale = 2
        var items: [Any] = [summary.message]
        if let image = renderer.uiImage { items.insert(image, at: 0) }
        let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              var top = scene.keyWindow?.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }
        sheet.popoverPresentationController?.sourceView = top.view
        top.present(sheet, animated: true)
    }
}
