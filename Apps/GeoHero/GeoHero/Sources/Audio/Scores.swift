import Foundation

/// オリジナルの曲。どれも 4/4 拍子・8小節のループで、`|` は小節の区切り（1小節 = 8分音符8つ）。
/// パートごとの長さがそろっていることはテストで確かめる。
extension MusicTrack {
    var score: Score {
        switch self {
        case .title:
            Score(tempo: 108, voices: [
                lead("o4 g4 e8 g8 >c4< g4 | a4 f8 a8 >c4< a4 | g8 a8 g8 f8 e4 c4 | d4 e8 f8 g2 | g4 e8 g8 >c4 e4< | >d4 c8< b8 a4 f4 | g8 f8 e8 d8 e4 d4 | c2 r2"),
                bass("o3 c4 g4 c4 g4 | f4 >c4< f4 >c4< | c4 g4 c4 g4 | g4 >d4< g4 b4 | c4 g4 c4 g4 | f4 a4 f4 a4 | g4 b4 g4 b4 | c4 g4 c2"),
            ])
        case .village:
            Score(tempo: 92, voices: [
                lead("o4 f4 a8 >c8< a4 f4 | g4 a8 b-8 a4 g4 | f4 a8 >c8 d4 c4< | b-8 a8 g8 a8 f2 | d4 f8 a8 g4 f4 | e4 g8 b-8 a4 g4 | f8 g8 a8 b-8 >c4< a4 | g4 e4 f2", duty: 0.5, volume: 0.09),
                bass("o3 f4 >c4< f4 >c4< | c4 g4 c4 g4 | f4 >c4< f4 >c4< | c4 g4 f2 | d4 a4 d4 a4 | c4 g4 c4 g4 | f4 >c4< f4 >c4< | c4 g4 f2"),
            ])
        case .overworld:
            Score(tempo: 126, voices: [
                lead("o4 d4 g8 a8 b4 a8 g8 | a4 f+8 d8 e4 f+4 | g4 b8 >d8 e4 d8 c8< | b4 a8 g8 a2 | d4 g8 a8 b4 >c8 d8< | >e4 d8 c8< b4 a4 | g8 a8 b8 g8 a4 f+4 | g2 r4 d4"),
                bass("o2 " + pump("g") + pump("d") + pump("c") + pump("d") + pump("g") + pump("c") + pump("d") + "g4 >d4< g2"),
                drums(String(repeating: "c8 r8 ", count: 32)),
            ])
        case .cave:
            Score(tempo: 84, voices: [
                lead("o4 e4 r4 f4 e4 | d+4 e8 r8 r2 | a4 r4 b-4 a4 | g+4 a8 r8 r2 | >c4 r8< b8 a4 g+4 | a4 f4 e2 | d4 e8 f8 e4 d4 | e2 r2", duty: 0.125, volume: 0.10),
                bass("o2 a4 r4 a4 r4 | a4 r4 a4 r4 | f4 r4 f4 r4 | e4 r4 e4 r4 | a4 r4 a4 r4 | d4 r4 d4 r4 | e4 r4 e4 r4 | e4 r4 e4 r4"),
            ])
        case .battle:
            Score(tempo: 150, voices: [
                lead("o4 e8 e8 g8 e8 a8 e8 b8 a8 | g8 f+8 e8 d8 e4 r4 | e8 e8 g8 e8 >c8< e8 b8 a8 | b8 >c8 d8 c8< b4 r4 | >e8 d8 c8< b8 a8 g8 f+8 e8 | f+8 g8 a8 b8 >c4< b4 | a8 g8 f+8 e8 d+8 e8 f+8 d+8 | e4 r4 e4 r4"),
                bass("o2 " + pump("e") + pump("e") + pump("c") + pump("b") + pump("c") + pump("a") + pump("b") + "e8 >e8< e8 >e8< e4 r4"),
                drums(String(repeating: "c8 r8 c8 c8 ", count: 16)),
            ])
        case .boss:
            Score(tempo: 160, voices: [
                lead("o4 d8 d8 r8 d8 f8 d8 g+8 a8 | a8 a8 r8 a8 b-8 a8 g8 f8 | d8 d8 r8 d8 f8 g8 a8 >c8< | >d4 c+4 d4< r4 | f8 g8 a8 b-8 a8 g8 f8 e8 | d8 e8 f8 g8 a4 f4 | g8 a8 b-8 >c8 d8 c8< b-8 g8 | a4 c+4 d2", duty: 0.25, volume: 0.12),
                bass("o2 " + pump("d") + pump("a") + pump("d") + "d8 d8 c+8 c+8 d4 r4 " + pump("b-") + pump("d") + pump("g") + "a8 a8 a8 a8 d4 r4"),
                drums(String(repeating: "c8 c8 r8 c8 ", count: 16)),
            ])
        case .ending:
            Score(tempo: 84, voices: [
                lead("o4 c4 e4 g4 >c4< | b4 g4 a2 | f4 a4 >c4 d4< | >e2 d4 c4< | a4 >c4< b4 a4 | g4 e4 f4 d4 | e4 f4 g4 b4 | >c2.< r4", duty: 0.5, volume: 0.10),
                bass("o3 c4 g4 c4 g4 | e4 g4 f2 | f4 a4 f4 a4 | c4 g4 c4 e4 | f4 a4 g4 f4 | c4 g4 d4 g4 | c4 d4 e4 g4 | c2. r4"),
            ])
        }
    }
}

