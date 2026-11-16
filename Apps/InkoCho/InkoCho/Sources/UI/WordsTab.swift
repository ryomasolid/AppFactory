import SwiftData
import SwiftUI

/// ことばタブ：おぼえた言葉・鳴きまねを、はじめて聞いた日といっしょに。
struct WordsTab: View {
    @Query(sort: \Bird.sortIndex) private var birds: [Bird]
    @AppStorage(Picked.key) private var picked = ""
    @Environment(\.modelContext) private var context
    @State private var adding = false

    var body: some View {
        NavigationStack {
            List {
                if let bird = Picked.bird(in: birds, tag: picked) {
                    let words = bird.vocabulary
                    Section {
                        HStack(spacing: 14) {
                            BirdBadge(bird: bird, size: 54)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("おぼえた言葉").font(.caption).foregroundStyle(Hue.soft)
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text("\(words.count)").font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(Hue.sky)
                                    Text("こ").foregroundStyle(Hue.soft)
                                }
                            }
                            Spacer()
                            if let first = words.last {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("さいしょの言葉").font(.caption2).foregroundStyle(Hue.soft)
                                    Text("「\(first.text)」").font(.subheadline.weight(.semibold)).lineLimit(1)
                                }
                            }
                        }
                        Button { adding = true } label: { Label("言葉を追加", systemImage: "plus.bubble.fill") }
                            .accessibilityIdentifier("add-word")
                    } footer: {
                        Text("セキセイインコはオスのほうがよくおしゃべりします。鳴きまね（電子レンジの音など）も残せます。")
                    }
                    if !words.isEmpty {
                        Section("言葉の一覧") {
                            ForEach(words) { w in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("「\(w.text)」").font(.body.weight(.semibold)).foregroundStyle(Hue.ink)
                                    Text("\(Say.ymd(w.heardOn)) にはじめて" + (w.memo.isEmpty ? "" : "・\(w.memo)")).font(.caption).foregroundStyle(Hue.soft)
                                }
                                .padding(.vertical, 2)
                            }
                            .onDelete { offsets in
                                offsets.map { words[$0] }.forEach(context.delete)
                                try? context.save()
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Hue.ground)
            .navigationTitle("ことば")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { BirdMenu(birds: birds, tag: $picked) } }
            .sheet(isPresented: $adding) {
                if let bird = Picked.bird(in: birds, tag: picked) { WordSheet(bird: bird) }
            }
        }
    }
}

private struct WordSheet: View {
    let bird: Bird
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var heardOn = Date()
    @State private var memo = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("おはよう", text: $text).focused($focused).accessibilityIdentifier("word-text")
                DatePicker("はじめて聞いた日", selection: $heardOn, in: ...Date(), displayedComponents: .date)
                TextField("メモ（どんなときに言う など）", text: $memo)
            }
            .navigationTitle("言葉を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let word = Word(text: text.trimmingCharacters(in: .whitespacesAndNewlines), heardOn: heardOn, bird: bird)
                        word.memo = memo.trimmingCharacters(in: .whitespaces)
                        context.insert(word)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}
