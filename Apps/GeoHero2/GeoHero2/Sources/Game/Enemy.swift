import Foundation

/// 東北に出る敵。県ごとに その土地の 名物・名所・生きものを 題材にする。
/// 旅の順に 24か所（＋クリア後の 恐山）あり、場所ごとに 3種ずつ 出る（`Balance.places`）。
enum EnemyKind: String, Codable, CaseIterable, CodingKeyRepresentable {
    // ── 青森 ──
    case ringoSlime, hotate, umineko
    case hachinoheIka, neputaGhost, ninnikun
    case himemasu, oiraseMoss, otomeStatue
    case sukayuSlime, kamoshika, yukinko
    // ── 秋田 ──
    case kiritanpoSoldier, hatahata, komachiRice
    case shidarezakura, kantoLantern, inaniwaUdon
    case kunimasu, ruriSlime, tamagawaAcid
    case konamahage, kanpuWind, shottsuru
    // ── 岩手 ──
    case wankoBowl, nanbuKettle, reimenSlime
    case tonoKappa, konjikiBeetle, chagchagUmako
    case dragonBlueSlime, stalactite, kikugashira
    case lavaFlow, komakusa, nanbuKatafuji
    // ── 宮城 ──
    case gyutanSoldier, zundaSlime, sasakama
    case kokeshiGhost, hoya, fukinagashi
    case oysterSoldier, pineSpirit, anago
    case mikazukiHelm, aobazuku, hirosegawaSpirit
    // ── 福島 ──
    case momoSpirit, warajiSoldier, ufo
    case kuraGhost, urushiSlime, kozuyu
    case limestoneGolem, takineBat, groundwater
    case goshikiSlime, inawashiroSpirit, bandaiBomb
    // ── 山形 ──
    case sakuranboTwins, imoniPot, benibanaSpirit
    case shogiPiece, mogamiSpirit, laFrance
    case shizukaCicada, stoneSteps, gankutsuSpirit
    case snowMonster, okamaSlime, zaoFox
    // ── 恐山（クリア後）──
    case pinwheelGhost, sulfurGas, osoreCrow
    // ── ボス ──
    /// 十和田湖の りゅう。青森の 中ボス。
    case hachirotaro
    /// 八甲田山の ぬし。ねぶたの 火を うばった。
    case yukioni
    /// 田沢湖の りゅう。秋田の 中ボス。
    case tatsuko
    /// 男鹿 真山の ぬし。竿燈の あかりを うばった。
    case namahageKing
    /// 龍泉洞の 地底湖の ぬし。岩手の 中ボス。
    case ryusendoLord
    /// 岩手山の ぬし。三ツ石の 鬼。
    case mitsuishiOni
    /// 松島の 島の ほらあなの ぬし。宮城の 中ボス。
    case giantOyster
    /// 青葉山の ぬし。あやつられた 独眼竜の よろい。
    case datemaru
    /// あぶくま洞の ぬし。福島の 中ボス。
    case abukumaLord
    /// 磐梯山の ぬし。
    case tenagaAshinaga
    /// 山寺の 大ぜみ。山形の 中ボス。
    case yamaderaCicada
    /// 蔵王の お釜の 東北の 守護神。ラスボス。
    case guardian
    /// 恐山の おくに ひそむ まおうの かげ。クリア後の 裏ボス。
    case maouShadow

    struct Stats: Equatable {
        let name: String
        let maxHP: Int
        let attack: Int
        let defense: Int
        let agility: Int
        let exp: Int
        let gold: Int
    }

    var stats: Stats { Balance.stats[self]! }

