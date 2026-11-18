import SwiftUI

/// 1回ぶんのクイズの設定。
struct Round: Identifiable {
    let id = UUID()
    let questions: [Question]
}

struct HomeTab: View {
    @Environment(Learned.self) private var progress
    @AppStorage("region") private var regionRaw = ""
    @AppStorage("count") private var count = 10
    @State private var round: Round?
    @State private var confirmReset = false

    private var region: Region? { Region(rawValue: regionRaw) }
    private var pool: [Country] { region.map { r in Country.all.filter { $0.region == r } } ?? Country.all }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    progressCard
                    scopeCard
                    VStack(spacing: 10) {
                        sectionTitle("国旗をおぼえる")
                        HStack(spacing: 10) {
                            modeButton(.flagToName)
                            modeButton(.nameToFlag)
                        }
                        sectionTitle("首都をおぼえる")
                        HStack(spacing: 10) {
                            modeButton(.nameToCapital)
                            modeButton(.capitalToName)
                        }
                        sectionTitle("まとめて")
                        mixButton
                        weakButtons
                    }
                }
                .padding(16)
            }
            .background(Hue.page)
            .navigationTitle("国旗と首都")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("記録をリセット", systemImage: "arrow.counterclockwise", role: .destructive) {
                            confirmReset = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("覚えた記録をすべて消しますか？", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("リセット", role: .destructive) { progress.reset() }
            }
            .fullScreenCover(item: $round) { r in
                QuizView(questions: r.questions, showAnswer: Demo.answered)
            }
            .task {
                if let mode = Demo.quizMode, round == nil { start([mode], pool: pool) }
            }
        }
    }

    // MARK: - 部品

    private var progressCard: some View {
        HStack(spacing: 12) {
            ring(.flag)
            ring(.capital)
        }
    }

    private func ring(_ topic: Topic) -> some View {
        let done = progress.masteredCount(topic, in: pool)
        let total = pool.count
        let color = Hue.color(topic)
        return VStack(spacing: 8) {
            ZStack {
                Circle().stroke(color.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: total == 0 ? 0 : CGFloat(done) / CGFloat(total))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(done)")
                        .font(.title.bold().monospacedDigit())
                    Text("/ \(total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 96, height: 96)
            Text("\(topic.label)を覚えた")
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Hue.card, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var scopeCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label("出題する地域", systemImage: "globe")
                    .font(.subheadline)
                Spacer()
                Menu {
                    Picker("地域", selection: $regionRaw) {
                        Text("世界ぜんぶ（\(Country.all.count)か国）").tag("")
                        ForEach(Region.allCases) { r in
                            Text("\(r.label)（\(Country.all.filter { $0.region == r }.count)か国）").tag(r.rawValue)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(region?.label ?? "世界ぜんぶ")
                        Image(systemName: "chevron.up.chevron.down").font(.caption)
                    }
                    .font(.subheadline.bold())
                }
            }
            Divider()
            HStack {
                Label("1回の問題数", systemImage: "number")
                    .font(.subheadline)
                Spacer()
                Picker("問題数", selection: $count) {
                    Text("10問").tag(10)
                    Text("20問").tag(20)
                    Text("30問").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
        }
        .padding(16)
        .background(Hue.card, in: .rect(cornerRadius: 16))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }

    private func modeButton(_ mode: Mode) -> some View {
        Button {
            start([mode], pool: pool)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: mode.symbol)
                    .font(.title2)
                Text(mode.title)
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .foregroundStyle(.white)
            .background(Hue.color(mode.topic).gradient, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("mode.\(mode.rawValue)")
    }

    private var mixButton: some View {
        Button {
            start(Mode.allCases, pool: pool)
        } label: {
            Label("4つの出し方をまぜる", systemImage: "shuffle")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(.white)
                .background(LinearGradient(colors: [Hue.navy, Hue.color(.capital)], startPoint: .leading, endPoint: .trailing), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var weakButtons: some View {
        let weakFlags = progress.weak(.flag, in: pool)
        let weakCaps = progress.weak(.capital, in: pool)
        if !weakFlags.isEmpty || !weakCaps.isEmpty {
            HStack(spacing: 10) {
                weakButton(.flag, weakFlags)
                weakButton(.capital, weakCaps)
            }
        }
    }

    private func weakButton(_ topic: Topic, _ list: [Country]) -> some View {
        Button {
            let modes: [Mode] = topic == .flag ? [.flagToName, .nameToFlag] : [.nameToCapital, .capitalToName]
            start(modes, pool: list)
        } label: {
            VStack(spacing: 2) {
                Text("にがてな\(topic.label)")
                    .font(.subheadline.bold())
                Text("\(list.count)か国")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(list.isEmpty ? Color.secondary : Hue.wrong)
            .background(Hue.card, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(list.isEmpty ? .clear : Hue.wrong.opacity(0.4), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(list.isEmpty)
    }

    private func start(_ modes: [Mode], pool: [Country]) {
        var rng = SystemRandomNumberGenerator()
        // まぜるときは、国ごとに出し方を決めるので、国旗と首都の記録の低いほうで選ぶ。
        let topic = modes.allSatisfy { $0.topic == .capital } ? Topic.capital : .flag
        let picked = QuizMaker.pick(from: pool, count: count, topic: topic, progress: progress, using: &rng)
        round = Round(questions: QuizMaker.round(modes: modes, countries: picked, using: &rng))
    }
}
