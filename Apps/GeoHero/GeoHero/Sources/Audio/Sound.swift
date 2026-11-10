import Foundation

/// 効果音。ゲームのロジック側はこの名前だけを知り、鳴らし方は `AudioManager` に任せる。
enum SoundCue: String, CaseIterable, Sendable {
    case cursor, confirm, bump, stairs, encounter
    case attack, critical, hit, damage, miss, spell, heal, fire, run
    case chest, coin
    // 短い曲（ジングル）
    case victory, levelUp, inn, gameOver

    var isJingle: Bool {
        switch self {
        case .victory, .levelUp, .inn, .gameOver: true
        default: false
        }
    }

    /// 同じ音を鳴らし直すまでの最短間隔（秒）。壁に向かって押しっぱなしのときに連打にならないように。
    var minInterval: Double {
        self == .bump ? 0.3 : 0.05
    }
}

/// 曲。北海道は 地方ごと（1.4 の 曲）。東北は フィールドは 県ごと、街・戦いは 北（青森・秋田）・中（岩手・宮城）・南（福島・山形）で 変える。
enum MusicTrack: String, CaseIterable, Sendable {
    case title, ending, boss, finalBoss, cave, caveDeep
    case fieldHakodate, fieldSapporo, fieldShiretoko
    case villageHakodate, villageSapporo, villageShiretoko
    case battleHakodate, battleSapporo, battleShiretoko
    case fieldAomori, fieldAkita, fieldIwate, fieldMiyagi, fieldFukushima, fieldYamagata
    case villageNorth, villageMiddle, villageSouth
    case battleNorth, battleMiddle, battleSouth

    static func field(_ region: Region) -> MusicTrack {
        switch region {
        case .hakodate: .fieldHakodate
        case .sapporo: .fieldSapporo
        case .shiretoko: .fieldShiretoko
        case .aomori: .fieldAomori
        case .akita: .fieldAkita
        case .iwate: .fieldIwate
        case .miyagi: .fieldMiyagi
        case .fukushima: .fieldFukushima
        case .yamagata: .fieldYamagata
        }
    }

    static func village(_ region: Region) -> MusicTrack {
        switch region {
        case .hakodate: .villageHakodate
        case .sapporo: .villageSapporo
        case .shiretoko: .villageShiretoko
        case .aomori, .akita: .villageNorth
        case .iwate, .miyagi: .villageMiddle
        case .fukushima, .yamagata: .villageSouth
        }
    }

    /// 函館エリア・青森・秋田の ほらあなは ふつうの曲、ほかは 奥ふかい曲。
    static func cave(_ region: Region) -> MusicTrack {
        [.hakodate, .aomori, .akita].contains(region) ? .cave : .caveDeep
    }

    static func battle(_ region: Region) -> MusicTrack {
        switch region {
        case .hakodate: .battleHakodate
        case .sapporo: .battleSapporo
        case .shiretoko: .battleShiretoko
        case .aomori, .akita: .battleNorth
        case .iwate, .miyagi: .battleMiddle
        case .fukushima, .yamagata: .battleSouth
        }
    }
}

enum Waveform: Equatable, Sendable {
    /// 矩形波。duty はオンの割合（0.125 / 0.25 / 0.5 で音色が変わる）。
    case square(duty: Double)
    case triangle
    case noise
}

/// 1つのパート。`notes` は MML（例: `o4 l8 c d e4 >c2`）。
struct Voice: Sendable {
    let wave: Waveform
    let volume: Float
    let notes: String
}

struct Score: Sendable {
    /// 1分あたりの4分音符の数。
    let tempo: Int
    let voices: [Voice]
}

/// 効果音の1区間。周波数を from → to へ滑らせる。volume 0 は無音。
struct Segment: Sendable {
    let wave: Waveform
    let from: Double
    let to: Double
    let duration: Double
    let volume: Float
}
