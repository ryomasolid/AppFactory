import SwiftUI

/// ずかん：国旗・国名・首都の一覧。覚えたものに印がつく。
struct DexTab: View {
    @Environment(Learned.self) private var progress
    @State private var region: Region?
    @State private var search = ""

    private var list: [Country] {
        var l = region.map { r in Country.all.filter { $0.region == r } } ?? Country.all
        let q = search.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            l = l.filter { $0.name.localizedStandardContains(q) || $0.capital.localizedStandardContains(q) }
        }
        return l
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip("すべて", selected: region == nil) { region = nil }
                            ForEach(Region.allCases) { r in
                                chip(r.label, selected: region == r) { region = r }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(list) { c in
                        row(c)
                    }
                } header: {
                    Text("\(list.count)か国")
                }
            }
            .navigationTitle("ずかん")
            .searchable(text: $search, prompt: "国名・首都でさがす")
        }
    }

    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? .white : .primary)
                .background(selected ? Hue.navy : Hue.card, in: .capsule)
        }
        .buttonStyle(.plain)
    }

    private func row(_ c: Country) -> some View {
        HStack(spacing: 12) {
            Text(c.flag)
                .font(.system(size: 40))
            VStack(alignment: .leading, spacing: 2) {
                Text(c.name)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(c.capital)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let note = c.note {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 4) {
                badge(.flag, c)
                badge(.capital, c)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func badge(_ topic: Topic, _ c: Country) -> some View {
        let m = progress.mark(c.code, topic)
        let color = Hue.color(topic)
        return HStack(spacing: 3) {
            Image(systemName: m.mastered ? "checkmark.circle.fill" : (m.seen ? "circle.lefthalf.filled" : "circle"))
            Text(topic.label)
        }
        .font(.caption2.bold())
        .foregroundStyle(m.mastered ? color : (m.seen ? color.opacity(0.6) : Color.secondary.opacity(0.5)))
        .accessibilityLabel("\(topic.label) \(m.mastered ? "覚えた" : (m.seen ? "練習中" : "まだ"))")
    }
}
