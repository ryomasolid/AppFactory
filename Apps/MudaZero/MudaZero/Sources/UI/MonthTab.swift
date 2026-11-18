import SwiftData
import SwiftUI

/// カレンダー：月の色分け → 月のふりかえり（ついつい の内訳）。日をタップでその日を開く。
struct MonthTab: View {
    @Query(sort: \Spend.createdAt, order: .reverse) private var spends: [Spend]
    @Query private var marks: [DayMark]
    @State private var shown = Calendar.current.dateInterval(of: .month, for: Date())!.start
    @State private var opened: OpenedDay?

    private let cal = Calendar.current

    var body: some View {
        let book = Book(spends: spends, marks: marks, calendar: cal)
        let summary = book.month(of: shown)
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    grid(book).card(14)
                    legend
                    summaryCard(summary)
                }
                .padding(16)
            }
            .background(Hue.ground)
            .navigationTitle(Words.month(shown))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { move(-1) } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel("前の月")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { move(1) } label: { Image(systemName: "chevron.right") }
                        .accessibilityLabel("次の月")
                        .disabled(shown >= cal.dateInterval(of: .month, for: Date())!.start)
                }
            }
            .sheet(item: $opened) { o in
                NavigationStack {
                    ScrollView {
                        DayPanel(
                            day: o.day,
                            book: book,
                            spends: spends.filter { cal.isDate($0.day, inSameDayAs: o.day) },
                            marks: marks.filter { cal.isDate($0.day, inSameDayAs: o.day) }
                        )
                        .padding(16)
                    }
                    .background(Hue.ground)
                    .navigationTitle(Words.long(o.day))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("とじる") { opened = nil } } }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func move(_ months: Int) {
        if let m = cal.date(byAdding: .month, value: months, to: shown) { shown = m }
    }

    // MARK: カレンダー

    private func grid(_ book: Book) -> some View {
        let count = cal.range(of: .day, in: .month, for: shown)?.count ?? 30
        let lead = (cal.component(.weekday, from: shown) - cal.firstWeekday + 7) % 7
        let today = cal.startOfDay(for: Date())
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let ordered = Array(symbols[(cal.firstWeekday - 1)...] + symbols[..<(cal.firstWeekday - 1)])
        // 見出し・空き・日付を1つの並びにする（ForEach を分けて Int の ID がぶつかると、1〜7日が消える）。
        let slots: [Slot] = ordered.enumerated().map { .head($0.offset, $0.element) }
            + (0..<lead).map { .blank($0) }
            + (0..<count).map { .day($0 + 1, cal.date(byAdding: .day, value: $0, to: shown)!) }
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
            ForEach(slots) { slot in
                switch slot {
                case .head(_, let s):
                    Text(s).font(.caption2.weight(.semibold)).foregroundStyle(Hue.soft)
                case .blank:
                    Color.clear.frame(height: 50)
                case .day(let n, let day):
                    DayCell(number: n, kind: book.kind(on: day), isToday: day == today, future: day > today)
                        .onTapGesture { if day <= today { opened = OpenedDay(day: day) } }
                        .accessibilityIdentifier("day-\(n)")
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            dot(Hue.gold, "0円の日")
            dot(Hue.mint, "ムダゼロ")
            dot(Hue.salmon, "ついつい")
        }
        .font(.caption)
        .foregroundStyle(Hue.soft)
    }

    private func dot(_ c: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(c).frame(width: 9, height: 9)
            Text(text)
        }
    }

    // MARK: ふりかえり

    private func summaryCard(_ s: MonthSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("この月のふりかえり").font(.headline).foregroundStyle(Hue.ink)
            HStack(spacing: 0) {
                stat("\(s.zeroDays)日", "0円の日", Hue.gold)
                stat("\(s.cleanDays)日", "ムダゼロ", Hue.mint)
                stat("\(s.slippedDays)日", "ついつい", Hue.salmon)
            }
            Divider()
            HStack {
                Text("ついつい 合計").foregroundStyle(Hue.soft)
                Spacer()
                Text(s.want.yen).font(.body.weight(.bold).monospacedDigit()).foregroundStyle(Hue.salmon)
            }
            HStack {
                Text("必要な出費 合計").foregroundStyle(Hue.soft)
                Spacer()
                Text(s.need.yen).font(.body.weight(.semibold).monospacedDigit()).foregroundStyle(Hue.ink)
            }
            if let top = s.wantByCategory.first {
                Divider()
                Text("ついつい の内訳").font(.subheadline.weight(.semibold)).foregroundStyle(Hue.ink)
                ForEach(s.wantByCategory.prefix(5), id: \.category) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(row.category.label, systemImage: row.category.symbol)
                                .font(.subheadline)
                                .foregroundStyle(Hue.ink)
                            Spacer()
                            Text(row.yen.yen).font(.subheadline.monospacedDigit()).foregroundStyle(Hue.soft)
                        }
                        Meter(ratio: Double(row.yen) / Double(top.yen), color: Hue.salmon.opacity(0.8))
                    }
                }
                Text("いちばん多いのは「\(top.category.label)」。ここを減らすと効きます。")
                    .font(.footnote)
                    .foregroundStyle(Hue.soft)
            }
        }
        .card()
    }

    private func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.weight(.heavy).monospacedDigit()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(Hue.soft)
        }
        .frame(maxWidth: .infinity)
    }
}

private enum Slot: Identifiable {
    case head(Int, String)
    case blank(Int)
    case day(Int, Date)

    var id: String {
        switch self {
        case .head(let i, _): "h\(i)"
        case .blank(let i): "b\(i)"
        case .day(let n, _): "d\(n)"
        }
    }
}

struct OpenedDay: Identifiable {
    let day: Date
    var id: Date { day }
}

private struct DayCell: View {
    let number: Int
    let kind: DayKind
    let isToday: Bool
    let future: Bool

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                switch kind {
                case .zero, .clean:
                    Circle().fill(kind.color)
                    Text("\(number)").font(.subheadline.weight(.bold)).foregroundStyle(.white)
                case .slipped:
                    Circle().strokeBorder(Hue.salmon, lineWidth: 2)
                    Text("\(number)").font(.subheadline.weight(.semibold)).foregroundStyle(Hue.salmon)
                case .open:
                    Text("\(number)")
                        .font(.subheadline)
                        .foregroundStyle(future ? Hue.soft.opacity(0.5) : Hue.ink)
                }
                if isToday {
                    Circle().strokeBorder(Hue.ink.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])).padding(-3)
                }
            }
            .frame(width: 34, height: 34)
            Text(caption)
                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                .foregroundStyle(kind.color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(height: 11)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .contentShape(Rectangle())
    }

    private var caption: String {
        switch kind {
        case .zero: "0円"
        case .slipped(let want, _): want >= 10000 ? "\(want / 1000)千" : "\(want)"
        default: ""
        }
    }
}