    var name: String {
        switch self {
        case .ringoSlime: "りんごスライム"
        case .hotate: "ホタテガイ"
        case .umineko: "うみねこ"
        case .hachinoheIka: "八戸イカ"
        case .neputaGhost: "ねぷたおばけ"
        case .ninnikun: "にんにくん"
        case .himemasu: "ヒメマス"
        case .oiraseMoss: "奥入瀬ゴケ"
        case .otomeStatue: "おとめぞう"
        case .sukayuSlime: "すかゆスライム"
        case .kamoshika: "カモシカ"
        case .yukinko: "ゆきんこ"
        case .kiritanpoSoldier: "きりたんぽへい"
        case .hatahata: "ハタハタ"
        case .komachiRice: "こまちいなほ"
        case .shidarezakura: "しだれざくら"
        case .kantoLantern: "かんとうちょうちん"
        case .inaniwaUdon: "いなにわうどん"
        case .kunimasu: "クニマス"
        case .ruriSlime: "るりいろスライム"
        case .tamagawaAcid: "さんせいスライム"
        case .konamahage: "こなまはげ"
        case .kanpuWind: "かんぷうのかぜ"
        case .shottsuru: "しょっつる"
        case .wankoBowl: "わんこおわん"
        case .nanbuKettle: "なんぶてつびん"
        case .reimenSlime: "れいめんスライム"
        case .tonoKappa: "遠野かっぱ"
        case .konjikiBeetle: "こんじきコガネ"
        case .chagchagUmako: "チャグチャグうまこ"
        case .dragonBlueSlime: "ちていこスライム"
        case .stalactite: "しょうにゅうせき"
        case .kikugashira: "キクガシラ"
        case .lavaFlow: "やけはしり"
        case .komakusa: "コマクサ"
        case .nanbuKatafuji: "なんぶかたふじ"
        case .gyutanSoldier: "ぎゅうたんへい"
        case .zundaSlime: "ずんだスライム"
        case .sasakama: "ささかま"
        case .kokeshiGhost: "こけしおばけ"
        case .hoya: "ホヤ"
        case .fukinagashi: "ふきながし"
        case .oysterSoldier: "カキへい"
        case .pineSpirit: "まつのせい"
        case .anago: "あなご"
        case .mikazukiHelm: "みかづきかぶと"
        case .aobazuku: "アオバズク"
        case .hirosegawaSpirit: "ひろせがわのせい"
        case .momoSpirit: "もものせい"
        case .warajiSoldier: "わらじへい"
        case .ufo: "ユーフォー"
        case .kuraGhost: "くらおばけ"
        case .urushiSlime: "うるしスライム"
        case .kozuyu: "こづゆ"
        case .limestoneGolem: "せっかいゴーレム"
        case .takineBat: "たきねコウモリ"
        case .groundwater: "ちかすいスライム"
        case .goshikiSlime: "ごしきぬま"
        case .inawashiroSpirit: "いなわしろのせい"
        case .bandaiBomb: "ふんえんだま"
        case .sakuranboTwins: "さくらんぼズ"
        case .imoniPot: "いもになべ"
        case .benibanaSpirit: "べにばなのせい"
        case .shogiPiece: "しょうぎごま"
        case .mogamiSpirit: "もがみがわのせい"
        case .laFrance: "ラ・フランス"
        case .shizukaCicada: "しずかぜみ"
        case .stoneSteps: "いしだんゴーレム"
        case .gankutsuSpirit: "がんくつのせい"
        case .snowMonster: "スノーモンスター"
        case .okamaSlime: "おかまスライム"
        case .zaoFox: "ざおうギツネ"
        case .pinwheelGhost: "かざぐるま"
        case .sulfurGas: "いおうガス"
        case .osoreCrow: "おそれカラス"
        case .hachirotaro: "八郎太郎"
        case .yukioni: "八甲田の ゆきおに"
        case .tatsuko: "たつこ"
        case .namahageKing: "なまはげ大王"
        case .ryusendoLord: "ドラゴンブルー"
        case .mitsuishiOni: "三ツ石の 鬼"
        case .giantOyster: "大がきの ぬし"
        case .datemaru: "独眼竜の よろい"
        case .abukumaLord: "石筍の ぬし"
        case .tenagaAshinaga: "手長足長"
        case .yamaderaCicada: "山寺の 大ぜみ"
        case .guardian: "東北の 守護神"
        case .maouShadow: "まおうの かげ"
        }
    }

    /// ボスは 話しかけて始まる戦闘。群れず、逃げられない。
    var isBoss: Bool { Balance.bosses[self] != nil }

    /// 最後の相手。倒すと物語が終わる。
    var isFinalBoss: Bool { self == .guardian }

    /// クリア後の 裏ボス。
    var isSecretBoss: Bool { self == .maouShadow }

    /// その県の ぬしなら その県（倒すと まつりが もどる）。
    var lordOf: Region? { Region.allCases.first { $0.lord == self } }

    /// どの県の 敵か（まもの ずかんの 見出しに 使う）。恐山は 青森。
    var region: Region {
        let place = Balance.place(of: self)
        return Region.allCases[min(5, max(0, (place - 1) / 4))]
    }

