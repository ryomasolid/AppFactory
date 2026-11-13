import CryptoKit
import Foundation

/// 旧 React Native 版（1.x）が端末に残した記録を読む。
///
/// 旧版は AsyncStorage のキー `calendarInfo` に `{ "yyyyMMdd": { status, weight, memo } }` の JSON 文字列を置いていた。
/// iOS での置き場所は `Application Support/<バンドルID>/RCTAsyncLocalStorage_V1/`（さらに古い版は `Documents/` 直下）。
/// - `manifest.json` … { キー: 値の文字列 } の辞書
/// - 1024文字を超える値は manifest では null になり、キーの MD5（小文字16進）の名前の別ファイルに入る
///
/// 読むだけで消さない（旧版に戻されても困らないように）。
enum LegacyStore {
    static let directoryName = "RCTAsyncLocalStorage_V1"
    static let key = "calendarInfo"

    static func candidateDirectories(bundleID: String = Bundle.main.bundleIdentifier ?? "") -> [URL] {
        let fm = FileManager.default
        var dirs: [URL] = []
        if let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            dirs.append(support.appending(path: bundleID).appending(path: directoryName))
        }
        if let documents = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            dirs.append(documents.appending(path: directoryName))
        }
        return dirs
    }

    static func load(from directories: [URL] = candidateDirectories()) -> [String: DayEntry]? {
        for dir in directories {
            guard let manifest = try? Data(contentsOf: dir.appending(path: "manifest.json")) else { continue }
            let entries = parse(manifest: manifest) { key in
                try? String(contentsOf: dir.appending(path: md5(key)), encoding: .utf8)
            }
            if let entries, !entries.isEmpty { return entries }
        }
        return nil
    }

    static func parse(manifest: Data, readFile: (String) -> String?) -> [String: DayEntry]? {
        guard let object = try? JSONSerialization.jsonObject(with: manifest) as? [String: Any] else { return nil }
        let raw: String?
        switch object[key] {
        case let inline as String: raw = inline
        case is NSNull: raw = readFile(key)
        default: raw = nil
        }
        guard let raw, let all = try? JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] else { return nil }

        var result: [String: DayEntry] = [:]
        for (date, value) in all {
            guard DayKey.date(date) != nil, let fields = value as? [String: Any] else { continue }
            let entry = DayEntry(
                status: SnackStatus(rawValue: text(fields["status"])) ?? .none,
                weight: text(fields["weight"]),
                memo: text(fields["memo"])
            )
            if !entry.isEmpty { result[date] = entry }
        }
        return result
    }

    /// 文字でも数でも文字列にそろえる（旧版は status を数で入れた時期があるかもしれないため）。
    private static func text(_ value: Any?) -> String {
        switch value {
        case let s as String: s
        case let n as NSNumber: n.stringValue
        default: ""
        }
    }

    static func md5(_ key: String) -> String {
        Insecure.MD5.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
