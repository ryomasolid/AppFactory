import Foundation

/// 行列の待ち時間 = （並んでいる人数 ÷ 席数）× 業態の平均滞在時間。
enum QueueEstimate {
    static func minutes(people: Int, seats: Int, stay: Int) -> Int {
        guard people > 0, seats > 0 else { return 0 }
        return Int((Double(people) / Double(seats) * Double(stay)).rounded(.up))
    }

    static func advice(minutes: Int) -> String {
        switch minutes {
        case 0: "すぐ入れます。空いているうちにどうぞ。"
        case ..<15: "少し待てば入れます。食券の小銭を用意しておきましょう。"
        case ..<45: "飲み物を買っておくと楽です。頼むサイズを決めておきましょう。"
        default: "長丁場です。水分をとりながら、別の店も考えてみましょう。"
        }
    }

    /// 通知を出す時刻。入店予定の5分前。もう5分を切っていれば通知しない。
    static func reminderDate(minutes: Int, now: Date = .now) -> Date? {
        minutes > 5 ? now.addingTimeInterval(Double(minutes - 5) * 60) : nil
    }
}
