import StoreKit
import SwiftUI

/// きょう間食したかを 1 タップで記録する画面。
struct TodayScreen: View {
    @Environment(SnackBook.self) private var book
    @Environment(\.requestReview) private var requestReview
    @State private var editing: DaySheet.Target?

    private var now: Date { Sample.now }
    private var key: String { DayKey.of(now) }

    var body: some View {
        let entry = book.entry(for: key)
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text(now, format: .dateTime.month().day().weekday(.wide))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.mute)
                        Text("きょう、間食した？")
                            .font(.title.bold())
                            .foregroundStyle(Palette.ink)
                    }
                    .padding(.top, 8)

                    HStack(spacing: 18) {
                        StatusBubble(status: .skipped, isOn: entry.status == .skipped) { choose(.skipped) }
                        StatusBubble(status: .snacked, isOn: entry.status == .snacked) { choose(.snacked) }
                    }

                    Text(message(for: entry.status))
                        .font(.callout)
                        .foregroundStyle(Palette.mute)
                        .multilineTextAlignment(.center)
                        .frame(minHeight: 44)

                    StreakTiles(
                        current: Streak.current(book.entries, today: now),
                        best: Streak.best(book.entries, today: now)
                    )

                    Button {
                        editing = DaySheet.Target(key: key)
                    } label: {
                        Card {
                            HStack {
                                Image(systemName: "scalemass")
                                    .foregroundStyle(Palette.crust)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("体重とメモ")
                                        .font(.headline)
                                        .foregroundStyle(Palette.ink)
                                    Text(summary(entry))
                                        .font(.caption)
                                        .foregroundStyle(Palette.mute)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Palette.mute)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                // iPad では横に広がりすぎないよう、iPhone くらいの幅で真ん中に置く。
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Palette.paper)
            .navigationTitle("間食ストップ")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editing) { target in
                DaySheet(target: target)
            }
        }
    }

    private func choose(_ status: SnackStatus) {
        let current = book.entry(for: key).status
        // もう一度押すと取り消し（旧版と同じ）。
        let next: SnackStatus = current == status ? .none : status
        withAnimation(.snappy) { book.setStatus(next, for: key) }
        if next == .skipped, ReviewAsk.shouldAsk(skippedDays: book.skippedDays) {
            ReviewAsk.markAsked()
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                requestReview()
            }
        }
    }

    private func message(for status: SnackStatus) -> String {
        switch status {
        case .none: "寝る前に、どちらかをタップ。\nあとからカレンダーで直せます。"
        case .skipped: "えらい！ 連続記録をのばそう。"
        case .snacked: "記録できたのがえらい。\nあしたまた、ここから。"
        }
    }

    private func summary(_ entry: DayEntry) -> String {
        var parts: [String] = []
        if !entry.weight.isEmpty { parts.append("\(entry.weight) kg") }
        if !entry.memo.isEmpty { parts.append(entry.memo.replacingOccurrences(of: "\n", with: " ")) }
        return parts.isEmpty ? "きょうの体重や、食べたものを書いておけます" : parts.joined(separator: "・")
    }
}
