import SwiftData
import SwiftUI

/// 「予定」タブ。ゴミの種類の一覧・追加・並べ替え・削除。
struct ScheduleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Query(sort: \GarbageKind.sortOrder) private var kinds: [GarbageKind]

    @State private var status = RefreshStatus.load()
    @State private var isAddingKind = false
    @State private var editingKind: GarbageKind?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if kinds.isEmpty {
                        Button {
                            startAddingKind()
                        } label: {
                            Label("ゴミの種類を登録する", systemImage: "plus.circle.fill")
                        }
                    }
                    ForEach(kinds) { kind in
                        Button {
                            editingKind = kind
                        } label: {
                            row(for: kind)
                        }
                        // 行の中身は「内容」なので、ボタンの色で染めない。
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteKinds)
                    .onMove(perform: moveKinds)
                } header: {
                    Text("ゴミの種類")
                } footer: {
                    // 並び順は通知文（「燃えるゴミ・プラ」）とホームの色ドットの順にそのまま出る。
                    Text(limitFooter)
                }

                proSection
                debugSection
            }
            .navigationTitle("予定")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !kinds.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startAddingKind()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("種類を追加")
                }
            }
            .sheet(isPresented: $isAddingKind) {
                KindEditorView(title: "種類を追加", draft: KindDraft()) { draft in
                    addKind(draft)
                }
            }
            .sheet(item: $editingKind) { kind in
                KindEditorView(
                    title: "種類を編集",
                    draft: KindDraft(kind),
                    onSave: { draft in
                        draft.apply(to: kind, in: modelContext)
                        save()
                    },
                    onDelete: { delete(kind) }
                )
            }
            .sheet(isPresented: $showPaywall) {
                // シートの中身には環境が自動で伝わらないので明示的に渡す。
                PaywallView()
                    .environment(store)
            }
        }
        .tint(Theme.accent)
    }

    private func row(for kind: GarbageKind) -> some View {
        HStack(spacing: 12) {
            Image(systemName: kind.symbolName)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    Color(hex: kind.colorHex),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.name)
                    .foregroundStyle(.primary)
                Text(kind.specs.map(\.summary).joined(separator: " / "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    private var proSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Label(
                        store.isPro ? "Pro を利用中" : "Pro（種類を無制限に・広告なし）",
                        systemImage: store.isPro ? "checkmark.seal.fill" : "crown.fill"
                    )
                    Spacer()
                    if !store.isPro {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    /// TODO: 本実装では「設定」タブに移し、通知の状態表示だけを残す。
    private var debugSection: some View {
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

    // MARK: - 上限

    /// 無料版の上限に達していたら、追加の代わりに課金画面を出す。
    private func startAddingKind() {
        if ProLimits.canAddKind(currentCount: kinds.count, isPro: store.isPro) {
            isAddingKind = true
        } else {
            showPaywall = true
        }
    }

    private var limitFooter: LocalizedStringKey {
        guard let remaining = ProLimits.remainingKinds(currentCount: kinds.count, isPro: store.isPro)
        else { return "並べ替えると、通知やホームでの表示順も変わります。" }
        if remaining == 0 {
            return "無料版で登録できるのは\(ProLimits.freeKinds)種類までです。Pro にすると無制限になります。"
        }
        return "並べ替えると、通知やホームでの表示順も変わります。（あと\(remaining)種類まで登録できます）"
    }

    // MARK: - 編集

    private func addKind(_ draft: KindDraft) {
        let kind = GarbageKind(
            name: draft.trimmedName,
            sortOrder: (kinds.map(\.sortOrder).max() ?? -1) + 1
        )
        modelContext.insert(kind)
        draft.apply(to: kind, in: modelContext)
        save()
    }

    private func deleteKinds(at offsets: IndexSet) {
        for index in offsets { delete(kinds[index]) }
    }

    private func delete(_ kind: GarbageKind) {
        // 「出した」記録は種類IDで持っているだけなので、種類を消すときに一緒に片付ける。
        let id = kind.id
        let records = (try? modelContext.fetch(FetchDescriptor<DoneRecord>())) ?? []
        for record in records where record.kindID == id {
            modelContext.delete(record)
        }
        modelContext.delete(kind)
        save()
    }

    private func moveKinds(from source: IndexSet, to destination: Int) {
        var ordered = kinds
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, kind) in ordered.enumerated() { kind.sortOrder = index }
        save()
    }

    /// 種類やルールが変わったら通知も組み直す。ここを忘れると「設定したのに鳴らない」になる。
    private func save() {
        try? modelContext.save()
        let container = modelContext.container
        Task { status = await NotificationRefresh.run(container: container) }
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
