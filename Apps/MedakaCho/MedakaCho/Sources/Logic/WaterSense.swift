import Foundation

/// 水温から「いまの季節のめだか」を読む。えさの量・水換えの控えめさを決める。
enum WaterSense {
    enum Mood: Equatable {
        /// 10℃未満。ほとんど動かず、えさは要らない。
        case dormant
        /// 10〜15℃。少しだけ食べる。
        case sluggish
        /// 15〜20℃。食べるが、まだ控えめ。
        case mild
        /// 20〜28℃。よく食べ、よく産む。
        case lively
        /// 30℃以上。酸欠と水の傷みに気をつける。
        case tooWarm
        /// 28〜30℃。元気だが水が傷みやすい。
        case warm

        var title: String {
            switch self {
            case .dormant: "冬眠中"
            case .sluggish: "ゆっくり"
            case .mild: "おだやか"
            case .lively: "活発"
            case .warm: "高め"
            case .tooWarm: "高水温"
            }
        }

        var feedingAdvice: String {
            switch self {
            case .dormant: "えさはお休み。底でじっとしていればだいじょうぶ"
            case .sluggish: "暖かい日の昼に、ほんの少しだけ"
            case .mild: "1日1〜2回、少なめに"
            case .lively: "1日2〜3回、数分で食べきる量"
            case .warm: "1日2回。食べ残しはすぐ取る"
            case .tooWarm: "えさは控えめに。日よけと足し水を"
            }
        }
    }

    static func mood(celsius: Double) -> Mood {
        switch celsius {
        case ..<10: .dormant
        case ..<15: .sluggish
        case ..<20: .mild
        case ..<28: .lively
        case ..<30: .warm
        default: .tooWarm
        }
    }

    /// 1匹あたりの水の量（L）。いない容器は nil。
    static func litersPerFish(liters: Double, headcount: Int) -> Double? {
        guard headcount > 0 else { return nil }
        return liters / Double(headcount)
    }

    /// 1匹 1L を切ると過密の目安。針子・稚魚は小さいので半分まで許す。
    static func isCrowded(liters: Double, headcount: Int, stage: LifeStage) -> Bool {
        guard let perFish = litersPerFish(liters: liters, headcount: headcount) else { return false }
        let floor: Double = switch stage {
        case .fry: 0.2
        case .juvenile: 0.5
        case .young, .adult: 1
        }
        return perFish < floor
    }

    /// 次の水換えまでの日数の目安。
    ///
    /// 1匹あたりの水が多いほど間をあけられる。屋外は植物や青水が水を整えるので長め、
    /// 冬（10℃未満）は水を動かさないほうがよいので 30 日、高水温は傷みやすいので短めにする。
    static func waterChangeInterval(liters: Double, headcount: Int, outdoors: Bool, celsius: Double?) -> Int {
        let perFish = litersPerFish(liters: liters, headcount: headcount) ?? 10
        var days: Int = switch perFish {
        case 3...: 21
        case 2..<3: 14
        case 1..<2: 10
        case 0.5..<1: 7
        default: 4
        }
        if outdoors { days += 4 }
        if let celsius {
            switch mood(celsius: celsius) {
            case .dormant: return 30
            case .warm, .tooWarm: days = max(3, days * 2 / 3)
            default: break
            }
        }
        return days
    }
}
