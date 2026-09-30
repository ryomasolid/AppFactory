import SwiftData
import SwiftUI

/// 見直し。サブスクごとに「先月何回使ったか」をつけ、1回あたりの値段で元が取れているかを見る。
///
/// 合計を眺めるだけでは解約に踏み切れない。「ジム 1回 ¥3,278」のように1回の値段にすると決めやすい。
struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Subscription> { !$0.isCancelled }, sort: \Subscription.createdAt)
    private var subscriptions: [Subscription]

    @State private var path: [Subscription] = []

    private var today: Date { AppClock.now }

    /// やめる候補を先に、その中では月あたりの高い順。未記入は最後。
    private var ordered: [Subscription] {
        subscriptions.sorted { lhs, rhs in
            let l = rank(lhs.usageVerdict), r = rank(rhs.usageVerdict)
            return l == r ? lhs.monthlyAmount > rhs.monthlyAmount : l < r
        }
    }

    private func rank(_ verdict: UsageReview.Verdict) -> Int {
        switch verdict {
        case .unused: 0
        case .pricy: 1
        case .worth: 2
        case .unrated: 3
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if !subscriptions.isEmpty {
                    verdictCard
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                }
                Section {
                    ForEach(ordered) { subscription in
                        ReviewRow(
                            subscription: subscription, today: today,
                            onOpen: { path.append(subscription) },
                            onChange: { record($0, for: subscription) }
                        )
                    }
                } header: {
                    if !subscriptions.isEmpty { Text("先月、何回使いましたか？") }
                } footer: {
                    if !subscriptions.isEmpty {
                        Text("1回あたり \(Formatting.yen(UsageReview.pricyPerUse)) 以上を「割高」としています。回数はこの端末の中だけに保存されます。")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if subscriptions.isEmpty {
                    ContentUnavailableView(
                        "見直すサブスクがありません",
                        systemImage: "scalemass",
                        description: Text("ホームでサブスクを追加すると、ここで1回あたりの値段を確かめられます。")
                    )
                }
            }
            .navigationTitle("見直し")
            .navigationDestination(for: Subscription.self) { SubscriptionDetailView(subscription: $0) }
        }
    }

    // MARK: - 上部のまとめ

    private var verdictCard: some View {
        let saving = UsageReview.yearlySaving(subscriptions.map { ($0.plan, $0.usesLastMonth) })
        let unrated = subscriptions.filter { $0.usesLastMonth == nil }.count
        let candidates = subscriptions.filter(\.usageVerdict.isCandidate).count

        return VStack(alignment: .leading, spacing: 8) {
            if candidates > 0 {
                Text("やめる候補 \(candidates)件")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("年 \(Formatting.yen(saving)) 浮きます")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Palette.saving)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("使っていない・1回あたりが高いサブスクをすべてやめた場合です。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if unrated == subscriptions.count {
                Label("回数をつけると、元が取れているか分かります", systemImage: "hand.tap.fill")
                    .font(.headline)
                Text("下の一覧で、先月使った回数を ＋ で入れてください。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Label("どれも元が取れています", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Palette.saving)
                Text("1回あたり \(Formatting.yen(UsageReview.pricyPerUse)) 未満で使えています。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if unrated > 0, unrated < subscriptions.count {
                Text("まだ回数をつけていないものが\(unrated)件あります。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.deadline)
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private func record(_ uses: Int, for subscription: Subscription) {
        subscription.usesLastMonth = uses
        subscription.usageCheckedAt = today
        try? modelContext.save()
    }
}

/// 見直しの1行。回数の増減と、1回あたりの値段。
private struct ReviewRow: View {
    let subscription: Subscription
    let today: Date
    let onOpen: () -> Void
    let onChange: (Int) -> Void

    var body: some View {
        let verdict = subscription.usageVerdict
        VStack(alignment: .leading, spacing: 10) {
            // 行全体を NavigationLink にすると ＋／− を押しても詳細が開くので、見出しだけをボタンにする。
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    ServiceIcon(name: subscription.name, category: subscription.category, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscription.name)
                            .font(.body.weight(.semibold))
                            .lineLimit(1)
                        Text("月あたり \(Formatting.yen(subscription.monthlyAmount))")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    verdictTag(verdict)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.primary)
            HStack {
                usesStepper
                Spacer(minLength: 8)
                perUseText(verdict)
            }
            if UsageReview.isStale(checkedAt: subscription.usageCheckedAt, today: today) {
                Text("回数をつけてから30日以上たちました。先月の回数に直してください。")
                    .font(.caption)
                    .foregroundStyle(Palette.deadline)
            }
        }
        .padding(.vertical, 4)
    }

    private var usesStepper: some View {
        let uses = subscription.usesLastMonth
        return HStack(spacing: 0) {
            stepButton("minus", enabled: (uses ?? 0) > 0) { onChange(max(0, (uses ?? 0) - 1)) }
            Text(uses.map { String(localized: "\($0)回") } ?? String(localized: "未記入"))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 56)
                .foregroundStyle(uses == nil ? .secondary : .primary)
            stepButton("plus", enabled: (uses ?? 0) < 99) { onChange(uses.map { $0 + 1 } ?? 0) }
        }
        .background(Color(.tertiarySystemFill), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("先月使った回数")
        .accessibilityValue(uses.map { String(localized: "\($0)回") } ?? String(localized: "未記入"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onChange(uses.map { min(99, $0 + 1) } ?? 0)
            case .decrement: onChange(max(0, (uses ?? 0) - 1))
            @unknown default: break
            }
        }
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .frame(width: 40, height: 32)
        }
        .buttonStyle(.borderless)
        .disabled(!enabled)
    }

    @ViewBuilder
    private func perUseText(_ verdict: UsageReview.Verdict) -> some View {
        switch verdict {
        case .unrated:
            Text("＋で先月の回数を")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .unused:
            Text("1回も使っていません")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.idle)
        case .pricy(let perUse), .worth(let perUse):
            Text("1回 \(Formatting.yen(perUse))")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(verdict.isCandidate ? Palette.idle : .primary)
        }
    }

    @ViewBuilder
    private func verdictTag(_ verdict: UsageReview.Verdict) -> some View {
        switch verdict {
        case .unrated: EmptyView()
        case .unused: TagLabel(text: String(localized: "使っていない"), color: Palette.idle)
        case .pricy: TagLabel(text: String(localized: "割高"), color: Palette.deadline)
        case .worth: TagLabel(text: String(localized: "元が取れている"), color: Palette.saving)
        }
    }
}
