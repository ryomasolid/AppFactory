import Foundation

/// 戦闘の「ちしき」で出す 地理の問題。3つから1つ選ぶ。
/// 答えは その土地の 街の人・名所の看板・物語の人の話に かならず書いておく（`QuizTests` が見張る）。
/// 話を聞いて覚える → 戦いで使う、という流れにするため。
struct Quiz: Equatable, Hashable {
    let question: String
    let choices: [String]
    let answer: Int

    var correctChoice: String { choices[answer] }
}

/// 問題を出す土地。街・ちかくの ほらあな・その街へ むかう区域で、その街の問題を出す。
enum QuizRegion: CaseIterable {
    case hakodate, matsumae, onuma, sapporo, rausu

    /// 答えを教えてくれる街。小樽の問題は 札幌の山に まぜてある。
    var towns: [MapID] {
        switch self {
        case .hakodate: [.hakodate]
        case .matsumae: [.matsumae]
        case .onuma: [.onuma]
        case .sapporo: [.sapporo, .otaru]
        case .rausu: [.rausu]
        }
    }

    /// フィールドで この土地の問題が出る区域（`GameMap.encounterAreas` の名前）。
    private var areas: Set<String> {
        switch self {
        case .hakodate: ["函館のまわり", "函館山のふもと"]
        case .matsumae: ["松前へむかう道"]
        case .onuma: ["大沼のまわり"]
        case .sapporo: ["札幌のまわり", "藻岩山のふもと"]
        case .rausu: ["知床へむかう道", "羅臼岳へむかう道"]
        }
    }

    /// いる場所から 土地を決める。問題のない場所なら nil（「ちしき」を出さない）。
    static func at(_ mapID: MapID, _ point: Point) -> QuizRegion? {
        switch mapID {
        case .hakodate, .hakodateyama: .hakodate
        case .matsumae: .matsumae
        case .onuma, .komagatake: .onuma
        case .sapporo, .otaru, .moiwa1, .moiwa2: .sapporo
        case .rausu, .rausudake1, .rausudake2: .rausu
        case .hakodateArea, .sapporoArea, .shiretokoArea:
            World.map(mapID).area(at: point).flatMap { area in allCases.first { $0.areas.contains(area.name) } }
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
            // 街の看板で 読める問題。歩きまわった ごほうびに なる。
            Quiz(question: "函館の みなとに ならぶ 明治の 倉庫は？", choices: ["時計台", "五稜郭", "赤レンガ倉庫"], answer: 2),
            Quiz(question: "函館で 朝に ひらかれる 市場は？", choices: ["夜市", "朝市", "のみの市"], answer: 1),
        ]
        case .matsumae: [
            Quiz(question: "北海道で ただ ひとつの 日本式の 城は？", choices: ["五稜郭", "松前城", "姫路城"], answer: 1),
            Quiz(question: "松前が 名所として しられる 花は？", choices: ["さくら", "ラベンダー", "ひまわり"], answer: 0),
            Quiz(question: "江戸時代に 松前を おさめていた 藩は？", choices: ["薩摩藩", "加賀藩", "松前藩"], answer: 2),
            Quiz(question: "スルメと こんぶで つくる 松前の つけものは？", choices: ["松前漬け", "野沢菜漬け", "奈良漬け"], answer: 0),
            Quiz(question: "日本海を 行き来して 荷を はこんだ 船は？", choices: ["青函連絡船", "北前船", "黒船"], answer: 1),
            Quiz(question: "北海道の いちばん 南の みさきは？", choices: ["宗谷岬", "襟裳岬", "白神岬"], answer: 2),
        ]
        case .onuma: [
            Quiz(question: "大沼から 見える 火山は？", choices: ["駒ヶ岳", "富士山", "桜島"], answer: 0),
            Quiz(question: "駒ヶ岳の 名前の もとに なった どうぶつは？", choices: ["くま", "うま", "うし"], answer: 1),
            Quiz(question: "大沼の 名物の おかしは？", choices: ["もみじまんじゅう", "八ツ橋", "大沼だんご"], answer: 2),
            Quiz(question: "日本で はじめて 西洋りんごを そだてた 町は？", choices: ["七飯", "弘前", "松前"], answer: 0),
            Quiz(question: "大沼に うかぶ 島の かずは？", choices: ["12", "126", "1260"], answer: 1),
            Quiz(question: "冬に 大沼へ わたってくる 鳥は？", choices: ["ツバメ", "ペンギン", "ハクチョウ"], answer: 2),
        ]
        case .sapporo: [
            Quiz(question: "札幌の まちなかに ある 白い 木の たてものは？", choices: ["五稜郭", "時計台", "赤レンガ倉庫"], answer: 1),
            Quiz(question: "冬の 札幌で ひらかれる まつりは？", choices: ["雪まつり", "ねぶた祭", "祇園祭"], answer: 0),
            Quiz(question: "札幌で 生まれた 名物の ラーメンは？", choices: ["とんこつ", "しょうゆ", "みそ"], answer: 2),
            Quiz(question: "札幌の まんなかを 東西に のびる 公園は？", choices: ["大通公園", "上野公園", "奈良公園"], answer: 0),
            Quiz(question: "札幌の 夜景が 見える 山は？", choices: ["函館山", "藻岩山", "羅臼岳"], answer: 1),
            Quiz(question: "「少年よ 大志を いだけ」と いった 博士は？", choices: ["ペリー", "ザビエル", "クラーク"], answer: 2),
            // 小樽で 聞ける問題。
            Quiz(question: "小樽の まちなかを ながれる 古い 水の みちは？", choices: ["運河", "お堀", "滝"], answer: 0),
            Quiz(question: "小樽の 名物の こうげいひんは？", choices: ["うるし", "ガラス", "やきもの"], answer: 1),
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