/// ジングル（1回だけ鳴らす短い曲）。
enum Jingles {
    static let victory = Score(tempo: 150, voices: [
        lead("o4 c8 e8 g8 >c4< g8 >c2<", duty: 0.5),
        bass("o3 c2 r4 c2"),
    ])
    static let levelUp = Score(tempo: 170, voices: [
        lead("o5 c8 d8 e8 g8 e8 g8 >c4<"),
        bass("o3 c4 e4 g4 c4"),
    ])
    static let inn = Score(tempo: 96, voices: [
        lead("o4 e4 g4 >c4< r8 g8 >c2<", duty: 0.5, volume: 0.10),
        bass("o3 c2 g2 c2"),
    ])
    static let gameOver = Score(tempo: 72, voices: [
        lead("o4 e4 d+4 d4 c+4 c2", duty: 0.5, volume: 0.10),
        bass("o2 a2 a2 a2"),
    ])
}

extension SoundCue {
    func render() -> [Float] {
        switch self {
        case .victory: Synth.render(Jingles.victory)
        case .levelUp: Synth.render(Jingles.levelUp)
        case .inn: Synth.render(Jingles.inn)
        case .gameOver: Synth.render(Jingles.gameOver)
        default: Synth.render(segments)
        }
    }

    var segments: [Segment] {
        switch self {
        case .cursor: [sq(1320, 1320, 0.03, 0.10)]
        case .confirm: [sq(880, 880, 0.04), sq(1320, 1320, 0.06)]
        case .bump: [sq(140, 70, 0.07, 0.22)]
        case .stairs: [784, 659, 523, 392, 262].map { sq($0, $0, 0.05, 0.13, duty: 0.25) }
        case .encounter: [440, 880, 494, 988, 554, 1109, 659].map { sq($0, $0, 0.04, 0.15, duty: 0.25) }
        case .attack: [noise(0.07, 0.30)]
        case .critical: [sq(1600, 400, 0.10, 0.18), noise(0.10, 0.35)]
        case .hit: [noise(0.12, 0.35), sq(220, 110, 0.05, 0.15)]
        case .damage: [sq(400, 80, 0.15, 0.25), noise(0.08, 0.25)]
        case .miss: [sq(1000, 1500, 0.06, 0.10)]
        case .spell: [523, 659, 784, 1047, 1319].map { sq($0, $0, 0.04, 0.13, duty: 0.25) }
        case .heal: [784, 988, 1175, 1568].map { Segment(wave: .triangle, from: $0, to: $0, duration: 0.07, volume: 0.35) }
        case .fire: [noise(0.35, 0.35)]
        case .run: [sq(600, 600, 0.04), rest(0.02), sq(500, 500, 0.04), rest(0.02), sq(400, 400, 0.06)]
        case .chest: [523, 659, 784, 1047].map { sq($0, $0, 0.05, 0.13, duty: 0.25) } + [sq(1319, 1319, 0.12, 0.13, duty: 0.25)]
        case .coin: [sq(988, 988, 0.05), sq(1319, 1319, 0.15)]
        case .victory, .levelUp, .inn, .gameOver: []
        }
    }
}

// MARK: - 書きやすくするための部品

private func lead(_ notes: String, duty: Double = 0.25, volume: Float = 0.11) -> Voice {
    Voice(wave: .square(duty: duty), volume: volume, notes: "l8 " + notes)
}

private func bass(_ notes: String) -> Voice {
    Voice(wave: .triangle, volume: 0.28, notes: "l8 " + notes)
}

private func drums(_ notes: String) -> Voice {
    Voice(wave: .noise, volume: 0.05, notes: "l8 " + notes)
}

/// 根音とその1オクターブ上を8分音符で交互に（1小節ぶん）。
private func pump(_ root: String) -> String {
    String(repeating: "\(root)8 >\(root)8< ", count: 4) + "| "
}

private func sq(_ from: Double, _ to: Double, _ duration: Double, _ volume: Float = 0.15, duty: Double = 0.5) -> Segment {
    Segment(wave: .square(duty: duty), from: from, to: to, duration: duration, volume: volume)
}

private func noise(_ duration: Double, _ volume: Float) -> Segment {
    Segment(wave: .noise, from: 0, to: 0, duration: duration, volume: volume)
}

private func rest(_ duration: Double) -> Segment {
    Segment(wave: .square(duty: 0.5), from: 0, to: 0, duration: duration, volume: 0)
}
