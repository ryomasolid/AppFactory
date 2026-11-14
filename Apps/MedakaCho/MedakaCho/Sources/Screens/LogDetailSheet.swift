import SwiftData
import SwiftUI

/// 保存ずみの記録を開いて、写真とメモをあとから付ける・直す。
/// ワンタップで保存した えさ・足し水・底掃除 にも写真を残せるように。
/// 数（匹・個）は容器の数と連動しているので、ここでは変えない（直したいときは消して記録しなおす）。
struct LogDetailSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let log: PondLog

    @State private var at = Date()
    @State private var note = ""
    @State private var photo: Data?
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(log.kind.label, systemImage: log.kind.symbol)
                        .font(.headline)
                        .foregroundStyle(Palette.deep)
                    if !summaryWithoutNote.isEmpty {
                        Text(summaryWithoutNote).foregroundStyle(.secondary)
                    }
                    DatePicker("日時", selection: $at, in: ...Date())
                }
                Section("メモ") {
                    TextField("気づいたこと", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
                PhotoField(photo: $photo)
            }
            .navigationTitle(log.vessel?.name ?? "記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                at = log.at
                note = log.note
                photo = log.photo
            }
        }
    }

    /// 数や水温など、メモ以外の中身。
    private var summaryWithoutNote: String {
        guard !log.note.isEmpty else { return log.summary }
        return log.summary
            .replacingOccurrences(of: log.note, with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "　 "))
    }

    private func save() {
        log.at = at
        log.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if log.photo != photo { log.photo = photo }
        try? context.save()
        let context = context
        Task { await MorningDigest.refresh(context: context) }
        dismiss()
    }
}
