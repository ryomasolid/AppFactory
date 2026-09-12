import SwiftData
import SwiftUI

/// 月カレンダー。収集日を色ドットで俯瞰する。
/// 「今週どうだったか」ではなく「この先どうなるか」を確かめる画面なので、
/// 日付を選ぶとその日の内訳を下に出す。
struct CalendarView: View {
    @Query(sort: \GarbageKind.sortOrder) private var kinds: [GarbageKind]

    private let calendar = Calendar.current
    @State private var month: CalendarMonth = .make(containing: Date())
    @State private var selected: Date = Calendar.current.startOfDay(for: Date())

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    weekdayHeader
                    grid
                    selectedDayDetail
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(Theme.accent)
    }

    // MARK: - 月の移動

    private var header: some View {
        HStack {
            Button {
                month = month.adding(months: -1, calendar: calendar)
            } label: {
                Image(systemName: "chevron.left").font(.headline)
            }
            .accessibilityLabel("前の月")

            Spacer()
            Text(month.firstDay.formatted(.dateTime.year().month()))
                .font(.headline)
            Spacer()

            Button {
                month = month.adding(months: 1, calendar: calendar)
            } label: {
                Image(systemName: "chevron.right").font(.headline)
            }
            .accessibilityLabel("次の月")
        }
        .padding(.top, 4)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(CalendarMonth.weekdayOrder(calendar: calendar)) { weekday in
                Text(weekday.shortLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color(for: weekday))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        VStack(spacing: 6) {
            ForEach(Array(month.weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 6) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                        if let date {
                            dayCell(date)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 54)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = date == selected
        let isToday = date == calendar.startOfDay(for: Date())
        return Button {
            selected = date
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(dayColor(date, isSelected: isSelected))
                HStack(spacing: 3) {
                    // ドットは3つまで。それ以上は "+n" にして升目を崩さない。
                    ForEach(dots(on: date).prefix(3), id: \.self) { hex in
                        Circle().fill(Color(hex: hex)).frame(width: 6, height: 6)
                    }
                    if dots(on: date).count > 3 {
                        Text("+\(dots(on: date).count - 3)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                isSelected ? Theme.accent : (isToday ? Color(.tertiarySystemFill) : Color.clear),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: date))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var selectedDayDetail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selected.formatted(.dateTime.month().day().weekday()))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if kindList(on: selected).isEmpty {
                Text(HolidayCalendar.isHoliday(selected, calendar: calendar) ? "祝日・収集なし" : "収集なし")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(kindList(on: selected), id: \.id) { kind in
                    HStack(spacing: 10) {
                        Image(systemName: kind.symbolName)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                Color(hex: kind.colorHex),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                        Text(kind.name)
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    // MARK: - 予定の引き当て

    /// 表示中の月の収集予定。通知と同じ条件（祝日設定を含む）で出す。
    private var daysInMonth: [CollectionDay] {
        guard let first = month.days.first, let last = month.days.last else { return [] }
        return UpcomingSchedule.days(
            for: kinds.map(KindPlan.init),
            from: first,
            through: last,
            settings: .load(),
            calendar: calendar
        )
    }

    private var kindsByID: [UUID: GarbageKind] {
        Dictionary(kinds.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private func kindList(on date: Date) -> [GarbageKind] {
        guard let day = daysInMonth.first(where: { $0.date == date }) else { return [] }
        return day.kindIDs.compactMap { kindsByID[$0] }
    }

    private func dots(on date: Date) -> [String] {
        kindList(on: date).map(\.colorHex)
    }

    private func dayColor(_ date: Date, isSelected: Bool) -> Color {
        if isSelected { return .white }
        if HolidayCalendar.isHoliday(date, calendar: calendar) { return .red }
        return color(for: Weekday.of(date, calendar: calendar))
    }

    private func color(for weekday: Weekday) -> Color {
        switch weekday {
        case .sunday: return .red
        case .saturday: return .blue
        default: return .primary
        }
    }

    private func accessibilityLabel(for date: Date) -> String {
        let names = kindList(on: date).map(\.name).joined(separator: "・")
        let day = date.formatted(.dateTime.month().day())
        return names.isEmpty ? day : "\(day) \(names)"
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [GarbageKind.self, CollectionRule.self, DoneRecord.self], inMemory: true)
}
