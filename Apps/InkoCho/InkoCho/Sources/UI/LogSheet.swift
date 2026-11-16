import StoreKit
import SwiftData
import SwiftUI

/// 1日の記録（体重・様子・フン・放鳥・室温・換羽・産卵・写真・メモ）。
struct LogSheet: View {
    let bird: Bird

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var day: Date
    @State private var gramsText = ""
    @State private var look: Look?
    @State private var dropping: Dropping?
    @State private var outside = 0
    @State private var tempText = ""
    @State private var molting = false
    @State private var laidEgg = false
    @State private var memo = ""
    @State private var picture: Data?

    init(bird: Bird, day: Date) {
        self.bird = bird
        _day = State(initialValue: Calendar.current.startOfDay(for: day))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("日付", selection: $day, in: ...Date(), displayedComponents: .date)
                        .onChange(of: day) { _, _ in fill() }
                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("35.0", text: $gramsText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
                            .accessibilityIdentifier("log-grams")
                        Text("g").foregroundStyle(.secondary)
                    }
                }
                Section("様子") {
                    Flow(spacing: 8) {
                        ForEach(Look.allCases) { l in
                            Button { look = look == l ? nil : l } label: {
                                Label(l.label, systemImage: l.symbol)
                                    .font(.subheadline)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .foregroundStyle(look == l ? .white : (l.warning ? Hue.danger : Hue.blush))
                                    .background(look == l ? (l.warning ? Hue.danger : Hue.blush) : Hue.blush.opacity(0.1), in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("look-\(l.rawValue)")
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("フン") {
                    Picker("フン", selection: $dropping) {
                        Text("記録しない").tag(Dropping?.none)
                        ForEach(Dropping.allCases) { Text($0.label).tag(Optional($0)) }
                    }
                }
                Section("放鳥・室温") {
                    Stepper(outside == 0 ? "放鳥 ―" : "放鳥 \(outside)分", value: $outside, in: 0...600, step: 10)
                        .accessibilityIdentifier("outside")
                    HStack {
                        Text("室温")
                        Spacer()
                        TextField("24.0", text: $tempText).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
                        Text("℃").foregroundStyle(.secondary)
                    }
                    Toggle("換羽中", isOn: $molting)
                    if bird.sex != .male { Toggle("卵を産んだ", isOn: $laidEgg) }
                }
                Section("写真") {
                    PhotoField(data: $picture).listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                }
                Section("メモ") {
                    TextField("おぼえた言葉・できごと など", text: $memo, axis: .vertical).lineLimit(3...10)
                }
            }
            .navigationTitle("\(bird.name)の\(Say.day(day))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save) }
            }
            .onAppear(perform: fill)
        }
    }

    private func number(_ s: String) -> Double? { Double(s.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) }

    private func fill() {
        let log = bird.log(on: day)
        gramsText = log?.grams.map { String(format: "%.1f", $0) } ?? ""
        look = log?.look
        dropping = log?.dropping
        outside = log?.outsideMinutes ?? 0
        tempText = log?.roomCelsius.map { String(format: "%.1f", $0) } ?? ""
        molting = log?.molting ?? (bird.log(on: Calendar.current.date(byAdding: .day, value: -1, to: day)!)?.molting ?? false)
        laidEgg = log?.laidEgg ?? false
        memo = log?.memo ?? ""
        picture = log?.picture
    }

    private func save() {
        let existing = bird.log(on: day)
        let log = existing ?? DayLog(day: day, bird: bird)
        log.grams = number(gramsText).flatMap { (10...120).contains($0) ? $0 : nil }
        log.look = look
        log.dropping = dropping
        log.outsideMinutes = outside
        log.roomCelsius = number(tempText).flatMap { (-10...50).contains($0) ? $0 : nil }
        log.molting = molting
        log.laidEgg = laidEgg
        log.memo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        log.picture = picture
        if log.isEmpty {
            if existing != nil { context.delete(log) }
        } else if existing == nil {
            context.insert(log)
        }
        try? context.save()
        // 記録を続けている人にだけ、ときどき評価をお願いする。
        if !Demo.on, [7, 30, 90].contains(bird.logs?.count ?? 0) { requestReview() }
        dismiss()
    }
}