    /// まもの ずかんの ひとこと。その土地の ことを ひとつ おしえる。
    var lore: String {
        switch self {
        case .ringoSlime: "青森県は りんごの 生産量 日本一。"
        case .hotate: "陸奥湾では ホタテの 養殖が さかん。"
        case .umineko: "八戸の 蕪島は うみねこの はんしょく地。"
        case .hachinoheIka: "八戸港は イカの 水あげが 日本有数。"
        case .neputaGhost: "弘前では『ねぷた』、青森では『ねぶた』と よぶ。"
        case .ninnikun: "青森県は にんにくの 生産量も 日本一。"
        case .himemasu: "十和田湖では ヒメマスが そだてられている。"
        case .oiraseMoss: "奥入瀬渓流は コケと 滝の 名所。"
        case .otomeStatue: "十和田湖の ほとりには『乙女の像』が たつ。"
        case .sukayuSlime: "八甲田の 酸ヶ湯温泉は『千人風呂』で しられる。"
        case .kamoshika: "ニホンカモシカは 国の 特別天然記念物。"
        case .yukinko: "八甲田は 世界でも めずらしい 豪雪地帯。"
        case .kiritanpoSoldier: "きりたんぽは つぶした ごはんを 杉の くしに まいて やく。"
        case .hatahata: "ハタハタは 秋田県の さかな。"
        case .komachiRice: "秋田の お米『あきたこまち』は 小野小町に ちなむ。"
        case .shidarezakura: "角館の しだれざくらは 武家屋敷を いろどる。"
        case .kantoLantern: "竿燈は 稲穂に みたてた ちょうちんの まつり。"
        case .inaniwaUdon: "稲庭うどんは 秋田の 名物の ほそい うどん。"
        case .kunimasu: "クニマスは むかし 田沢湖だけに いた さかな。"
        case .ruriSlime: "田沢湖は 日本一 ふかい 湖（423m）。"
        case .tamagawaAcid: "玉川温泉の 強い 酸の 湯が 田沢湖に ながれこんだ。"
        case .konamahage: "なまはげは 大みそかの 夜に 家を まわる 男鹿の 行事。"
        case .kanpuWind: "男鹿の 寒風山からは 八郎潟が 見わたせる。"
        case .shottsuru: "しょっつるは ハタハタで つくる 秋田の 魚しょうゆ。"
        case .wankoBowl: "わんこそばは 小さな おわんで つぎつぎ たべる。"
        case .nanbuKettle: "南部鉄器は 盛岡と 奥州の 伝統工芸。"
        case .reimenSlime: "盛岡冷麺は『盛岡三大麺』の ひとつ。"
        case .tonoKappa: "遠野の カッパ淵には かっぱが すむと いう。"
        case .konjikiBeetle: "中尊寺金色堂は 金箔で おおわれている。"
        case .chagchagUmako: "チャグチャグ馬コは 鈴を つけた 馬が あるく まつり。"
        case .dragonBlueSlime: "龍泉洞の 地底湖の 青さは『ドラゴンブルー』。"
        case .stalactite: "龍泉洞は 日本三大鍾乳洞の ひとつ。"
        case .kikugashira: "龍泉洞の コウモリは 国の 天然記念物。"
        case .lavaFlow: "岩手山の『焼走り溶岩流』は 特別天然記念物。"
        case .komakusa: "岩手山には 高山植物の コマクサが さく。"
        case .nanbuKatafuji: "岩手山は『南部片富士』とも よばれる。"
        case .gyutanSoldier: "仙台の 牛たん焼きは 戦後に うまれた 名物。"
        case .zundaSlime: "ずんだは えだまめを つぶして つくる あん。"
        case .sasakama: "笹かまぼこは 笹の 葉の かたちの かまぼこ。"
        case .kokeshiGhost: "鳴子こけしは 首を まわすと キュッと なる。"
        case .hoya: "宮城県は ホヤの 養殖が さかん。"
        case .fukinagashi: "仙台七夕の かざりは『七つ飾り』と いう。"
        case .oysterSoldier: "松島湾は カキの 養殖で 有名。"
        case .pineSpirit: "松島は 日本三景の ひとつ。"
        case .anago: "松島では あなご丼も 名物。"
        case .mikazukiHelm: "伊達政宗の かぶとには 三日月の かざりが ある。"
        case .aobazuku: "仙台は『杜の都』と よばれる みどりの 街。"
        case .hirosegawaSpirit: "広瀬川は 仙台の まちを ながれる 川。"
        case .momoSpirit: "福島市は ももの 産地として 有名。"
        case .warajiSoldier: "福島わらじまつりでは 大きな わらじを かつぐ。"
        case .ufo: "福島市の 飯野町は『UFOの里』と よばれる。"
        case .kuraGhost: "喜多方は 蔵の まちとしても しられる。"
        case .urushiSlime: "会津塗は 会津の 伝統の 漆器。"
        case .kozuyu: "こづゆは 会津の おいわいの すいもの。"
        case .limestoneGolem: "あぶくま洞は 石灰岩を ほる 山の 中で 見つかった。"
        case .takineBat: "あぶくま洞は 田村市の 滝根町に ある。"
        case .groundwater: "鍾乳洞は 雨水が 石灰岩を とかして できる。"
        case .goshikiSlime: "五色沼は 磐梯山の 噴火で できた 沼の あつまり。"
        case .inawashiroSpirit: "猪苗代湖は『天鏡湖』とも よばれる。"
        case .bandaiBomb: "磐梯山は 1888年の 噴火で 山の かたちが かわった。"
        case .sakuranboTwins: "山形県は さくらんぼの 生産量 日本一。"
        case .imoniPot: "山形の 芋煮会では 河原で 大なべを かこむ。"
        case .benibanaSpirit: "紅花は 山形県の 県の 花。"
        case .shogiPiece: "天童は 将棋の 駒の 生産量 日本一。"
        case .mogamiSpirit: "最上川は 日本三大急流の ひとつ。"
        case .laFrance: "山形県は 西洋なし『ラ・フランス』の 産地。"
        case .shizukaCicada: "芭蕉は 山寺で『閑さや 岩にしみ入る 蝉の声』と よんだ。"
        case .stoneSteps: "山寺の 石段は 1000段 あまり。"
        case .gankutsuSpirit: "山寺は 立石寺と いう お寺。"
        case .snowMonster: "蔵王の 樹氷は『スノーモンスター』と よばれる。"
        case .okamaSlime: "蔵王の 御釜は エメラルド色の 火口湖。"
        case .zaoFox: "蔵王には キツネが たくさん くらす 村も ある。"
        case .pinwheelGhost: "恐山の 湖の ほとりには かざぐるまが まわる。"
        case .sulfurGas: "恐山には 硫黄の においが ただよう。"
        case .osoreCrow: "恐山は 日本三大霊場の ひとつ。"
        case .hachirotaro: "十和田湖の 伝説の りゅう。のちに 八郎潟へ うつったと いう。"
        case .yukioni: "八甲田の 雪から うまれた おに。ねぶたの 火を うばった。"
        case .tatsuko: "田沢湖の 伝説の りゅう。もとは 美しい むすめ たつこ。"
        case .namahageKing: "なまはげの かしら。なまけものを こらしめる。"
        case .ryusendoLord: "龍泉洞の 地底湖に すむ 青い りゅうの かげ。"
        case .mitsuishiOni: "三ツ石に 手形を おした 鬼。『岩手』の 名の もとに なった。"
        case .giantOyster: "松島湾の そこで 大きく なりすぎた カキ。"
        case .datemaru: "まおうに あやつられた 独眼竜の よろい。"
        case .abukumaLord: "あぶくま洞の 石筍に やどった ぬし。"
        case .tenagaAshinaga: "磐梯山に すみ 空を ふさいだと いう 伝説の 巨人。"
        case .yamaderaCicada: "山寺の しずけさを うばった 大きな せみ。"
        case .guardian: "東北を まもる 守護神。まおうに あやつられていた。"
        case .maouShadow: "恐山の おくに のこった まおうの かげ。"
        }
    }

