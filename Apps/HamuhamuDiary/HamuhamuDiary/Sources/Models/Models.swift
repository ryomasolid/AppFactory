import Foundation
import SwiftData

// 旧 React Native 版・バックアップファイルと項目名を揃えている。
// 文字列の `key` は旧版の `id`（"record-1750000000000" / "pellet_open" など）。
// バックアップの取り込みで同じものを突き合わせるのに使うので、作り直しても変えない。

/// 1日ぶんの記録。旧版と同じく「1日1件」を基本にし、バックアップの取り込みも日付で突き合わせる。
@Model
final class DiaryRecord {
    var key: String = ""
    /// 記録した日（その日の 0:00）。
    var date: Date = Date()
    /// 体重(g)。未入力は nil。
    var weight: Double?
    var food: String = ""
    /// `CleaningOption.key` の並び。
    var cleaningKeys: [String] = []
    var memo: String = ""
    /// Documents からの相対パス（"photos/xxx.jpg"）。`PhotoStore` で解決する。
    var photoPath: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        key: String = DiaryRecord.newKey(),
        date: Date,
        weight: Double? = nil,
        food: String = "",
        cleaningKeys: [String] = [],
        memo: String = "",
        photoPath: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.key = key
        self.date = date
        self.weight = weight
        self.food = food
        self.cleaningKeys = cleaningKeys
        self.memo = memo
        self.photoPath = photoPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 旧版と同じ形式の新しいキー。
    static func newKey(now: Date = Date()) -> String {
        "record-\(Int(now.timeIntervalSince1970 * 1000))"
    }
}

/// ハムスターのプロフィール（1匹）。
@Model
final class HamsterProfile {
    var name: String = ""
    var species: String = ""
    var birthDate: Date?
    var welcomeDate: Date?
    var photoPath: String?

    init(name: String, species: String, birthDate: Date? = nil, welcomeDate: Date? = nil, photoPath: String? = nil) {
        self.name = name
        self.species = species
        self.birthDate = birthDate
        self.welcomeDate = welcomeDate
        self.photoPath = photoPath
    }
}

/// フード・消耗品の交換サイクル。
@Model
final class SupplyReminder {
    var key: String = ""
    var name: String = ""
    var emoji: String = ""
    var cycleDays: Int = 30
    /// 最後に交換した日。未設定なら「交換時期」扱い。
    var lastDate: Date?
    /// 旧版の category（food / bedding / equipment / other）。表示には使わないが往復で落とさない。
    var category: String = "other"
    var sortOrder: Int = 0

    init(key: String, name: String, emoji: String, cycleDays: Int, lastDate: Date? = nil, category: String, sortOrder: Int) {
        self.key = key
        self.name = name
        self.emoji = emoji
        self.cycleDays = cycleDays
        self.lastDate = lastDate
        self.category = category
        self.sortOrder = sortOrder
    }
}

/// 1タップで入れられる献立テンプレート。
@Model
final class PresetMeal {
    var key: String = ""
    var name: String = ""
    var text: String = ""
    var sortOrder: Int = 0

    init(key: String = "meal-\(Int(Date().timeIntervalSince1970 * 1000))", name: String, text: String, sortOrder: Int) {
        self.key = key
        self.name = name
        self.text = text
        self.sortOrder = sortOrder
    }
}

/// おやつ・追加フードの選択肢。
@Model
final class SingleFood {
    var key: String = ""
    var name: String = ""
    var sortOrder: Int = 0

    init(key: String = "food-\(Int(Date().timeIntervalSince1970 * 1000))", name: String, sortOrder: Int) {
        self.key = key
        self.name = name
        self.sortOrder = sortOrder
    }
}

/// 記録フォームのお掃除項目。
@Model
final class CleaningOption {
    var key: String = ""
    var name: String = ""
    var emoji: String = ""
    var sortOrder: Int = 0

    init(key: String = "cleaning-\(Int(Date().timeIntervalSince1970 * 1000))", name: String, emoji: String, sortOrder: Int) {
        self.key = key
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
    }
}

enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        DiaryRecord.self, HamsterProfile.self, SupplyReminder.self,
        PresetMeal.self, SingleFood.self, CleaningOption.self,
    ]
}
