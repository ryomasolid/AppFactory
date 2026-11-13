import SwiftUI

/// 1日ぶんの記録（間食・体重・メモ）を書くシート。閉じるときに保存する。
struct DaySheet: View {
    struct Target: Identifiable {
        let key: String
        var id: String { key }
    }

    let target: Target
    @Environment(SnackBook.self) private var book
    @Environment(\.dismiss) private var dismiss
    @State private var draft = DayEntry()
    @State private var loaded = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Spacer(minLength: 0)
                        StatusBubble(status: .skipped, isOn: draft.status == .skipped, diameter: 110) { toggle(.skipped) }
                        StatusBubble(status: .snacked, isOn: draft.status == .snacked, diameter: 110) { toggle(.snacked) }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.clear)
                }
                Section("体重（kg）") {
                    TextField("例：55.2", text: $draft.weight)
                        .keyboardType(.decimalPad)
                        .focused($focused)
                        .onChange(of: draft.weight) { _, new in
                            if new.count > 6 { draft.weight = String(new.prefix(6)) }
                        }
                }
                Section("メモ") {
                    TextField("食べたもの・食べたくなった理由など", text: $draft.memo, axis: .vertical)
                        .lineLimit(3...8)
                        .focused($focused)
                        .onChange(of: draft.memo) { _, new in
                            if new.count > 200 { draft.memo = String(new.prefix(200)) }
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.paper)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("閉じる") { focused = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            guard !loaded else { return }
            draft = book.entry(for: target.key)
            loaded = true
        }
        .onDisappear {
            book.set(draft, for: target.key)
        }
    }

    private var title: String {
        guard let date = DayKey.date(target.key) else { return "" }
        return date.formatted(.dateTime.month().day().weekday(.abbreviated))
    }

    private func toggle(_ status: SnackStatus) {
        withAnimation(.snappy) { draft.status = draft.status == status ? .none : status }
    }
}
