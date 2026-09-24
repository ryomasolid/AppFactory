import Foundation

/// 戦闘の「ちしき」で出す 地理の問題。3つから1つ選ぶ。
/// 答えは その土地の 街の人・看板・長老の話に かならず書いておく（`QuizTests` が見張る）。
/// 話を聞いて覚える → 戦いで使う、という流れにするため。
struct Quiz: Equatable, Hashable {
    let question: String
    let choices: [String]
    let answer: Int

    var correctChoice: String { choices[answer] }
}

/// 問題を出す土地。いまは試作として函館のあたりだけ。
enum QuizRegion: CaseIterable {
    case hakodate

    /// フィールドで函館の問題が出る区域（`GameMap.encounterAreas` の名前）。
    private static let hakodateAreas: Set<String> = ["函館のまわり", "函館山のふもと"]

    /// いる場所から 土地を決める。問題のない土地なら nil（「ちしき」を出さない）。
    static func at(_ mapID: MapID, _ point: Point) -> QuizRegion? {
        switch mapID {
        case .hakodate, .hakodateyama: .hakodate
        case .field: World.field.area(at: point).flatMap { hakodateAreas.contains($0.name) ? .hakodate : nil }
        default: nil
        }
    }

    /// 答えの位置は 問題ごとに ばらしてある（いつも1つめ、だと 読まずに当たる）。
    var quizzes: [Quiz] {
        switch self {
        case .hakodate: [
            Quiz(question: "函館山から 見る 名物は？", choices: ["りゅうひょう", "やけい", "おはなばたけ"], answer: 1),
            Quiz(question: "函館にある 星のかたちの 城あとは？", choices: ["五稜郭", "首里城", "大阪城"], answer: 0),
            Quiz(question: "函館の みなとが めんする 海峡は？", choices: ["関門海峡", "宗谷海峡", "津軽海峡"], answer: 2),
            Quiz(question: "函館の 市の さかな は？", choices: ["サケ", "イカ", "タイ"], answer: 1),
            Quiz(question: "函館と 青森を むすんでいた 船は？", choices: ["青函連絡船", "黒船", "宝船"], answer: 0),
            Quiz(question: "函館が ある 半島は？", choices: ["知床半島", "積丹半島", "渡島半島"], answer: 2),
        ]
        }
    }
}
