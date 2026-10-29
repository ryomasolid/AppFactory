import SwiftData
import SwiftUI

/// 産卵から孵化までの見守り。温度から孵化予定日と性別の傾向を出す。
struct EggScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Clutch.laidOn, order: .reverse) private var clutches: [Clutch]
    @State private var adding = false
    @State private var editing: Clutch?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    let active = clutches.filter { !$0.isFinished }
                    let finished = clutches.filter(\.isFinished)
                    if clutches.isEmpty {
                        intro
                    }
                    ForEach(active) { clutch in
                        ClutchCard(clutch: clutch, edit: { editing = clutch })
                    }
                    if !finished.isEmpty {
                        Text("おわった卵").font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                        ForEach(finished) { clutch in
                            ClutchCard(clutch: clutch, edit: { editing = clutch })
                        }
                    }
                }
                .padding(16)
            }
            .background(Terrarium.sand)
            .navigationTitle("たまご")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { adding = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("産卵を記録")
                }
            }
            .sheet(isPresented: $adding) { ClutchForm(clutch: nil) }
            .sheet(item: $editing) { ClutchForm(clutch: $0) }
        }
    }

    private var intro: some View {
        VStack(spacing: 12) {
            Image(systemName: "oval.portrait.fill").font(.system(size: 44)).foregroundStyle(Terrarium.yolk)
            Text("産卵したら記録しよう").font(.title3.weight(.bold))
            Text("インキュベーターの温度を入れると、孵化までの日数と\nオス・メスの傾向の目安を出します。")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("産卵を記録する") { adding = true }.buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .cardSurface()
    }
}

private struct ClutchCard: View {
    @Environment(\.modelContext) private var context
    let clutch: Clutch
    let edit: () -> Void

    var body: some View {
        let total = Incubation.expectedDays(at: clutch.incubationC)
        let elapsed = CareRhythm.days(from: clutch.laidOn, to: Date())
        let remaining = CareRhythm.days(from: Date(), to: clutch.expectedHatchDay)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(clutch.motherName.isEmpty ? "卵 \(clutch.eggCount)個" : "\(clutch.motherName)の卵 \(clutch.eggCount)個")
                    .font(.headline)
                Spacer()
                Menu {
                    Button("編集", systemImage: "pencil", action: edit)
                    if !clutch.isFinished {
                        Button("見守りをおわる", systemImage: "xmark.circle") { clutch.closed = true; try? context.save() }
                    }
                    Button("削除", systemImage: "trash", role: .destructive) { context.delete(clutch); try? context.save() }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3)
                }
            }
            Text("\(clutch.laidOn.shortDayText) に産卵 ・ \(String(format: "%.1f", clutch.incubationC))℃")
                .font(.subheadline).foregroundStyle(.secondary)

            if clutch.isFinished {
                Text(clutch.hatchedCount > 0 ? "\(clutch.hatchedCount)匹 孵化しました" : "見守りをおわりました")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Terrarium.moss)
            } else {
                ProgressView(value: Double(min(elapsed, total)), total: Double(total))
                    .tint(Terrarium.yolk)
                HStack(alignment: .firstTextBaseline) {
                    Text("\(elapsed)日目").font(.title3.weight(.bold).monospacedDigit())
                    Spacer()
                    Text(remaining > 0 ? "孵化予定 \(clutch.expectedHatchDay.shortDayText)（あと\(remaining)日）" : "そろそろ孵化しそう")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(remaining > 0 ? Color.primary : Terrarium.moss)
                }
                Tag(text: "性別の傾向: \(Incubation.sexTendency(at: clutch.incubationC))", color: Terrarium.spot)
                HStack {
                    Text("孵化 \(clutch.hatchedCount) / \(clutch.eggCount)").font(.subheadline)
                    Spacer()
                    Button("1匹 孵化した") {
                        clutch.hatchedCount += 1
                        try? context.save()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .cardSurface()
    }
}

private struct ClutchForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Gecko.position) private var geckos: [Gecko]

    let clutch: Clutch?

    @State private var laidOn = Date()
    @State private var eggCount = 2
    @State private var celsius = 28.0
    @State private var motherName = ""
    @State private var hatchedCount = 0
    @State private var note = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("産卵日", selection: $laidOn, in: ...Date(), displayedComponents: .date)
                    Stepper("卵 \(eggCount)個", value: $eggCount, in: 1...6)
                    if clutch != nil {
                        Stepper("孵化 \(hatchedCount)匹", value: $hatchedCount, in: 0...eggCount)
                    }
                }
                Section("おかあさん") {
                    let females = geckos.filter { $0.sex != .male }
                    if !females.isEmpty {
                        Picker("登録している子から", selection: $motherName) {
                            Text("えらばない").tag("")
                            ForEach(females) { Text($0.name).tag($0.name) }
                            if !motherName.isEmpty && !females.contains(where: { $0.name == motherName }) {
                                Text(motherName).tag(motherName)
                            }
                        }
                    } else {
                        TextField("名前", text: $motherName)
                    }
                }
                Section {
                    Stepper(String(format: "%.1f℃", celsius), value: $celsius, in: Incubation.supportedRange, step: 0.5)
                    LabeledContent("孵化までの目安", value: "約\(Incubation.expectedDays(at: celsius))日")
                    LabeledContent("性別の傾向", value: Incubation.sexTendency(at: celsius))
                } header: {
                    Text("インキュベーターの温度")
                } footer: {
                    Text("レオパは卵の温度で性別が決まりやすい生き物です。ここの数字は一般的な目安で、実際には個体差があります。")
                }
                Section("メモ") {
                    TextField("床材・湿度など", text: $note, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle(clutch == nil ? "産卵を記録" : "卵の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let clutch else { return }
        laidOn = clutch.laidOn
        eggCount = clutch.eggCount
        celsius = clutch.incubationC
        motherName = clutch.motherName
        hatchedCount = clutch.hatchedCount
        note = clutch.note
    }

    private func save() {
        let target = clutch ?? Clutch(laidOn: laidOn)
        target.laidOn = Calendar.current.startOfDay(for: laidOn)
        target.eggCount = eggCount
        target.incubationC = celsius
        target.motherName = motherName
        target.hatchedCount = min(hatchedCount, eggCount)
        target.note = note
        if clutch == nil { context.insert(target) }
        try? context.save()
        dismiss()
    }
}
