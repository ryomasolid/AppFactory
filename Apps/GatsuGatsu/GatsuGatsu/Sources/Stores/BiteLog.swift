import Foundation
import Observation

/// ガツログの保存先。端末の中の JSON 1つだけで、外へは送らない。
@MainActor
@Observable
final class BiteLog {
    private(set) var bites: [Bite] = []
    private let fileURL: URL

    init(fileURL: URL = BiteLog.defaultURL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Bite].self, from: data) {
            bites = saved
        }
    }

    nonisolated static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "bites.json")
    }

    var stats: BiteStats { BiteStats(bites: bites) }

    func add(_ bite: Bite) {
        bites.append(bite)
        bites.sort { $0.eatenAt > $1.eatenAt }
        save()
    }

    func remove(_ bite: Bite) {
        bites.removeAll { $0.id == bite.id }
        save()
    }

    func replaceAll(_ newBites: [Bite]) {
        bites = newBites.sorted { $0.eatenAt > $1.eatenAt }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(bites).write(to: fileURL, options: .atomic)
        } catch {
            // 空き容量不足など。記録は画面に残っているので、次の保存でまた書く。
            print("ガツログを保存できません: \(error)")
        }
    }
}
