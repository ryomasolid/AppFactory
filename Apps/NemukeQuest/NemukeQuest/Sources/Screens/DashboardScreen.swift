import StoreKit
import SwiftUI

/// ひとつだけの画面。上にプレイヤーの状態、下にクエスト・実績・ショップを切り替えて出す。
struct DashboardScreen: View {
    enum Tab: Int, CaseIterable {
        case quest, achievements, shop

        var label: String {
            switch self {
            case .quest: "クエスト"
            case .achievements: "実績"
            case .shop: "ショップ"
            }
        }

        var symbol: String {
            switch self {
            case .quest: "bolt.shield.fill"
            case .achievements: "trophy.fill"
            case .shop: "cart.fill"
            }
        }
    }

    @Environment(Game.self) private var game
    @Environment(\.requestReview) private var requestReview
    @State private var tab = Sample.firstTab
    @State private var notice: Notice?
    @State private var consent = AdConsent()
    @State private var bonus = RewardedBonus()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    PlayerCard(player: game.player)
                    tabBar
                    switch tab {
                    case .quest: QuestSection(onComplete: complete)
                    case .achievements: AchievementSection(player: game.player)
                    case .shop: ShopSection(onBuy: buy)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                // iPad では横に広がりすぎないよう、iPhone くらいの幅で真ん中に置く。
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Palette.background.ignoresSafeArea())
            .adStrip(consent)
            .navigationTitle("ねむけクエスト ⚔️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.background, for: .navigationBar)
            .alert(notice?.title ?? "", isPresented: Binding(get: { notice != nil }, set: { if !$0 { closeNotice() } })) {
                if notice?.offersBonus == true && bonus.isReady {
                    Button("広告を見てボーナス（+\(RewardedBonus.exp) EXP / +\(RewardedBonus.gold) G）") { watchBonus() }
                }
                Button("OK", role: .cancel) { closeNotice() }
            } message: {
                Text(notice?.message ?? "")
            }
        }
        .task {
            await consent.begin()
            await bonus.start(consent: consent)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases, id: \.self) { item in
                Button {
                    withAnimation(.snappy) { tab = item }
                } label: {
                    Label(item.label, systemImage: item.symbol)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(tab == item ? Palette.text : Palette.textMuted)
                        .background(tab == item ? Palette.primary : .clear, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.border))
        .sensoryFeedback(.selection, trigger: tab)
    }

    // MARK: - お知らせ

    private struct Notice {
        let title: String
        let message: String
        var askReviewAfter = false
        /// クエスト達成・討伐のあとだけ「広告を見てボーナス」を出す（旧版と同じ）。
        var offersBonus = false
    }

    private func complete(_ quest: Quest) {
        guard let (outcome, fresh) = game.complete(quest) else { return }
        let unlocked = fresh.isEmpty ? "" : "\n\n🏆 実績「\(fresh.map(\.title).joined(separator: "」「"))」を解除！"
        switch outcome {
        case let .hit(damage, quest):
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            notice = Notice(
                title: "クエスト達成！",
                message: "デーモンに \(damage) ダメージ！\n+\(quest.exp) EXP / +\(quest.gold) G を獲得" + unlocked,
                offersBonus: true
            )
        case let .defeated(bonusExp, bonusGold, _):
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            notice = Notice(
                title: "🎉 デーモン討伐！",
                message: "スリープデーモンを倒した！\n討伐ボーナス +\(bonusExp) EXP / +\(bonusGold) G" + unlocked,
                askReviewAfter: true,
                offersBonus: true
            )
        }
    }

    private func buy(_ item: ShopItem) {
        if game.buy(item) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            notice = Notice(
                title: "購入成功！",
                message: item == .expBoost ? "獲得EXPが1.5倍になりました！" : "ストリークフリーズを手に入れた！連続記録が守られます。"
            )
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            notice = Notice(title: "購入できません", message: "ゴールドが足りません。")
        }
    }

    private func watchBonus() {
        notice = nil
        Task {
            guard await bonus.show() else { return }
            let fresh = game.grantBonus(exp: RewardedBonus.exp, gold: RewardedBonus.gold)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            let unlocked = fresh.isEmpty ? "" : "\n\n🏆 実績「\(fresh.map(\.title).joined(separator: "」「"))」を解除！"
            notice = Notice(title: "ボーナス獲得！", message: "広告を見てくれてありがとう！\n+\(RewardedBonus.exp) EXP / +\(RewardedBonus.gold) G を獲得" + unlocked)
        }
    }

    private func closeNotice() {
        let ask = notice?.askReviewAfter == true
        notice = nil
        guard ask, ReviewAsk.shouldAsk(demonsDefeated: game.player.demonsDefeated) else { return }
        ReviewAsk.markAsked()
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            requestReview()
        }
    }
}

// MARK: - プレイヤーの状態

struct PlayerCard: View {
    let player: PlayerState

    var body: some View {
        let buddy = Catalog.buddy(level: player.level)
        let next = Catalog.nextBuddy(level: player.level)
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 10) {
                    Text(buddy.emoji).font(.system(size: 34))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(buddy.title)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(Palette.text)
                        Text(next.map { "Lv.\($0.minLevel)で進化 \($0.emoji)" } ?? "最終進化！")
                            .font(.caption2)
                            .foregroundStyle(Palette.textMuted)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 4)
                HStack(spacing: 6) {
                    chip("🔥 \(player.streak)日", tint: Palette.fire, fill: Palette.fire.opacity(0.15))
                    chip("🪙 \(player.gold) G", tint: Palette.gold, fill: Palette.surfaceLight)
                    ShareLink(item: shareText(buddy)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption.bold())
                            .foregroundStyle(Palette.textMuted)
                            .padding(7)
                            .background(Palette.surfaceLight, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityLabel("シェア")
                }
            }
            HStack(spacing: 12) {
                Text("Lv.\(player.level)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Palette.primary))
                VStack(alignment: .leading, spacing: 6) {
                    Text("EXP \(player.currentExp) / \(player.expToNextLevel)")
                        .font(.caption)
                        .foregroundStyle(Palette.textMuted)
                        .contentTransition(.numericText())
                    Meter(ratio: Double(player.currentExp) / Double(max(player.expToNextLevel, 1)), tint: Palette.accent)
                }
            }
        }
        .padding(16)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.border))
        .padding(.top, 8)
    }

    private func chip(_ text: String, tint: Color, fill: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(fill, in: RoundedRectangle(cornerRadius: 10))
            .fixedSize()
    }

    private func shareText(_ buddy: BuddyStage) -> String {
        "🔥 連続\(player.streak)日活動中！ Lv.\(player.level)「\(buddy.title)」\(buddy.emoji) 眠気をクエストで撃退してます ⚔️ #ねむけクエスト #NemukeQuest"
    }
}
