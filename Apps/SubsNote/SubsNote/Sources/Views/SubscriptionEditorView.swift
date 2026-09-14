import SwiftData
import SwiftUI

/// 追加・編集。プリセットの料金は候補として出すだけで、保存前に必ず入力欄で見せる。
///
/// ナビゲーションの外枠（NavigationStack・キャンセル）は呼び出し側が持つ。
/// プリセット一覧から push される場合と、シートの根になる場合の両方で使うため。
struct SubscriptionEditorView: View {
    let subscription: Subscription?
    var onFinish: (Subscription) -> Void

    @Environment(\.modelContext) private var modelContext

    private let presetKey: String?
    private let presetPlans: [PresetPlan]
    /// 編集前の起点。周期・日付・体験を触っていなければそのまま残す（これまでの支払い回数の基準を変えない）。
    private let originalAnchor: Date?

    @State private var name: String
    @State private var category: SubCategory
    @State private var priceText: String
    @State private var cycle: BillingCycle
    @State private var interval: Int
    @State private var isTrial: Bool
    @State private var trialEnd: Date
    @State private var billingDate: Date
    @State private var paymentMethod: PaymentMethod
    @State private var paymentNote: String
    @State private var cancelNote: String
    @State private var note: String
    @State private var scheduleTouched = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case price
    }

    init(
        subscription: Subscription?,
        preset: ServicePreset? = nil,
        initialName: String = "",
        onFinish: @escaping (Subscription) -> Void
    ) {
        self.subscription = subscription
        self.onFinish = onFinish
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: AppClock.now)
        let defaultTrialEnd = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        if let subscription {
            presetKey = subscription.presetKey
            presetPlans = subscription.presetKey.flatMap(ServicePreset.find(key:))?.plans ?? []
            originalAnchor = subscription.anchorDate
            _name = State(initialValue: subscription.name)
            _category = State(initialValue: subscription.category)
            _priceText = State(initialValue: String(subscription.price))
            _cycle = State(initialValue: subscription.cycle)
            _interval = State(initialValue: max(1, subscription.cycleInterval))
            _isTrial = State(initialValue: subscription.state(today: today) == .trial)
            _trialEnd = State(initialValue: subscription.trialEndDate ?? defaultTrialEnd)
            _billingDate = State(initialValue: subscription.nextBillingDate(today: today) ?? subscription.anchorDate)
            _paymentMethod = State(initialValue: subscription.paymentMethod)
            _paymentNote = State(initialValue: subscription.paymentNote)
            _cancelNote = State(initialValue: subscription.cancelNote)
            _note = State(initialValue: subscription.note)
        } else {
            let plan = preset?.plans.first
            let payment = preset?.payment ?? .creditCard
            presetKey = preset?.key
            presetPlans = preset?.plans ?? []
            originalAnchor = nil
            _name = State(initialValue: preset?.name ?? initialName)
            _category = State(initialValue: preset?.category ?? .life)
            _priceText = State(initialValue: plan.map { String($0.price) } ?? "")
            _cycle = State(initialValue: plan?.cycle ?? .month)
            _interval = State(initialValue: plan?.interval ?? 1)
            _isTrial = State(initialValue: false)
            _trialEnd = State(initialValue: defaultTrialEnd)
            _billingDate = State(initialValue: today)
            _paymentMethod = State(initialValue: payment)
            _paymentNote = State(initialValue: "")
            _cancelNote = State(initialValue: payment.cancelGuide)
            _note = State(initialValue: "")
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var price: Int? { NumberInput.int(priceText) }

    private var computedAnchor: Date {
        isTrial
            ? BillingSchedule.firstBillingDate(afterTrialEnd: trialEnd)
            : Calendar.current.startOfDay(for: billingDate)
    }

    private var anchor: Date {
        if let originalAnchor, !scheduleTouched { return originalAnchor }
        return computedAnchor
    }

    private func draftPlan(price: Int) -> BillingPlan {
        BillingPlan(
            price: price, cycle: cycle, interval: interval, anchorDate: anchor,
            trialEndDate: isTrial ? Calendar.current.startOfDay(for: trialEnd) : nil
        )
    }

    var body: some View {
        Form {
            basicSection
            priceSection
            scheduleSection
            paymentSection
            cancelSection
            noteSection
        }
        .navigationTitle(subscription == nil ? "サブスクを追加" : "編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(trimmedName.isEmpty || price == nil)
            }
        }
        .onChange(of: cycle) { scheduleTouched = true }
        .onChange(of: interval) { scheduleTouched = true }
        .onChange(of: isTrial) { scheduleTouched = true }
        .onChange(of: trialEnd) { scheduleTouched = true }
        .onChange(of: billingDate) { scheduleTouched = true }
        .onChange(of: paymentMethod) { old, new in
            // 手順を書き換えていなければ、支払い方法に合わせて差し替える。
            if cancelNote.isEmpty || cancelNote == old.cancelGuide { cancelNote = new.cancelGuide }
        }
        .onAppear {
            // リストにないサービスを追加するときは名前から入れる（スクショ撮影時はキーボードを出さない）。
            if subscription == nil, name.isEmpty, !Launch.isDemo { focusedField = .name }
        }
    }

    // MARK: - 基本

    private var basicSection: some View {
        Section {
            TextField("サービス名（例：動画サービス、ジム）", text: $name)
                .font(.body.weight(.medium))
                .focused($focusedField, equals: .name)
                .submitLabel(.done)
            Picker("カテゴリ", selection: $category) {
                ForEach(SubCategory.allCases) { value in
                    Label(value.label, systemImage: value.symbolName).tag(value)
                }
            }
        }
    }

    // MARK: - 料金

    private var priceSection: some View {
        Section {
            if !presetPlans.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presetPlans, id: \.self) { plan in
                            planChip(plan)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            HStack {
                Text("金額")
                TextField("0", text: $priceText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .price)
                Text("円").foregroundStyle(.secondary)
            }
            Picker("周期", selection: $cycle) {
                ForEach(BillingCycle.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            Stepper(value: $interval, in: 1...cycle.maxInterval) {
                LabeledContent("間隔", value: Formatting.cycle(cycle, interval: interval))
            }
        } header: {
            Text("料金")
        } footer: {
            if !presetPlans.isEmpty {
                Text("料金プランの候補は目安です。値上げされていることがあるので、ご契約の金額を確かめてください。")
            }
        }
        .onChange(of: cycle) { _, newValue in
            interval = min(interval, newValue.maxInterval)
        }
    }

    private func planChip(_ plan: PresetPlan) -> some View {
        let isSelected = price == plan.price && cycle == plan.cycle && interval == plan.interval
        return Button {
            priceText = String(plan.price)
            cycle = plan.cycle
            interval = plan.interval
        } label: {
            VStack(alignment: .leading, spacing: 1) {
                Text(plan.label).font(.caption.weight(.semibold))
                Text(Formatting.cyclePrice(price: plan.price, cycle: plan.cycle, interval: plan.interval))
                    .font(.caption2)
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                isSelected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color(.tertiarySystemFill)),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 支払日

    private var scheduleSection: some View {
        Section {
            Toggle("無料体験中", isOn: $isTrial)
            if isTrial {
                DatePicker("無料体験の最終日", selection: $trialEnd, displayedComponents: .date)
                LabeledContent("初回の支払日", value: Formatting.dateWithWeekday(computedAnchor))
                    .foregroundStyle(.secondary)
            } else {
                DatePicker("支払日", selection: $billingDate, displayedComponents: .date)
            }
        } header: {
            Text("支払日")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if isTrial {
                    Text("最終日の3日前と前日に、続けるかどうかを知らせます。")
                } else {
                    Text("次回の支払日か、これまでに支払った日を選んでください。以後の支払日はこの日から数えます。")
                }
                if let preview = previewText {
                    Text(preview)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private var previewText: String? {
        guard let price else { return nil }
        let plan = draftPlan(price: price)
        let today = AppClock.now
        guard let next = BillingSchedule.nextBillingDate(onOrAfter: today, plan: plan) else { return nil }
        let recurrence = Formatting.recurrence(anchor: plan.anchorDate, cycle: cycle, interval: interval)
        let monthly = Formatting.yen(CostSummary.monthly(plan))
        if isTrial {
            return String(localized: "\(Formatting.shortDate(next))から\(recurrence)・月あたり \(monthly)")
        }
        let days = Formatting.days(from: today, to: next)
        return String(localized: "次回 \(Formatting.shortDate(next))（\(Formatting.daysUntil(days))）・以後\(recurrence)・月あたり \(monthly)")
    }

    // MARK: - 支払い方法・解約

    private var paymentSection: some View {
        Section {
            Picker("支払い方法", selection: $paymentMethod) {
                ForEach(PaymentMethod.allCases) { Text($0.label).tag($0) }
            }
            HStack {
                Text("メモ")
                TextField("カード名など", text: $paymentNote)
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("支払い方法")
        }
    }

    private var cancelSection: some View {
        Section {
            TextField("解約の手順", text: $cancelNote, axis: .vertical)
                .lineLimit(2...6)
            if cancelNote != paymentMethod.cancelGuide {
                Button("支払い方法の一般的な手順に戻す") { cancelNote = paymentMethod.cancelGuide }
                    .font(.subheadline)
            }
        } header: {
            Text("解約の手順")
        } footer: {
            Text("解約する場所は支払い方法によって違います。サービス独自の手順があれば書き足しておけます。")
        }
    }

    private var noteSection: some View {
        Section {
            TextField("メモ（家族で共有・プランの内容など）", text: $note, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    // MARK: - 保存

    private func save() {
        guard let price else { return }
        let target: Subscription
        if let subscription {
            target = subscription
        } else {
            target = Subscription()
            modelContext.insert(target)
        }
        let calendar = Calendar.current
        target.name = trimmedName
        target.presetKey = presetKey
        target.category = category
        target.price = price
        target.cycle = cycle
        target.cycleInterval = interval
        target.anchorDate = anchor
        target.trialEndDate = isTrial ? calendar.startOfDay(for: trialEnd) : nil
        target.paymentMethod = paymentMethod
        target.paymentNote = paymentNote.trimmingCharacters(in: .whitespacesAndNewlines)
        target.cancelNote = cancelNote.trimmingCharacters(in: .whitespacesAndNewlines)
        target.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try? modelContext.save()

        let container = modelContext.container
        Task { await NotificationRefresh.run(container: container) }
        onFinish(target)
    }
}
