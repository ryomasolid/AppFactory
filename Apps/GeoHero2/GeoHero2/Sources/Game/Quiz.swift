import Foundation

/// 戦闘の「ちしきの チャンス」と ちしき検定で出す 地理の問題。3つから1つ選ぶ。
/// 答えは その街の 人・名所の看板・物語の人の話に かならず書いておく（`QuizTests` が見張る）。
/// 話を聞いて覚える → 戦いで使う、という流れにするため。
struct Quiz: Equatable, Hashable {
    let question: String
    let choices: [String]
    let answer: Int

    var correctChoice: String { choices[answer] }
}

/// 問題の 置き場。問題は 街ごとに あり、県ごとの ファイル（`Regions/`）に 書く。
enum QuizBank {
    /// 街ごとの 問題。
    static let byTown: [MapID: [Quiz]] = aomori
        .merging(akita) { first, _ in first }
        .merging(iwate) { first, _ in first }
        .merging(miyagi) { first, _ in first }
        .merging(fukushima) { first, _ in first }
        .merging(yamagata) { first, _ in first }

    /// いる場所で 問題を 出す 街。問題の ない 場所なら nil（「ちしき」を 出さない）。
    static func town(at mapID: MapID, _ point: Point) -> MapID? {
        let map = World.map(mapID)
        if map.kind == .field { return map.area(at: point)?.quizTown }
        return map.quizTown
    }

    /// 県の 問題 ぜんぶ（ちしき検定・ちしきの てちょうで 使う）。
    static func quizzes(in region: Region) -> [Quiz] {
        towns(in: region).flatMap { byTown[$0] ?? [] }
    }

    /// 県の 問題の ある 街（旅の順）。
    static func towns(in region: Region) -> [MapID] {
        MapID.allCases.filter { $0.isTown && $0.region == region && byTown[$0] != nil }
    }

    /// 問題 ぜんぶの 数。
    static var total: Int { byTown.values.map(\.count).reduce(0, +) }
}