    /// こうげき の ほかに 使う わざ。その土地の 題材に ちなむ。
    /// 空なら こうげき だけ。
    var specialMoves: [EnemyMove] {
        switch self {
        case .ringoSlime: [.heal("みつを なめた")]
        case .hotate: [.boost(.defense, "からを とじた")]
        case .umineko: [.magic("はねを とばした")]
        case .hachinoheIka: [.magic("すみを はいた")]
        case .neputaGhost: [.boost(.attack, "たいこを たたいた")]
        case .ninnikun: [.heal("げんきを だした")]
        case .himemasu: [.boost(.agility, "すいすい およいだ")]
        case .oiraseMoss: [.heal("しずくを すった"), .magic("ほうしを まいた")]
        case .otomeStatue: [.boost(.defense, "ポーズを きめた")]
        case .sukayuSlime: [.magic("あつい ゆを かけた")]
        case .kamoshika: [.smash]
        case .yukinko: [.magic("ふぶきを はいた")]
        case .kiritanpoSoldier: [.heal("みそを ぬった")]
        case .hatahata: [.magic("あわを はいた")]
        case .komachiRice: [.heal("みのりを すった"), .boost(.defense, "ほを たれた")]
        case .shidarezakura: [.magic("はなふぶきを よんだ"), .heal("ヒールを となえた")]
        case .kantoLantern: [.smash, .boost(.attack, "ささえを たかくした")]
        case .inaniwaUdon: [.boost(.defense, "めんを まいた")]
        case .kunimasu: [.boost(.agility, "ふかく もぐった")]
        case .ruriSlime: [.magic("るりいろの ひかりを はなった"), .heal("ヒールを となえた")]
        case .tamagawaAcid: [.magic("さんの ゆを とばした")]
        case .konamahage: [.smash, .magic("なぐごは いねがー と さけんだ")]
        case .kanpuWind: [.magic("さむい かぜを おこした")]
        case .shottsuru: [.heal("しおを なめた"), .magic("においを はなった")]
        case .wankoBowl: [.heal("おかわりを ついだ"), .boost(.agility, "どんどん ついだ")]
        case .nanbuKettle: [.boost(.defense, "てつを あつくした"), .magic("ゆげを ふいた")]
        case .reimenSlime: [.magic("つめたい スープを かけた")]
        case .tonoKappa: [.smash, .heal("さらを ぬらした")]
        case .konjikiBeetle: [.boost(.defense, "きんぱくを まとった")]
        case .chagchagUmako: [.smash, .boost(.agility, "すずを ならした")]
        case .dragonBlueSlime: [.magic("つめたい みずを はいた"), .heal("ヒールを となえた")]
        case .stalactite: [.boost(.defense, "かたく のびた"), .smash]
        case .kikugashira: [.magic("ちょうおんぱを はなった")]
        case .lavaFlow: [.magic("ようがんを ながした")]
        case .komakusa: [.heal("ヒールを となえた"), .magic("はなびらを とばした")]
        case .nanbuKatafuji: [.boost(.defense, "どっしり かまえた"), .smash]
        case .gyutanSoldier: [.boost(.attack, "すみびで あぶった"), .smash]
        case .zundaSlime: [.heal("あんを ぬった")]
        case .sasakama: [.boost(.defense, "かたく やけた")]
        case .kokeshiGhost: [.magic("キュッと ないた"), .boost(.agility, "くびを まわした")]
        case .hoya: [.magic("みずを ふきだした"), .heal("うみの みずを すった")]
        case .fukinagashi: [.magic("かぜを おこした")]
        case .oysterSoldier: [.boost(.defense, "からを かさねた"), .smash]
        case .pineSpirit: [.heal("ヒールを となえた"), .magic("まつばを とばした")]
        case .anago: [.boost(.agility, "すきまに かくれた"), .smash]
        case .mikazukiHelm: [.smash, .boost(.defense, "みかづきを ひからせた")]
        case .aobazuku: [.magic("かぜを おこした"), .boost(.agility, "よるの もりに きえた")]
        case .hirosegawaSpirit: [.magic("かわの みずを あびせた"), .heal("ヒールを となえた")]
        case .momoSpirit: [.heal("あまい かおりを はなった")]
        case .warajiSoldier: [.smash, .boost(.attack, "わらじを かついだ")]
        case .ufo: [.magic("ふしぎな ひかりを はなった"), .boost(.agility, "ジグザグに とんだ")]
        case .kuraGhost: [.boost(.defense, "とびらを しめた"), .smash]
        case .urushiSlime: [.magic("うるしを ぬりつけた"), .heal("ヒールを となえた")]
        case .kozuyu: [.heal("だしを すった"), .boost(.defense, "ほたてで だしを とった")]
        case .limestoneGolem: [.boost(.defense, "いしを かためた"), .smash]
        case .takineBat: [.magic("ちょうおんぱを はなった")]
        case .groundwater: [.magic("みずを ふきだした"), .heal("ヒールを となえた")]
        case .goshikiSlime: [.magic("ごしきの ひかりを はなった"), .heal("いろを かえた")]
        case .inawashiroSpirit: [.magic("みずうみの なみを よんだ"), .boost(.defense, "かがみに なった")]
        case .bandaiBomb: [.magic("ふんかを おこした"), .smash]
        case .sakuranboTwins: [.heal("ふたりで はげましあった"), .boost(.agility, "ころころ ころがった")]
        case .imoniPot: [.magic("あつい しるを かけた"), .boost(.defense, "ふたを しめた")]
        case .benibanaSpirit: [.magic("べにいろの こなを まいた"), .heal("ヒールを となえた")]
        case .shogiPiece: [.boost(.attack, "なりごまに なった"), .boost(.defense, "かこいを くんだ")]
        case .mogamiSpirit: [.magic("きゅうりゅうを よんだ"), .boost(.agility, "ながれに のった")]
        case .laFrance: [.heal("あまく じゅくした"), .smash]
        case .shizukaCicada: [.magic("なきごえで ゆさぶった"), .boost(.agility, "はねを ふるわせた")]
        case .stoneSteps: [.boost(.defense, "いしだんを つんだ"), .smash]
        case .gankutsuSpirit: [.magic("いわの こえを ひびかせた"), .heal("ヒールを となえた")]
        case .snowMonster: [.magic("ふぶきを おこした"), .boost(.defense, "こおりを まとった")]
        case .okamaSlime: [.magic("どくの みずを はいた"), .heal("ヒールを となえた")]
        case .zaoFox: [.magic("きつねびを はなった"), .boost(.agility, "ゆきに かくれた")]
        case .pinwheelGhost: [.magic("かぜを おこした"), .boost(.agility, "くるくる まわった")]
        case .sulfurGas: [.magic("どくけむりを はいた"), .heal("けむりを すった")]
        case .osoreCrow: [.smash, .magic("くろい はねを とばした")]
        case .hachirotaro:
            [.magic("みずの いきを はいた"), .boost(.defense, "うろこを かためた"), .heal("みずうみの みずを のんだ")]
        case .yukioni:
            [.magic("ふぶきを おこした"), .boost(.attack, "こんぼうを ふりあげた"), .smash]
        case .tatsuko:
            [.magic("るりいろの なみを よんだ"), .heal("ヒールを となえた"), .boost(.agility, "みずに とけこんだ")]
        case .namahageKing:
            [.smash, .boost(.attack, "わるいごは いねがー！ と ほえた"), .magic("まっかな いきを はいた"),
             .heal("ヒールを となえた")]
        case .ryusendoLord:
            [.magic("つめたい みずを はいた"), .boost(.defense, "しょうにゅうせきを まとった"),
             .boost(.agility, "ちていこに もぐった"), .heal("ヒールを となえた")]
        case .mitsuishiOni:
            [.smash, .boost(.attack, "いわを もちあげた"), .magic("ようがんを なげた"),
             .boost(.defense, "いわに てがたを おした"), .heal("ヒールを となえた")]
        case .giantOyster:
            [.boost(.defense, "からを ぴったり とじた"), .magic("しおみずを ふきだした"), .smash,
             .heal("うみの えいようを すった")]
        case .datemaru:
            [.smash, .boost(.attack, "かたなを ぬいた"), .boost(.defense, "くろい よろいを ひからせた"),
             .magic("みかづきの きりさきを はなった"), .heal("ハイヒールを となえた")]
        case .abukumaLord:
            [.boost(.defense, "せきじゅんを のばした"), .magic("つららいしを ふらせた"), .smash,
             .heal("ヒールを となえた")]
        case .tenagaAshinaga:
            [.smash, .magic("ながい てで 空を ふさいだ"), .boost(.attack, "ながい あしで ふみならした"),
             .boost(.agility, "おおまたで とびのいた"), .heal("ハイヒールを となえた")]
        case .yamaderaCicada:
            [.magic("いわに しみいる こえで ないた"), .boost(.agility, "はねを ふるわせた"),
             .boost(.attack, "はりを とがらせた"), .heal("ハイヒールを となえた")]
        case .guardian:
            [.magic("ふぶきを おこした"), .smash, .boost(.attack, "ちからを ためた"),
             .boost(.defense, "じゅひょうを まとった"), .boost(.agility, "かぜを まとった"),
             .heal("ハイヒールを となえた")]
        case .maouShadow:
            [.magic("やみの ほのおを はなった"), .smash, .boost(.attack, "やみを ためた"),
             .boost(.defense, "かげに とけた"), .boost(.agility, "かげが ゆらいだ"),
             .heal("やみを すった")]
        }
    }

