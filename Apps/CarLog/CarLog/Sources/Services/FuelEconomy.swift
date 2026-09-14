import Foundation

/// 満タン給油から次の満タン給油までの1区間。
struct FuelSegment: Identifiable, Equatable, Sendable {
    /// 区間の終わり（＝この燃費が表示される給油記録）のID。
    var id: UUID
    var startDate: Date
    var endDate: Date
    var startOdometer: Double
    var endOdometer: Double
    /// 区間内に入れた給油量の合計（途中の継ぎ足しを含む）。
    var liters: Double

    var distance: Double { endOdometer - startOdometer }

    /// 燃費 km/L。
    var kilometersPerLiter: Double { distance / liters }
}

/// 満タン法による燃費計算。
///
/// 満タンにした時点を基準に、次に満タンにするまでに走った距離を、
/// その間に入れた**全ての**燃料で割る。途中の継ぎ足し給油は区間を切らず、量だけ足す。
///
/// 最初の満タン給油は基準点にしかならないので燃費が出ない。これは満タン法として正しい。
enum FuelEconomy {
    /// 給油記録から区間燃費を古い順に並べて返す。
    ///
    /// 走行距離計の打ち間違い（前より小さい値・重複）があっても落ちないよう、
    /// 距離の昇順に並べ替えてから走査し、距離が進んでいない区間は捨てる。
    static func segments(for records: [FuelEntry]) -> [FuelSegment] {
        let sorted = records.sorted {
            $0.odometer == $1.odometer ? $0.date < $1.date : $0.odometer < $1.odometer
        }

        var segments: [FuelSegment] = []
        /// 直近の満タン給油（区間の始点）。
        var anchor: FuelEntry?
        /// 始点より後に入れた燃料の合計。
        var accumulated: Double = 0

        for record in sorted {
            guard let start = anchor else {
                // 最初の満タンが来るまでの記録は、区間の始点が無いので燃費計算に使えない。
                if record.isFullTank { anchor = record }
                continue
            }

            accumulated += record.liters
            guard record.isFullTank else { continue }

            if record.odometer > start.odometer, accumulated > 0 {
                segments.append(
                    FuelSegment(
                        id: record.id,
                        startDate: start.date,
                        endDate: record.date,
                        startOdometer: start.odometer,
                        endOdometer: record.odometer,
                        liters: accumulated
                    )
                )
            }
            anchor = record
            accumulated = 0
        }
        return segments
    }

    /// 記録ID → その記録で確定した区間燃費。一覧の各行に燃費を出すために使う。
    static func segmentsByRecordID(for records: [FuelEntry]) -> [UUID: FuelSegment] {
        Dictionary(uniqueKeysWithValues: segments(for: records).map { ($0.id, $0) })
    }

    /// 通算燃費 km/L。全区間の総距離 ÷ 総給油量。
    ///
    /// 区間燃費の単純平均ではない。長い区間の重みが正しく乗るのはこちら。
    static func overall(for records: [FuelEntry]) -> Double? {
        let segments = segments(for: records)
        let distance = segments.reduce(0) { $0 + $1.distance }
        let liters = segments.reduce(0) { $0 + $1.liters }
        guard distance > 0, liters > 0 else { return nil }
        return distance / liters
    }

    /// 最新の区間燃費。
    static func latest(for records: [FuelEntry]) -> FuelSegment? {
        segments(for: records).last
    }

    /// 給油の総額。ガソリン代としてコスト集計に合成する。
    static func totalSpent(for records: [FuelEntry]) -> Int {
        records.reduce(0) { $0 + $1.totalPrice }
    }

    /// 平均単価（円/L）。総額 ÷ 総給油量。
    static func averagePricePerLiter(for records: [FuelEntry]) -> Double? {
        let liters = records.reduce(0) { $0 + $1.liters }
        guard liters > 0 else { return nil }
        return Double(totalSpent(for: records)) / liters
    }
}
