import SwiftData
import SwiftUI

/// マーカーの編集シート。種別・メモ・次回予定（リマインド通知）を設定する。
struct MarkerEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var marker: PestMarker
    let planName: String

    @State private var hasReminder: Bool
    @State private var reminderDate: Date
    @State private var alertMessage: String?

    init(marker: PestMarker, planName: String) {
        self.marker = marker
        self.planName = planName
        _hasReminder = State(initialValue: marker.nextActionDate != nil)
        _reminderDate = State(
            initialValue: marker.nextActionDate ?? Date().addingTimeInterval(30 * 24 * 3600)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("種別") {
                    Picker("種別", selection: kindBinding) {
                        ForEach(MarkerKind.allCases) { kind in
                            Label(kind.label, systemImage: kind.symbol).tag(kind)
                        }
                    }
                }

                Section("メモ") {
                    TextField("例: シンク下に設置", text: $marker.note, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("次回の予定") {
                    Toggle("リマインドする", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker(
                            "日時",
                            selection: $reminderDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section {
                    Button("このマーカーを削除", role: .destructive) { deleteMarker() }
                }
            }
            .navigationTitle("マーカー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { Task { await save() } }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
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

    private var kindBinding: Binding<MarkerKind> {
        Binding(get: { marker.kind }, set: { marker.kind = $0 })
    }

    private func save() async {
        if hasReminder {
            let note = marker.note.isEmpty ? "" : "（\(marker.note)）"
            let outcome = await NotificationService.shared.schedule(
                title: "害虫対策のリマインド",
                body: "\(planName)：\(marker.kind.label)\(note)",
                at: reminderDate,
                existingID: marker.notificationID
            )
            switch outcome {
            case .scheduled(let id):
                marker.nextActionDate = reminderDate
                marker.notificationID = id
                dismiss()
            case .notAuthorized:
                alertMessage = "通知が許可されていません。設定アプリ →「PestMap」→「通知」で許可してください。"
            case .invalidDate:
                alertMessage = "過去の日時には設定できません。未来の日時を選んでください。"
            case .failed:
                alertMessage = "通知の登録に失敗しました。時間をおいて再度お試しください。"
            }
        } else {
            if let id = marker.notificationID {
                NotificationService.shared.cancel(id: id)
            }
            marker.nextActionDate = nil
            marker.notificationID = nil
            dismiss()
        }
    }

    private func deleteMarker() {
        if let id = marker.notificationID {
            NotificationService.shared.cancel(id: id)
        }
        context.delete(marker)
        dismiss()
    }
}
