import SwiftUI

/// 月ごとのカレンダー。しなかった日は緑、しちゃった日はオレンジ。日付をタップすると記録を直せる。
struct CalendarScreen: View {
    @Environment(SnackBook.self) private var book
    @State private var month = Calendar.current.startOfMonth(Sample.now)
    @State private var editing: DaySheet.Target?

    private let calendar = Calendar.current
    private var now: Date { Sample.now }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Card { monthGrid }
                    tally
                    StreakTiles(
                        current: Streak.current(book.entries, today: now),
                        best: Streak.best(book.entries, today: now)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                // iPad では横に広がりすぎないよう、iPhone くらいの幅で真ん中に置く。
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Palette.paper)
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editing) { target in
                DaySheet(target: target)
            }
        }
    }

    // MARK: - 月の表

    private var monthGrid: some View {
        VStack(spacing: 12) {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left").padding(8) }
                    .accessibilityLabel("前の月")
                Spacer()
                Text(month, format: .dateTime.year().month(.wide))
                    .font(.headline)
                    .foregroundStyle(Palette.ink)
                Spacer()
                Button { shift(1) } label: { Image(systemName: "chevron.right").padding(8) }
                    .accessibilityLabel("次の月")
                    .disabled(month >= calendar.startOfMonth(now))
            }
            .tint(Palette.ink)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(["月", "火", "水", "木", "金", "土", "日"].enumerated()), id: \.offset) { index, name in
                    Text(name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(index == 5 ? Color.blue.opacity(0.7) : index == 6 ? Palette.flame : Palette.mute)
                }
                ForEach(cells, id: \.self) { cell in
                    if let day = cell {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { value in
                if value.translation.width < -40 { shift(1) }
                if value.translation.width > 40 { shift(-1) }
            }
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let key = DayKey.of(day)
        let entry = book.entry(for: key)
        let isToday = calendar.isDate(day, inSameDayAs: now)
        let isFuture = day > now && !isToday
        let fill: Color = switch entry.status {
        case .skipped: Palette.leaf
        case .snacked: Palette.crust
        case .none: .clear
        }
        return Button {
            editing = DaySheet.Target(key: key)
        } label: {
            ZStack {
                Circle().fill(fill)
                if isToday && entry.status == .none {
                    Circle().strokeBorder(Palette.leaf, lineWidth: 2)
                }
                Text("\(calendar.component(.day, from: day))")
                    .font(.callout.weight(isToday ? .bold : .regular))
                    .foregroundStyle(entry.status == .none ? Palette.ink : .white)
                if !entry.memo.isEmpty || !entry.weight.isEmpty {
                    Circle()
                        .fill(entry.status == .none ? Palette.crust : .white)
                        .frame(width: 4, height: 4)
                        .offset(y: 13)
                }
            }
            .frame(width: 38, height: 38)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .opacity(isFuture ? 0.3 : 1)
        .accessibilityLabel(accessibility(day: day, entry: entry))
    }

    private var tally: some View {
        let counts = Streak.monthTally(book.entries, month: month)
        return HStack(spacing: 12) {
            Card {
                Label {
                    Text("しなかった \(counts.skipped)日")
                } icon: {
                    Circle().fill(Palette.leaf).frame(width: 10, height: 10)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.ink)
            }
            Card {
                Label {
                    Text("しちゃった \(counts.snacked)日")
                } icon: {
                    Circle().fill(Palette.crust).frame(width: 10, height: 10)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.ink)
            }
        }
    }

    // MARK: - 日付の計算

    /// 月曜はじまりの表に並べる日（前の空きは nil）。
    private var cells: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let weekday = calendar.component(.weekday, from: month) // 日=1 … 土=7
        let leading = (weekday + 5) % 7
        let days: [Date?] = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
        return Array(repeating: nil, count: leading) + days
    }

    private func shift(_ months: Int) {
        guard let next = calendar.date(byAdding: .month, value: months, to: month) else { return }
        if next > calendar.startOfMonth(now) { return }
        withAnimation(.snappy) { month = next }
    }

    private func accessibility(day: Date, entry: DayEntry) -> String {
        let label = day.formatted(.dateTime.month().day())
        switch entry.status {
        case .skipped: return "\(label)、間食しなかった"
        case .snacked: return "\(label)、間食しちゃった"
        case .none: return "\(label)、未記録"
        }
    }
}

extension Calendar {
    func startOfMonth(_ date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