    /// こうげき の かわりに わざを 使う 割合（分母）。ボスは 半分、ほかは 3回に1回。
    var specialChance: Int { isBoss ? 2 : 3 }
}

/// 強さを 上げる わざで あがる 能力。
enum EnemyBoost: Equatable, Hashable, CaseIterable {
    case attack, defense, agility

    var label: String {
        switch self {
        case .attack: "こうげき"
        case .defense: "しゅび"
        case .agility: "すばやさ"
        }
    }

    /// 何段まで 重ねられるか。
    static let maxStage = 2
}

/// 敵が こうげき の かわりに 使う わざ。文は「〇〇は 〜！」の 〜 の部分。
enum EnemyMove: Equatable {
    /// 守備力を 無視して 当てる 呪文・息。
    case magic(String)
    /// 自分か 仲間の いちばん 弱っている者を 回復する。
    case heal(String)
    /// 自分の 能力を 1段 上げる。
    case boost(EnemyBoost, String)
    /// つうこんの いちげき。ふつうの こうげきの 1.5倍。
    case smash
}

/// 戦いに出ている1体。同じ種類が並ぶので A / B / C を付けて呼び分ける。
struct Enemy: Equatable, Identifiable {
    let id: Int
    let kind: EnemyKind
    var hp: Int
    /// 同じ種類が2体以上いるときの番号（0 なら付けない）。
    var suffix: Int

