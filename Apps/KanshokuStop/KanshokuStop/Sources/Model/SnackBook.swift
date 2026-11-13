import Foundation
import Observation

/// その日に間食したかどうか。値は旧 React Native 版の保存形式（"0"/"1"/"2"）に合わせる。
enum SnackStatus: String, Codable, Sendable {
    case none = "0"
    case snacked = "1"
    case skipped = "2"
}

/// 1日ぶんの記録。
struct DayEntry: Codable, Equatable, Sendable {
    var status: SnackStatus = .none
    /// 体重（kg）。入力された文字をそのまま持つ（旧版と同じ）。
    var weight: String = ""
    var memo: String = ""

    var isEmpty: Bool { status == .none && weight.isEmpty && memo.isEmpty }
}

/// 日付のキー（yyyyMMdd・端末の暦）。旧版の保存キーと同じ形。
enum DayKey {
    static func of(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(_ key: String, calendar: Calendar = .current) -> Date? {
        guard key.count == 8, let y = Int(key.prefix(4)), let m = Int(key.dropFirst(4).prefix(2)), let d = Int(key.suffix(2)) else {
            return nil
        }
        return calendar.date(from: DateComponents(year: y, month: m, day: d))
    }
}

/// 間食の記録帳。端末の Application Support に JSON で置く。
@MainActor
@Observable
final class SnackBook {
    private(set) var entries: [String: DayEntry]
    private let fileURL: URL?

    /// - Parameter fileURL: nil ならメモリの中だけ（テストとスクショ用）。
    init(fileURL: URL?, seed: [String: DayEntry] = [:]) {
        self.fileURL = fileURL
        if let fileURL, let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([String: DayEntry].self, from: data) {
            entries = saved
        } else {
            entries = seed
        }
    }

    static var defaultURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appending(path: "snack-book.json")
    }

    /// ふだんの起動。初めての起動なら旧版の記録を引き継ぐ。
    static func open() -> SnackBook {
        let url = defaultURL
        if FileManager.default.fileExists(atPath: url.path) {
            return SnackBook(fileURL: url)
        }
        let book = SnackBook(fileURL: url, seed: LegacyStore.load() ?? [:])
        book.save()
        return book
    }

    func entry(for key: String) -> DayEntry { entries[key] ?? DayEntry() }

    func set(_ entry: DayEntry, for key: String) {
        if entry.isEmpty {
            entries[key] = nil
        } else {
            entries[key] = entry
        }
        save()
    }

    func setStatus(_ status: SnackStatus, for key: String) {
        var entry = entry(for: key)
        entry.status = status
        set(entry, for: key)
    }

    var skippedDays: Int { entries.values.filter { $0.status == .skipped }.count }

    private func save() {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(entries).write(to: fileURL, options: .atomic)
        } catch {
            print("記録を保存できませんでした: \(error)")
        }
    }
}
