import SwiftData
import SwiftUI

/// 採った卵の見守り。積算温度で孵化までの進み具合を出す。
struct EggsScreen: View {
    @Query(sort: \EggBatch.collectedOn, order: .reverse) private var batches: [EggBatch]
    @State private var editing: EggBatch?
    @State private var adding = false

    var body: some View {
        NavigationStack {
            List {
                let open = batches.filter(\.isOpen)
                let done = batches.filter { !$0.isOpen }
                if batches.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("採った卵を記録すると、孵る日の目安がわかります").font(.headline)
                            Text("めだかの卵は「水温×日数」がおよそ 250 で孵ります。25℃ なら 10 日、20℃ なら 13 日ほど。容器の画面の「採卵」からも追加できます。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Palette.surface)
                }
                if !open.isEmpty {
                    Section("見守り中") {
                        ForEach(open) { batch in
                            Button { editing = batch } label: { WatchRow(batch: batch) }
                                .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(Palette.surface)
                }
                if !done.isEmpty {
                    Section {
                        ForEach(done) { batch in
                            Button { editing = batch } label: { DoneRow(batch: batch) }
                                .buttonStyle(.plain)
                        }
                    } header: {
                        Text("孵ったもの")
                    } footer: {
                        let eggs = done.reduce(0) { $0 + $1.eggs }
                        let hatched = done.reduce(0) { $0 + ($1.hatched ?? 0) }
                        if let rate = HatchClock.hatchRate(eggs: eggs, hatched: hatched) {
                            Text("これまでの孵化率 \(rate)%（\(eggs)個中 \(hatched)匹）")
                        }
                    }
                    .listRowBackground(Palette.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.water)
            .navigationTitle("卵")
            .toolbar {
                Button("卵を追加", systemImage: "plus") { adding = true }
            }
            .sheet(item: $editing) { EggEditor(batch: $0) }
            .sheet(isPresented: $adding) { EggEditor(batch: nil) }
        }
    }
}

private struct WatchRow: View {
    let batch: EggBatch

    var body: some View {
        let now = Date()
        let progress = HatchClock.progress(collectedOn: batch.collectedOn, celsius: batch.celsius, now: now)
        let elapsed = HatchClock.elapsedDays(since: batch.collectedOn, now: now)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(batch.breed.isEmpty ? "ミックス" : batch.breed)　\(batch.eggs)個").font(.headline)
                Spacer()
                Text("\(elapsed)日目").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(progress >= 0.9 ? Palette.koi : Palette.deep)
            HStack(spacing: 6) {
                if let day = HatchClock.expectedDay(collectedOn: batch.collectedOn, celsius: batch.celsius) {
                    Text("孵化の目安 \(DayText.short(day))")
                } else {
                    Text("水温が低く、このままだと孵りにくいです").foregroundStyle(Palette.warn)
                }
                Text(String(format: "・%.0f℃", batch.celsius))
                if !batch.keptIn.isEmpty { Text("・\(batch.keptIn)") }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

private struct DoneRow: View {
    let batch: EggBatch

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(batch.breed.isEmpty ? "ミックス" : batch.breed)　\(batch.eggs)個 → \(batch.hatched ?? 0)匹")
                    .font(.subheadline.weight(.semibold))
                Text("\(DayText.short(batch.collectedOn))に採卵" + (batch.hatchedOn.map { "・\(DayText.short($0))に孵化" } ?? ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let rate = HatchClock.hatchRate(eggs: batch.eggs, hatched: batch.hatched ?? 0) {
                Pill(text: "\(rate)%", tint: Palette.duckweed)
            }
        }
        .contentShape(Rectangle())
    }
}

struct EggEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Vessel.order) private var vessels: [Vessel]

    let batch: EggBatch?

    @State private var collectedOn = Date()
    @State private var eggs = 20
    @State private var breed = ""
    @State private var keptIn = ""
    @State private var celsius = 25.0
    @State private var hatchedYet = false
    @State private var hatched = 0
    @State private var hatchedOn = Date()
    @State private var note = ""
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("採った日", selection: $collectedOn, in: ...Date(), displayedComponents: .date)
                    Stepper("卵 \(eggs)個", value: $eggs, in: 1...999)
                    TextField("品種", text: $breed)
                    TextField("置き場所（容器・タッパーなど）", text: $keptIn)
                    if !vessels.isEmpty {
                        Menu("登録した容器から選ぶ") {
                            ForEach(vessels) { vessel in
                                Button(vessel.name) {
                                    keptIn = vessel.name
                                    if breed.isEmpty { breed = vessel.breed }
                                }
                            }
                        }
                    }
                }
                Section {
                    Stepper(String(format: "水温 %.1f℃", celsius), value: $celsius, in: 10...35, step: 0.5)
                    if let days = HatchClock.daysToHatch(celsius: celsius) {
                        Text("この水温なら およそ \(days) 日で孵ります")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(Int(HatchClock.coldLimit))℃ を下回ると、ほとんど育ちません。室内に取りこむと進みます。")
                            .font(.footnote)
                            .foregroundStyle(Palette.warn)
                    }
                } footer: {
                    Text("水温が変わったら書きかえてください。孵化の目安が計算しなおされます。")
                }
                Section {
                    Toggle("孵った", isOn: $hatchedYet)
                    if hatchedYet {
                        Stepper("孵った数 \(hatched)匹", value: $hatched, in: 0...999)
                        DatePicker("孵った日", selection: $hatchedOn, in: collectedOn...Date(), displayedComponents: .date)
                    }
                }
                Section("メモ") {
                    TextField("カビた卵を取りのぞいた など", text: $note, axis: .vertical)
                }
                if batch != nil {
                    Section {
                        Button("この記録を削除", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(batch == nil ? "卵を追加" : "卵の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("やめる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() } }
            }
            .confirmationDialog("この卵の記録を削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("削除する", role: .destructive) {
                    if let batch { context.delete(batch) }
                    try? context.save()
                    refresh()
                    dismiss()
                }
            }
            .onAppear(perform: load)
            .onChange(of: hatchedYet) { _, on in
                if on, hatched == 0 { hatched = eggs }
            }
        }
    }

    private func load() {
        guard let batch else { return }
        collectedOn = batch.collectedOn
        eggs = batch.eggs
        breed = batch.breed
        keptIn = batch.keptIn
        celsius = batch.celsius
        hatchedYet = batch.hatched != nil
        hatched = batch.hatched ?? 0
        hatchedOn = batch.hatchedOn ?? Date()
        note = batch.note
    }

    private func save() {
        let target = batch ?? EggBatch(collectedOn: collectedOn, eggs: eggs, breed: breed, keptIn: keptIn, celsius: celsius)
        if batch == nil { context.insert(target) }
        target.collectedOn = collectedOn
        target.eggs = eggs
        target.breed = breed.trimmingCharacters(in: .whitespaces)
        target.keptIn = keptIn.trimmingCharacters(in: .whitespaces)
        target.celsius = celsius
        target.hatched = hatchedYet ? hatched : nil
        target.hatchedOn = hatchedYet ? max(hatchedOn, collectedOn) : nil
        target.note = note
        try? context.save()
        refresh()
        dismiss()
    }

    private func refresh() {
        let context = context
        Task { await MorningDigest.refresh(context: context) }
    }
}
