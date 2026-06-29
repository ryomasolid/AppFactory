import SwiftData
import SwiftUI
import UIKit

/// 予約中のリマインド一覧。全間取りのマーカーから「次回予定」が設定されたものを
/// 近い順に表示する。期限切れは赤で強調。
struct RemindersView: View {
    /// 行タップ時に対象の間取りへ移動するためのコールバック。
    let onSelect: (FloorPlan) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PestMarker.nextActionDate, order: .forward) private var allMarkers: [PestMarker]
    @State private var notificationsDenied = false

    private var reminders: [PestMarker] {
        allMarkers.filter { $0.nextActionDate != nil }
    }

    private var overdueCount: Int {
        reminders.filter { ($0.nextActionDate ?? .distantFuture) < Date() }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if reminders.isEmpty {
                    ContentUnavailableView(
                        "リマインドはありません",
                        systemImage: "bell.slash",
                        description: Text("マーカーに次回の予定を設定すると、ここに一覧表示されます")
                    )
                } else {
                    List {
                        if notificationsDenied {
                            deniedBanner
                        }
                        Section {
                            Text("予定 \(reminders.count) 件" + (overdueCount > 0 ? " ・ 期限切れ \(overdueCount) 件" : ""))
                                .font(.subheadline)
                                .foregroundStyle(overdueCount > 0 ? .red : .secondary)
                        }
                        ForEach(reminders) { marker in
                            Button {
                                if let plan = marker.plan { onSelect(plan) }
                            } label: {
                                row(marker)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("リマインド")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task { notificationsDenied = await NotificationService.shared.isDenied() }
        }
    }

    private var deniedBanner: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            Label("通知がオフです。タップして設定で許可してください。", systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.orange)
        }
    }

    private func row(_ marker: PestMarker) -> some View {
        let date = marker.nextActionDate ?? .distantFuture
        let overdue = date < Date()

        return HStack(spacing: 12) {
            Image(systemName: marker.kind.symbol)
                .foregroundStyle(.white)
                .padding(8)
                .background(marker.kind.color, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(marker.kind.label).font(.headline)
                if let plan = marker.plan {
                    Text(plan.name).font(.caption).foregroundStyle(.secondary)
                }
                if !marker.note.isEmpty {
                    Text(marker.note).font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(overdue ? .red : .primary)
                if overdue {
                    Text("期限切れ").font(.caption2).foregroundStyle(.red)
                }
            }
        }
    }
}
