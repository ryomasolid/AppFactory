import Foundation

/// クエスト・実績・相棒の一覧（旧版と同じ中身）。
enum Catalog {
    static let questsToShow = 4

    static let quests: [Quest] = [
        Quest(id: "1", title: "聖なる水を飲む", detail: "コップ一杯の水を飲んで身体を目覚めさせる", symbol: "drop.fill", exp: 10, gold: 5),
        Quest(id: "2", title: "太陽の光を浴びる", detail: "5分間、外の空気を吸ってリフレッシュする", symbol: "sun.max.fill", exp: 20, gold: 10),
        Quest(id: "3", title: "身体の解放", detail: "簡単なストレッチで血行を促進する", symbol: "figure.flexibility", exp: 15, gold: 7),
        Quest(id: "4", title: "深呼吸の儀式", detail: "3回ゆっくりと深呼吸して脳に酸素を送る", symbol: "wind", exp: 10, gold: 4),
        Quest(id: "5", title: "階段の試練", detail: "1フロア分の階段を上り下りする", symbol: "figure.stairs", exp: 25, gold: 12),
        Quest(id: "6", title: "ツボ押し", detail: "手の甲にある眠気覚ましのツボを押す", symbol: "hand.point.up.left.fill", exp: 10, gold: 5),
        Quest(id: "7", title: "ミントの刺激", detail: "ガムを噛んだり歯を磨いて脳を活性化", symbol: "leaf.fill", exp: 5, gold: 3),
        Quest(id: "8", title: "冷水の手洗い", detail: "冷たい水で顔や手を洗ってリフレッシュ", symbol: "hands.and.sparkles.fill", exp: 15, gold: 6),
        Quest(id: "9", title: "音楽の力", detail: "アップテンポな曲を1曲聴いて気分を上げる", symbol: "music.note", exp: 10, gold: 4),
        Quest(id: "10", title: "換気の魔法", detail: "窓を開けて部屋の空気を入れ替える", symbol: "window.casement", exp: 15, gold: 8),
        Quest(id: "11", title: "場所移動", detail: "数分間だけ別の場所に移動して作業する", symbol: "arrow.left.arrow.right", exp: 10, gold: 5),
        Quest(id: "12", title: "1分間ジャーナル", detail: "今の気分やタスクを1分で書き出す", symbol: "pencil", exp: 20, gold: 10),
        Quest(id: "13", title: "タスクの分解", detail: "大きなタスクを3つの小さなステップに分ける", symbol: "list.bullet.indent", exp: 25, gold: 15),
    ]

    static let achievements: [Achievement] = [
        Achievement(id: "LEVEL_5", title: "覚醒の始まり", detail: "レベル5に到達する") { $0.level >= 5 },
        Achievement(id: "LEVEL_10", title: "睡魔ハンター", detail: "レベル10に到達する") { $0.level >= 10 },
        Achievement(id: "LEVEL_20", title: "覚醒の騎士", detail: "レベル20に到達する") { $0.level >= 20 },
        Achievement(id: "COMPLETE_10_QUESTS", title: "クエスト初心者", detail: "クエストを10回達成する") { $0.questsCompleted >= 10 },
        Achievement(id: "COMPLETE_50_QUESTS", title: "クエストマスター", detail: "クエストを50回達成する") { $0.questsCompleted >= 50 },
        Achievement(id: "EARN_100_GOLD", title: "小さな富", detail: "所持金を100ゴールドにする") { $0.gold >= 100 },
        Achievement(id: "STREAK_3", title: "三日坊主卒業", detail: "3日連続でクエストを達成する") { $0.bestStreak >= 3 },
        Achievement(id: "STREAK_7", title: "週間覚醒者", detail: "7日連続でクエストを達成する") { $0.bestStreak >= 7 },
        Achievement(id: "STREAK_30", title: "習慣の支配者", detail: "30日連続でクエストを達成する") { $0.bestStreak >= 30 },
        Achievement(id: "DEFEAT_1_DEMON", title: "初討伐", detail: "スリープデーモンを1体討伐する") { $0.demonsDefeated >= 1 },
        Achievement(id: "DEFEAT_10_DEMONS", title: "デーモンスレイヤー", detail: "スリープデーモンを10体討伐する") { $0.demonsDefeated >= 10 },
    ]

    static let buddyStages: [BuddyStage] = [
        BuddyStage(minLevel: 1, emoji: "🐣", title: "見習い覚醒者"),
        BuddyStage(minLevel: 5, emoji: "🐥", title: "目覚めの戦士"),
        BuddyStage(minLevel: 10, emoji: "🦉", title: "睡魔ハンター"),
        BuddyStage(minLevel: 20, emoji: "🦅", title: "覚醒の騎士"),
        BuddyStage(minLevel: 30, emoji: "🐉", title: "不眠の竜騎士"),
        BuddyStage(minLevel: 50, emoji: "👑", title: "覚醒王"),
    ]

    static func buddy(level: Int) -> BuddyStage {
        buddyStages.last { level >= $0.minLevel } ?? buddyStages[0]
    }

    /// 次の進化（最終進化なら nil）。
    static func nextBuddy(level: Int) -> BuddyStage? {
        buddyStages.first { $0.minLevel > level }
    }
}
