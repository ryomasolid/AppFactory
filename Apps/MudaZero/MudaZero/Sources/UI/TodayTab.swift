import SwiftData
import SwiftUI

/// きょう：連続記録 → きょうをしめる → 今月のムダ予算 → もくひょう（浮いたお金）。
struct TodayTab: View {
    @Query(sort: \Spend.createdAt, order: .reverse) private var spends: [Spend]
    @Query private var marks: [DayMark]
    @AppStorage(Plan.usualKey) private var usual = Plan.usualDefault
    @AppStorage(Plan.budgetKey) private var budget = Plan.budgetDefault
    @AppStorage(Plan.goalNameKey) private var goalName = ""
    @AppStorage(Plan.goalYenKey) private var goalYen = 0
    @AppStorage(Plan.goalStartKey) private var goalStart = 0.0
    @Environment(\.scenePhase) private var phase
    @State private var now = Date()
    @State private var editingGoal = false

    private let cal = Calendar.current

    var body: some View {
        let book = Book(spends: spends, marks: marks, calendar: cal)
        let today = cal.startOfDay(for: now)
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    streakCard(book)
                    DayPanel(
                        day: today,
                        book: book,
                        spends: spends.filter { cal.isDate($0.day, inSameDayAs: today) },
                        marks: marks.filter { cal.isDate($0.day, inSameDayAs: today) }
                    )
                    budgetCard(book.pace(budget: budget, today: now))
                    goalCard(book)
                }
                .padding(16)
            }
            .background(Hue.ground)
            .navigationTitle(Words.long(now))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: phase) { _, p in if p == .active { now = Date() } }
        .sheet(isPresented: $editingGoal) { GoalForm() }
    }

    // MARK: 連続記録

    private func streakCard(_ book: Book) -> some View {
        let streak = book.streak(today: now)
        let month = book.month(of: now)
        return HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ムダゼロ連続")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Hue.soft)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(streak)")
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundStyle(streak > 0 ? Hue.mint : Hue.soft)
                        .contentTransition(.numericText())
                        .accessibilityIdentifier("streak")
                    Text("日").font(.title3.weight(.bold)).foregroundStyle(Hue.ink)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Pill(text: "今月の0円の日 \(month.zeroDays)", icon: "circle.fill", color: Hue.gold)
                Pill(text: "今月のムダゼロ \(month.cleanDays)", icon: "checkmark.seal.fill", color: Hue.mint)
            }
        }
        .card()
    }

    // MARK: ムダ予算

    private func budgetCard(_ pace: Pace) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("今月のムダ予算").font(.headline).foregroundStyle(Hue.ink)
                Spacer()
                Text("\(pace.spent.yen) / \(pace.budget.yen)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Hue.soft)
            }
            Meter(ratio: pace.ratio, color: pace.over ? Hue.salmon : (pace.ratio > 0.8 ? Hue.gold : Hue.mint))
            if pace.over {
                Text("予算を \((-pace.left).yen) オーバー。のこり\(pace.daysLeft)日はムダゼロでいこう。")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Hue.salmon)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("のこり \(pace.left.yen)").foregroundStyle(Hue.ink)
                    Text("→ 1日").foregroundStyle(Hue.soft)
                    Text(pace.perDay.yen).font(.title3.weight(.heavy).monospacedDigit()).foregroundStyle(Hue.mint)
                    Text("まで").foregroundStyle(Hue.soft)
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .card()
    }

    // MARK: もくひょう

    @ViewBuilder private func goalCard(_ book: Book) -> some View {
        if goalYen > 0 {
            let start = goalStart > 0 ? Date(timeIntervalSinceReferenceDate: goalStart) : now
            let saved = book.saved(from: start, through: now, usual: usual)
            let done = saved >= goalYen
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(goalName.isEmpty ? "もくひょう" : goalName, systemImage: "flag.checkered")
                        .font(.headline)
                        .foregroundStyle(Hue.ink)
                    Spacer()
                    Button("変える") { editingGoal = true }.font(.footnote)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(saved.yen)
                        .font(.system(size: 30, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(done ? Hue.gold : Hue.ink)
                    Text("/ \(goalYen.yen)").foregroundStyle(Hue.soft)
                }
                Meter(ratio: Double(saved) / Double(goalYen), color: Hue.gold)
                Text(done
                    ? "たまりました！ 浮いたお金を本当に移して、ごほうびにしましょう。"
                    : "あと \((goalYen - saved).yen)。ムダゼロの日は ふだんのムダ \(usual.yen) が浮いたとかぞえます。")
                    .font(.footnote)
                    .foregroundStyle(Hue.soft)
            }
            .card()
        } else {
            let first = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
            let saved = book.saved(from: first, through: now, usual: usual)
            VStack(alignment: .leading, spacing: 10) {
                Text("今月 浮いたお金").font(.headline).foregroundStyle(Hue.ink)
                Text(saved.yen)
                    .font(.system(size: 30, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(Hue.gold)
                Text("ふだんのムダ 1日 \(usual.yen) をがまんできた分です。")
                    .font(.footnote)
                    .foregroundStyle(Hue.soft)
                Button {
                    editingGoal = true
                } label: {
                    Label("ためる もくひょうを決める", systemImage: "flag.checkered")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Hue.gold)
            }
            .card()
        }
    }
}

/// もくひょう（なにに・いくら）。保存した日から浮いたお金をかぞえなおす。
struct GoalForm: View {
    @AppStorage(Plan.goalNameKey) private var goalName = ""
    @AppStorage(Plan.goalYenKey) private var goalYen = 0
    @AppStorage(Plan.goalStartKey) private var goalStart = 0.0
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var yen: Int?
    @State private var restart = true

    private let ideas: [(String, Int)] = [("旅行", 50000), ("ほしいもの", 20000), ("ごほうびディナー", 10000), ("貯金", 30000)]

    var body: some View {
        NavigationStack {
            Form {
                Section("なにのために？") {
                    TextField("例: 沖縄旅行", text: $name).accessibilityIdentifier("goal-name")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(ideas, id: \.0) { idea in
                                Button(idea.0) {
                                    name = idea.0
                                    yen = idea.1
                                }
                                .buttonStyle(.bordered)
                                .tint(Hue.gold)
                            }
                        }
                    }
                }
                Section("いくら ためる？") {
                    HStack {
                        TextField("50000", value: $yen, format: .number)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("goal-yen")
                        Text("円").foregroundStyle(Hue.soft)
                    }
                }
                if goalYen > 0 {
                    Section {
                        Toggle("きょうから かぞえなおす", isOn: $restart)
                    } footer: {
                        Text("オフにすると、これまでの浮いたお金をそのまま引きつぎます。")
                    }
                    Section {
                        Button("もくひょうをやめる", role: .destructive) {
                            goalYen = 0
                            goalName = ""
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("ためる もくひょう")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if goalYen == 0 || restart { goalStart = Calendar.current.startOfDay(for: Date()).timeIntervalSinceReferenceDate }
                        goalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        goalYen = yen ?? 0
                        dismiss()
                    }
                    .disabled((yen ?? 0) <= 0)
                }
            }
            .onAppear {
                name = goalName
                yen = goalYen > 0 ? goalYen : nil
                restart = goalYen == 0
            }
        }
    }
}