    init(_ kind: EnemyKind, id: Int = 0, suffix: Int = 0) {
        self.id = id
        self.kind = kind
        self.hp = kind.stats.maxHP
        self.suffix = suffix
    }

    /// 戦いの あいだに 上げた 能力の段（0〜`EnemyBoost.maxStage`）。
    var boosts: [EnemyBoost: Int] = [:]
    /// もう 回復の わざを 使ったか。ボス でない敵は 1戦に 1回だけ（何度も 治されると 終わらない）。
    var hasHealed = false

    func stage(_ boost: EnemyBoost) -> Int { boosts[boost, default: 0] }

    /// 段ごとに こうげきは 1/4、しゅびは 1/2、すばやさは 1/2 ずつ 上がる。
    var attack: Int { kind.stats.attack * (4 + stage(.attack)) / 4 }
    var defense: Int { kind.stats.defense * (2 + stage(.defense)) / 2 }
    var agility: Int { kind.stats.agility * (2 + stage(.agility)) / 2 }
    var maxHP: Int { kind.stats.maxHP }

    var name: String {
        guard suffix > 0 else { return kind.stats.name }
        let letters = ["", "A", "B", "C", "D"]
        return kind.stats.name + (suffix < letters.count ? letters[suffix] : "\(suffix)")
    }

    var isDead: Bool { hp <= 0 }
}

/// 出てくる敵の組み方。
enum EnemyGroup {
    /// 一度に出る数。ボスは必ず1体。
    static let sizeRange = 1...3

    /// 同じ表から何体か選ぶ。同じ種類が重なったら A / B / C を振る。
    static func random(from table: [EnemyKind], rng: inout some RandomSource) -> [Enemy] {
        guard !table.isEmpty else { return [] }
        let count = rng.next(in: sizeRange)
        let kinds = (0..<count).map { _ in table[rng.next(in: 0...(table.count - 1))] }
        return numbered(kinds)
    }

    /// 同じ種類が2体以上あるものだけ番号を振る。
    static func numbered(_ kinds: [EnemyKind]) -> [Enemy] {
        var totals: [EnemyKind: Int] = [:]
        for kind in kinds { totals[kind, default: 0] += 1 }
        var seen: [EnemyKind: Int] = [:]
        return kinds.enumerated().map { index, kind in
            guard totals[kind, default: 0] > 1 else { return Enemy(kind, id: index) }
            seen[kind, default: 0] += 1
            return Enemy(kind, id: index, suffix: seen[kind] ?? 0)
        }
    }

    /// 「りんごスライムが 2ひき あらわれた！」の形にまとめる。
    static func encounterText(_ enemies: [Enemy]) -> String {
        var order: [EnemyKind] = []
        var totals: [EnemyKind: Int] = [:]
        for enemy in enemies {
            if totals[enemy.kind] == nil { order.append(enemy.kind) }
            totals[enemy.kind, default: 0] += 1
        }
        let parts = order.map { kind -> String in
            let count = totals[kind] ?? 0
            return count > 1 ? "\(kind.stats.name) \(count)ひき" : kind.stats.name
        }
        return parts.joined(separator: "と") + "が あらわれた！"
    }
}

/// 敵の 強さの 決めかた。
///
/// 東北は 24か所（＋恐山）と 場所が 多いので、敵ごとに 数字を 書かず、
/// 「その場所に 着くころの 勇者（レベル・装備）」から 計算する。
/// - ふつうの 敵は 着いたころなら 2回ほど なぐって 倒せる（ひと振りでは 倒れない）。
/// - 3体に 囲まれると HP が 2〜3割まで へる（回復しながら 進む 手ごたえ）。
/// - 2レベル 足りないと 3体には まず 勝てない。
/// 見張りは `EncounterTests`、ボスは `BossBalanceTests`。
enum Balance {
    /// 場所ごとの 着くころの 勇者。`places` と 同じ 並び（1 から）。
    struct Arrival: Equatable {
        let level: Int
        let weapon: Item
        let armor: Item
    }

