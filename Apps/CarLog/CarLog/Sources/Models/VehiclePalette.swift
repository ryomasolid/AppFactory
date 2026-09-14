import Foundation

/// クルマの色・アイコンの選択肢。複数台を一覧で見分けるためだけのもの。
enum VehiclePalette {
    static let colors: [String] = [
        "#0F7A80", "#2F7DD1", "#D1495B", "#E0A21B",
        "#3E9B6B", "#8E5BD1", "#C4622D", "#5B6B8C",
    ]

    static let symbols: [String] = [
        "car.fill", "bolt.car.fill", "car.side.fill", "suv.side.fill",
        "truck.box.fill", "bus.fill", "motorcycle.fill", "van.fill",
    ]
}
