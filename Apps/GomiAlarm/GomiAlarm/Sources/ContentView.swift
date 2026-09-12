import SwiftData
import SwiftUI

/// TODO: 本実装では `Docs/Design.md` の4タブ（ホーム／予定／カレンダー／設定）に置き換える。
/// 現状はスケジューラの動作確認用の仮画面。
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GarbageKind.sortOrder) private var kinds: [GarbageKind]
    @State private var status = RefreshStatus.load()

    private var upcoming: [(date: Date, names: String)] {
        let today = Calendar.current.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .day, value: 14, to: today) else { return [] }
        var byDate: [Date: [String]] = [:]
        for kind in kinds {
            for date in ScheduleCalculator.occurrences(of: kind.specs, from: today, through: end) {
                byDate[date, default: []].append(kind.name)
            }
        }
        return byDate.keys.sorted().map { ($0, byDate[$0]!.joined(separator: "・")) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("今後2週間") {
                    if upcoming.isEmpty {
                        Text("収集日がありません")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(upcoming, id: \.date) { item in
                        HStack {
                            Text(item.date.formatted(.dateTime.month().day().weekday()))
                            Spacer()
                            Text(item.names).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("登録済みの種類") {
                    ForEach(kinds) { kind in
                        VStack(alignment: .leading, spacing: 2) {
                            Label(kind.name, systemImage: kind.symbolName)
                            Text(kind.specs.map(\.summary).joined(separator: " / "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("通知（デバッグ）") {
                    Button("デモデータを入れる") { Launch.seedIfNeeded(modelContext) }
                    Button("通知を作り直す") {
                        Task {
                            status = await NotificationRefresh.run(
                                container: modelContext.container, requestingAuthorization: true
                            )
                        }
                    }
                    Text(statusText).font(.caption.monospaced())
                }
            }
            .navigationTitle("ゴミの日アラーム")
        }
        .onAppear {
            NotificationScheduler.shared.registerCategories()
            if Launch.isDemo { Launch.seedIfNeeded(modelContext) }
        }
    }

    private var statusText: String {
        let never = String(localized: "未実行")
        let run = status.lastRunAt?.formatted(.dateTime.month().day().hour().minute()) ?? never
        let covered = status.coveredThrough?.formatted(.dateTime.month().day()) ?? "—"
        let next = status.nextBackgroundRefreshAt?.formatted(.dateTime.month().day().hour()) ?? "—"
        return """
            最終実行: \(run)
            許可: \(status.authorized ? "あり" : "なし")／登録: \(status.scheduled)件
            方式: \(status.isPermanent ? "毎週くり返し（永続）" : "具体日を列挙")
            カバー: \(covered)まで／次のBG再構築: \(next)
            上限で切り捨て: \(status.truncated ? "あり" : "なし")
            """
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [GarbageKind.self, CollectionRule.self, DoneRecord.self], inMemory: true)
}
