import SwiftData
import SwiftUI

/// ホーム。「今日出すゴミ」が一目で分かることだけに全振りする画面。
/// アプリを開く理由はほぼこれひとつなので、スクロールせずに答えが出ることを最優先にする。
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GarbageKind.sortOrder) private var kinds: [GarbageKind]
    @Query private var doneRecords: [DoneRecord]

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if kinds.isEmpty {
                        emptyState
                    } else {
                        todaySection
                        tomorrowSection
                        if !laterDays.isEmpty { laterSection }
                        if streak > 0 { streakLabel }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text(today.formatted(.dateTime.month().day().weekday())))
        }
        .tint(Theme.accent)
    }

    // MARK: - セクション

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("今日出すゴミ")
            if let todayDay {
                ForEach(kindList(todayDay), id: \.id) { kind in
                    todayCard(kind)
                }
            } else {
                noCollectionCard
            }
        }
    }

    private func todayCard(_ kind: GarbageKind) -> some View {
        let color = Color(hex: kind.colorHex)
        let done = isDone(kind, on: today)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: kind.symbolName)
                    .font(.title2.weight(.semibold))
                Text(kind.name)
                    .font(.title2.weight(.bold))
                Spacer(minLength: 0)
            }
            if !kind.note.isEmpty {
                Text(kind.note)
                    .font(.subheadline)
                    .opacity(0.92)
            }
            Button {
                toggleDone(kind, on: today)
            } label: {
                Label(
                    done ? "出しました" : "出したらタップ",
                    systemImage: done ? "checkmark.circle.fill" : "circle"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(.white.opacity(done ? 0.34 : 0.18), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(done ? [.isButton, .isSelected] : .isButton)
        }
        .foregroundStyle(.white)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        // 出し終えた種類は少し落として、まだのものが目立つようにする。
        .opacity(done ? 0.72 : 1)
    }

    private var noCollectionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今日は収集なし")
                .font(.title3.weight(.semibold))
            if let next = upcoming.first {
                Text("次は \(dateLabel(next.date))　\(names(of: next))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    private var tomorrowSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("明日（\(weekdayLabel(tomorrow))）")
                .font(.subheadline.weight(.semibold))
            Spacer()
            if let tomorrowDay {
                Text(names(of: tomorrowDay))
                    .font(.subheadline)
            } else {
                Text("収集なし")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var laterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("今後の予定")
            VStack(spacing: 0) {
                ForEach(laterDays) { day in
                    HStack(spacing: 10) {
                        Text(dateLabel(day.date))
                            .font(.subheadline)
                            .monospacedDigit()
                            .frame(width: 96, alignment: .leading)
                        HStack(spacing: 6) {
                            ForEach(kindList(day), id: \.id) { kind in
                                Circle()
                                    .fill(Color(hex: kind.colorHex))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Text(names(of: day))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 11)
                    if day.id != laterDays.last?.id {
                        Divider().padding(.leading, 96)
                    }
                }
            }
            .padding(.horizontal, 18)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }

    private var streakLabel: some View {
        Label("\(streak)回連続で出せています", systemImage: "flame.fill")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 4)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ゴミの種類を登録しましょう")
                .font(.title3.weight(.semibold))
            Text("「予定」タブで、燃えるゴミなどの種類と収集の曜日を登録すると、前夜と当日の朝にお知らせします。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    // MARK: - 予定の組み立て

    private var today: Date { calendar.startOfDay(for: Date()) }
    private var tomorrow: Date { calendar.date(byAdding: .day, value: 1, to: today) ?? today }

    private var kindsByID: [UUID: GarbageKind] {
        Dictionary(kinds.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// 今日を含む今後の収集日。
    private var upcoming: [CollectionDay] {
        guard let end = calendar.date(byAdding: .day, value: 60, to: today) else { return [] }
        return UpcomingSchedule.days(
            for: kinds.map(KindPlan.init),
            from: today,
            through: end,
            settings: .load(),
            calendar: calendar
        )
    }

    private var todayDay: CollectionDay? { upcoming.first { $0.date == today } }
    private var tomorrowDay: CollectionDay? { upcoming.first { $0.date == tomorrow } }
    private var laterDays: [CollectionDay] { Array(upcoming.filter { $0.date > tomorrow }.prefix(5)) }

    /// 「出した」の連続回数。過去120日ぶんの収集日から数える。
    private var streak: Int {
        guard let start = calendar.date(byAdding: .day, value: -120, to: today) else { return 0 }
        let past = UpcomingSchedule.days(
            for: kinds.map(KindPlan.init),
            from: start,
            through: today,
            settings: .load(),
            calendar: calendar
        )
        let done = Set(
            doneRecords.map { StreakCalculator.DoneKey(kindID: $0.kindID, date: $0.date, calendar: calendar) }
        )
        return StreakCalculator.streak(days: past, done: done, today: today, calendar: calendar)
    }

    private func kindList(_ day: CollectionDay) -> [GarbageKind] {
        day.kindIDs.compactMap { kindsByID[$0] }
    }

    private func names(of day: CollectionDay) -> String {
        kindList(day).map(\.name).joined(separator: "・")
    }

    private func dateLabel(_ date: Date) -> String {
        date.formatted(.dateTime.month(.defaultDigits).day().weekday(.abbreviated))
    }

    private func weekdayLabel(_ date: Date) -> String {
        Weekday.of(date, calendar: calendar).shortLabel
    }

    // MARK: - 「出した」記録

    private func isDone(_ kind: GarbageKind, on date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        return doneRecords.contains { $0.kindID == kind.id && $0.date == day }
    }

    private func toggleDone(_ kind: GarbageKind, on date: Date) {
        let day = calendar.startOfDay(for: date)
        if let record = doneRecords.first(where: { $0.kindID == kind.id && $0.date == day }) {
            modelContext.delete(record)
        } else {
            modelContext.insert(DoneRecord(kindID: kind.id, date: day, calendar: calendar))
        }
        try? modelContext.save()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [GarbageKind.self, CollectionRule.self, DoneRecord.self], inMemory: true)
}
