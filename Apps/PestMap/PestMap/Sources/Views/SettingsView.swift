import SwiftUI

/// 設定。季節の害虫対策アドバイス通知のオン/オフ。
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("seasonalTipsEnabled") private var seasonalTipsEnabled = false
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("季節の害虫対策アドバイス", isOn: $seasonalTipsEnabled)
                } footer: {
                    Text("春・梅雨・夏・秋の年4回、その季節に効く害虫対策のヒントを通知でお届けします。アプリを開かなくても対策のタイミングを逃しません。")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .onChange(of: seasonalTipsEnabled) { _, enabled in
                Task { await applySeasonalTips(enabled) }
            }
            .alert("通知を設定できません", isPresented: alertBinding) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })
    }

    private func applySeasonalTips(_ enabled: Bool) async {
        if enabled {
            let ok = await NotificationService.shared.scheduleSeasonalTips()
            if !ok {
                seasonalTipsEnabled = false
                alertMessage = String(localized: "通知が許可されていません。設定アプリ →「PestMap」→「通知」で許可してください。")
            }
        } else {
            NotificationService.shared.cancelSeasonalTips()
        }
    }
}
