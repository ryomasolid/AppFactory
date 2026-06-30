import SwiftData
import SwiftUI

/// 間取り一覧。新規作成（増分1では空の間取り）と削除、詳細への遷移。
struct FloorPlanListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FloorPlan.createdAt, order: .reverse) private var plans: [FloorPlan]

    @State private var showingNewPlanAlert = false
    @State private var newPlanName = ""
    @State private var showingReminders = false
    @State private var showingSettings = false
    @State private var path: [FloorPlan] = []
    @AppStorage("pm.hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if plans.isEmpty {
                    ContentUnavailableView(
                        "間取りがありません",
                        systemImage: "map",
                        description: Text("右上の＋から間取りを追加できます")
                    )
                } else {
                    List {
                        ForEach(plans) { plan in
                            NavigationLink(value: plan) {
                                row(plan)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("PestMap")
            .navigationDestination(for: FloorPlan.self) { plan in
                FloorPlanEditorView(plan: plan)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingReminders = true
                    } label: {
                        Image(systemName: "bell.badge")
                    }
                    .accessibilityLabel("リマインド一覧")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("設定")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newPlanName = ""
                        showingNewPlanAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("間取りを追加")
                }
            }
            .sheet(isPresented: $showingReminders) {
                RemindersView { plan in
                    showingReminders = false
                    path = [plan]
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                showOnboarding = !hasSeenOnboarding
                // 広告の同意（UMP）→ ATT → AdMob 初期化を実行。
                ConsentManager.shared.start()
                #if DEBUG
                SampleData.seedIfNeeded(context)
                #endif
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView {
                    hasSeenOnboarding = true
                    showOnboarding = false
                }
            }
            .safeAreaInset(edge: .bottom) {
                BannerAdView()
            }
            .alert("新しい間取り", isPresented: $showingNewPlanAlert) {
                TextField("名前（例: 1階キッチン）", text: $newPlanName)
                Button("作成") { createPlan() }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("空の間取りを作成します。写真の取り込みは次の画面で行えます。")
            }
        }
    }

    private func row(_ plan: FloorPlan) -> some View {
        let overdue = plan.markers.filter { ($0.nextActionDate ?? .distantFuture) < Date() }.count
        return VStack(alignment: .leading, spacing: 4) {
            Text(plan.name)
                .font(.headline)
            HStack(spacing: 6) {
                Text("マーカー \(plan.markers.count) 件 ・ \(plan.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if overdue > 0 {
                    Text("期限切れ \(overdue)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red, in: Capsule())
                }
            }
        }
    }

    private func createPlan() {
        let trimmed = newPlanName.trimmingCharacters(in: .whitespacesAndNewlines)
        let plan = FloorPlan(name: trimmed.isEmpty ? "無題の間取り" : trimmed)
        context.insert(plan)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(plans[index])
        }
    }
}
