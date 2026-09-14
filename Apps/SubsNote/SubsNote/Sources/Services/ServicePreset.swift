import Foundation

/// よくある料金プランの候補。
struct PresetPlan: Hashable, Sendable {
    var label: String
    var price: Int
    var cycle: BillingCycle
    var interval: Int = 1
}

/// 国内でよく使われるサービスのプリセット。選ぶと名前・カテゴリ・料金プランの候補・支払い方法が入る。
///
/// - **料金は候補として出すだけ**。保存前に必ず入力欄で見せる（値上げで古くなるため）。
///   値が怪しいものは候補を持たせず（`plans` を空にして）、ユーザーに入れてもらう。
/// - ロゴは使わない（商標）。一覧では頭文字とカテゴリ色の丸アイコンで表す。
/// - 解約手順はサービスごとに持たず、支払い方法ごとの一般的な手順（`PaymentMethod.cancelGuide`）を使う。
///
/// 料金の最終確認: 2026-09-14。出典と確度は `Docs/PresetPrices.md`。アップデートのたびに見直し、両方の日付を更新する。
/// 支払い方法で料金が違うものは、Web 申込の料金を先に、アプリ内課金をラベル付きで併記する。
struct ServicePreset: Identifiable, Hashable, Sendable {
    var key: String
    var name: String
    /// 検索用の読みがな（ひらがな）。英字のサービス名をかなで探せるようにする。
    var kana: String
    var category: SubCategory
    var plans: [PresetPlan] = []
    /// よくある支払い方法。nil ならクレジットカード。
    var payment: PaymentMethod?

    var id: String { key }

    static func find(key: String) -> ServicePreset? {
        all.first { $0.key == key }
    }

