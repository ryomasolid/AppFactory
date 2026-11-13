import SwiftUI

// MARK: - クエスト

struct QuestSection: View {
    @Environment(Game.self) private var game
    let onComplete: (Quest) -> Void

    var body: some View {
        VStack(spacing: 12) {
            demonPanel
            HStack {
                Text("クエスト一覧")
                    .font(.title3.bold())
                    .foregroundStyle(Palette.text)
                Spacer()
                Button {
                    withAnimation(.snappy) { game.shuffle() }
                } label: {
                    Label("再抽選", systemImage: "shuffle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Palette.surfaceLight, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
            if game.demon == nil {
                Text("デーモンを呼び出すと、クエストで攻撃できます")
                    .font(.caption)
                    .foregroundStyle(Palette.textFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(game.quests) { quest in
                QuestCard(quest: quest, isActive: game.demon != nil) { onComplete(quest) }
            }
        }
    }

    @ViewBuilder
    private var demonPanel: some View {
        if let demon = game.demon {
            let ratio = Double(demon.hp) / Double(max(demon.maxHp, 1))
            VStack(spacing: 6) {
                Text(ratio > 0.5 ? "😈" : "😵")
                    .font(.system(size: 52))
                    .contentTransition(.symbolEffect)
                Text("スリープデーモンが現れた！")
                    .font(.headline)
                    .foregroundStyle(Palette.text)
                Meter(ratio: ratio, tint: Palette.danger, track: Color.black.opacity(0.4))
                    .padding(.top, 4)
                Text("HP \(demon.hp) / \(demon.maxHp)")
                    .font(.caption.bold())
                    .foregroundStyle(Palette.danger)
                    .contentTransition(.numericText())
                Text("クエストを達成してダメージを与えよう！")
                    .font(.caption)
                    .foregroundStyle(Palette.textMuted)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Palette.demon, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            VStack(spacing: 8) {
                Text("😊").font(.system(size: 52))
                Text("今日も快調！")
                    .font(.headline)
                    .foregroundStyle(Palette.text)
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.snappy) { game.summonDemon() }
                } label: {
                    Text("眠気を感じたらタップ")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 11)
                        .background(Palette.hero, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
        }
    }
}

struct QuestCard: View {
    let quest: Quest
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: quest.symbol)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(isActive ? Palette.accent : Palette.surfaceLight))
                VStack(alignment: .leading, spacing: 2) {
                    Text(quest.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isActive ? Palette.text : Palette.textFaint)
                    Text(quest.detail)
                        .font(.caption)
                        .foregroundStyle(isActive ? Palette.textMuted : Palette.textFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+\(quest.exp) EXP").foregroundStyle(isActive ? Palette.accent : Palette.textFaint)
                    Text("+\(quest.gold) G").foregroundStyle(isActive ? Palette.gold : Palette.textFaint)
                }
                .font(.subheadline.bold())
            }
            .padding(16)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.border))
        }
        .buttonStyle(.plain)
        .disabled(!isActive)
    }
}

// MARK: - 実績

struct AchievementSection: View {
    let player: PlayerState

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("アチーブメント")
                    .font(.title3.bold())
                    .foregroundStyle(Palette.text)
                Spacer()
                Text("\(player.unlockedAchievements.count) / \(Catalog.achievements.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Palette.gold)
            }
            .padding(.top, 4)
            ForEach(Catalog.achievements) { item in
                let isUnlocked = player.unlockedAchievements.contains(item.id)
                Panel(dimmed: !isUnlocked) {
                    HStack(spacing: 16) {
                        Text(isUnlocked ? "🏆" : "❓").font(.system(size: 30))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isUnlocked ? item.title : "？？？")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(isUnlocked ? Palette.text : Palette.textFaint)
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(isUnlocked ? Palette.textMuted : Palette.textFaint)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ショップ

struct ShopSection: View {
    @Environment(Game.self) private var game
    let onBuy: (ShopItem) -> Void

    var body: some View {
        let boosted = game.player.inventory.expBoostMultiplier > 1
        let freezes = game.player.inventory.streakFreezes
        VStack(spacing: 12) {
            HStack {
                Text("アイテムショップ")
                    .font(.title3.bold())
                    .foregroundStyle(Palette.text)
                Spacer()
                Text("🪙 \(game.player.gold) G")
                    .font(.subheadline.bold())
                    .foregroundStyle(Palette.gold)
            }
            .padding(.top, 4)
            row(
                icon: "⚡️", title: "経験値ブースト（永続）", detail: "獲得するEXPが永久に1.5倍になる",
                price: boosted ? "購入済み" : "\(ShopItem.expBoost.cost) G", enabled: !boosted
            ) { onBuy(.expBoost) }
            row(
                icon: "🧊", title: freezes > 0 ? "ストリークフリーズ（所持: \(freezes)）" : "ストリークフリーズ",
                detail: "1日サボっても🔥連続記録が途切れない",
                price: "\(ShopItem.streakFreeze.cost) G", enabled: true
            ) { onBuy(.streakFreeze) }
        }
    }

    private func row(icon: String, title: String, detail: String, price: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Panel {
            HStack(spacing: 16) {
                Text(icon).font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Palette.text)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Palette.textMuted)
                }
                Spacer(minLength: 4)
                Button(action: action) {
                    Text(price)
                        .font(.subheadline.bold())
                        .foregroundStyle(enabled ? Color(hex: 0x1A1A1A) : Palette.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(enabled ? Palette.gold : Palette.surfaceLight, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
            }
        }
    }
}