    /// 旅の順の 場所と、そこに 出る 敵（3種ずつ）。
    static let places: [(name: String, arrival: Arrival, enemies: [EnemyKind])] = [
        ("青森のまわり", Arrival(level: 1, weapon: .bunaStick, armor: .hanten), [.ringoSlime, .hotate, .umineko]),
        ("弘前・八戸へむかう道", Arrival(level: 3, weapon: .ringoBokuto, armor: .koginCoat), [.hachinoheIka, .neputaGhost, .ninnikun]),
        ("十和田湖の ほこら", Arrival(level: 4, weapon: .ringoBokuto, armor: .koginCoat), [.himemasu, .oiraseMoss, .otomeStatue]),
        ("八甲田山", Arrival(level: 6, weapon: .nebutaHoko, armor: .nebutaHappi), [.sukayuSlime, .kamoshika, .yukinko]),
        ("秋田のまわり", Arrival(level: 7, weapon: .nebutaHoko, armor: .nebutaHappi), [.kiritanpoSoldier, .hatahata, .komachiRice]),
        ("角館・男鹿へむかう道", Arrival(level: 8, weapon: .tsugaruKatana, armor: .hirosakiArmor), [.shidarezakura, .kantoLantern, .inaniwaUdon]),
        ("田沢湖の ほらあな", Arrival(level: 9, weapon: .tsugaruKatana, armor: .hirosakiArmor), [.kunimasu, .ruriSlime, .tamagawaAcid]),
        ("真山の ほらあな", Arrival(level: 10, weapon: .namahageHocho, armor: .akitaSugiArmor), [.konamahage, .kanpuWind, .shottsuru]),
        ("盛岡のまわり", Arrival(level: 11, weapon: .namahageHocho, armor: .akitaSugiArmor), [.wankoBowl, .nanbuKettle, .reimenSlime]),
        ("平泉・遠野へむかう道", Arrival(level: 12, weapon: .nanbuSword, armor: .nanbuArmor), [.tonoKappa, .konjikiBeetle, .chagchagUmako]),
        ("龍泉洞", Arrival(level: 13, weapon: .nanbuSword, armor: .nanbuArmor), [.dragonBlueSlime, .stalactite, .kikugashira]),
        ("岩手山", Arrival(level: 14, weapon: .konjikiTachi, armor: .fujiwaraArmor), [.lavaFlow, .komakusa, .nanbuKatafuji]),
        ("仙台のまわり", Arrival(level: 15, weapon: .konjikiTachi, armor: .fujiwaraArmor), [.gyutanSoldier, .zundaSlime, .sasakama]),
        ("松島・鳴子へむかう道", Arrival(level: 16, weapon: .dateKatana, armor: .dateArmor), [.kokeshiGhost, .hoya, .fukinagashi]),
        ("松島の 島の ほらあな", Arrival(level: 17, weapon: .dateKatana, armor: .dateArmor), [.oysterSoldier, .pineSpirit, .anago]),
        ("青葉山", Arrival(level: 18, weapon: .dateKatana, armor: .dateArmor), [.mikazukiHelm, .aobazuku, .hirosegawaSpirit]),
        ("福島のまわり", Arrival(level: 19, weapon: .byakkoKatana, armor: .aizuArmor), [.momoSpirit, .warajiSoldier, .ufo]),
        ("会津・喜多方へむかう道", Arrival(level: 20, weapon: .byakkoKatana, armor: .aizuArmor), [.kuraGhost, .urushiSlime, .kozuyu]),
        ("あぶくま洞", Arrival(level: 21, weapon: .byakkoKatana, armor: .aizuArmor), [.limestoneGolem, .takineBat, .groundwater]),
        ("磐梯山", Arrival(level: 22, weapon: .mogamiNaginata, armor: .benibanaArmor), [.goshikiSlime, .inawashiroSpirit, .bandaiBomb]),
        ("山形のまわり", Arrival(level: 23, weapon: .mogamiNaginata, armor: .benibanaArmor), [.sakuranboTwins, .imoniPot, .benibanaSpirit]),
        ("天童・酒田へむかう道", Arrival(level: 24, weapon: .mogamiNaginata, armor: .benibanaArmor), [.shogiPiece, .mogamiSpirit, .laFrance]),
        ("山寺", Arrival(level: 25, weapon: .mogamiNaginata, armor: .benibanaArmor), [.shizukaCicada, .stoneSteps, .gankutsuSpirit]),
        ("蔵王", Arrival(level: 26, weapon: .juhyoSword, armor: .benibanaArmor), [.snowMonster, .okamaSlime, .zaoFox]),
        ("恐山", Arrival(level: 28, weapon: .juhyoSword, armor: .juhyoArmor), [.pinwheelGhost, .sulfurGas, .osoreCrow]),
    ]

    /// ボスと、いどむ 場所（`places` の 番号）・レベル。
    struct BossPlan {
        let place: Int
        let level: Int
        /// HP は 勇者の こうげき力の 何倍か。
        let hpFactor: Double
        /// こうげき力は「勇者の しゅび/2 ＋ 勇者の HP / この数」。
        let attackDivisor: Double
    }

    static let bosses: [EnemyKind: BossPlan] = [
        .hachirotaro: BossPlan(place: 3, level: 5, hpFactor: 10.0, attackDivisor: 4.8),
        .yukioni: BossPlan(place: 4, level: 7, hpFactor: 10.5, attackDivisor: 4.6),
        .tatsuko: BossPlan(place: 7, level: 10, hpFactor: 10.0, attackDivisor: 4.8),
        .namahageKing: BossPlan(place: 8, level: 11, hpFactor: 11.5, attackDivisor: 4.5),
        .ryusendoLord: BossPlan(place: 11, level: 14, hpFactor: 11.0, attackDivisor: 4.8),
        .mitsuishiOni: BossPlan(place: 12, level: 15, hpFactor: 12.5, attackDivisor: 4.4),
        .giantOyster: BossPlan(place: 15, level: 18, hpFactor: 12.0, attackDivisor: 4.7),
        .datemaru: BossPlan(place: 16, level: 19, hpFactor: 13.5, attackDivisor: 4.3),
        .abukumaLord: BossPlan(place: 19, level: 22, hpFactor: 13.0, attackDivisor: 4.6),
        .tenagaAshinaga: BossPlan(place: 20, level: 23, hpFactor: 14.5, attackDivisor: 4.2),
        .yamaderaCicada: BossPlan(place: 23, level: 26, hpFactor: 14.0, attackDivisor: 4.5),
        .guardian: BossPlan(place: 24, level: 27, hpFactor: 17.0, attackDivisor: 4.1),
        .maouShadow: BossPlan(place: 25, level: 30, hpFactor: 20.0, attackDivisor: 3.9),
    ]

