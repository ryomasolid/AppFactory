import SwiftData
import SwiftUI

/// 期限の一覧。まもなく終了 → 保証中（終了日の近い順）→ 終了（最近終わった順）。
/// 延長保証がある商品は、メーカー保証と延長保証の2行ぶん並ぶ。
struct ExpiryListView: View {
    @Query(filter: #Predicate<Item> { $0.isArchived == false }, sort: \Item.purchaseDate)
    private var items: [Item]

    private struct Entry: Identifiable {
        let item: Item
        let period: WarrantyPeriod
        let status: WarrantyStatus
        var id: String { "\(item.id.uuidString)-\(period.kind.rawValue)" }
    }

    var body: some View {
        let entries = items.flatMap { item in
            item.periods().map { Entry(item: item, period: $0, status: WarrantyTerm.status(of: $0)) }
        }
        let soon = entries.filter { $0.status.state == .soon }.sorted { $0.period.lastDay < $1.period.lastDay }
        let active = entries.filter { $0.status.state == .active }.sorted { $0.period.lastDay < $1.period.lastDay }
        let expired = entries.filter { $0.status.state == .expired }.sorted { $0.period.lastDay > $1.period.lastDay }

        NavigationStack {
            List {
                if !soon.isEmpty {
                    Section {
                        ForEach(soon) { row($0) }
                    } header: {
                        Label("まもなく終了", systemImage: "clock.badge.exclamationmark.fill")
                            .foregroundStyle(WarrantyState.soon.color)
                    } footer: {
                        Text("気になる不具合があれば、保証が使えるうちにメーカーやお店に相談しましょう。")
                    }
                }
                if !active.isEmpty {
                    Section("保証中") {
                        ForEach(active) { row($0) }
                    }
                }
                if !expired.isEmpty {
                    Section("終了") {
                        ForEach(expired) { row($0) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "保証の期限はまだありません",
                        systemImage: "calendar.badge.clock",
                        description: Text("商品を登録すると、保証が終わる日の近い順にここに並びます。")
                    )
                }
            }
            .navigationTitle("期限")
            .navigationDestination(for: Item.self) { ItemDetailView(item: $0) }
        }
    }

    private func row(_ entry: Entry) -> some View {
        NavigationLink(value: entry.item) {
            HStack(spacing: 12) {
                ThumbnailView(
                    data: entry.item.sortedAttachments.first?.thumbnailData, category: entry.item.category, size: 44
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.item.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    Text(kindText(entry))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 3) {
                    StatusBadge(status: entry.status)
                    Text("\(Formatting.date(entry.period.lastDay)) まで")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func kindText(_ entry: Entry) -> String {
        let provider = entry.item.extendedWarrantyProvider
        if entry.period.kind == .extended, !provider.isEmpty {
            return "\(entry.period.kind.label)（\(provider)）・\(Formatting.term(months: entry.period.months))"
        }
        return "\(entry.period.kind.label)・\(Formatting.term(months: entry.period.months))"
    }
}
