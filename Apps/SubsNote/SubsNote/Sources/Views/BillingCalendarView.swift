import SwiftData
import SwiftUI

/// 支払いカレンダー。月表示で支払いのある日に丸アイコン、下に選んだ日の支払いとその月の合計。
struct BillingCalendarView: View {
    @Query(sort: \Subscription.createdAt) private var subscriptions: [Subscription]

    @State private var month: Date
    @State private var selectedDay: Date

    private let calendar = Calendar.current

    init() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: AppClock.now)
        _month = State(initialValue: CostSummary.monthRange(containing: today, calendar: calendar).start)
        _selectedDay = State(initialValue: today)
    }

    var body: some View {
        let range = CostSummary.monthRange(containing: month, calendar: calendar)
        let payments = paymentsByDay(from: range.start, through: range.end)
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        monthHeader
                        weekdayHeader
                        grid(monthStart: range.start, payments: payments)
                    }
                    .card(padding: 12)
                    monthTotal(payments)
                    dayList(payments[selectedDay] ?? [])
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Subscription.self) { SubscriptionDetailView(subscription: $0) }
            .simultaneousGesture(
                DragGesture(minimumDistance: 30).onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                    shiftMonth(value.translation.width < 0 ? 1 : -1)
                }
            )
        }
    }

    // MARK: - 見出し

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left").font(.headline).frame(width: 44, height: 36)
            }
            .accessibilityLabel(Text("前の月"))
            Spacer()
            Text(Formatting.yearMonth(month, calendar: calendar))
                .font(.headline)
                .monospacedDigit()
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right").font(.headline).frame(width: 44, height: 36)
            }
            .accessibilityLabel(Text("次の月"))
        }
        .overlay(alignment: .trailing) {
            if !isCurrentMonth {
                Button("今日") { goToToday() }
                    .font(.caption.weight(.semibold))
                    .padding(.trailing, 48)
            }
        }
    }

    private var weekdayHeader: some View {
        let symbols = ["日", "月", "火", "水", "木", "金", "土"]
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first...] + symbols[..<first])
        return HStack(spacing: 0) {
            ForEach(Array(ordered.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(symbol == "日" ? Color.red.opacity(0.8) : symbol == "土" ? Color.blue.opacity(0.8) : .secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - 日付のマス

    private func grid(monthStart: Date, payments: [Date: [Subscription]]) -> some View {
        let days = gridDays(monthStart: monthStart)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day, subscriptions: payments[day] ?? [])
                } else {
                    Color.clear.frame(height: 54)
                }
            }
        }
    }

    private func dayCell(_ day: Date, subscriptions: [Subscription]) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let isToday = calendar.isDate(day, inSameDayAs: AppClock.now)
        return Button {
            selectedDay = day
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline.weight(isToday || isSelected ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white : isToday ? Theme.accent : .primary)
                    .frame(width: 30, height: 30)
                    .background {
                        if isSelected {
                            Circle().fill(Theme.accent)
                        } else if isToday {
                            Circle().fill(Theme.accent.opacity(0.14))
                        }
                    }
                HStack(spacing: -4) {
                    ForEach(subscriptions.prefix(3)) { subscription in
                        ServiceIcon(name: subscription.name, category: subscription.category, size: 15)
                            .overlay(Circle().strokeBorder(Color(.secondarySystemGroupedBackground), lineWidth: 1))
                    }
                }
                .frame(height: 15)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(Formatting.monthDay(day))、支払い\(subscriptions.count)件"))
    }

    // MARK: - 合計と一覧

    private func monthTotal(_ payments: [Date: [Subscription]]) -> some View {
        let entries = payments.values.flatMap { $0 }
        let total = entries.reduce(0) { $0 + $1.price }
        let monthNumber = calendar.component(.month, from: month)
        return HStack {
            Text("\(monthNumber)月の支払い").font(.subheadline.weight(.semibold))
            Spacer()
            Text(Formatting.yen(total))
                .font(.title3.weight(.bold))
                .monospacedDigit()
            Text("（\(entries.count)件）")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card(padding: 14)
    }

    private func dayList(_ subscriptions: [Subscription]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(Formatting.monthDayWithWeekday(selectedDay, calendar: calendar))の支払い")
                .font(.headline)
            if subscriptions.isEmpty {
                Text("支払いはありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(subscriptions) { subscription in
                    NavigationLink(value: subscription) {
                        HStack(spacing: 12) {
                            ServiceIcon(name: subscription.name, category: subscription.category, size: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subscription.name).font(.body.weight(.medium)).foregroundStyle(.primary)
                                Text(subscription.paymentMethod.label).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(Formatting.yen(subscription.price))
                                .font(.body.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .card()
    }

    // MARK: - 計算

    private var isCurrentMonth: Bool {
        calendar.isDate(month, equalTo: AppClock.now, toGranularity: .month)
    }

    /// 日付（その日の0時）ごとの支払い。解約済みは出さない。
    private func paymentsByDay(from start: Date, through end: Date) -> [Date: [Subscription]] {
        var result: [Date: [Subscription]] = [:]
        for subscription in subscriptions where !subscription.isCancelled {
            for date in BillingSchedule.billingDates(from: start, through: end, plan: subscription.plan, calendar: calendar) {
                result[calendar.startOfDay(for: date), default: []].append(subscription)
            }
        }
        return result.mapValues { $0.sorted { $0.price > $1.price } }
    }

    /// 月のマス。1日の前の空きは nil。
    private func gridDays(monthStart: Date) -> [Date?] {
        let weekday = calendar.component(.weekday, from: monthStart)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        var days: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<count {
            days.append(calendar.date(byAdding: .day, value: offset, to: monthStart))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func shiftMonth(_ value: Int) {
        guard let next = calendar.date(byAdding: .month, value: value, to: month) else { return }
        withAnimation(.snappy) {
            month = next
            selectedDay = calendar.isDate(next, equalTo: AppClock.now, toGranularity: .month)
                ? calendar.startOfDay(for: AppClock.now)
                : next
        }
    }

    private func goToToday() {
        withAnimation(.snappy) {
            month = CostSummary.monthRange(containing: AppClock.now, calendar: calendar).start
            selectedDay = calendar.startOfDay(for: AppClock.now)
        }
    }
}
