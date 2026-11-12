import SwiftData
import SwiftUI

/// 品種ごとのまとめ。どの容器に何匹いて、卵がどれだけ孵ったか。
struct BreedsScreen: View {
    @Query(sort: \Vessel.order) private var vessels: [Vessel]
    @Query private var batches: [EggBatch]

    struct Group: Identifiable {
        let name: String
        let vessels: [Vessel]
        let eggs: Int
        let hatched: Int
        var id: String { name }
        var headcount: Int { vessels.reduce(0) { $0 + $1.headcount } }
    }

    private var groups: [Group] {
        var names = Set(vessels.map(\.breedLabel))
        for batch in batches { names.insert(batch.breed.isEmpty ? "ミックス" : batch.breed) }
        return names.map { name in
            let finished = batches.filter { !$0.isOpen && ($0.breed.isEmpty ? "ミックス" : $0.breed) == name }
            return Group(
                name: name,
                vessels: vessels.filter { $0.breedLabel == name },
                eggs: finished.reduce(0) { $0 + $1.eggs },
                hatched: finished.reduce(0) { $0 + ($1.hatched ?? 0) }
            )
        }
        .sorted { ($0.headcount, $1.name) > ($1.headcount, $0.name) }
    }

    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    Text("容器に品種を入れると、ここに品種ごとの数がまとまります。")
                        .foregroundStyle(.secondary)
                        .listRowBackground(Palette.surface)
                }
                ForEach(groups) { group in
                    Section {
                        ForEach(group.vessels) { vessel in
                            HStack {
                                BowlGlyph(style: vessel.style, headcount: vessel.headcount, size: 28)
                                Text(vessel.name)
                                Spacer()
                                Text("\(vessel.stage.label) \(vessel.headcount)匹")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        if group.eggs > 0, let rate = HatchClock.hatchRate(eggs: group.eggs, hatched: group.hatched) {
                            LabeledContent("孵化率", value: "\(rate)%（\(group.eggs)個中 \(group.hatched)匹）")
                                .font(.subheadline)
                        }
                    } header: {
                        HStack {
                            Text(group.name).font(.headline).foregroundStyle(.primary)
                            Spacer()
                            Text("\(group.headcount)匹").font(.subheadline.monospacedDigit())
                        }
                        .textCase(nil)
                    }
                    .listRowBackground(Palette.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.water)
            .navigationTitle("品種")
        }
    }
}
