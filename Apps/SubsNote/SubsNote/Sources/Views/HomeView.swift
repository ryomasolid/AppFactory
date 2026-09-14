import SwiftData
import SwiftUI

enum HomeSort: String, CaseIterable, Identifiable {
    case nextBilling
    case price
    case name

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nextBilling: String(localized: "次の支払い順")
        case .price: String(localized: "金額順")
        case .name: String(localized: "名前順")
        }
    }
}

private enum HomeRoute: Hashable {
    case breakdown
}

/// ホーム。月あたりの合計・無料体験中・次の支払い・解約済み。
struct HomeView: View {
    @Environment(StoreManager.self) private var store
    @Query(sort: \Subscription.createdAt) private var subscriptions: [Subscription]
    @AppStorage(StorageKey.homeSort) private var sortRaw = HomeSort.nextBilling.rawValue

    @State private var path = NavigationPath()
    @State private var addRequest: AddRequest?
    @State private var showPaywall = false
    @State private var showCancelled = false

    private struct AddRequest: Identifiable {
        let id = UUID()
        var preset: ServicePreset?
    }

    private var today: Date { AppClock.now }
    private var sort: HomeSort { HomeSort(rawValue: sortRaw) ?? .nextBilling }
    private var live: [Subscription] { subscriptions.filter { !$0.isCancelled } }

    private var trials: [Subscription] {
        live.filter { $0.state(today: today) == .trial }
            .sorted { ($0.trialEndDate ?? .distantFuture) < ($1.trialEndDate ?? .distantFuture) }
    }