    /// その敵が 出る 場所（1 から）。ボスは いどむ 場所。
    static func place(of kind: EnemyKind) -> Int {
        if let plan = bosses[kind] { return plan.place }
        return (places.firstIndex { $0.enemies.contains(kind) } ?? 0) + 1
    }

    /// 敵の 型。同じ 場所の 3種に ちがう 手ごたえを もたせる。
    enum Build {
        case normal, tough, strong, quick, armored, caster

        /// HP・こうげき・しゅび・すばやさ・けいけんちの 倍率。
        var factors: (hp: Double, attack: Double, defense: Double, agility: Double, exp: Double) {
            switch self {
            case .normal: (1.0, 1.0, 1.0, 1.0, 1.0)
            case .tough: (1.15, 0.85, 1.1, 0.7, 1.1)
            case .strong: (0.95, 1.05, 0.9, 1.0, 1.1)
            case .quick: (0.85, 1.0, 0.85, 1.7, 1.05)
            case .armored: (0.75, 0.95, 1.5, 0.6, 1.15)
            case .caster: (0.9, 0.95, 0.9, 1.1, 1.05)
            }
        }
    }

    static func build(of kind: EnemyKind) -> Build {
        switch kind {
        case .ringoSlime, .hachinoheIka, .kiritanpoSoldier, .tonoKappa, .bandaiBomb, .wankoBowl, .gyutanSoldier, .momoSpirit, .sakuranboTwins,
             .yukinko, .himemasu: .normal
        case .hotate, .ninnikun, .komachiRice, .inaniwaUdon, .shottsuru, .nanbuKatafuji, .sasakama, .kozuyu,
             .imoniPot, .snowMonster, .laFrance: .tough
        case .neputaGhost, .kantoLantern, .konamahage, .warajiSoldier, .mikazukiHelm,
             .osoreCrow, .kamoshika: .strong
        case .umineko, .kunimasu, .chagchagUmako, .kikugashira, .anago, .aobazuku, .ufo, .takineBat, .zaoFox,
             .shizukaCicada, .mogamiSpirit: .quick
        case .otomeStatue, .nanbuKettle, .konjikiBeetle, .stalactite, .oysterSoldier, .kuraGhost, .limestoneGolem,
             .shogiPiece, .stoneSteps: .armored
        default: .caster
        }
    }

    /// 着くころの 勇者の 強さ。
    static func hero(_ arrival: Arrival) -> Hero {
        var hero = Hero()
        _ = hero.gainExp(LevelTable.row(arrival.level).exp)
        hero.receive(arrival.weapon)
        hero.receive(arrival.armor)
        return hero
    }

    /// レベル `level` から 次へ 上がるのに いる 経験値。
    static func step(_ level: Int) -> Int {
        LevelTable.row(level + 1).exp - LevelTable.row(level).exp
    }

    static let stats: [EnemyKind: EnemyKind.Stats] = Dictionary(uniqueKeysWithValues: EnemyKind.allCases.map {
        ($0, makeStats($0))
    })

    private static func makeStats(_ kind: EnemyKind) -> EnemyKind.Stats {
        if let plan = bosses[kind] {
            let arrival = places[plan.place - 1].arrival
            let hero = hero(Arrival(level: plan.level, weapon: arrival.weapon, armor: arrival.armor))
            let a = Double(hero.attack)
            let isLast = kind == .guardian || kind == .maouShadow
            return EnemyKind.Stats(
                name: kind.name,
                maxHP: Int(a * plan.hpFactor),
                attack: Int(Double(hero.defense) / 2 + Double(hero.maxHP) / plan.attackDivisor),
                defense: Int(a * 0.45),
                agility: Int(Double(hero.agility) * 0.65),
                exp: isLast ? 0 : step(plan.level) * 3 / 5,
                gold: isLast ? 0 : 60 + plan.place * 25
            )
        }
        let place = place(of: kind)
        let arrival = places[place - 1].arrival
        let hero = hero(arrival)
        let f = build(of: kind).factors
        let a = Double(hero.attack)
        // ほらあなの 敵は すばやい（奥ほど 手ごわく 感じるように）。
        let isCave = [3, 4, 7, 8, 11, 12, 15, 16, 19, 20, 23, 24, 25].contains(place)
        // 1か所で だいたい 1レベル（ボス 2体の ぶんを のぞく）。はじめの うちは 2 より 下げない。
        let exp = max(2, Int(Double(step(arrival.level)) / 13 * f.exp))
        return EnemyKind.Stats(
            name: kind.name,
            maxHP: max(5, Int(a * 1.25 * f.hp)),
            attack: max(4, Int((Double(hero.defense) / 2 + Double(hero.maxHP) / 11) * f.attack)),
            defense: max(1, Int(a * 0.5 * f.defense)),
            agility: max(1, Int(Double(hero.agility) * (isCave ? 0.6 : 0.45) * f.agility)),
            exp: exp,
            gold: max(2, exp * 9 / 10 + 2)
        )
    }
}
