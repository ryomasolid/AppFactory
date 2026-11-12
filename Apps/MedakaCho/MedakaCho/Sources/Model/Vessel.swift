import Foundation
import SwiftData

/// めだかを入れている入れもの1つ。めだか帳の記録はすべて「容器」につく（1匹ずつは追わない）。
@Model
final class Vessel {
    var name: String = ""
    /// `VesselStyle` の rawValue。
    var styleCode: String = VesselStyle.bowl.rawValue
    var outdoors: Bool = true
    /// 水の量（リットル）。過密の目安と水換えの間隔に使う。
    var liters: Double = 20
    /// 品種（楊貴妃・幹之 など）。空なら「ミックス」。
    var breed: String = ""
    /// `LifeStage` の rawValue。
    var stageCode: String = LifeStage.adult.rawValue
    /// いまいる数（だいたい）。落ちた・移した・入れたの記録で増減する。
    var headcount: Int = 0
    var setUpOn: Date = Date()
    var hasHeater: Bool = false
    var order: Int = 0
    var note: String = ""

    @Relationship(deleteRule: .cascade, inverse: \PondLog.vessel)
    var logs: [PondLog]? = []

    init(name: String, style: VesselStyle, outdoors: Bool, liters: Double, breed: String, stage: LifeStage, headcount: Int, setUpOn: Date = Date(), order: Int = 0) {
        self.name = name
        self.styleCode = style.rawValue
        self.outdoors = outdoors
        self.liters = liters
        self.breed = breed
        self.stageCode = stage.rawValue
        self.headcount = headcount
        self.setUpOn = setUpOn
        self.order = order
    }

    var style: VesselStyle {
        get { VesselStyle(rawValue: styleCode) ?? .bowl }
        set { styleCode = newValue.rawValue }
    }

    var stage: LifeStage {
        get { LifeStage(rawValue: stageCode) ?? .adult }
        set { stageCode = newValue.rawValue }
    }

    var breedLabel: String { breed.trimmingCharacters(in: .whitespaces).isEmpty ? "ミックス" : breed }

    /// 新しい順。
    var history: [PondLog] { (logs ?? []).sorted { $0.at > $1.at } }

    func latest(_ kind: LogKind) -> PondLog? {
        (logs ?? []).filter { $0.kind == kind }.max { $0.at < $1.at }
    }

    /// いちばん新しい水温。
    var lastTemperature: (celsius: Double, at: Date)? {
        guard let log = (logs ?? []).filter({ $0.celsius != nil }).max(by: { $0.at < $1.at }), let c = log.celsius else { return nil }
        return (c, log.at)
    }
}

enum VesselStyle: String, CaseIterable, Identifiable {
    case bowl, styrofoam, tub, tank, case_
    var id: String { rawValue }

    var label: String {
        switch self {
        case .bowl: "睡蓮鉢"
        case .styrofoam: "発泡スチロール"
        case .tub: "トロ舟・プラ舟"
        case .tank: "水槽"
        case .case_: "プラケース"
        }
    }

    var symbol: String {
        switch self {
        case .bowl: "circle.bottomhalf.filled"
        case .styrofoam: "shippingbox"
        case .tub: "rectangle.bottomhalf.filled"
        case .tank: "square.split.bottomrightquarter"
        case .case_: "archivebox"
        }
    }
}

/// 容器に入っている子たちの育ち具合。
enum LifeStage: String, CaseIterable, Identifiable {
    case fry, juvenile, young, adult
    var id: String { rawValue }

    var label: String {
        switch self {
        case .fry: "針子"
        case .juvenile: "稚魚"
        case .young: "若魚"
        case .adult: "親"
        }
    }
}
