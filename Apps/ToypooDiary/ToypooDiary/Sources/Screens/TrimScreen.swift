import SwiftData
import SwiftUI

/// トリミングタブ：前回からの日数と毛の伸び・次の目安・これまでのスタイル。
struct TrimScreen: View {
    @Query(sort: \Dog.order) private var dogs: [Dog]
    @AppStorage(CurrentDog.storageKey) private var currentKey = ""
    @State private var editing: TrimPick?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let dog = CurrentDog.pick(dogs, key: currentKey) {
                    VStack(spacing: 16) {
                        RhythmCard(dog: dog) { editing = TrimPick(trim: nil) }
                        YearCard(trims: dog.trimHistory)
                        gallery(dog)
                    }
                    .padding(16)
                }
            }
            .background(Tone.paper)
            .navigationTitle("トリミング")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { DogSwitcher(dogs: dogs, currentKey: $currentKey) }
                ToolbarItem(placement: .primaryAction) {
                    Button { editing = TrimPick(trim: nil) } label: { Image(systemName: "plus") }
                        .accessibilityLabel("トリミングを記録")
                }
            }
            .sheet(item: $editing) { pick in
                if let dog = CurrentDog.pick(dogs, key: currentKey) { TrimEditor(dog: dog, trim: pick.trim) }
            }
        }
    }

    @ViewBuilder
    private func gallery(_ dog: Dog) -> some View {
        let trims = dog.trimHistory
        if !trims.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("これまでのスタイル").font(.headline).foregroundStyle(Tone.cocoa)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(trims) { trim in
                        Button { editing = TrimPick(trim: trim) } label: { TrimTile(trim: trim) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct TrimPick: Identifiable {
    let id = UUID()
    let trim: Trim?
}

private struct RhythmCard: View {
    let dog: Dog
    let onAdd: () -> Void

    var body: some View {
        let status = TrimRhythm.status(cuts: dog.trimHistory.filter(\.menu.cutsCoat).map(\.on), now: Date())
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("つぎのトリミング").font(.headline).foregroundStyle(Tone.cocoa)
                Spacer()
                phaseTag(status.phase)
            }
            if let since = status.daysSince, let due = status.nextDue, let left = status.daysLeft {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("前回のカットから").font(.subheadline).foregroundStyle(.secondary)
                    Text("\(since)").font(.system(size: 40, weight: .bold, design: .rounded)).foregroundStyle(Tone.cocoa)
                    Text("日").font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    if let cm = status.grownCm {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("毛の伸び").font(.caption2).foregroundStyle(.secondary)
                            Text("約\(cm.formatted(.number.precision(.fractionLength(1))))cm").font(.headline).foregroundStyle(Tone.apricot)
                        }
                    }
                }
                ProgressView(value: min(Double(since), Double(status.interval)), total: Double(status.interval))
                    .tint(status.phase == .overdue ? Tone.alert : Tone.apricot)
                HStack {
                    Text("目安 \(Words.day(due))（\(Words.left(left))）").font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("いつも\(status.interval)日ごと").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("トリミングに行った日を記録すると、前回からの日数と次の目安を出します。プードルの毛は1か月でおよそ1cm伸びます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button(action: onAdd) {
                Label("トリミングを記録", systemImage: "scissors").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("add-trim")
        }
        .cardStyle()
    }

    @ViewBuilder
    private func phaseTag(_ phase: TrimRhythm.Phase) -> some View {
        switch phase {
        case .noRecord: EmptyView()
        case .fresh: Tag(text: "カットしたて", symbol: "sparkles", tint: Tone.leaf)
        case .growing: Tag(text: "のびのび中", tint: Tone.mute)
        case .soon: Tag(text: "そろそろ予約", symbol: "calendar", tint: Tone.apricot)
        case .overdue: Tag(text: "もじゃもじゃ注意", symbol: "exclamationmark", tint: Tone.alert)
        }
    }
}

private struct YearCard: View {
    let trims: [Trim]

    var body: some View {
        let year = Calendar.current.component(.year, from: Date())
        let thisYear = trims.filter { Calendar.current.component(.year, from: $0.on) == year }
        let spent = thisYear.compactMap(\.price).reduce(0, +)
        if !thisYear.isEmpty {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(String(year))年のトリミング").font(.caption).foregroundStyle(.secondary)
                    Text("\(thisYear.count)回").font(.title3.bold()).foregroundStyle(Tone.cocoa)
                }
                Spacer()
                if spent > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("かかった金額").font(.caption).foregroundStyle(.secondary)
                        Text(spent.formatted(.currency(code: "JPY"))).font(.title3.bold()).foregroundStyle(Tone.cocoa)
                    }
                }
            }
            .cardStyle(padding: 14)
        }
    }
}

private struct TrimTile: View {
    let trim: Trim

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                Tone.apricot.opacity(0.15)
                if let data = trim.photo, let image = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 480, height: 480)) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    PoodleFace(coat: trim.dog?.coat ?? .apricot, size: 80)
                }
            }
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(trim.title).font(.subheadline.weight(.semibold)).lineLimit(1)
            HStack(spacing: 4) {
                Text(Words.long(trim.on)).font(.caption2).foregroundStyle(.secondary)
                if trim.menu != .full { Text("・\(trim.menu.label)").font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
            }
        }
        .padding(8)
        .background(Tone.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
