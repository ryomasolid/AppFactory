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
            HStack(spacing: 18) {
                SpriteCache.image(.hero1).resizable().interpolation(.none).frame(width: 96, height: 96)
                if let boss = summary.lastBoss {
                    SpriteCache.image(SpriteID(enemy: boss)).resizable().interpolation(.none).frame(width: 96, height: 96)
                }
            }
            RetroWindow {
                Text("\(summary.name)  LV \(summary.level)")
                Text("いま: \(summary.regionName)")
                Text("たおした ぬし: \(summary.bosses) / \(summary.bossTotal)")
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
    let bosses: Int
    let bossTotal: Int
    let stamps: Int
    let stampTotal: Int
    let lastBoss: EnemyKind?
    let cleared: Bool

    var headline: String { cleared ? "北海道に へいわを とりもどした！" : "北海道を 冒険中！" }

    /// シェアに そえる 文。
    var message: String {
        "「地理の勇者 RPG」で \(headline) LV\(level)・ぬし \(bosses)/\(bossTotal)・めいしょスタンプ \(stamps)/\(stampTotal) #地理の勇者 \(Self.storeURL)"
    }

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
