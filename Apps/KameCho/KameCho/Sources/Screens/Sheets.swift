import SwiftData
import SwiftUI

/// ごはんをあげた。
struct FeedSheet: View {
    let turtle: Turtle
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var food: Food = .pellet
    @State private var appetite: Appetite = .all

    var body: some View {
        NavigationStack {
            Form {
                Picker("あげたもの", selection: $food) {
                    ForEach(Food.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.inline)
                Picker("食べぐあい", selection: $appetite) {
                    ForEach(Appetite.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("appetite")
            }
            .navigationTitle("\(turtle.name)のごはん")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let care = Care(kind: .feed, at: Date(), turtle: turtle)
                        care.food = food
                        care.appetite = appetite
                        context.insert(care)
                        Task { await Reminders.refresh(context) }
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 前回と同じものから始める。
                if let last = turtle.careLog.first(where: { $0.kind == .feed }), let f = last.food { food = f }
                else if turtle.species.habitat == .land { food = .greens }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// 甲長と体重を計った。
struct MeasureSheet: View {
    let turtle: Turtle
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var on = Date()
    @State private var shell = ""
    @State private var grams = ""

    var body: some View {
        let last = turtle.growth.last
        NavigationStack {
            Form {
                Section {
                    DatePicker("日にち", selection: $on, in: ...Date(), displayedComponents: .date)
                    HStack {
                        Text("甲長")
                        TextField(last?.shellMM.map { Fmt.number($0) } ?? "0", text: $shell)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("measure-shell")
                        Text("mm").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("体重")
                        TextField(last?.grams.map { Fmt.number($0) } ?? "0", text: $grams)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("measure-grams")
                        Text("g").foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("甲長は、背中の甲羅の頭側から尾側までをまっすぐ測ります。片方だけでも記録できます。")
                }
            }
            .navigationTitle("\(turtle.name)を計る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        context.insert(Measure(on: on, shellMM: Fmt.parse(shell), grams: Fmt.parse(grams), turtle: turtle))
                        Task { await Reminders.refresh(context) }
                        dismiss()
                    }
                    .disabled(Fmt.parse(shell) == nil && Fmt.parse(grams) == nil)
                }
            }
        }
        .presentationDetents([.large])
    }
}

/// 体のようす。気になるところに印を付ける。
struct CheckSheet: View {
    let turtle: Turtle
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var signs: Set<Sign> = []
    @State private var memo = ""
    @State private var photo: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Sign.allCases) { sign in
                        Button {
                            if signs.contains(sign) { signs.remove(sign) } else { signs.insert(sign) }
                        } label: {
                            HStack {
                                Image(systemName: signs.contains(sign) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(signs.contains(sign) ? (sign.serious ? Palette.rust : Palette.amber) : .secondary)
                                Text(sign.label).foregroundStyle(Palette.ink)
                            }
                        }
                        .accessibilityIdentifier("sign-\(sign.rawValue)")
                    }
                } header: {
                    Text("気になるところ")
                } footer: {
                    Text("何もなければ、そのまま保存して「異常なし」の記録にできます。")
                }
                Section("メモ") {
                    TextField("例：甲羅干しの時間が長かった", text: $memo, axis: .vertical)
                        .lineLimit(2...5)
                        .accessibilityIdentifier("check-memo")
                    PhotoPick(title: "写真を添える", data: $photo)
                }
            }
            .navigationTitle("体のようす")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let check = Checkup(on: Date(), turtle: turtle)
                        check.signs = signs
                        check.memo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
                        check.photo = photo
                        context.insert(check)
                        dismiss()
                    }
                }
            }
        }
    }
}
