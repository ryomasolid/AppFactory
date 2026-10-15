import Foundation

/// アプリからウィジェットへ渡す中身。
///
/// SwiftData のストアはアプリのコンテナに置いたまま動かさず（旧版からの引き継ぎを壊さないため）、
/// ウィジェットに要る分だけを App Group の共有フォルダに JSON で書き出す。
struct WidgetSnapshot: Codable, Equatable {
    var name: String?
    var birthDate: Date?
    var welcomeDate: Date?
    /// いちばん新しい記録の日。ウィジェットはこれと「今日」を比べて、記録済みかを出す。
    var lastRecordDate: Date?
    var latestWeight: Double?
    /// 前回の体重からの増減(g)。
    var weightChange: Double?
    /// 体重が急に減っているか（`WeightAlert`）。
    var weightDropping = false
    var hasAvatar = false

    static let appGroup = "group.com.ryomasolid.hamuhamudiary"
    static let widgetKind = "HamuhamuWidget"
    /// ウィジェットを押したときに開く URL（今日の記録の入力画面）。
    static let recordURL = URL(string: "hamuhamudiary://record")!

    static var folder: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }
    static var fileURL: URL? { folder?.appending(path: "widget.json") }
    static var avatarURL: URL? { folder?.appending(path: "widget-avatar.jpg") }

    static func load() -> WidgetSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let url = Self.fileURL, let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// その日に記録があるか。
    func recorded(on day: Date, calendar: Calendar = .current) -> Bool {
        guard let lastRecordDate else { return false }
        return calendar.isDate(lastRecordDate, inSameDayAs: day)
    }
}
