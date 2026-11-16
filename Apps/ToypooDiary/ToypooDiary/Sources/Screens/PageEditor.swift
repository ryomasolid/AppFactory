import StoreKit
import SwiftData
import SwiftUI

/// 1日ぶんの日記を書く。同じ日のページがあれば、それを開いて書きたす。
struct PageEditor: View {
    let dog: Dog

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var day: Date
    @State private var photo: Data?
    @State private var mood: Mood?
    @State private var walkCount = 0
    @State private var walkMinutes = 0
    @State private var meals = 0
    @State private var brushed = false
    @State private var poop: Poop?
    @State private var tear: TearStain?
    @State private var note = ""
    @State private var weightText = ""

    init(dog: Dog, day: Date) {
        self.dog = dog
        _day = State(initialValue: Calendar.current.startOfDay(for: day))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("日付", selection: $day, in: ...Date(), displayedComponents: .date)
                        .onChange(of: day) { _, _ in load() }
                }
                Section {
                    PhotoSlot(data: $photo)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Section("きぶん") {
                    HStack(spacing: 6) {
                        ForEach(Mood.allCases) { option in
                            Button { mood = mood == option ? nil : option } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: option.symbol).font(.title3)
                                    Text(option.label).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundStyle(mood == option ? .white : Tone.rose)
                                .background(mood == option ? Tone.rose : Tone.rose.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("mood-\(option.rawValue)")
                        }
                    }
                }
                Section("おさんぽ") {
                    Stepper("\(walkCount)回", value: $walkCount, in: 0...6)
                        .accessibilityIdentifier("walk-count")
                    Stepper(walkMinutes == 0 ? "時間 ―" : "あわせて\(walkMinutes)分", value: $walkMinutes, in: 0...300, step: 5)
                        .accessibilityIdentifier("walk-minutes")
                }
                Section("ごはん・おせわ") {
                    Picker("ごはん", selection: $meals) {
                        Text("―").tag(0)
                        Text("1回").tag(1)
                        Text("2回").tag(2)
                        Text("3回").tag(3)
                    }
                    .pickerStyle(.segmented)
                    Toggle("歯みがきした", isOn: $brushed)
                    Picker("うんち", selection: $poop) {
                        Text("記録しない").tag(Poop?.none)
                        ForEach(Poop.allCases) { Text($0.label).tag(Optional($0)) }
                    }
                    Picker("涙やけ", selection: $tear) {
                        Text("記録しない").tag(TearStain?.none)
                        ForEach(TearStain.allCases) { Text($0.label).tag(Optional($0)) }
                    }
                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("3.20", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .accessibilityIdentifier("page-weight")
                        Text("kg").foregroundStyle(.secondary)
                    }
                }
                Section("メモ") {
                    TextField("きょうのできごと", text: $note, axis: .vertical)
                        .lineLimit(4...12)
                        .accessibilityIdentifier("page-note")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("\(dog.name)の\(Words.day(day))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        let page = dog.page(on: day)
        photo = page?.photo
        mood = page?.mood
        walkCount = page?.walkCount ?? 0
        walkMinutes = page?.walkMinutes ?? 0
        meals = page?.meals ?? 0
        brushed = page?.brushed ?? false
        poop = page?.poop
        tear = page?.tear
        note = page?.note ?? ""
        let weight = (dog.weighIns ?? []).first { Calendar.current.isDate($0.on, inSameDayAs: day) }
        weightText = weight.map { String(format: "%.2f", $0.kg) } ?? ""
    }

    private func save() {
        let existing = dog.page(on: day)
        let page = existing ?? DayPage(day: day, dog: dog)
        page.photo = photo
        page.mood = mood
        page.walkCount = walkCount
        page.walkMinutes = walkMinutes
        page.meals = meals
        page.brushed = brushed
        page.poop = poop
        page.tear = tear
        page.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if page.isBlank {
            if existing != nil { context.delete(page) }
        } else if existing == nil {
            context.insert(page)
        }
        saveWeight()
        try? context.save()

        // 書きつづけてくれている人にだけ、たまに評価をお願いする。
        let count = dog.pages?.count ?? 0
        if !Showcase.isOn, [5, 20, 60].contains(count) { requestReview() }
        dismiss()
    }

    private func saveWeight() {
        let sameDay = (dog.weighIns ?? []).first { Calendar.current.isDate($0.on, inSameDayAs: day) }
        let text = weightText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let kg = Double(text), (0.3...20).contains(kg) else {
            if text.isEmpty, let sameDay { context.delete(sameDay) }
            return
        }
        if let sameDay { sameDay.kg = kg } else { context.insert(WeighIn(on: day, kg: kg, dog: dog)) }
    }
}
