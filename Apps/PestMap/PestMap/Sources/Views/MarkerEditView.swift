import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// マーカーの編集シート。種別・害虫タグ・メモ・次回予定（繰り返し含む）を設定し、
/// 「完了」で実施を記録して次回を自動再設定する。
struct MarkerEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var marker: PestMarker
    let planName: String

    @State private var hasReminder: Bool
    @State private var reminderDate: Date
    @State private var alertMessage: String?
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var pickedItem: PhotosPickerItem?

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
                    Picker("害虫", selection: pestBinding) {
                        ForEach(PestType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                }

                Section("メモ") {
                    TextField("例: シンク下に設置", text: $marker.note, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("設置場所の写真") {
                    if let data = marker.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button("写真を削除", role: .destructive) { marker.photoData = nil }
                    }
                    Menu {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button { showCamera = true } label: { Label("カメラで撮影", systemImage: "camera") }
                        }
                        Button { showLibrary = true } label: { Label("ライブラリから選択", systemImage: "photo") }
                    } label: {
                        Label(marker.photoData == nil ? "写真を追加" : "写真を変更", systemImage: "camera.fill")
                    }
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
                        Picker("繰り返し", selection: $marker.repeatInterval) {
                            ForEach(RepeatInterval.allCases) { interval in
                                Text(interval.label).tag(interval)
                            }
                        }
                    }
                }

                if marker.nextActionDate != nil {
                    Section {
                        Button {
                            Task { await markDone() }
                        } label: {
                            Label("実施した（記録して次回へ）", systemImage: "checkmark.circle.fill")
                        }
                    }
                }

                if !marker.records.isEmpty {
                    Section("実施履歴") {
                        ForEach(sortedRecords) { record in
                            Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.callout)
                        }
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
            .photosPicker(isPresented: $showLibrary, selection: $pickedItem, matching: .images)
            .onChange(of: pickedItem) { _, item in Task { await loadPicked(item) } }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { setPhoto($0) }
                    .ignoresSafeArea()
            }
        }
    }

    private func setPhoto(_ image: UIImage) {
        marker.photoData = image.jpegDataForStorage()
    }

    private func loadPicked(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            setPhoto(image)
        }
        pickedItem = nil
    }

    private var sortedRecords: [DoneRecord] {
        marker.records.sorted { $0.date > $1.date }
    }

    private var alertBinding: Binding<Bool> {
        Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })
    }

    private var kindBinding: Binding<MarkerKind> {
        Binding(
            get: { marker.kind },
            set: { newKind in
                marker.kind = newKind
                // 種別変更時は、その製品の標準周期をプリセットとして反映する。
                marker.repeatInterval = newKind.defaultRepeat
            }
        )
    }

    private var pestBinding: Binding<PestType> {
        Binding(get: { marker.pestType }, set: { marker.pestType = $0 })
    }

    private func save() async {
        if hasReminder {
            let outcome = await schedule(at: reminderDate)
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
            cancelReminder()
            dismiss()
        }
    }

    /// 実施を記録し、繰り返し設定があれば次回を自動再スケジュールする。
    private func markDone() async {
        let record = DoneRecord(date: Date())
        record.marker = marker
        context.insert(record)
        marker.lastDoneDate = record.date

        if let next = marker.repeatInterval.nextDate(from: record.date) {
            let outcome = await schedule(at: next)
            if case .scheduled(let id) = outcome {
                marker.nextActionDate = next
                marker.notificationID = id
                reminderDate = next
            }
        } else {
            // 繰り返しなし → 予定を消化
            cancelReminder()
            hasReminder = false
        }
        dismiss()
    }

    private func schedule(at date: Date) async -> NotificationService.ScheduleOutcome {
        let note = marker.note.isEmpty ? "" : "（\(marker.note)）"
        return await NotificationService.shared.schedule(
            title: "害虫対策のリマインド",
            body: "\(planName)：\(marker.kind.label)\(note)",
            at: date,
            existingID: marker.notificationID
        )
    }

    private func cancelReminder() {
        if let id = marker.notificationID {
            NotificationService.shared.cancel(id: id)
        }
        marker.nextActionDate = nil
        marker.notificationID = nil
    }

    private func deleteMarker() {
        if let id = marker.notificationID {
            NotificationService.shared.cancel(id: id)
        }
        context.delete(marker)
        dismiss()
    }
}
