import SwiftData
import SwiftUI

/// 数や水温を入れる記録のシート。
struct LogSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Vessel.order) private var allVessels: [Vessel]

    let vessel: Vessel
    let kind: LogKind

    @State private var at = Date()
    @State private var percent = 30
    @State private var withTemp = false
    @State private var celsius = 22.0
    @State private var count = 1
    @State private var destinationName = ""
    @State private var watchEggs = true
    @State private var note = ""

    private var others: [Vessel] { allVessels.filter { $0.persistentModelID != vessel.persistentModelID } }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("日時", selection: $at, in: ...Date())
                }

                switch kind {
                case .waterChange:
                    Section {
                        Stepper("替えた量 \(percent)%", value: $percent, in: 10...100, step: 10)
                    } footer: {
                        Text("一度に替えるのは 1/3 くらいまでが目安です。全部替えると水質が急に変わって弱ることがあります。")
                    }
                case .temperature:
                    Section {
                        Stepper(String(format: "%.1f℃", celsius), value: $celsius, in: 0...40, step: 0.5)
                    } footer: {
                        Text("朝に測ると、その日いちばん低い水温がわかります。")
                    }
                case .eggs, .loss, .moveOut, .addIn:
                    Section {
                        Stepper("\(count)\(kind == .eggs ? "個" : "匹")", value: $count, in: 1...999)
                        if kind == .moveOut {
                            Picker("移した先", selection: $destinationName) {
                                Text("ほかへ（譲った・販売）").tag("")
                                ForEach(others) { other in
                                    Text(other.name).tag(other.name)
                                }
                            }
                        }
                        if kind == .eggs {
                            Toggle("「卵」タブで孵化まで見守る", isOn: $watchEggs)
                        }
                    } footer: {
                        countFooter
                    }
                default:
                    EmptyView()
                }

                if kind != .temperature {
                    Section {
                        Toggle("水温も記録する", isOn: $withTemp)
                        if withTemp {
                            Stepper(String(format: "%.1f℃", celsius), value: $celsius, in: 0...40, step: 0.5)
                        }
                    }
                }

                Section("メモ") {
                    TextField(notePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("\(vessel.name)・\(kind.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
            .onAppear {
                if let last = vessel.lastTemperature?.celsius { celsius = last }
            }
        }
    }

    @ViewBuilder
    private var countFooter: some View {
        switch kind {
        case .loss: Text("容器の数から引きます。続くときは水温や水の汚れを見直してみてください。")
        case .moveOut: Text(destinationName.isEmpty ? "容器の数から引きます。" : "\(destinationName)の数に足します。")
        case .addIn: Text("容器の数に足します。")
        case .eggs: Text("積算温度（水温×日数）でおよそ 250 になると孵ります。")
        default: EmptyView()
        }
    }

    private var notePlaceholder: String {
        switch kind {
        case .treatment: "0.5%塩水浴・3日目 など"
        case .loss: "様子・思い当たること"
        case .memo: "気づいたこと"
        default: "（なくてもOK）"
        }
    }

    private func save() {
        let log = PondLog(kind: kind, at: at, vessel: vessel)
        log.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .waterChange: log.percent = percent
        case .temperature: log.celsius = celsius
        default: if withTemp { log.celsius = celsius }
        }
        if kind.takesCount {
            log.count = count
            vessel.headcount = max(0, vessel.headcount + kind.headcountSign * count)
        }
        if kind == .moveOut {
            log.destination = destinationName
            if let target = others.first(where: { $0.name == destinationName }) {
                let arrival = PondLog(kind: .addIn, at: at, vessel: target)
                arrival.count = count
                arrival.note = "\(vessel.name)から"
                context.insert(arrival)
                target.headcount += count
            }
        }
        if kind == .eggs, watchEggs {
            let batch = EggBatch(collectedOn: at, eggs: count, breed: vessel.breed, keptIn: vessel.name, celsius: log.celsius ?? vessel.lastTemperature?.celsius ?? 25)
            context.insert(batch)
        }
        context.insert(log)
        try? context.save()
        let context = context
        Task { await MorningDigest.refresh(context: context) }
        dismiss()
    }
}
