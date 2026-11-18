import SwiftData
import SwiftUI

/// お金を使ったときの入力。「ついつい」か「必要」かを先に選ぶ。
struct SpendSheet: View {
    let day: Date

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var want = true
    @State private var yen: Int?
    @State private var type: SpendType = .konbini
    @State private var memo = ""
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("種類", selection: $want) {
                        Text("ついつい（ムダ）").tag(true)
                        Text("必要な出費").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .accessibilityIdentifier("want-picker")
                } footer: {
                    Text(want
                        ? "なくても困らなかったもの。今月のムダ予算から引きます。"
                        : "食材・日用品・交通など。ムダゼロの日にかぞえます。")
                }

                Section("金額") {
                    HStack {
                        TextField("0", value: $yen, format: .number)
                            .keyboardType(.numberPad)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .focused($amountFocused)
                            .accessibilityIdentifier("amount")
                        Text("円").font(.title3.weight(.semibold)).foregroundStyle(Hue.soft)
                    }
                }

                Section("なにに？") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(SpendType.choices(want: want)) { t in
                            Button {
                                type = t
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: t.symbol).font(.title3)
                                    Text(t.label).font(.caption2.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .foregroundStyle(type == t ? .white : Hue.ink)
                                .background(type == t ? tint : Hue.line.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("type-\(t.rawValue)")
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("メモ（なくてもOK）") {
                    TextField("例: 新作のアイス", text: $memo)
                        .accessibilityIdentifier("memo")
                }
            }
            .navigationTitle(Words.day(day) + "使ったお金")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save).disabled((yen ?? 0) <= 0)
                }
            }
            .onChange(of: want) { _, w in type = SpendType.choices(want: w)[0] }
            .onAppear { amountFocused = true }
        }
    }

    private var tint: Color { want ? Hue.salmon : Hue.mint }

    private func save() {
        guard let yen, yen > 0 else { return }
        context.insert(Spend(day: day, yen: yen, category: type, memo: memo.trimmingCharacters(in: .whitespacesAndNewlines)))
        try? context.save()
        Task { await Notice.reschedule(context) }
        dismiss()
    }
}
