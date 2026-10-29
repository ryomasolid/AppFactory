import SwiftData
import SwiftUI

/// ホーム。飼っている子をケージ単位のカードで並べ、今日ごはんの子・気にかけたい子を上に出す。
struct CageScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Gecko.position) private var geckos: [Gecko]
    @State private var addingGecko = false
    @State private var feedingRound = false
    @State private var path: [Gecko] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 14) {
                    if geckos.isEmpty {
                        FirstGeckoPrompt { addingGecko = true }
                    } else {
                        TodayBoard(geckos: geckos) { feedingRound = true }
                        ForEach(geckos) { gecko in
                            NavigationLink(value: gecko) {
                                GeckoCard(gecko: gecko)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Terrarium.sand)
            .navigationTitle("ケージ")
            .navigationDestination(for: Gecko.self) { GeckoScreen(gecko: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { addingGecko = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("個体を追加")
                }
            }
            .sheet(isPresented: $addingGecko) { GeckoForm(gecko: nil) }
            .sheet(isPresented: $feedingRound) { FeedRoundSheet() }
            .onAppear {
                if Showcase.opensFirstGecko, path.isEmpty, let first = geckos.first { path = [first] }
            }
        }
    }
}

/// 一覧のいちばん上。今日の仕事を数字で見せる。
private struct TodayBoard: View {
    let geckos: [Gecko]
    let startRound: () -> Void

    var body: some View {
        let statuses = geckos.map { $0.status() }
        let due = statuses.filter(\.isFeedingDue).count
        let watch = statuses.filter { $0.needsAppetiteWatch || $0.isLosingWeight }.count
        let shed = statuses.filter(\.isShedNear).count

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                counter(value: due, label: "今日ごはん", color: Terrarium.moss)
                counter(value: shed, label: "脱皮が近い", color: Terrarium.shed)
                counter(value: watch, label: "見守り", color: watch > 0 ? Terrarium.alert : .secondary)
            }
            Button(action: startRound) {
                Label(due > 0 ? "ごはんをまとめて記録（\(due)匹）" : "ごはんをまとめて記録", systemImage: "fork.knife")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))
        }
        .cardSurface()
    }

    private func counter(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct GeckoCard: View {
    let gecko: Gecko

    var body: some View {
        let status = gecko.status()
        HStack(alignment: .top, spacing: 12) {
            GeckoAvatar(name: gecko.name, portrait: gecko.portrait, size: 56)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(gecko.name).font(.title3.weight(.bold))
                    Text(gecko.sex.mark).foregroundStyle(.secondary)
                    Spacer()
                    if let grams = status.latestGrams {
                        Text(CareEntry.gramText(grams)).font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
                Text([gecko.morph, status.stage.label, gecko.ageText()].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " ・ "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                FlowTags(status: status)
            }
        }
        .cardSurface()
        .contentShape(Rectangle())
    }
}

/// カードの札。気にかけたいものから順に。
struct FlowTags: View {
    let status: GeckoStatus

    var body: some View {
        HStack(spacing: 6) {
            feedingTag
            if status.refusalStreak >= 2 {
                Tag(text: "拒食\(status.refusalStreak)回", color: Terrarium.alert, symbol: "exclamationmark")
            } else if let since = status.daysSinceAte, since >= 14 {
                Tag(text: "\(since)日食べてない", color: Terrarium.alert, symbol: "exclamationmark")
            }
            if status.isLosingWeight, let change = status.monthlyWeightChange {
                Tag(text: String(format: "体重%.0f%%", change), color: Terrarium.alert, symbol: "arrow.down")
            }
            if status.isShedNear {
                Tag(text: "脱皮が近い", color: Terrarium.shed, symbol: "sparkles")
            }
        }
    }

    @ViewBuilder private var feedingTag: some View {
        switch status.daysUntilFeeding {
        case ..<0: Tag(text: "ごはん \(-status.daysUntilFeeding)日すぎ", color: Terrarium.yolk, symbol: "fork.knife")
        case 0: Tag(text: "今日ごはん", color: Terrarium.moss, symbol: "fork.knife")
        default: Tag(text: "ごはん あと\(status.daysUntilFeeding)日", color: .secondary)
        }
    }
}

private struct FirstGeckoPrompt: View {
    let add: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            GeckoAvatar(name: "🦎", portrait: nil, size: 96)
            Text("うちの子を登録しよう").font(.title3.weight(.bold))
            Text("名前とハッチ日を入れると、年齢に合わせて\nごはんの間隔と脱皮の時期を見守ります。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("1匹目を登録する", action: add)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .cardSurface()
    }
}
