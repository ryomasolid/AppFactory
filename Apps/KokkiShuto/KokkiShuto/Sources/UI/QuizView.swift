import SwiftUI

struct QuizView: View {
    @Environment(Learned.self) private var progress
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [Question]
    @State private var index = 0
    @State private var chosen: Country?
    @State private var misses: [Question] = []
    @State private var finished = false
    @State private var advance: Task<Void, Never>?

    init(questions: [Question], showAnswer: Bool = false) {
        _questions = State(initialValue: questions)
        // 見本（-answered）：1問目を まちがえた形で見せる。
        if showAnswer, let q = questions.first {
            _chosen = State(initialValue: q.choices.first { $0 != q.answer })
        }
    }

    private var current: Question? { questions.indices.contains(index) ? questions[index] : nil }

    var body: some View {
        NavigationStack {
            Group {
                if finished {
                    ResultView(total: questions.count, misses: misses, retry: retryMisses, close: { dismiss() })
                } else if let q = current {
                    play(q)
                }
            }
            .background(Hue.page)
            .toolbar {
                if !finished {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("やめる") { dismiss() }
                    }
                    ToolbarItem(placement: .principal) {
                        Text("\(index + 1) / \(questions.count)")
                            .font(.headline.monospacedDigit())
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sensoryFeedback(trigger: chosen) { _, new in
            guard let new, let q = current else { return nil }
            return new == q.answer ? .success : .error
        }
    }

    // MARK: - 出題

    private func play(_ q: Question) -> some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(index), total: Double(questions.count))
                .tint(Hue.color(q.mode.topic))
                .padding(.horizontal, 16)

            VStack(spacing: 10) {
                Text(q.mode.question)
                    .font(.subheadline.bold())
                    .foregroundStyle(Hue.color(q.mode.topic))
                promptView(q)
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(Hue.card, in: .rect(cornerRadius: 18))
            }
            .padding(16)

            choicesView(q)
                .padding(.horizontal, 16)

            Spacer(minLength: 12)

            if let chosen {
                answerCard(q, chosen: chosen)
                    .padding(16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.25), value: chosen)
        .id(q.id)
    }

    @ViewBuilder private func promptView(_ q: Question) -> some View {
        if q.mode == .flagToName {
            Text(q.prompt)
                .font(.system(size: 120))
                .accessibilityLabel("国旗")
        } else {
            Text(q.prompt)
                .font(.system(size: 34, weight: .heavy))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder private func choicesView(_ q: Question) -> some View {
        if q.mode == .nameToFlag {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(q.choices) { c in
                    choiceButton(q, c) {
                        Text(c.flag)
                            .font(.system(size: 76))
                            .frame(maxWidth: .infinity, minHeight: 110)
                    }
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(q.choices) { c in
                    choiceButton(q, c) {
                        Text(q.label(of: c))
                            .font(.title3.bold())
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
    }

    private func choiceButton(_ q: Question, _ c: Country, @ViewBuilder label: () -> some View) -> some View {
        let state = state(of: c, in: q)
        return Button {
            answer(q, c)
        } label: {
            label()
                .foregroundStyle(.primary)
                .background(state.fill, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(state.stroke, lineWidth: 3))
                .overlay(alignment: .topTrailing) {
                    if let mark = state.mark {
                        Image(systemName: mark)
                            .font(.title3.bold())
                            .foregroundStyle(state.stroke)
                            .padding(6)
                    }
                }
                .opacity(state.dim ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(chosen == nil)
        .accessibilityLabel(q.mode == .nameToFlag ? "国旗 \(choiceIndex(q, c))" : q.label(of: c))
        .accessibilityIdentifier("choice-\(choiceIndex(q, c))")
    }

    private func choiceIndex(_ q: Question, _ c: Country) -> Int { (q.choices.firstIndex(of: c) ?? 0) + 1 }

    private struct ChoiceState {
        var fill: Color = Hue.card
        var stroke: Color = .clear
        var mark: String?
        var dim = false
    }

    private func state(of c: Country, in q: Question) -> ChoiceState {
        guard let chosen else { return ChoiceState() }
        if c == q.answer {
            return ChoiceState(fill: Hue.correct.opacity(0.15), stroke: Hue.correct, mark: "checkmark.circle.fill")
        }
        if c == chosen {
            return ChoiceState(fill: Hue.wrong.opacity(0.12), stroke: Hue.wrong, mark: "xmark.circle.fill")
        }
        return ChoiceState(dim: true)
    }

    // MARK: - 答えのあと

    private func answerCard(_ q: Question, chosen: Country) -> some View {
        let right = chosen == q.answer
        return VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: right ? "circle" : "xmark")
                    .font(.title.bold())
                Text(right ? "せいかい！" : "ざんねん")
                    .font(.title3.bold())
                Spacer()
            }
            .foregroundStyle(right ? Hue.correct : Hue.wrong)

            CountryLine(country: q.answer)

            if !right {
                HStack(spacing: 6) {
                    Text("えらんだのは")
                        .foregroundStyle(.secondary)
                    Text("\(chosen.flag) \(chosen.name)（\(chosen.capital)）")
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 0)
                }
                .font(.footnote)
            }

            Button {
                next()
            } label: {
                Text(index + 1 < questions.count ? "つぎへ" : "結果を見る")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(Hue.color(q.mode.topic))
            .accessibilityIdentifier("next")
        }
        .padding(16)
        .background(Hue.card, in: .rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 2)
    }

    private func answer(_ q: Question, _ c: Country) {
        guard chosen == nil else { return }
        chosen = c
        let right = c == q.answer
        progress.record(q.answer.code, q.mode.topic, correct: right)
        if right {
            // 正解なら少し見せて、そのまま次へ。
            advance = Task {
                try? await Task.sleep(for: .seconds(1.1))
                guard !Task.isCancelled else { return }
                next()
            }
        } else {
            misses.append(q)
        }
    }

    private func next() {
        advance?.cancel()
        advance = nil
        chosen = nil
        if index + 1 < questions.count {
            index += 1
        } else {
            finished = true
        }
    }

    private func retryMisses() {
        var rng = SystemRandomNumberGenerator()
        let again = misses.map { QuizMaker.question(for: $0.answer, mode: $0.mode, using: &rng) }.shuffled()
        questions = again
        misses = []
        index = 0
        chosen = nil
        finished = false
    }
}

/// 国旗・国名・首都を1行で。
struct CountryLine: View {
    let country: Country

    var body: some View {
        HStack(spacing: 12) {
            Text(country.flag)
                .font(.system(size: 44))
            VStack(alignment: .leading, spacing: 2) {
                Text(country.name)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text("首都 \(country.capital)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let note = country.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
