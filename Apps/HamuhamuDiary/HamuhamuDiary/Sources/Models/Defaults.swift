import Foundation

/// 初回起動時の既定値。旧版（constants/defaults.ts）と同じキー・同じ中身にしている。
/// キーが揃っていれば、旧版のバックアップを取り込んだときに同じ項目として突き合わさる。
enum Defaults {
    static let cleaningOptions: [CleaningOptionDTO] = [
        .init(id: "partial", name: "部分掃除", emoji: "🧹"),
        .init(id: "toilet_sand", name: "トイレ砂交換", emoji: "🏖️"),
        .init(id: "full_wash", name: "ケージ丸洗い", emoji: "🚿"),
        .init(id: "water_bottle", name: "給水器洗浄", emoji: "💧"),
        .init(id: "wheel", name: "回し車洗浄", emoji: "🎡"),
        .init(id: "bedding", name: "床材交換", emoji: "🌿"),
    ]

    static let presetMeals: [PresetMealDTO] = [
        .init(id: "pellets", name: "いつものペレット", text: "いつものペレット 4g"),
        .init(id: "seeds", name: "シードミックス", text: "シードミックス 5g"),
        .init(id: "veggies", name: "野菜盛り合わせ", text: "ブロッコリー・にんじん少々"),
    ]

    static let singleFoods: [SingleFoodDTO] = [
        .init(id: "broccoli", name: "ブロッコリー"),
        .init(id: "carrot", name: "にんじん"),
        .init(id: "sunflower", name: "ひまわりの種"),
        .init(id: "pumpkin_seed", name: "かぼちゃの種"),
        .init(id: "corn", name: "コーン"),
        .init(id: "cucumber", name: "きゅうり"),
        .init(id: "apple", name: "りんご"),
        .init(id: "mealworm", name: "ミールワーム"),
        .init(id: "boiled_egg", name: "ゆで卵（少量）"),
        .init(id: "tofu", name: "豆腐（少量）"),
    ]

    static let reminders: [ReminderDTO] = [
        .init(id: "pellet_open", name: "ペレット開封", lastDate: nil, cycleDays: 30, category: "food", emoji: "🌾"),
        .init(id: "bedding_change", name: "床材全面交換", lastDate: nil, cycleDays: 14, category: "bedding", emoji: "🌿"),
        .init(id: "water_filter", name: "給水フィルター交換", lastDate: nil, cycleDays: 7, category: "equipment", emoji: "💧"),
        .init(id: "wheel_clean", name: "回し車洗浄", lastDate: nil, cycleDays: 30, category: "equipment", emoji: "🎡"),
    ]

    static let species: [String] = [
        "ゴールデンハムスター",
        "ジャンガリアンハムスター",
        "キャンベルハムスター",
        "ロボロフスキーハムスター",
        "チャイニーズハムスター",
        "その他",
    ]
}
