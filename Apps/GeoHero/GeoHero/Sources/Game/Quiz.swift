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

/// 問題を出す土地。街・ちかくの ほらあな・その街へ むかう区域で、その街の問題を出す。
enum QuizRegion: CaseIterable {
    case hakodate, sapporo, rausu

    /// 答えを教えてくれる街。
    var town: MapID {
        switch self {
        case .hakodate: .hakodate
        case .sapporo: .sapporo
        case .rausu: .rausu
        }
    }

    /// フィールドで この土地の問題が出る区域（`GameMap.encounterAreas` の名前）。
    private var areas: Set<String> {
        switch self {
        case .hakodate: ["函館のまわり", "函館山のふもと"]
        case .sapporo: ["札幌へむかう道", "藻岩山へむかう道"]
        case .rausu: ["知床へむかう道", "羅臼岳へむかう道"]
        }
    }

    /// いる場所から 土地を決める。問題のない場所なら nil（「ちしき」を出さない）。
    static func at(_ mapID: MapID, _ point: Point) -> QuizRegion? {
        switch mapID {
        case .hakodate, .hakodateyama: .hakodate
        case .sapporo, .moiwa1, .moiwa2: .sapporo
        case .rausu, .rausudake1, .rausudake2: .rausu
        case .field:
            World.field.area(at: point).flatMap { area in allCases.first { $0.areas.contains(area.name) } }
        default: nil
        }
    }

    /// 答えの位置は 問題ごとに ばらしてある（いつも1つめ、だと 読まずに当たる）。
    /// まちがいの選択肢には ほかの土地の名物を まぜる（旅の はじめに 聞いた話が 引っかけになる）。
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
        case .sapporo: [
            Quiz(question: "札幌の まちなかに ある 白い 木の たてものは？", choices: ["五稜郭", "時計台", "赤レンガ倉庫"], answer: 1),
            Quiz(question: "冬の 札幌で ひらかれる まつりは？", choices: ["雪まつり", "ねぶた祭", "祇園祭"], answer: 0),
            Quiz(question: "札幌で 生まれた 名物の ラーメンは？", choices: ["とんこつ", "しょうゆ", "みそ"], answer: 2),
            Quiz(question: "札幌の まんなかを 東西に のびる 公園は？", choices: ["大通公園", "上野公園", "奈良公園"], answer: 0),
            Quiz(question: "札幌の 夜景が 見える 山は？", choices: ["函館山", "藻岩山", "羅臼岳"], answer: 1),
            Quiz(question: "「少年よ 大志を いだけ」と いった 博士は？", choices: ["ペリー", "ザビエル", "クラーク"], answer: 2),
        ]
        case .rausu: [
            Quiz(question: "知床が えらばれた ものは？", choices: ["世界文化遺産", "世界自然遺産", "日本三景"], answer: 1),
            Quiz(question: "冬に 知床の 海へ ながれつく ものは？", choices: ["りゅうひょう", "やけい", "さくら"], answer: 0),
            Quiz(question: "知床半島の 北に ひろがる 海は？", choices: ["日本海", "瀬戸内海", "オホーツク海"], answer: 2),
            Quiz(question: "羅臼の 名物の 海そうは？", choices: ["わかめ", "こんぶ", "のり"], answer: 1),
            Quiz(question: "羅臼の 海で 見られる 大きな いきものは？", choices: ["シャチ", "ジンベエザメ", "ウミガメ"], answer: 0),
            Quiz(question: "「知床」は アイヌの ことばで どんな いみ？", choices: ["はなの みやこ", "ひの いずる くに", "ちの はて"], answer: 2),
        ]
        }
    }
}
