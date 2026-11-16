import SwiftData
import SwiftUI

/// おせわタブ：大掃除・止まり木・爪切り・水浴び・健康診断の「前回」と「次の目安」。
struct ChoresTab: View {
    @Query(sort: \Bird.sortIndex) private var birds: [Bird]
    @AppStorage(Picked.key) private var picked = ""
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            List {
                if let bird = Picked.bird(in: birds, tag: picked) {
                    Section {
                        ForEach(ChoreKind.allCases) { kind in
                            let last = (bird.chores ?? []).filter { $0.kind == kind }.map(\.doneOn).max()
                            let due = ChoreClock.due(kind: kind, last: last, now: Date())
                            HStack(spacing: 12) {
                                NavigationLink { ChoreHistory(bird: bird, kind: kind) } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: kind.symbol)
                                            .foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Hue.sky, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(kind.label).font(.subheadline.weight(.semibold))
                                            if let left = due.daysLeft, let next = due.next {
                                                Text("次は \(Say.day(next))（\(Say.until(left))）")
                                                    .font(.caption)
                                                    .foregroundStyle(left < 0 ? Hue.danger : left <= 1 ? Hue.lemon : Hue.soft)
                                            } else {
                                                Text("目安 \(kind.everyDays)日ごと").font(.caption).foregroundStyle(Hue.soft)
                                            }
                                        }
                                    }
                                }
                                Button("した") { done(kind, bird) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .disabled(last.map { Calendar.current.isDateInToday($0) } ?? false)
                                    .accessibilityIdentifier("chore-\(kind.rawValue)")
                            }
                        }
                    } footer: {
                        Text("間隔は一般的な目安です。爪やくちばしの伸び方は子によって違います。健康診断は鳥をみられる病院で。")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Hue.ground)
            .navigationTitle("おせわ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { BirdMenu(birds: birds, tag: $picked) } }
        }
    }

    private func done(_ kind: ChoreKind, _ bird: Bird) {
        context.insert(Chore(kind: kind, doneOn: Date(), bird: bird))
        try? context.save()
    }
}

private struct ChoreHistory: View {
    let bird: Bird
    let kind: ChoreKind
    @Environment(\.modelContext) private var context
    @State private var date = Date()

    var body: some View {
        let list = (bird.chores ?? []).filter { $0.kind == kind }.sorted { $0.doneOn > $1.doneOn }
        List {
            Section("日付を選んで記録") {
                DatePicker("した日", selection: $date, in: ...Date(), displayedComponents: .date)
                Button("この日に記録") {
                    context.insert(Chore(kind: kind, doneOn: date, bird: bird))
                    try? context.save()
                }
            }
            if !list.isEmpty {
                Section("これまで") {
                    ForEach(list) { Text(Say.ymd($0.doneOn)) }
                        .onDelete { offsets in
                            offsets.map { list[$0] }.forEach(context.delete)
                            try? context.save()
                        }
                }
            }
        }
        .navigationTitle(kind.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}
