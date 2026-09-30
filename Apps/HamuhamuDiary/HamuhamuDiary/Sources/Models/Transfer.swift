import Foundation

// 旧 React Native 版のデータとバックアップファイル（hamuhamu-*.json）の形。
// 旧版の型定義（types/index.ts）と同じキー名・同じ値の形を守る。
// 旧版どうし・旧版と新版のあいだで「データを送る / 取り込む」をそのまま使えるようにするため。
//
// どの項目も欠けていたり null だったりする前提で読む（古い版のデータも混ざるため）。

/// 日付だけの値（"yyyy-MM-dd"）と Date の相互変換。常にその端末のカレンダー・タイムゾーンで扱う。
enum DayFormat {
    static func string(from date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(from string: String, calendar: Calendar = .current) -> Date? {
        let parts = string.prefix(10).split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}

/// 旧版の createdAt / updatedAt（JavaScript の toISOString。ミリ秒つきUTC）。
enum Timestamp {
    /// "2026-06-24T12:34:56.789Z"（JavaScript の toISOString と同じ形）。
    private static let style = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    static func string(from date: Date) -> String {
        date.formatted(style)
    }

    static func date(from string: String) -> Date? {
        (try? style.parse(string)) ?? (try? Date.ISO8601FormatStyle().parse(string))
    }
}

struct RecordDTO: Codable, Equatable, Sendable {
    var id: String
    var date: String
    var weight: Double?
    var food: String
    var cleaningTaskIds: [String]
    var memo: String
    var photoUri: String?
    var createdAt: String
    var updatedAt: String
    /// バックアップファイルにだけ入る写真の中身（base64 の JPEG）。
    var photoData: String?

    init(
        id: String, date: String, weight: Double?, food: String, cleaningTaskIds: [String],
        memo: String, photoUri: String?, createdAt: String, updatedAt: String, photoData: String? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.food = food
        self.cleaningTaskIds = cleaningTaskIds
        self.memo = memo
        self.photoUri = photoUri
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.photoData = photoData
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(String.self, forKey: .date)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? "record-\(date)"
        weight = try? c.decodeIfPresent(Double.self, forKey: .weight)
        food = (try? c.decodeIfPresent(String.self, forKey: .food)) ?? ""
        cleaningTaskIds = (try? c.decodeIfPresent([String].self, forKey: .cleaningTaskIds)) ?? []
        memo = (try? c.decodeIfPresent(String.self, forKey: .memo)) ?? ""
        photoUri = try? c.decodeIfPresent(String.self, forKey: .photoUri)
        createdAt = (try? c.decodeIfPresent(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? c.decodeIfPresent(String.self, forKey: .updatedAt)) ?? createdAt
        photoData = try? c.decodeIfPresent(String.self, forKey: .photoData)
    }
}

struct ProfileDTO: Codable, Equatable, Sendable {
    var id: String
    var name: String
    var species: String
    var birthDate: String?
    var welcomeDate: String?
    var photoUri: String?

    init(id: String = "profile", name: String, species: String, birthDate: String?, welcomeDate: String?, photoUri: String?) {
        self.id = id
        self.name = name
        self.species = species
        self.birthDate = birthDate
        self.welcomeDate = welcomeDate
        self.photoUri = photoUri
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? "profile"
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? ""
        species = (try? c.decodeIfPresent(String.self, forKey: .species)) ?? ""
        birthDate = (try? c.decodeIfPresent(String.self, forKey: .birthDate)).flatMap { $0 }.flatMap { $0.isEmpty ? nil : $0 }
        welcomeDate = (try? c.decodeIfPresent(String.self, forKey: .welcomeDate)).flatMap { $0 }.flatMap { $0.isEmpty ? nil : $0 }
        photoUri = try? c.decodeIfPresent(String.self, forKey: .photoUri)
    }
}

struct ReminderDTO: Codable, Equatable, Sendable {
    var id: String
    var name: String
    var lastDate: String?
    var cycleDays: Int
    var category: String
    var emoji: String

    init(id: String, name: String, lastDate: String?, cycleDays: Int, category: String, emoji: String) {
        self.id = id
        self.name = name
        self.lastDate = lastDate
        self.cycleDays = cycleDays
        self.category = category
        self.emoji = emoji
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? ""
        lastDate = try? c.decodeIfPresent(String.self, forKey: .lastDate)
        cycleDays = max(1, (try? c.decodeIfPresent(Int.self, forKey: .cycleDays)) ?? 30)
        category = (try? c.decodeIfPresent(String.self, forKey: .category)) ?? "other"
        emoji = (try? c.decodeIfPresent(String.self, forKey: .emoji)) ?? "📦"
    }
}

struct PresetMealDTO: Codable, Equatable, Sendable {
    var id: String
    var name: String
    var text: String
}

struct SingleFoodDTO: Codable, Equatable, Sendable {
    var id: String
    var name: String
}

struct CleaningOptionDTO: Codable, Equatable, Sendable {
    var id: String
    var name: String
    var emoji: String
}

/// 端末内の全データ。旧版からの引き継ぎ・バックアップの読み書きで共通に使う。
/// 旧版で保存されていなかった項目は nil（＝既定値のままにする）。
struct DataSnapshot: Equatable, Sendable {
    var records: [RecordDTO] = []
    var profile: ProfileDTO?
    var reminders: [ReminderDTO]?
    var presetMeals: [PresetMealDTO]?
    var singleFoods: [SingleFoodDTO]?
    var cleaningOptions: [CleaningOptionDTO]?

    var isEmpty: Bool {
        records.isEmpty && profile == nil && reminders == nil
            && presetMeals == nil && singleFoods == nil && cleaningOptions == nil
    }
}

/// バックアップファイル（旧版の BackupData と同じ形。version 1）。
struct BackupFile: Codable, Sendable {
    var version: Int
    var exportedAt: String
    var records: [RecordDTO]
    var profile: ProfileDTO?
    var reminders: [ReminderDTO]
    var presetMeals: [PresetMealDTO]
    var singleFoods: [SingleFoodDTO]
    var cleaningOptions: [CleaningOptionDTO]

    init(snapshot: DataSnapshot, exportedAt: Date = Date()) {
        version = 1
        self.exportedAt = Timestamp.string(from: exportedAt)
        records = snapshot.records
        profile = snapshot.profile
        reminders = snapshot.reminders ?? []
        presetMeals = snapshot.presetMeals ?? []
        singleFoods = snapshot.singleFoods ?? []
        cleaningOptions = snapshot.cleaningOptions ?? []
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decode(Int.self, forKey: .version)
        exportedAt = (try? c.decodeIfPresent(String.self, forKey: .exportedAt)) ?? ""
        records = try c.decode([RecordDTO].self, forKey: .records)
        profile = try? c.decodeIfPresent(ProfileDTO.self, forKey: .profile)
        reminders = (try? c.decodeIfPresent([ReminderDTO].self, forKey: .reminders)) ?? []
        presetMeals = (try? c.decodeIfPresent([PresetMealDTO].self, forKey: .presetMeals)) ?? []
        singleFoods = (try? c.decodeIfPresent([SingleFoodDTO].self, forKey: .singleFoods)) ?? []
        cleaningOptions = (try? c.decodeIfPresent([CleaningOptionDTO].self, forKey: .cleaningOptions)) ?? []
    }

    var snapshot: DataSnapshot {
        DataSnapshot(
            records: records, profile: profile, reminders: reminders,
            presetMeals: presetMeals, singleFoods: singleFoods, cleaningOptions: cleaningOptions
        )
    }
}
