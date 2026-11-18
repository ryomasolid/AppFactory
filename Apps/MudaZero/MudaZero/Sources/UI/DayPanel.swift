import SwiftData
import SwiftUI

/// 1日ぶん：結果のカード・しめるボタン・使ったお金の一覧。きょうタブとカレンダーの両方で使う。
struct DayPanel: View {
    let day: Date
    let book: Book
    /// その日の出費（新しい順）。
    let spends: [Spend]
    let marks: [DayMark]

    @Environment(\.modelContext) private var context
    @State private var adding = false
    @State private var cheer = 0

    private var kind: DayKind { book.kind(on: day) }
    private var isToday: Bool { book.calendar.isDateInToday(day) }
    private var subject: String { isToday ? "きょう" : "この日" }

    var body: some View {
        VStack(spacing: 12) {
            result
            if !spends.isEmpty { list }
        }
        .sensoryFeedback(.success, trigger: cheer)
        .sheet(isPresented: $adding) { SpendSheet(day: day) }
    }

    // MARK: 結果

    @ViewBuilder private var result: some View {
        VStack(spacing: 14) {
            switch kind {
            case .open(let need):
                VStack(spacing: 6) {
                    Text("\(subject)は まだ しめていません")
                        .font(.headline)
                        .foregroundStyle(Hue.ink)
                    Text(need > 0
                        ? "必要な出費 \(need.yen) だけなら、ムダゼロでしめられます。"
                        : "ムダ遣いしなかったら、ねる前にタップ。")
                        .font(.subheadline)
                        .foregroundStyle(Hue.soft)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
                Button(action: close) {
                    Label("ムダ遣いしなかった", systemImage: "checkmark.seal.fill")
                        .font(.title3.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Hue.mint)
                .accessibilityIdentifier("close-day")
                spendButton(prominent: true)

            case .zero, .clean:
                Badge(kind: kind)
                HStack {
                    spendButton(prominent: false)
                    Spacer()
                    Button("取り消す", action: reopen)
                        .font(.footnote)
                        .foregroundStyle(Hue.soft)
                        .accessibilityIdentifier("reopen-day")
                }

            case .slipped:
                Badge(kind: kind)
                spendButton(prominent: false)
            }
        }
        .card(18)
    }

    private func spendButton(prominent: Bool) -> some View {
        Button {
            adding = true
        } label: {
            Label("お金を使った", systemImage: "plus.circle")
                .font(prominent ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                .frame(maxWidth: prominent ? .infinity : nil)
                .padding(.vertical, prominent ? 10 : 0)
        }
        .buttonStyle(.bordered)
        .tint(prominent ? Hue.ink : Hue.mint)
        .accessibilityIdentifier("add-spend")
    }

    // MARK: 一覧

    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("使ったお金")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Hue.soft)
                .padding(.bottom, 8)
            ForEach(spends) { s in
                HStack(spacing: 12) {
                    Image(systemName: s.category.symbol)
                        .frame(width: 32, height: 32)
                        .foregroundStyle(s.isWant ? Hue.salmon : Hue.mint)
                        .background((s.isWant ? Hue.salmon : Hue.mint).opacity(0.13), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.memo.isEmpty ? s.category.label : s.memo)
                            .foregroundStyle(Hue.ink)
                        Text(s.isWant ? "ついつい・\(s.category.label)" : "必要・\(s.category.label)")
                            .font(.caption)
                            .foregroundStyle(Hue.soft)
                    }
                    Spacer()
                    Text(s.yen.yen)
                        .font(.body.weight(.semibold).monospacedDigit())
                        .foregroundStyle(s.isWant ? Hue.salmon : Hue.ink)
                    Menu {
                        Button("消す", systemImage: "trash", role: .destructive) { remove(s) }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Hue.soft)
                            .frame(width: 28, height: 32)
                    }
                    .accessibilityLabel("\(s.yen.yen)の記録の操作")
                }
                .padding(.vertical, 6)
            }
        }
        .card()
    }

    // MARK: 操作

    private func close() {
        if marks.isEmpty { context.insert(DayMark(day: day)) }
        try? context.save()
        cheer += 1
        Task { await Notice.reschedule(context) }
    }

    private func reopen() {
        marks.forEach(context.delete)
        try? context.save()
        Task { await Notice.reschedule(context) }
    }

    private func remove(_ s: Spend) {
        context.delete(s)
        try? context.save()
        Task { await Notice.reschedule(context) }
    }
}

/// 0円の日・ムダゼロ・ついつい の大きな表示。
struct Badge: View {
    let kind: DayKind

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(kind.color.gradient)
                Circle().strokeBorder(.white.opacity(0.5), lineWidth: 3).padding(5)
                Text(mark)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 68, height: 68)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(kind.color)
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(Hue.soft)
            }
            Spacer(minLength: 0)
        }
    }

    private var mark: String {
        switch kind {
        case .zero: "0円"
        case .clean: "ゼロ"
        case .slipped: "…"
        case .open: ""
        }
    }

    private var title: String {
        switch kind {
        case .zero: "0円の日！"
        case .clean: "ムダゼロ！"
        case .slipped(let want, _): "ついつい \(want.yen)"
        case .open: ""
        }
    }

    private var note: String {
        switch kind {
        case .zero: "1円も使わなかった、最高の日です。"
        case .clean(let need): "必要な出費 \(need.yen) だけ。えらい！"
        case .slipped(_, let need): need > 0 ? "必要な出費 \(need.yen) も記録ずみ。次はムダゼロに。" : "記録できたのがえらい。次はムダゼロに。"
        case .open: ""
        }
    }
}