    private var actives: [Subscription] {
        let items = live.filter { $0.state(today: today) == .active }
        switch sort {
        case .nextBilling:
            return items.sorted { lhs, rhs in
                let l = lhs.nextBillingDate(today: today) ?? .distantFuture
                let r = rhs.nextBillingDate(today: today) ?? .distantFuture
                return l == r ? lhs.monthlyAmount > rhs.monthlyAmount : l < r
            }
        case .price:
            return items.sorted { $0.monthlyAmount > $1.monthlyAmount }
        case .name:
            return items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    private var cancelled: [Subscription] {
        subscriptions.filter(\.isCancelled)
            .sorted { ($0.cancelledAt ?? .distantPast) > ($1.cancelledAt ?? .distantPast) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if !live.isEmpty {
                    summary
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                    breakdownButton
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                }
                if !trials.isEmpty {
                    Section("無料体験中") {
                        ForEach(trials) { subscription in
                            NavigationLink(value: subscription) {
                                TrialRow(subscription: subscription, today: today)
                            }
                        }
                    }
                }
                if !actives.isEmpty {
                    Section {
                        ForEach(actives) { subscription in
                            NavigationLink(value: subscription) {
                                SubscriptionRow(subscription: subscription, today: today)
                            }
                        }
                    } header: {
                        Text(sort.label)
                    } footer: {
                        limitFooter
                    }
                }
                if !cancelled.isEmpty {
                    cancelledSection
                }
            }
            .listStyle(.insetGrouped)
            .overlay { emptyState }
            .navigationTitle("サブスク帳")
            .toolbar {
                if !live.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("並べ替え", selection: $sortRaw) {
                                ForEach(HomeSort.allCases) { Text($0.label).tag($0.rawValue) }
                            }
                        } label: {
                            Label("並べ替え", systemImage: "arrow.up.arrow.down")
                        }
                    }
                }
            }
            .navigationDestination(for: Subscription.self) { SubscriptionDetailView(subscription: $0) }
            .navigationDestination(for: HomeRoute.self) { _ in BreakdownView() }
            .safeAreaInset(edge: .bottom) {
                if !subscriptions.isEmpty {
                    HStack {
                        Spacer()
                        Button { startAdding(nil) } label: { addButtonLabel }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            .sheet(item: $addRequest) { request in
                AddSubscriptionSheet(preset: request.preset).environment(store)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environment(store)
            }
            .task(id: subscriptions.count) {
                // スクショ撮影用: デモ投入後に詳細・内訳を開く。
                guard path.isEmpty else { return }
                if Launch.showDetail, let subscription = subscriptions.first(where: { $0.name == Launch.demoDetailName }) {
                    path.append(subscription)
                } else if Launch.showBreakdown, !subscriptions.isEmpty {
                    path.append(HomeRoute.breakdown)
                }
            }
        }
    }

    // MARK: - 上部の合計

    private var summary: some View {
        let plans = subscriptions.map(\.plan)
        let totals = CostSummary.activeTotals(plans, today: today)
        let remaining = CostSummary.remainingInMonth(plans, today: today)
        let trialAddition = CostSummary.trialMonthlyAddition(plans, today: today)

        return VStack(alignment: .leading, spacing: 8) {
            Text("月あたり")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(Formatting.yen(totals.monthly))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 16) {
                subTotal("年", totals.yearly)
                subTotal("1日", totals.daily)
            }
            Divider().padding(.vertical, 2)
            HStack {
                Label("今月の残りの支払い", systemImage: "calendar")
                    .font(.subheadline)
                Spacer()
                Text(Formatting.yen(remaining))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            if trialAddition > 0 {
                Label("体験が終わると 月 +\(Formatting.yen(trialAddition))", systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BillingState.trial.color)
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private func subTotal(_ title: LocalizedStringKey, _ amount: Int) -> some View {
        HStack(spacing: 4) {
            Text(title).foregroundStyle(.secondary)
            Text(Formatting.yen(amount)).fontWeight(.semibold).monospacedDigit()
        }
        .font(.subheadline)
    }

    private var breakdownButton: some View {
        Button {
            if ProLimits.canSeeBreakdown(isPro: store.isPro) {
                path.append(HomeRoute.breakdown)
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.fill").foregroundStyle(Theme.accent)
                Text("カテゴリ別・支払い方法別の内訳")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 4)
                if !store.isPro { ProBadge() }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .card(padding: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 解約済み

    private var cancelledSection: some View {
        Section {
            DisclosureGroup(isExpanded: $showCancelled) {
                ForEach(cancelled) { subscription in
                    NavigationLink(value: subscription) {
                        CancelledRow(subscription: subscription)
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("解約済み（\(cancelled.count)件）").font(.body.weight(.semibold))
                    Text("解約して年 \(Formatting.yen(CostSummary.yearlySaved(cancelled.map(\.plan)))) 浮いています")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    // MARK: - 追加

    @ViewBuilder
    private var limitFooter: some View {
        // 上限が近づいてから知らせる（最初から「あと○件」を出すと、使う前に制限を意識させてしまう）。
        if !Launch.isDemo,
           let remaining = ProLimits.remaining(activeCount: live.count, isPro: store.isPro),
           remaining <= 2 {
            Text("無料版であと\(remaining)件登録できます（解約済みは数えません）。")
        }
    }

    private func startAdding(_ preset: ServicePreset?) {
        if ProLimits.canAdd(activeCount: live.count, isPro: store.isPro) {
            addRequest = AddRequest(preset: preset)
        } else {
            showPaywall = true
        }
    }

    private var addButtonLabel: some View {
        Label("追加", systemImage: "plus")
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(Theme.accent, in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
    }

    // MARK: - 空の状態

    @ViewBuilder
    private var emptyState: some View {
        if subscriptions.isEmpty {
            VStack(spacing: 18) {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                Text("まずはよく使うサービスを1つ追加してみましょう")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("毎月いくら払っているかをまとめ、支払日と無料体験の終わりの前にお知らせします。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(ServicePreset.popular) { preset in
                        Button { startAdding(preset) } label: {
                            HStack(spacing: 8) {
                                ServiceIcon(name: preset.name, category: preset.category, size: 24)
                                Text(preset.name)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button { startAdding(nil) } label: {
                    PrimaryButtonLabel(title: "サービスを選んで追加", systemImage: "plus")
                }
                .padding(.top, 4)
            }
            .padding(28)
        }
    }
}

// MARK: - 行

/// 契約中の1行。次の支払日と金額。
struct SubscriptionRow: View {
    let subscription: Subscription
    let today: Date

    var body: some View {
        HStack(spacing: 12) {
            ServiceIcon(name: subscription.name, category: subscription.category)
            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Text(subscription.paymentMethod.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(Formatting.cyclePrice(price: subscription.price, cycle: subscription.cycle, interval: subscription.cycleInterval))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                if let next = subscription.nextBillingDate(today: today) {
                    let days = Formatting.days(from: today, to: next)
                    Text("\(Formatting.shortDate(next))（\(Formatting.daysUntil(days))）")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(DueStyle.color(daysLeft: days))
                        .lineLimit(1)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 2)
    }
}

/// 無料体験中の1行。終了までの日数を目立たせる。
struct TrialRow: View {
    let subscription: Subscription
    let today: Date

    var body: some View {
        HStack(spacing: 12) {
            ServiceIcon(name: subscription.name, category: subscription.category)
            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Text("終わると \(Formatting.cyclePrice(price: subscription.price, cycle: subscription.cycle, interval: subscription.cycleInterval))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let end = subscription.trialEndDate {
                let days = Formatting.days(from: today, to: end)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(days == 0 ? String(localized: "今日まで") : String(localized: "あと\(days)日"))
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(BillingState.trial.color)
                    Text("\(Formatting.shortDate(end))まで")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(.vertical, 2)
    }
}

/// 解約済みの1行。浮いた年額。
struct CancelledRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 12) {
            ServiceIcon(name: subscription.name, category: subscription.category, size: 34)
                .opacity(0.6)
            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let date = subscription.cancelledAt {
                    Text("\(Formatting.date(date)) 解約")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text("年 \(Formatting.yen(CostSummary.yearly(subscription.plan).rounded()))")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}