    /// 名前か読みがなに、スペース区切りの語が**すべて**含まれるもの。ひらがな・カタカナ・全角半角・大文字小文字を区別しない。
    static func search(_ query: String, in presets: [ServicePreset] = all) -> [ServicePreset] {
        let tokens = normalize(query).split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else { return presets }
        return presets.filter { preset in
            let haystack = normalize(preset.name) + " " + normalize(preset.kana)
            return tokens.allSatisfy { haystack.contains($0) }
        }
    }

    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
        // カタカナをひらがなにそろえる（長音「ー」はそのまま残る）。
        return folded.applyingTransform(.hiraganaToKatakana, reverse: true) ?? folded
    }

    /// 空の状態で出す、よく使われるサービス。
    static let popular: [ServicePreset] = ["netflix", "amazonPrime", "youtubePremium", "spotify", "appleMusic", "icloud"]
        .compactMap { key in all.first { $0.key == key } }

    // MARK: - 一覧

    static let all: [ServicePreset] = [
        // 動画
        ServicePreset(key: "netflix", name: "Netflix", kana: "ねっとふりっくす", category: .video, plans: [
            PresetPlan(label: "広告つきスタンダード", price: 890, cycle: .month),
            PresetPlan(label: "スタンダード", price: 1590, cycle: .month),
            PresetPlan(label: "プレミアム", price: 2290, cycle: .month),
        ]),
        // 公式ページで確認できず、2023-08 改定の値のまま（Docs/PresetPrices.md）。
        ServicePreset(key: "amazonPrime", name: "Amazon プライム", kana: "あまぞんぷらいむ", category: .video, plans: [
            PresetPlan(label: "月間プラン", price: 600, cycle: .month),
            PresetPlan(label: "年間プラン", price: 5900, cycle: .year),
        ], payment: .amazon),
        ServicePreset(key: "unext", name: "U-NEXT", kana: "ゆーねくすと", category: .video, plans: [
            PresetPlan(label: "月額プラン", price: 2189, cycle: .month),
            PresetPlan(label: "アプリ内課金", price: 2400, cycle: .month),
        ]),
        ServicePreset(key: "disneyPlus", name: "Disney+", kana: "でぃずにーぷらす", category: .video, plans: [
            PresetPlan(label: "スタンダード", price: 1250, cycle: .month),
            PresetPlan(label: "プレミアム", price: 1670, cycle: .month),
            PresetPlan(label: "スタンダード（年額）", price: 12500, cycle: .year),
            PresetPlan(label: "プレミアム（年額）", price: 16700, cycle: .year),
        ]),
        ServicePreset(key: "hulu", name: "Hulu", kana: "ふーる", category: .video, plans: [
            PresetPlan(label: "月額", price: 1320, cycle: .month),
            PresetPlan(label: "アプリ内課金", price: 1450, cycle: .month),
        ]),
        ServicePreset(key: "dazn", name: "DAZN", kana: "だぞーん", category: .video, plans: [
            PresetPlan(label: "Standard 月間", price: 4200, cycle: .month),
            PresetPlan(label: "Standard 年間（月々払い）", price: 3200, cycle: .month),
            PresetPlan(label: "Standard 年間（一括）", price: 32000, cycle: .year),
        ]),
        ServicePreset(key: "abema", name: "ABEMA プレミアム", kana: "あべま", category: .video, plans: [
            PresetPlan(label: "広告つき", price: 680, cycle: .month),
            PresetPlan(label: "プレミアム", price: 1180, cycle: .month),
        ]),
        ServicePreset(key: "youtubePremium", name: "YouTube Premium", kana: "ゆーちゅーぶぷれみあむ", category: .video, plans: [
            PresetPlan(label: "個人", price: 1280, cycle: .month),
            PresetPlan(label: "ファミリー", price: 2280, cycle: .month),
            PresetPlan(label: "学生", price: 780, cycle: .month),
        ]),
        ServicePreset(key: "lemino", name: "Lemino プレミアム", kana: "れみの", category: .video, plans: [
            PresetPlan(label: "月額", price: 1540, cycle: .month),
            PresetPlan(label: "App Store・Google Play", price: 1650, cycle: .month),
        ], payment: .carrier),
        ServicePreset(key: "dAnime", name: "dアニメストア", kana: "でぃーあにめすとあ", category: .video, plans: [
            PresetPlan(label: "月額", price: 660, cycle: .month),
            PresetPlan(label: "App Store・Google Play", price: 760, cycle: .month),
        ], payment: .carrier),
        ServicePreset(key: "fod", name: "FOD プレミアム", kana: "えふおーでぃー ふじてれび", category: .video, plans: [
            PresetPlan(label: "スタンダード", price: 1320, cycle: .month),
            PresetPlan(label: "広告付きライト", price: 976, cycle: .month),
            PresetPlan(label: "ポイントMAX", price: 2090, cycle: .month),
        ]),
        ServicePreset(key: "telasa", name: "TELASA", kana: "てらさ", category: .video, plans: [
            PresetPlan(label: "見放題プラン", price: 990, cycle: .month),
        ]),
        ServicePreset(key: "appleTV", name: "Apple TV", kana: "あっぷるてぃーびー", category: .video, plans: [
            PresetPlan(label: "月額", price: 1200, cycle: .month),
        ], payment: .appStore),
        ServicePreset(key: "wowow", name: "WOWOW オンデマンド", kana: "わうわう", category: .video, plans: [
            PresetPlan(label: "月額", price: 2530, cycle: .month),
        ]),
        ServicePreset(key: "niconico", name: "ニコニコプレミアム", kana: "にこにこ", category: .video, plans: [
            PresetPlan(label: "月額", price: 990, cycle: .month),
        ]),

        // 音楽
        ServicePreset(key: "spotify", name: "Spotify Premium", kana: "すぽてぃふぁい", category: .music, plans: [
            PresetPlan(label: "Standard", price: 1080, cycle: .month),
            PresetPlan(label: "Duo", price: 1480, cycle: .month),
            PresetPlan(label: "Family", price: 1880, cycle: .month),
            PresetPlan(label: "Student", price: 580, cycle: .month),
        ]),
        ServicePreset(key: "appleMusic", name: "Apple Music", kana: "あっぷるみゅーじっく", category: .music, plans: [
            PresetPlan(label: "個人", price: 1180, cycle: .month),
            PresetPlan(label: "ファミリー", price: 1980, cycle: .month),
            PresetPlan(label: "学生", price: 680, cycle: .month),
        ], payment: .appStore),
        ServicePreset(key: "amazonMusic", name: "Amazon Music Unlimited", kana: "あまぞんみゅーじっくあんりみてっど", category: .music, plans: [
            PresetPlan(label: "個人（プライム会員）", price: 1080, cycle: .month),
            PresetPlan(label: "個人（プライム会員以外）", price: 1180, cycle: .month),
            PresetPlan(label: "個人（プライム会員・年額）", price: 10800, cycle: .year),
            PresetPlan(label: "ファミリー", price: 1980, cycle: .month),
        ], payment: .amazon),
        ServicePreset(key: "youtubeMusic", name: "YouTube Music Premium", kana: "ゆーちゅーぶみゅーじっく", category: .music, plans: [
            PresetPlan(label: "個人", price: 1080, cycle: .month),
        ]),
        ServicePreset(key: "lineMusic", name: "LINE MUSIC", kana: "らいんみゅーじっく", category: .music, plans: [
            PresetPlan(label: "一般（LINE STORE）", price: 980, cycle: .month),
            PresetPlan(label: "一般（アプリ内課金）", price: 1080, cycle: .month),
        ]),
        ServicePreset(key: "awa", name: "AWA", kana: "あわ", category: .music, plans: [
            PresetPlan(label: "Standard", price: 980, cycle: .month),
        ]),

        // ゲーム
        ServicePreset(key: "switchOnline", name: "Nintendo Switch Online", kana: "にんてんどーすいっちおんらいん", category: .game, plans: [
            PresetPlan(label: "個人 12か月", price: 3000, cycle: .year),
            PresetPlan(label: "個人 3か月", price: 1000, cycle: .month, interval: 3),
            PresetPlan(label: "個人 1か月", price: 400, cycle: .month),
            PresetPlan(label: "個人＋追加パック 12か月", price: 5900, cycle: .year),
        ]),
        ServicePreset(key: "psPlus", name: "PlayStation Plus", kana: "ぷれいすてーしょんぷらす ぷれすて", category: .game, plans: [
            PresetPlan(label: "エッセンシャル 1ヶ月", price: 850, cycle: .month),
            PresetPlan(label: "エッセンシャル 12ヶ月", price: 6800, cycle: .year),
            PresetPlan(label: "エクストラ 1ヶ月", price: 1300, cycle: .month),
            PresetPlan(label: "エクストラ 12ヶ月", price: 11700, cycle: .year),
            PresetPlan(label: "プレミアム 1ヶ月", price: 1550, cycle: .month),
            PresetPlan(label: "プレミアム 12ヶ月", price: 13900, cycle: .year),
        ]),
        ServicePreset(key: "gamePass", name: "Xbox Game Pass", kana: "えっくすぼっくすげーむぱす", category: .game, plans: [
            PresetPlan(label: "Ultimate", price: 1550, cycle: .month),
            PresetPlan(label: "PC Game Pass", price: 1300, cycle: .month),
        ]),
        ServicePreset(key: "appleArcade", name: "Apple Arcade", kana: "あっぷるあーけーど", category: .game, plans: [
            PresetPlan(label: "月額", price: 900, cycle: .month),
        ], payment: .appStore),

        // ニュース・書籍
        ServicePreset(key: "nikkei", name: "日経電子版", kana: "にっけいでんしばん", category: .reading, plans: [
            PresetPlan(label: "月額", price: 4277, cycle: .month),
        ]),
        ServicePreset(key: "asahi", name: "朝日新聞デジタル", kana: "あさひしんぶんでじたる", category: .reading, plans: [
            PresetPlan(label: "スタンダード", price: 1980, cycle: .month),
        ]),
        ServicePreset(key: "kindleUnlimited", name: "Kindle Unlimited", kana: "きんどるあんりみてっど", category: .reading, plans: [
            PresetPlan(label: "月額", price: 980, cycle: .month),
        ], payment: .amazon),
        ServicePreset(key: "audible", name: "Audible", kana: "おーでぃぶる", category: .reading, plans: [
            PresetPlan(label: "月額", price: 1500, cycle: .month),
        ], payment: .amazon),
        ServicePreset(key: "rakutenMagazine", name: "楽天マガジン", kana: "らくてんまがじん", category: .reading, plans: [
            PresetPlan(label: "月額", price: 597, cycle: .month),
            PresetPlan(label: "年額", price: 5980, cycle: .year),
            PresetPlan(label: "アプリ内課金", price: 710, cycle: .month),
        ]),
        ServicePreset(key: "dMagazine", name: "dマガジン", kana: "でぃーまがじん", category: .reading, plans: [
            PresetPlan(label: "月額", price: 580, cycle: .month),
        ], payment: .carrier),

        // クラウド・ソフト
        ServicePreset(key: "icloud", name: "iCloud+", kana: "あいくらうどぷらす", category: .cloud, plans: [
            PresetPlan(label: "50GB", price: 180, cycle: .month),
            PresetPlan(label: "200GB", price: 540, cycle: .month),
            PresetPlan(label: "2TB", price: 1800, cycle: .month),
        ], payment: .appStore),
        ServicePreset(key: "googleOne", name: "Google One", kana: "ぐーぐるわん", category: .cloud, plans: [
            PresetPlan(label: "Basic 100GB", price: 290, cycle: .month),
            PresetPlan(label: "Google AI Plus 2TB", price: 1450, cycle: .month),
        ]),
        ServicePreset(key: "microsoft365", name: "Microsoft 365", kana: "まいくろそふとさんろくご おふぃす", category: .cloud, plans: [
            PresetPlan(label: "Personal（年額）", price: 21300, cycle: .year),
            PresetPlan(label: "Personal（月額）", price: 2130, cycle: .month),
            PresetPlan(label: "Family（年額）", price: 27400, cycle: .year),
            PresetPlan(label: "Family（月額）", price: 2740, cycle: .month),
        ]),
        ServicePreset(key: "adobe", name: "Adobe Creative Cloud", kana: "あどびくりえいてぃぶくらうど ふぉとしょっぷ らいとるーむ", category: .cloud, plans: [
            PresetPlan(label: "フォトプラン 1TB（年間・月々払い）", price: 2380, cycle: .month),
            PresetPlan(label: "Lightroom 1TB（年間・月々払い）", price: 1480, cycle: .month),
            PresetPlan(label: "Creative Cloud Pro（年間・月々払い）", price: 9080, cycle: .month),
        ]),
        ServicePreset(key: "dropbox", name: "Dropbox", kana: "どろっぷぼっくす", category: .cloud, plans: [
            PresetPlan(label: "Plus（年額）", price: 14400, cycle: .year),
            PresetPlan(label: "Plus（月額）", price: 1500, cycle: .month),
        ]),
        ServicePreset(key: "canva", name: "Canva Pro", kana: "きゃんば", category: .cloud, plans: [
            PresetPlan(label: "年額", price: 11800, cycle: .year),
        ]),
        ServicePreset(key: "appleOne", name: "Apple One", kana: "あっぷるわん", category: .cloud, plans: [
            PresetPlan(label: "個人", price: 1350, cycle: .month),
            PresetPlan(label: "ファミリー", price: 2500, cycle: .month),
        ], payment: .appStore),

        // AI
        ServicePreset(key: "chatgpt", name: "ChatGPT Plus", kana: "ちゃっとじーぴーてぃー", category: .ai, plans: [
            PresetPlan(label: "Plus（App Store）", price: 3000, cycle: .month),
        ]),
        // 米ドル建てで円の固定価格が無いため、候補を持たせない。
        ServicePreset(key: "claude", name: "Claude Pro", kana: "くろーど", category: .ai),
        ServicePreset(key: "gemini", name: "Google AI Pro（Gemini）", kana: "じぇみに ぐーぐるえーあい", category: .ai, plans: [
            PresetPlan(label: "月額", price: 2900, cycle: .month),
        ]),
        // Copilot Pro 単体は販売終了。後継の Microsoft 365 Premium を「こぱいろっと」でも探せるようにする。
        ServicePreset(key: "m365Premium", name: "Microsoft 365 Premium（Copilot）", kana: "こぱいろっと まいくろそふと", category: .ai, plans: [
            PresetPlan(label: "月額", price: 3200, cycle: .month),
            PresetPlan(label: "年額", price: 32000, cycle: .year),
        ]),

        // フィットネス
        ServicePreset(key: "chocozap", name: "chocoZAP", kana: "ちょこざっぷ", category: .fitness, plans: [
            PresetPlan(label: "月額", price: 3278, cycle: .month),
        ]),
        ServicePreset(key: "anytime", name: "エニタイムフィットネス", kana: "えにたいむふぃっとねす", category: .fitness),
        ServicePreset(key: "asken", name: "あすけん プレミアム", kana: "あすけん", category: .fitness, plans: [
            PresetPlan(label: "月額（Web）", price: 580, cycle: .month),
        ]),

        // 通信
        ServicePreset(key: "lyp", name: "LYPプレミアム", kana: "えるわいぴー やふー らいん すたんぷ", category: .telecom, plans: [
            PresetPlan(label: "スタンダード（Web）", price: 508, cycle: .month),
            PresetPlan(label: "スタンダード（アプリ内課金）", price: 650, cycle: .month),
            PresetPlan(label: "ライトプラン", price: 290, cycle: .month),
        ]),
        ServicePreset(key: "carrierOption", name: "スマホのオプションサービス", kana: "きゃりあ おぷしょん ほしょう", category: .telecom, payment: .carrier),

        // 生活・その他
        ServicePreset(key: "uberOne", name: "Uber One", kana: "うーばーわん", category: .life, plans: [
            PresetPlan(label: "月額", price: 698, cycle: .month),
            PresetPlan(label: "年額", price: 5598, cycle: .year),
        ]),
        ServicePreset(key: "costco", name: "コストコ 年会費", kana: "こすとこ", category: .life, plans: [
            PresetPlan(label: "ゴールドスター", price: 5280, cycle: .year),
        ]),
        ServicePreset(key: "pixiv", name: "pixivプレミアム", kana: "ぴくしぶ", category: .life, plans: [
            PresetPlan(label: "1ヶ月（App Store）", price: 600, cycle: .month),
        ]),
    ]
}
