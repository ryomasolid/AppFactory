import SwiftData
import SwiftUI

/// 全個体の記録を日ごとに。種類と個体でしぼりこめる。
struct JournalScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CareEntry.occurredAt, order: .reverse) private var entries: [CareEntry]
    @Query(sort: \Gecko.position) private var geckos: [Gecko]

    @State private var kindFilter: CareKind?
    @State private var geckoFilter: UUID?
    @State private var editing: CareEntry?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    kindChips
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                }
                if filtered.isEmpty {
                    Text(entries.isEmpty ? "ケージのタブで個体を選んで、ごはんや脱皮を記録しましょう。" : "この条件の記録はありません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
                ForEach(days, id: \.self) { day in
                    Section(day.shortDayText) {
                        ForEach(grouped[day] ?? []) { entry in
                            Button { editing = entry } label: { EntryRow(entry: entry, showsName: true) }
                                .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            let items = grouped[day] ?? []
                            offsets.map { items[$0] }.forEach(context.delete)
                            try? context.save()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Terrarium.sand)
            .navigationTitle("きろく")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("個体", selection: $geckoFilter) {
                            Text("みんな").tag(UUID?.none)
                            ForEach(geckos) { Text($0.name).tag(UUID?.some($0.uid)) }
                        }
                    } label: {
                        Label(geckos.first { $0.uid == geckoFilter }?.name ?? "みんな", systemImage: "line.3.horizontal.decrease.circle")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            .sheet(item: $editing) { entry in
                if let gecko = entry.gecko {
                    EntrySheet(gecko: gecko, kind: entry.kind, existing: entry)
                }
            }
        }
    }

    private var filtered: [CareEntry] {
        entries.filter { entry in
            (kindFilter == nil || entry.kind == kindFilter) && (geckoFilter == nil || entry.gecko?.uid == geckoFilter)
        }
    }

    private var grouped: [Date: [CareEntry]] {
        Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.occurredAt) }
    }

    private var days: [Date] { grouped.keys.sorted(by: >) }

    private var kindChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("すべて", isOn: kindFilter == nil) { kindFilter = nil }
                ForEach(CareKind.allCases) { kind in
                    chip(kind.label, isOn: kindFilter == kind) { kindFilter = kind }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isOn ? Color.white : Color.primary)
            .background(isOn ? Terrarium.moss : Terrarium.card, in: Capsule())
            .buttonStyle(.plain)
    }
}
