import CryptoKit
import Foundation

/// 旧 React Native 版（v1.x）が端末に残した日記を読む。
///
/// 旧版は AsyncStorage に Zustand の状態を JSON 文字列で保存していた。iOS での置き場所は
/// `Application Support/<バンドルID>/RCTAsyncLocalStorage_V1/`（さらに古い版は `Documents/` 直下）で、
/// - `manifest.json` … { キー: 値の文字列 } の辞書
/// - 1024文字を超える値は manifest では null になり、キーの MD5（小文字16進）の名前の別ファイルに入る
///
/// Zustand の値は `{"state": {...}, "version": 0}` の形。使っていたキーは
/// `hamu-records` / `hamu-profile` / `hamu-reminders`。
///
/// 読むだけで消さない（引き継ぎに失敗しても次の起動でやり直せるように、また旧版に戻されても困らないように）。
enum LegacyStore {
    static let directoryName = "RCTAsyncLocalStorage_V1"

    /// 端末上の旧データの場所の候補（新しい置き場所を先に見る）。
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

    /// 端末の旧データを読む。見つからなければ nil。
    static func load(from directories: [URL] = candidateDirectories()) -> DataSnapshot? {
        for dir in directories {
            let manifestURL = dir.appending(path: "manifest.json")
            guard let manifest = try? Data(contentsOf: manifestURL) else { continue }
            let snapshot = parse(manifest: manifest) { key in
                try? String(contentsOf: dir.appending(path: md5(key)), encoding: .utf8)
            }
            if let snapshot, !snapshot.isEmpty { return snapshot }
        }
        return nil
    }

    /// manifest と「大きな値の別ファイル」から中身を組み立てる。
    /// - Parameter readFile: キーを受け取り、別ファイルに入っている値を返す。
    static func parse(manifest: Data, readFile: (String) -> String?) -> DataSnapshot? {
        guard let object = try? JSONSerialization.jsonObject(with: manifest) as? [String: Any] else { return nil }

        func value(_ key: String) -> Data? {
            switch object[key] {
            case let inline as String: return Data(inline.utf8)
            case is NSNull: return readFile(key).map { Data($0.utf8) }
            default: return nil
            }
        }

        var snapshot = DataSnapshot()
        if let data = value("hamu-records"),
           let state = try? JSONDecoder().decode(Persisted<RecordsState>.self, from: data).state {
            snapshot.records = state.records ?? []
        }
        if let data = value("hamu-profile"),
           let state = try? JSONDecoder().decode(Persisted<ProfileState>.self, from: data).state {
            snapshot.profile = state.profile
            snapshot.presetMeals = state.presetMeals
            snapshot.singleFoods = state.singleFoods
            snapshot.cleaningOptions = state.cleaningOptions
        }
        if let data = value("hamu-reminders"),
           let state = try? JSONDecoder().decode(Persisted<RemindersState>.self, from: data).state {
            snapshot.reminders = state.reminders
        }
        return snapshot
    }

    /// AsyncStorage が大きな値のファイル名に使う MD5（小文字16進）。
    static func md5(_ key: String) -> String {
        Insecure.MD5.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Zustand の保存形式

    private struct Persisted<State: Decodable>: Decodable {
        var state: State
    }

    private struct RecordsState: Decodable {
        var records: [RecordDTO]?
        init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            records = try? c.decodeIfPresent(LossyArray<RecordDTO>.self, forKey: .records)?.elements
        }
        enum CodingKeys: String, CodingKey { case records }
    }

    private struct ProfileState: Decodable {
        var profile: ProfileDTO?
        var presetMeals: [PresetMealDTO]?
        var singleFoods: [SingleFoodDTO]?
        var cleaningOptions: [CleaningOptionDTO]?
        init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            profile = try? c.decodeIfPresent(ProfileDTO.self, forKey: .profile)
            presetMeals = try? c.decodeIfPresent(LossyArray<PresetMealDTO>.self, forKey: .presetMeals)?.elements
            singleFoods = try? c.decodeIfPresent(LossyArray<SingleFoodDTO>.self, forKey: .singleFoods)?.elements
            cleaningOptions = try? c.decodeIfPresent(LossyArray<CleaningOptionDTO>.self, forKey: .cleaningOptions)?.elements
        }
        enum CodingKeys: String, CodingKey { case profile, presetMeals, singleFoods, cleaningOptions }
    }

    private struct RemindersState: Decodable {
        var reminders: [ReminderDTO]?
        init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            reminders = try? c.decodeIfPresent(LossyArray<ReminderDTO>.self, forKey: .reminders)?.elements
        }
        enum CodingKeys: String, CodingKey { case reminders }
    }
}

/// 1件壊れていても残りは読む配列（1件のせいで日記全体を失わないため）。
struct LossyArray<Element: Decodable>: Decodable {
    var elements: [Element]

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Element] = []
        while !container.isAtEnd {
            if let element = try? container.decode(Element.self) {
                result.append(element)
            } else {
                _ = try? container.decode(Skip.self)
            }
        }
        elements = result
    }

    /// どんな値でも必ず読み進める（失敗すると同じ要素で止まり続けるため、投げない）。
    private struct Skip: Decodable {
        init(from decoder: any Decoder) {}
    }
}
