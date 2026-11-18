import Foundation

enum Region: String, CaseIterable, Identifiable, Codable {
    case asia, middleEast, europe, africa, northAmerica, southAmerica, oceania

    var id: String { rawValue }

    var label: String {
        switch self {
        case .asia: "アジア"
        case .middleEast: "中東"
        case .europe: "ヨーロッパ"
        case .africa: "アフリカ"
        case .northAmerica: "北中米"
        case .southAmerica: "南米"
        case .oceania: "オセアニア"
        }
    }
}

struct Country: Identifiable, Hashable {
    /// ISO 3166-1 の2文字（コソボは XK）。
    let code: String
    let name: String
    let capital: String
    let region: Region
    /// ずかんに出す補足（首都の扱いが特殊な国など）。
    var note: String? = nil

    var id: String { code }

    /// 国旗の絵文字（地域指示記号の組み合わせ）。
    var flag: String {
        code.unicodeScalars
            .compactMap { UnicodeScalar(127_397 + $0.value) }
            .map(String.init)
            .joined()
    }
}

extension Country {
    static func find(_ code: String) -> Country? { byCode[code] }
    private static let byCode = Dictionary(uniqueKeysWithValues: all.map { ($0.code, $0) })

    /// 国連加盟の193か国＋バチカン・コソボ・クック諸島・ニウエ（日本が承認している国と北朝鮮）。
    /// 国名・首都は外務省の表記に合わせた。
    static let all: [Country] = [
        // アジア
        .init(code: "JP", name: "日本", capital: "東京", region: .asia),
        .init(code: "KR", name: "韓国", capital: "ソウル", region: .asia),
        .init(code: "KP", name: "北朝鮮", capital: "ピョンヤン", region: .asia),
        .init(code: "CN", name: "中国", capital: "北京", region: .asia),
        .init(code: "MN", name: "モンゴル", capital: "ウランバートル", region: .asia),
        .init(code: "VN", name: "ベトナム", capital: "ハノイ", region: .asia),
        .init(code: "LA", name: "ラオス", capital: "ビエンチャン", region: .asia),
        .init(code: "KH", name: "カンボジア", capital: "プノンペン", region: .asia),
        .init(code: "TH", name: "タイ", capital: "バンコク", region: .asia),
        .init(code: "MM", name: "ミャンマー", capital: "ネーピードー", region: .asia),
        .init(code: "MY", name: "マレーシア", capital: "クアラルンプール", region: .asia),
        .init(code: "SG", name: "シンガポール", capital: "シンガポール", region: .asia, note: "都市国家なので、国名と首都が同じ。"),
        .init(code: "ID", name: "インドネシア", capital: "ジャカルタ", region: .asia, note: "首都をヌサンタラへ移す計画が進んでいる。"),
        .init(code: "PH", name: "フィリピン", capital: "マニラ", region: .asia),
        .init(code: "BN", name: "ブルネイ", capital: "バンダルスリブガワン", region: .asia),
        .init(code: "TL", name: "東ティモール", capital: "ディリ", region: .asia),
        .init(code: "IN", name: "インド", capital: "ニューデリー", region: .asia),
        .init(code: "PK", name: "パキスタン", capital: "イスラマバード", region: .asia),
        .init(code: "BD", name: "バングラデシュ", capital: "ダッカ", region: .asia),
        .init(code: "LK", name: "スリランカ", capital: "スリジャヤワルダナプラコッテ", region: .asia),
        .init(code: "NP", name: "ネパール", capital: "カトマンズ", region: .asia),
        .init(code: "BT", name: "ブータン", capital: "ティンプー", region: .asia),
        .init(code: "MV", name: "モルディブ", capital: "マレ", region: .asia),
        .init(code: "AF", name: "アフガニスタン", capital: "カブール", region: .asia),
        .init(code: "KZ", name: "カザフスタン", capital: "アスタナ", region: .asia),
        .init(code: "UZ", name: "ウズベキスタン", capital: "タシケント", region: .asia),
        .init(code: "TM", name: "トルクメニスタン", capital: "アシガバット", region: .asia),
        .init(code: "KG", name: "キルギス", capital: "ビシュケク", region: .asia),
        .init(code: "TJ", name: "タジキスタン", capital: "ドゥシャンベ", region: .asia),

        // 中東
        .init(code: "TR", name: "トルコ", capital: "アンカラ", region: .middleEast),
        .init(code: "IR", name: "イラン", capital: "テヘラン", region: .middleEast),
        .init(code: "IQ", name: "イラク", capital: "バグダッド", region: .middleEast),
        .init(code: "SA", name: "サウジアラビア", capital: "リヤド", region: .middleEast),
        .init(code: "AE", name: "アラブ首長国連邦", capital: "アブダビ", region: .middleEast),
        .init(code: "QA", name: "カタール", capital: "ドーハ", region: .middleEast),
        .init(code: "KW", name: "クウェート", capital: "クウェート", region: .middleEast, note: "首都の名前も クウェート（クウェート市）。"),
        .init(code: "BH", name: "バーレーン", capital: "マナーマ", region: .middleEast),
        .init(code: "OM", name: "オマーン", capital: "マスカット", region: .middleEast),
        .init(code: "YE", name: "イエメン", capital: "サヌア", region: .middleEast),
        .init(code: "JO", name: "ヨルダン", capital: "アンマン", region: .middleEast),
        .init(code: "SY", name: "シリア", capital: "ダマスカス", region: .middleEast),
        .init(code: "LB", name: "レバノン", capital: "ベイルート", region: .middleEast),
        .init(code: "IL", name: "イスラエル", capital: "エルサレム", region: .middleEast, note: "イスラエルは首都をエルサレムとしているが、日本を含め国際的には認められていない。"),

        // ヨーロッパ
        .init(code: "GB", name: "イギリス", capital: "ロンドン", region: .europe),
        .init(code: "IE", name: "アイルランド", capital: "ダブリン", region: .europe),
        .init(code: "FR", name: "フランス", capital: "パリ", region: .europe),
        .init(code: "DE", name: "ドイツ", capital: "ベルリン", region: .europe),
        .init(code: "IT", name: "イタリア", capital: "ローマ", region: .europe),
        .init(code: "ES", name: "スペイン", capital: "マドリード", region: .europe),
        .init(code: "PT", name: "ポルトガル", capital: "リスボン", region: .europe),
        .init(code: "NL", name: "オランダ", capital: "アムステルダム", region: .europe, note: "王宮や政府はハーグにある。"),
        .init(code: "BE", name: "ベルギー", capital: "ブリュッセル", region: .europe),
        .init(code: "LU", name: "ルクセンブルク", capital: "ルクセンブルク", region: .europe),
        .init(code: "CH", name: "スイス", capital: "ベルン", region: .europe),
        .init(code: "AT", name: "オーストリア", capital: "ウィーン", region: .europe),
        .init(code: "LI", name: "リヒテンシュタイン", capital: "ファドーツ", region: .europe),
        .init(code: "MC", name: "モナコ", capital: "モナコ", region: .europe),
        .init(code: "AD", name: "アンドラ", capital: "アンドララベリャ", region: .europe),
        .init(code: "SM", name: "サンマリノ", capital: "サンマリノ", region: .europe),
        .init(code: "VA", name: "バチカン", capital: "バチカン", region: .europe, note: "世界でいちばん小さい国。国全体が首都。"),
        .init(code: "MT", name: "マルタ", capital: "バレッタ", region: .europe),
        .init(code: "GR", name: "ギリシャ", capital: "アテネ", region: .europe),
        .init(code: "CY", name: "キプロス", capital: "ニコシア", region: .europe),
        .init(code: "DK", name: "デンマーク", capital: "コペンハーゲン", region: .europe),
        .init(code: "NO", name: "ノルウェー", capital: "オスロ", region: .europe),
        .init(code: "SE", name: "スウェーデン", capital: "ストックホルム", region: .europe),
        .init(code: "FI", name: "フィンランド", capital: "ヘルシンキ", region: .europe),
        .init(code: "IS", name: "アイスランド", capital: "レイキャビク", region: .europe),
        .init(code: "EE", name: "エストニア", capital: "タリン", region: .europe),
        .init(code: "LV", name: "ラトビア", capital: "リガ", region: .europe),
        .init(code: "LT", name: "リトアニア", capital: "ビリニュス", region: .europe),
        .init(code: "PL", name: "ポーランド", capital: "ワルシャワ", region: .europe),
        .init(code: "CZ", name: "チェコ", capital: "プラハ", region: .europe),
        .init(code: "SK", name: "スロバキア", capital: "ブラチスラバ", region: .europe),
        .init(code: "HU", name: "ハンガリー", capital: "ブダペスト", region: .europe),
        .init(code: "RO", name: "ルーマニア", capital: "ブカレスト", region: .europe),
        .init(code: "BG", name: "ブルガリア", capital: "ソフィア", region: .europe),
        .init(code: "SI", name: "スロベニア", capital: "リュブリャナ", region: .europe),
        .init(code: "HR", name: "クロアチア", capital: "ザグレブ", region: .europe),
        .init(code: "BA", name: "ボスニア・ヘルツェゴビナ", capital: "サラエボ", region: .europe),
        .init(code: "RS", name: "セルビア", capital: "ベオグラード", region: .europe),
        .init(code: "ME", name: "モンテネグロ", capital: "ポドゴリツァ", region: .europe),
        .init(code: "MK", name: "北マケドニア", capital: "スコピエ", region: .europe),
        .init(code: "AL", name: "アルバニア", capital: "ティラナ", region: .europe),
        .init(code: "XK", name: "コソボ", capital: "プリシュティナ", region: .europe),
        .init(code: "MD", name: "モルドバ", capital: "キシナウ", region: .europe),
        .init(code: "UA", name: "ウクライナ", capital: "キーウ", region: .europe),
        .init(code: "BY", name: "ベラルーシ", capital: "ミンスク", region: .europe),
        .init(code: "RU", name: "ロシア", capital: "モスクワ", region: .europe),
        .init(code: "GE", name: "ジョージア", capital: "トビリシ", region: .europe),
        .init(code: "AM", name: "アルメニア", capital: "エレバン", region: .europe),
        .init(code: "AZ", name: "アゼルバイジャン", capital: "バクー", region: .europe),

        // アフリカ
        .init(code: "EG", name: "エジプト", capital: "カイロ", region: .africa),
        .init(code: "LY", name: "リビア", capital: "トリポリ", region: .africa),
        .init(code: "TN", name: "チュニジア", capital: "チュニス", region: .africa),
        .init(code: "DZ", name: "アルジェリア", capital: "アルジェ", region: .africa),
        .init(code: "MA", name: "モロッコ", capital: "ラバト", region: .africa),
        .init(code: "SD", name: "スーダン", capital: "ハルツーム", region: .africa),
        .init(code: "SS", name: "南スーダン", capital: "ジュバ", region: .africa),
        .init(code: "ET", name: "エチオピア", capital: "アディスアベバ", region: .africa),
        .init(code: "ER", name: "エリトリア", capital: "アスマラ", region: .africa),
        .init(code: "DJ", name: "ジブチ", capital: "ジブチ", region: .africa),
        .init(code: "SO", name: "ソマリア", capital: "モガディシュ", region: .africa),
        .init(code: "KE", name: "ケニア", capital: "ナイロビ", region: .africa),
        .init(code: "UG", name: "ウガンダ", capital: "カンパラ", region: .africa),
        .init(code: "RW", name: "ルワンダ", capital: "キガリ", region: .africa),
        .init(code: "BI", name: "ブルンジ", capital: "ギテガ", region: .africa),
        .init(code: "TZ", name: "タンザニア", capital: "ドドマ", region: .africa),
        .init(code: "MZ", name: "モザンビーク", capital: "マプト", region: .africa),
        .init(code: "MW", name: "マラウイ", capital: "リロングウェ", region: .africa),
        .init(code: "ZM", name: "ザンビア", capital: "ルサカ", region: .africa),
        .init(code: "ZW", name: "ジンバブエ", capital: "ハラレ", region: .africa),
        .init(code: "BW", name: "ボツワナ", capital: "ハボローネ", region: .africa),
        .init(code: "NA", name: "ナミビア", capital: "ウィントフック", region: .africa),
        .init(code: "ZA", name: "南アフリカ", capital: "プレトリア", region: .africa, note: "国会はケープタウン、最高裁判所はブルームフォンテーンにある。"),
        .init(code: "LS", name: "レソト", capital: "マセル", region: .africa),
        .init(code: "SZ", name: "エスワティニ", capital: "ムババーネ", region: .africa),
        .init(code: "MG", name: "マダガスカル", capital: "アンタナナリボ", region: .africa),
        .init(code: "MU", name: "モーリシャス", capital: "ポートルイス", region: .africa),
        .init(code: "SC", name: "セーシェル", capital: "ビクトリア", region: .africa),
        .init(code: "KM", name: "コモロ", capital: "モロニ", region: .africa),
        .init(code: "AO", name: "アンゴラ", capital: "ルアンダ", region: .africa),
        .init(code: "CD", name: "コンゴ民主共和国", capital: "キンシャサ", region: .africa),
        .init(code: "CG", name: "コンゴ共和国", capital: "ブラザビル", region: .africa),
        .init(code: "GA", name: "ガボン", capital: "リーブルビル", region: .africa),
        .init(code: "GQ", name: "赤道ギニア", capital: "マラボ", region: .africa),
        .init(code: "CM", name: "カメルーン", capital: "ヤウンデ", region: .africa),
        .init(code: "CF", name: "中央アフリカ", capital: "バンギ", region: .africa),
        .init(code: "TD", name: "チャド", capital: "ンジャメナ", region: .africa),
        .init(code: "NE", name: "ニジェール", capital: "ニアメ", region: .africa),
        .init(code: "NG", name: "ナイジェリア", capital: "アブジャ", region: .africa),
        .init(code: "BJ", name: "ベナン", capital: "ポルトノボ", region: .africa),
        .init(code: "TG", name: "トーゴ", capital: "ロメ", region: .africa),
        .init(code: "GH", name: "ガーナ", capital: "アクラ", region: .africa),
        .init(code: "CI", name: "コートジボワール", capital: "ヤムスクロ", region: .africa, note: "政治・経済の中心はアビジャン。"),
        .init(code: "BF", name: "ブルキナファソ", capital: "ワガドゥグ", region: .africa),
        .init(code: "ML", name: "マリ", capital: "バマコ", region: .africa),
        .init(code: "MR", name: "モーリタニア", capital: "ヌアクショット", region: .africa),
        .init(code: "SN", name: "セネガル", capital: "ダカール", region: .africa),
        .init(code: "GM", name: "ガンビア", capital: "バンジュール", region: .africa),
        .init(code: "GW", name: "ギニアビサウ", capital: "ビサウ", region: .africa),
        .init(code: "GN", name: "ギニア", capital: "コナクリ", region: .africa),
        .init(code: "SL", name: "シエラレオネ", capital: "フリータウン", region: .africa),
        .init(code: "LR", name: "リベリア", capital: "モンロビア", region: .africa),
        .init(code: "CV", name: "カーボベルデ", capital: "プライア", region: .africa),
        .init(code: "ST", name: "サントメ・プリンシペ", capital: "サントメ", region: .africa),

        // 北中米
        .init(code: "US", name: "アメリカ", capital: "ワシントンD.C.", region: .northAmerica),
        .init(code: "CA", name: "カナダ", capital: "オタワ", region: .northAmerica),
        .init(code: "MX", name: "メキシコ", capital: "メキシコシティ", region: .northAmerica),
        .init(code: "GT", name: "グアテマラ", capital: "グアテマラシティ", region: .northAmerica),
        .init(code: "BZ", name: "ベリーズ", capital: "ベルモパン", region: .northAmerica),
        .init(code: "SV", name: "エルサルバドル", capital: "サンサルバドル", region: .northAmerica),
        .init(code: "HN", name: "ホンジュラス", capital: "テグシガルパ", region: .northAmerica),
        .init(code: "NI", name: "ニカラグア", capital: "マナグア", region: .northAmerica),
        .init(code: "CR", name: "コスタリカ", capital: "サンホセ", region: .northAmerica),
        .init(code: "PA", name: "パナマ", capital: "パナマシティ", region: .northAmerica),
        .init(code: "CU", name: "キューバ", capital: "ハバナ", region: .northAmerica),
        .init(code: "JM", name: "ジャマイカ", capital: "キングストン", region: .northAmerica),
        .init(code: "HT", name: "ハイチ", capital: "ポルトープランス", region: .northAmerica),
        .init(code: "DO", name: "ドミニカ共和国", capital: "サントドミンゴ", region: .northAmerica),
        .init(code: "BS", name: "バハマ", capital: "ナッソー", region: .northAmerica),
        .init(code: "BB", name: "バルバドス", capital: "ブリッジタウン", region: .northAmerica),
        .init(code: "TT", name: "トリニダード・トバゴ", capital: "ポートオブスペイン", region: .northAmerica),
        .init(code: "DM", name: "ドミニカ国", capital: "ロゾー", region: .northAmerica),
        .init(code: "LC", name: "セントルシア", capital: "カストリーズ", region: .northAmerica),
        .init(code: "VC", name: "セントビンセント及びグレナディーン諸島", capital: "キングスタウン", region: .northAmerica),
        .init(code: "GD", name: "グレナダ", capital: "セントジョージズ", region: .northAmerica),
        .init(code: "AG", name: "アンティグア・バーブーダ", capital: "セントジョンズ", region: .northAmerica),
        .init(code: "KN", name: "セントクリストファー・ネービス", capital: "バセテール", region: .northAmerica),

        // 南米
        .init(code: "BR", name: "ブラジル", capital: "ブラジリア", region: .southAmerica),
        .init(code: "AR", name: "アルゼンチン", capital: "ブエノスアイレス", region: .southAmerica),
        .init(code: "CL", name: "チリ", capital: "サンティアゴ", region: .southAmerica),
        .init(code: "PE", name: "ペルー", capital: "リマ", region: .southAmerica),
        .init(code: "CO", name: "コロンビア", capital: "ボゴタ", region: .southAmerica),
        .init(code: "VE", name: "ベネズエラ", capital: "カラカス", region: .southAmerica),
        .init(code: "EC", name: "エクアドル", capital: "キト", region: .southAmerica),
        .init(code: "BO", name: "ボリビア", capital: "スクレ", region: .southAmerica, note: "憲法上の首都はスクレ。政府や国会はラパスにある。"),
        .init(code: "PY", name: "パラグアイ", capital: "アスンシオン", region: .southAmerica),
        .init(code: "UY", name: "ウルグアイ", capital: "モンテビデオ", region: .southAmerica),
        .init(code: "GY", name: "ガイアナ", capital: "ジョージタウン", region: .southAmerica),
        .init(code: "SR", name: "スリナム", capital: "パラマリボ", region: .southAmerica),

        // オセアニア
        .init(code: "AU", name: "オーストラリア", capital: "キャンベラ", region: .oceania),
        .init(code: "NZ", name: "ニュージーランド", capital: "ウェリントン", region: .oceania),
        .init(code: "PG", name: "パプアニューギニア", capital: "ポートモレスビー", region: .oceania),
        .init(code: "FJ", name: "フィジー", capital: "スバ", region: .oceania),
        .init(code: "SB", name: "ソロモン諸島", capital: "ホニアラ", region: .oceania),
        .init(code: "VU", name: "バヌアツ", capital: "ポートビラ", region: .oceania),
        .init(code: "WS", name: "サモア", capital: "アピア", region: .oceania),
        .init(code: "TO", name: "トンガ", capital: "ヌクアロファ", region: .oceania),
        .init(code: "KI", name: "キリバス", capital: "タラワ", region: .oceania),
        .init(code: "TV", name: "ツバル", capital: "フナフティ", region: .oceania),
        .init(code: "NR", name: "ナウル", capital: "ヤレン", region: .oceania, note: "法律で決まった首都はなく、政府はヤレン地区にある。"),
        .init(code: "PW", name: "パラオ", capital: "マルキョク", region: .oceania),
        .init(code: "FM", name: "ミクロネシア連邦", capital: "パリキール", region: .oceania),
        .init(code: "MH", name: "マーシャル諸島", capital: "マジュロ", region: .oceania),
        .init(code: "CK", name: "クック諸島", capital: "アバルア", region: .oceania),
        .init(code: "NU", name: "ニウエ", capital: "アロフィ", region: .oceania),
    ]

    /// 国旗がほとんど同じで、絵文字では見分けにくい組み合わせ。国旗の選択肢に同時に出さない。
    static let lookalikes: [Set<String>] = [
        ["TD", "RO"],
        ["ID", "MC"],
    ]
}
