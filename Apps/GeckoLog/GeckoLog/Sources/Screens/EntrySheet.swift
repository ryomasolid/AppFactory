import SwiftData
import SwiftUI

/// 記録の追加・編集。種類ごとに必要な欄だけを出す。
struct EntrySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let gecko: Gecko
    let kind: CareKind
    let existing: CareEntry?

    @State private var occurredAt = Date()
    @State private var accepted = true
    @State private var feeder: Feeder = .cricket
    @State private var count = 3
    @State private var dusted = false
    @State private var skinLeftover = false
    @State private var gramsText = ""
    @State private var dropping: Dropping = .normal
    @State private var warmText = ""
    @State private var humidityText = ""
    @State private var note = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("日時", selection: $occurredAt, in: ...Date())
                }
                fields
                Section(kind == .memo || kind == .vet || kind == .cleaning ? "内容" : "メモ") {
                    TextField(placeholder, text: $note, axis: .vertical)
                        .lineLimit(2...6)
                }
                if let existing {
                    Section {
                        Button("この記録を削除", role: .destructive) {
                            context.delete(existing)
                            finish()
                        }
                    }
                }
            }
            .navigationTitle("\(gecko.name)の\(kind.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save).disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    @ViewBuilder private var fields: some View {
        switch kind {
        case .feeding:
            Section {
                Picker("結果", selection: $accepted) {
                    Text("食べた").tag(true)
                    Text("食べなかった").tag(false)
                }
                .pickerStyle(.segmented)
                if accepted {
                    FeederPicker(feeder: $feeder)
                    Stepper("\(count)\(feeder.counter)", value: $count, in: 0...50)
                    Toggle("カルシウム・ビタミンをまぶした", isOn: $dusted)
                }
            }
        case .shed:
            Section {
                Toggle("指先・しっぽの先に皮が残った", isOn: $skinLeftover)
            } footer: {
                Text("残った皮は締め付けて指先が取れる原因になります。ぬるま湯で湿らせてから、無理せず取ってあげましょう。")
            }
        case .weight:
            Section("体重") {
                HStack {
                    TextField("例: 45.5", text: $gramsText).keyboardType(.decimalPad)
                    Text("g").foregroundStyle(.secondary)
                }
            }
        case .dropping:
            Section("ようす") {
                Picker("ようす", selection: $dropping) {
                    ForEach(Dropping.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        case .climate:
            Section {
                HStack {
                    Text("ホットスポット")
                    TextField("例: 31", text: $warmText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Text("℃").foregroundStyle(.secondary)
                }
                HStack {
                    Text("湿度")
                    TextField("例: 50", text: $humidityText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Text("%").foregroundStyle(.secondary)
                }
            } footer: {
                Text("目安はホットスポット 30〜32℃・ケージ全体 25〜28℃・湿度 40〜60%（ウェットシェルターはもっと高く）。")
            }
        case .cleaning, .vet, .memo:
            EmptyView()
        }
    }

    private var placeholder: String {
        switch kind {
        case .vet: "病院名・診断・お薬など"
        case .cleaning: "床材交換・水入れ洗い など"
        default: "気づいたこと"
        }
    }

    private var canSave: Bool {
        switch kind {
        case .weight: number(gramsText) != nil
        case .climate: number(warmText) != nil || number(humidityText) != nil
        case .vet, .memo: !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .feeding, .shed, .dropping, .cleaning: true
        }
    }

    private func number(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let entry = existing else {
            // ごはんは前回と同じエサ・数から始める。
            if kind == .feeding, let last = gecko.allEntries
                .filter({ $0.kind == .feeding && $0.accepted && $0.feeder != nil })
                .max(by: { $0.occurredAt < $1.occurredAt }) {
                feeder = last.feeder ?? .cricket
                count = last.feederCount
                dusted = last.dusted
            }
            return
        }
        occurredAt = entry.occurredAt
        accepted = entry.accepted
        feeder = entry.feeder ?? .cricket
        count = entry.feederCount
        dusted = entry.dusted
        skinLeftover = entry.skinLeftover
        gramsText = entry.grams.map { String(format: "%g", $0) } ?? ""
        dropping = entry.dropping ?? .normal
        warmText = entry.warmSideC.map { String(format: "%g", $0) } ?? ""
        humidityText = entry.humidityPercent.map { String(format: "%g", $0) } ?? ""
        note = entry.note
    }

    private func save() {
        let entry = existing ?? CareEntry(kind: kind, occurredAt: occurredAt, gecko: gecko)
        entry.occurredAt = occurredAt
        entry.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .feeding:
            entry.accepted = accepted
            entry.feederCode = accepted ? feeder.rawValue : ""
            entry.feederCount = accepted ? count : 0
            entry.dusted = accepted && dusted
        case .shed:
            entry.skinLeftover = skinLeftover
        case .weight:
            entry.grams = number(gramsText)
        case .dropping:
            entry.droppingCode = dropping.rawValue
        case .climate:
            entry.warmSideC = number(warmText)
            entry.humidityPercent = number(humidityText)
        case .cleaning, .vet, .memo:
            break
        }
        if existing == nil { context.insert(entry) }
        finish()
    }

    private func finish() {
        try? context.save()
        Task { await FeedingAlarm.reschedule(context: context) }
        dismiss()
    }
}
