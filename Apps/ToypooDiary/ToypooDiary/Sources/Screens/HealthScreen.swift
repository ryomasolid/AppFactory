import Charts
import SwiftData
import SwiftUI

/// けんこうタブ：体重のグラフと、予防（ワクチン・フィラリア・ノミダニ・健康診断）の次の予定。
struct HealthScreen: View {
    @Query(sort: \Dog.order) private var dogs: [Dog]
    @AppStorage(CurrentDog.storageKey) private var currentKey = ""
    @State private var weighing = false

    var body: some View {
        NavigationStack {
            List {
                if let dog = CurrentDog.pick(dogs, key: currentKey) {
                    weightSection(dog)
                    Section {
                        ForEach(CareKind.allCases) { kind in
                            NavigationLink { CareKindScreen(dog: dog, kind: kind) } label: { CareRow(dog: dog, kind: kind) }
                        }
                    } header: {
                        Text("予防・健診のよてい")
                    } footer: {
                        Text("次の予定は前回の記録からの目安です。お薬の間隔やワクチンの時期は、かかりつけの獣医さんの指示を優先してください。")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Tone.paper)
            .navigationTitle("けんこう")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { DogSwitcher(dogs: dogs, currentKey: $currentKey) }
            }
            .sheet(isPresented: $weighing) {
                if let dog = CurrentDog.pick(dogs, key: currentKey) { WeightSheet(dog: dog) }
            }
        }
    }

    @ViewBuilder
    private func weightSection(_ dog: Dog) -> some View {
        let points = dog.weights
        let growing = dog.birthday.map { DogYears.stage(months: DogYears.months(from: $0, to: Date())) == .puppy } ?? false
        let reading = WeightTrend.read(points.map { ($0.on, $0.kg) }, growing: growing)
        Section("体重") {
            if let reading {
                HStack(alignment: .firstTextBaseline) {
                    Text(WeightTrend.kgText(reading.latest)).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(Tone.cocoa)
                    if let diff = reading.sincePrevious {
                        Text(diff == 0 ? "前回と同じ" : "前回から\(diff > 0 ? "+" : "")\(diff.formatted(.number.precision(.fractionLength(2))))kg")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                if points.count >= 2 { WeightChart(points: points) }
                if let alert = reading.alert {
                    Label(alertText(alert), systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(Tone.alert)
                }
                NavigationLink("体重の記録をすべて見る") { WeightLog(dog: dog) }
            } else {
                Text("小さな体なので、100g の変化も大事なサインです。月に1〜2回はかっておくと安心です。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Button { weighing = true } label: { Label("体重を記録", systemImage: "scalemass") }
                .accessibilityIdentifier("add-weight")
        }
    }

    private func alertText(_ alert: WeightTrend.Alert) -> String {
        switch alert {
        case .dropping(let p): "この1か月で\(p)%へっています。ごはんの量や元気をみて、続くようなら獣医さんに相談を。"
        case .gaining(let p): "この1か月で\(p)%ふえています。おやつやごはんの量を見なおしてみましょう。"
        }
    }
}

private struct WeightChart: View {
    let points: [WeighIn]

    var body: some View {
        let recent = points.suffix(24)
        let values = recent.map(\.kg)
        let low = (values.min() ?? 0) - 0.2, high = (values.max() ?? 1) + 0.2
        Chart(Array(recent)) { point in
            LineMark(x: .value("日付", point.on), y: .value("体重", point.kg))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Tone.apricot)
            PointMark(x: .value("日付", point.on), y: .value("体重", point.kg))
                .foregroundStyle(Tone.cocoa)
                .symbolSize(30)
        }
        .chartYScale(domain: max(0, low)...high)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) { _ in AxisValueLabel(format: .dateTime.month(.defaultDigits).day()) } }
        .frame(height: 160)
        .padding(.vertical, 4)
    }
}

private struct CareRow: View {
    let dog: Dog
    let kind: CareKind

    var body: some View {
        let last = dog.shots(of: kind).first
        let season = SeasonSetting.load(kind)
        let due = last == nil ? nil : PreventionPlan.next(kind: kind, last: last?.on, season: season, today: Date())
        HStack(spacing: 12) {
            Image(systemName: kind.symbol)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Tone.rose, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.label).font(.subheadline.weight(.semibold))
                Text(last.map { "前回 \(Words.long($0.on))" } ?? "まだ記録がありません")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let due {
                let left = PreventionPlan.daysLeft(until: due, from: Date())
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Words.day(due)).font(.subheadline.weight(.semibold))
                    Text(left > 0 && kind.isMonthly && !season.contains(month: Calendar.current.component(.month, from: Date())) ? "シーズン外" : Words.left(left))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(left < 0 ? Tone.alert : left <= 7 ? Tone.apricot : Tone.mute)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

/// 予防1種類の履歴と記録。
struct CareKindScreen: View {
    let dog: Dog
    let kind: CareKind

    @Environment(\.modelContext) private var context
    @State private var adding = false

    var body: some View {
        let history = dog.shots(of: kind)
        List {
            Section {
                Button { record(on: Date()) } label: {
                    Label(kind.isMonthly ? "今日のませた・つけた" : "今日うけた", systemImage: "checkmark.circle.fill")
                }
                .accessibilityIdentifier("done-\(kind.rawValue)")
                Button { adding = true } label: { Label("日付を選んで記録", systemImage: "calendar.badge.plus") }
            } footer: {
                if kind.isMonthly {
                    Text("シーズン：\(SeasonSetting.load(kind).text)（設定で変えられます）")
                } else {
                    Text("前回から1年後を次の目安にします。")
                }
            }
            if !history.isEmpty {
                Section("これまで") {
                    ForEach(history) { shot in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Words.long(shot.on))
                            let detail = [shot.clinic, shot.note].filter { !$0.isEmpty }.joined(separator: "・")
                            if !detail.isEmpty { Text(detail).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { history[$0] }.forEach(context.delete)
                        try? context.save()
                    }
                }
            }
        }
        .navigationTitle(kind.label)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $adding) { CareSheet(dog: dog, kind: kind) }
    }

    private func record(on day: Date) {
        guard !dog.shots(of: kind).contains(where: { Calendar.current.isDate($0.on, inSameDayAs: day) }) else { return }
        context.insert(CareShot(kind: kind, on: day, clinic: dog.shots(of: kind).first?.clinic ?? "", dog: dog))
        try? context.save()
    }
}

private struct CareSheet: View {
    let dog: Dog
    let kind: CareKind

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var on = Date()
    @State private var clinic = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("日付", selection: $on, in: ...Date(), displayedComponents: .date)
                TextField("病院の名前", text: $clinic)
                TextField(kind.isMonthly ? "お薬の名前 など" : "メモ", text: $note)
            }
            .navigationTitle(kind.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let shot = CareShot(kind: kind, on: on, clinic: clinic.trimmingCharacters(in: .whitespaces), dog: dog)
                        shot.note = note.trimmingCharacters(in: .whitespaces)
                        context.insert(shot)
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .onAppear { clinic = dog.shots(of: kind).first?.clinic ?? "" }
        }
        .presentationDetents([.medium])
    }
}

private struct WeightSheet: View {
    let dog: Dog

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var on = Date()
    @State private var text = ""
    @FocusState private var focused: Bool

    private var kg: Double? {
        Double(text.replacingOccurrences(of: ",", with: ".")).flatMap { (0.3...20).contains($0) ? $0 : nil }
    }

    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    TextField(dog.weights.last.map { String(format: "%.2f", $0.kg) } ?? "3.20", text: $text)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .focused($focused)
                        .accessibilityIdentifier("weight-kg")
                    Text("kg").font(.title3).foregroundStyle(.secondary)
                }
                DatePicker("はかった日", selection: $on, in: ...Date(), displayedComponents: .date)
            }
            .navigationTitle("体重を記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let kg else { return }
                        if let same = (dog.weighIns ?? []).first(where: { Calendar.current.isDate($0.on, inSameDayAs: on) }) {
                            same.kg = kg
                        } else {
                            context.insert(WeighIn(on: on, kg: kg, dog: dog))
                        }
                        try? context.save()
                        dismiss()
                    }
                    .disabled(kg == nil)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}

private struct WeightLog: View {
    let dog: Dog
    @Environment(\.modelContext) private var context

    var body: some View {
        let list = Array(dog.weights.reversed())
        List {
            ForEach(list) { point in
                HStack {
                    Text(Words.long(point.on))
                    Spacer()
                    Text(WeightTrend.kgText(point.kg)).monospacedDigit()
                }
            }
            .onDelete { offsets in
                offsets.map { list[$0] }.forEach(context.delete)
                try? context.save()
            }
        }
        .navigationTitle("体重の記録")
        .navigationBarTitleDisplayMode(.inline)
    }
}
