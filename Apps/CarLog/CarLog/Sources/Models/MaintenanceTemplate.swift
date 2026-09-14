import Foundation

/// メンテ項目のテンプレート。
///
/// 間隔は「一般的な目安」であって車種ごとの指定ではない。
/// 取扱説明書の値と違うことがあるので、UI では編集できる前提で出す。
struct MaintenanceTemplate: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var symbolName: String
    var intervalMonths: Int?
    var intervalDistance: Double?
    /// オンボーディングで既定チェックを入れるか（まず要るものだけ true）。
    var isRecommended: Bool

    static let all: [MaintenanceTemplate] = [
        .init(
            id: "oil", title: String(localized: "オイル交換"), symbolName: "drop.fill",
            intervalMonths: 6, intervalDistance: 5000, isRecommended: true
        ),
        .init(
            id: "oilFilter", title: String(localized: "オイルフィルタ交換"), symbolName: "circle.hexagongrid.fill",
            intervalMonths: 12, intervalDistance: 10000, isRecommended: false
        ),
        .init(
            id: "inspection", title: String(localized: "車検"), symbolName: "checkmark.seal.fill",
            intervalMonths: 24, intervalDistance: nil, isRecommended: true
        ),
        .init(
            id: "tax", title: String(localized: "自動車税"), symbolName: "yensign.circle.fill",
            intervalMonths: 12, intervalDistance: nil, isRecommended: true
        ),
        .init(
            id: "insurance", title: String(localized: "任意保険の更新"), symbolName: "shield.lefthalf.filled",
            intervalMonths: 12, intervalDistance: nil, isRecommended: false
        ),
        .init(
            id: "tire", title: String(localized: "タイヤ交換"), symbolName: "circle.circle.fill",
            intervalMonths: nil, intervalDistance: 30000, isRecommended: false
        ),
        .init(
            id: "tireRotation", title: String(localized: "タイヤローテーション"), symbolName: "arrow.triangle.2.circlepath",
            intervalMonths: nil, intervalDistance: 5000, isRecommended: false
        ),
        .init(
            id: "battery", title: String(localized: "バッテリー交換"), symbolName: "minus.plus.batteryblock.fill",
            intervalMonths: 36, intervalDistance: nil, isRecommended: false
        ),
        .init(
            id: "wiper", title: String(localized: "ワイパー交換"), symbolName: "windshield.front.and.wiper",
            intervalMonths: 12, intervalDistance: nil, isRecommended: false
        ),
        .init(
            id: "brakePad", title: String(localized: "ブレーキパッド点検"), symbolName: "brakesignal",
            intervalMonths: nil, intervalDistance: 30000, isRecommended: false
        ),
        .init(
            id: "coolant", title: String(localized: "冷却水交換"), symbolName: "thermometer.snowflake",
            intervalMonths: 24, intervalDistance: nil, isRecommended: false
        ),
        .init(
            id: "airFilter", title: String(localized: "エアフィルタ交換"), symbolName: "wind",
            intervalMonths: nil, intervalDistance: 20000, isRecommended: false
        ),
    ]

    func makeItem(sortOrder: Int, startDate: Date?, startOdometer: Double?) -> MaintenanceItem {
        MaintenanceItem(
            title: title,
            symbolName: symbolName,
            intervalMonths: intervalMonths,
            intervalDistance: intervalDistance,
            lastDoneDate: startDate,
            lastDoneOdometer: startOdometer,
            sortOrder: sortOrder
        )
    }
}
