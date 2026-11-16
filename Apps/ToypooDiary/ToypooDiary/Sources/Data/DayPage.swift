import Foundation
import SwiftData

/// 1頭の1日ぶんの日記。同じ子の同じ日には1ページだけ。
@Model
final class DayPage {
    /// その日の 0:00。
    var day: Date = Date()
    var moodCode: String?
    var walkCount: Int = 0
    var walkMinutes: Int = 0
    /// ごはんを食べた回数（0〜3）。
    var meals: Int = 0
    var brushed: Bool = false
    var poopCode: String?
    var tearCode: String?
    var note: String = ""
    @Attribute(.externalStorage) var photo: Data?
    var dog: Dog?

    init(day: Date, dog: Dog, calendar: Calendar = .current) {
        self.day = calendar.startOfDay(for: day)
        self.dog = dog
    }

    var mood: Mood? {
        get { moodCode.flatMap(Mood.init(rawValue:)) }
        set { moodCode = newValue?.rawValue }
    }

    var poop: Poop? {
        get { poopCode.flatMap(Poop.init(rawValue:)) }
        set { poopCode = newValue?.rawValue }
    }

    var tear: TearStain? {
        get { tearCode.flatMap(TearStain.init(rawValue:)) }
        set { tearCode = newValue?.rawValue }
    }

    /// 何も書いていないページ（保存しない）。
    var isBlank: Bool {
        mood == nil && walkCount == 0 && walkMinutes == 0 && meals == 0 && !brushed && poop == nil && tear == nil
            && note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photo == nil
    }
}

enum Mood: String, CaseIterable, Identifiable {
    case hyper, happy, calm, sleepy, blue
    var id: String { rawValue }
    var label: String {
        switch self {
        case .hyper: "はしゃいだ"
        case .happy: "ごきげん"
        case .calm: "まったり"
        case .sleepy: "ねむねむ"
        case .blue: "しょんぼり"
        }
    }

    var symbol: String {
        switch self {
        case .hyper: "sparkles"
        case .happy: "sun.max.fill"
        case .calm: "cloud.sun.fill"
        case .sleepy: "moon.zzz.fill"
        case .blue: "cloud.rain.fill"
        }
    }
}

enum Poop: String, CaseIterable, Identifiable {
    case good, soft, hard, none
    var id: String { rawValue }
    var label: String {
        switch self {
        case .good: "いい感じ"
        case .soft: "やわらかめ"
        case .hard: "かため"
        case .none: "出なかった"
        }
    }

    var needsEye: Bool { self != .good }
}

/// 涙やけ。トイプードルは出やすいので、毎日の変化を残せるようにする。
enum TearStain: String, CaseIterable, Identifiable {
    case clear, little, heavy
    var id: String { rawValue }
    var label: String {
        switch self {
        case .clear: "なし"
        case .little: "すこし"
        case .heavy: "多め"
        }
    }
}
