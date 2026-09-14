import SwiftData
import SwiftUI
import UIKit

/// 詳細。金額と次の支払日、今後の支払日、解約の手順。
struct SubscriptionDetailView: View {
    let subscription: Subscription

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store
    @Query private var all: [Subscription]

    @State private var showEditor = false
    @State private var showCancelSheet = false
    @State private var showPaywall = false
    @State private var confirmDelete = false
    @State private var copied = false

    private var today: Date { AppClock.now }

    var body: some View {
        let plan = subscription.plan
        let state = subscription.state(today: today)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(state: state)
                schedule(plan: plan, state: state)
                if state != .cancelled { upcoming(plan: plan) }
                cancelGuide
                payment
                if !subscription.note.isEmpty { memo }
                actions(state: state)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                SubscriptionEditorView(subscription: subscription) { _ in showEditor = false }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("キャンセル") { showEditor = false }
                        }
                    }
            }
            .tint(Theme.accent)
            .environment(store)
        }
        .sheet(isPresented: $showCancelSheet) {
            CancelRecordSheet(name: subscription.name, yearlySaving: CostSummary.yearly(plan).rounded()) { date in
                markCancelled(on: date)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environment(store)
        }
        .confirmationDialog(
            Text("「\(subscription.name)」を削除しますか？"), isPresented: $confirmDelete, titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) { delete() }
        } message: {
            Text("元に戻せません。解約しただけなら「解約した」にすると、浮いた金額の記録が残ります。")
        }
    }

    // MARK: - 見出し

    private func header(state: BillingState) -> some View {
        HStack(spacing: 14) {
            ServiceIcon(name: subscription.name, category: subscription.category, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.title3.bold())
                    .lineLimit(2)
                Text(Formatting.cyclePrice(price: subscription.price, cycle: subscription.cycle, interval: subscription.cycleInterval))
                    .font(.headline)
                    .monospacedDigit()
                Text("\(subscription.category.label)・\(Formatting.cycle(subscription.cycle, interval: subscription.cycleInterval))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if state != .active {
                TagLabel(text: state.label, color: state.color)
            }
        }
        .card()
    }

    // MARK: - 支払日と金額

    private func schedule(plan: BillingPlan, state: BillingState) -> some View {
        VStack(spacing: 0) {
            switch state {
            case .trial:
                if let end = subscription.trialEndDate {
                    let days = Formatting.days(from: today, to: end)
                    infoRow("無料体験の最終日", "\(Formatting.shortDateWithWeekday(end))（\(Formatting.daysUntil(days))）", color: BillingState.trial.color)
                }
                if let next = subscription.nextBillingDate(today: today) {
                    infoRow("初回の支払日", Formatting.shortDateWithWeekday(next))
                }
            case .active:
                if let next = subscription.nextBillingDate(today: today) {
                    let days = Formatting.days(from: today, to: next)
                    infoRow("次回の支払日", "\(Formatting.shortDateWithWeekday(next))（\(Formatting.daysUntil(days))）", color: DueStyle.color(daysLeft: days))
                }
            case .cancelled:
                if let date = subscription.cancelledAt {
                    infoRow("解約した日", Formatting.date(date))
                }
                infoRow("解約で浮いた額", String(localized: "年 \(Formatting.yen(CostSummary.yearly(plan).rounded()))"), color: Theme.accent)
            }
            infoRow("月あたり", Formatting.yen(CostSummary.monthly(plan)))
            infoRow("年あたり", Formatting.yen(CostSummary.yearly(plan).rounded()))
            let count = BillingSchedule.paidCount(plan: plan, today: today)
            if count > 0 {
                infoRow("これまでの支払い（概算）", String(localized: "\(Formatting.yen(count * plan.price))（\(count)回）"), showsDivider: false)
            }
        }
        .card(padding: 14)
    }

    private func upcoming(plan: BillingPlan) -> some View {
        let dates = BillingSchedule.upcoming(6, from: today, plan: plan)
        return VStack(alignment: .leading, spacing: 10) {
            Text("今後の支払日").font(.headline)
            ForEach(dates, id: \.self) { date in
                HStack {
                    Text(Formatting.dateWithWeekday(date))
                    Spacer()
                    Text(Formatting.yen(plan.price)).monospacedDigit()
                }
                .font(.subheadline)
            }
        }
        .card()
    }

    // MARK: - 解約の手順・支払い方法

    private var cancelGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("解約の手順", systemImage: "scissors").font(.headline)
                Spacer()
                Button {
                    UIPasteboard.general.string = subscription.cancelGuide
                    copied = true
                } label: {
                    Label(copied ? "コピーしました" : "コピー", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderless)
            }
            Text(subscription.cancelGuide)
                .font(.subheadline)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
    }

    private var payment: some View {
        VStack(spacing: 0) {
            infoRow("支払い方法", subscription.paymentMethod.label, showsDivider: !subscription.paymentNote.isEmpty)
            if !subscription.paymentNote.isEmpty {
                infoRow("メモ", subscription.paymentNote, showsDivider: false)
            }
        }
        .card(padding: 14)
    }

    private var memo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("メモ").font(.subheadline).foregroundStyle(.secondary)
            Text(subscription.note).font(.body)
        }
        .card()
    }

    private func infoRow(
        _ title: LocalizedStringKey, _ value: String, color: Color = .primary, showsDivider: Bool = true
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline).foregroundStyle(.secondary)
                Spacer(minLength: 12)
                Text(value)
                    .font(.body.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 10)
            if showsDivider { Divider() }
        }
    }

    // MARK: - 操作

    private func actions(state: BillingState) -> some View {
        VStack(spacing: 10) {
            if state == .cancelled {
                Button { resume() } label: {
                    Label("再開する（契約中に戻す）", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            } else {
                Button { showCancelSheet = true } label: {
                    Label("解約した", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }

            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("削除", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 4)
    }

    private func markCancelled(on date: Date) {
        subscription.isCancelled = true
        subscription.cancelledAt = Calendar.current.startOfDay(for: date)
        try? modelContext.save()
        rebuildNotifications()
    }

    /// 解約済みから戻すときに無料版の上限を確認する（解約済みは上限に数えないため）。
    private func resume() {
        let activeCount = ProLimits.countedSubscriptions(isCancelled: all.map(\.isCancelled))
        guard ProLimits.canAdd(activeCount: activeCount, isPro: store.isPro) else {
            showPaywall = true
            return
        }
        subscription.isCancelled = false
        subscription.cancelledAt = nil
        try? modelContext.save()
        rebuildNotifications()
    }

    private func rebuildNotifications() {
        let container = modelContext.container
        Task { await NotificationRefresh.run(container: container) }
    }

    private func delete() {
        let target = subscription
        let context = modelContext
        dismiss()
        // 画面が閉じてから消す（表示中のモデルを消すと描画中に参照して落ちる）。
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            context.delete(target)
            try? context.save()
            await NotificationRefresh.run(container: context.container)
        }
    }
}

/// 「解約した」の記録。日付を選ぶ。
struct CancelRecordSheet: View {
    let name: String
    let yearlySaving: Int
    var onRecord: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var date = Calendar.current.startOfDay(for: AppClock.now)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("解約した日", selection: $date, displayedComponents: .date)
                } footer: {
                    Text("記録すると合計と通知から外れ、「解約済み」に残ります。解約で年 \(Formatting.yen(yearlySaving)) 浮きます。")
                }
            }
            .navigationTitle(Text("「\(name)」を解約した"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("記録する") {
                        onRecord(date)
                        dismiss()
                    }
                }
            }
        }
        .tint(Theme.accent)
    }
}
