import Foundation
import SwiftData

/// トリミング（サロン・おうちカット）の1回ぶん。
@Model
final class Trim {
    var on: Date = Date()
    var menuCode: String = TrimMenu.full.rawValue
    /// カットのスタイル（テディベアカット など）。
    var style: String = ""
    var salon: String = ""
    /// 料金（円）。わからなければ nil。
    var price: Int?
    var note: String = ""
    @Attribute(.externalStorage) var photo: Data?
    var dog: Dog?

    init(on: Date, menu: TrimMenu, style: String = "", salon: String = "", price: Int? = nil, dog: Dog) {
        self.on = on
        self.menuCode = menu.rawValue
        self.style = style
        self.salon = salon
        self.price = price
        self.dog = dog
    }

    var menu: TrimMenu {
        get { TrimMenu(rawValue: menuCode) ?? .full }
        set { menuCode = newValue.rawValue }
    }

    var title: String {
        let s = style.trimmingCharacters(in: .whitespaces)
        return s.isEmpty ? menu.label : s
    }
}

enum TrimMenu: String, CaseIterable, Identifiable {
    case full, partial, bath
    var id: String { rawValue }
    var label: String {
        switch self {
        case .full: "カット＋シャンプー"
        case .partial: "部分カット"
        case .bath: "シャンプーのみ"
        }
    }

    /// 毛の長さが リセットされるか（次のカットの目安に使う）。
    var cutsCoat: Bool { self == .full }
}

enum TrimStyles {
    /// よく選ばれるスタイル。自由に書くこともできる。
    static let presets = [
        "テディベアカット", "アフロカット", "マッシュルームカット", "サマーカット",
        "パピーカット", "ラムカット", "ボブカット", "おまかせ",
    ]
}
