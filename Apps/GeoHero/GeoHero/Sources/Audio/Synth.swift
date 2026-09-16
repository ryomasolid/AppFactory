import Foundation

struct MMLNote: Equatable, Sendable {
    /// MIDI ノート番号。nil は休符。
    let midi: Int?
    let ticks: Int

    var frequency: Double? {
        midi.map { 440 * pow(2, Double($0 - 69) / 12) }
    }
}

/// 簡易 MML の読み取り。
/// - `c d e f g a b` 音名（後ろに `+` `#` でシャープ、`-` でフラット）、`r` 休符
/// - 数字で長さ（4 = 4分音符）、`.` で付点
/// - `o4` オクターブ指定、`>` `<` で1つ上げ下げ、`l8` 既定の長さ
/// - 空白と `|`（小節の区切りの目印）は無視
enum MML {
    static let ticksPerWhole = 192
    private static let semitones: [Character: Int] = ["c": 0, "d": 2, "e": 4, "f": 5, "g": 7, "a": 9, "b": 11]

    static func parse(_ text: String) -> [MMLNote] {
        let chars = Array(text.lowercased())
        var i = 0
        var octave = 4
        var defaultTicks = ticksPerWhole / 4
        var notes: [MMLNote] = []

        func number() -> Int? {
            var value = 0
            var found = false
            while i < chars.count, let digit = chars[i].wholeNumberValue {
                value = value * 10 + digit
                i += 1
                found = true
            }
            return found ? value : nil
        }

        func dotted(_ ticks: Int) -> Int {
            guard i < chars.count, chars[i] == "." else { return ticks }
            i += 1
            return ticks + ticks / 2
        }

        while i < chars.count {
            let char = chars[i]
            i += 1
            switch char {
            case "o":
                octave = number() ?? octave
            case ">":
                octave += 1
            case "<":
                octave -= 1
            case "l":
                if let n = number(), n > 0 { defaultTicks = dotted(ticksPerWhole / n) }
            case "a"..."g", "r":
                var semitone = semitones[char]
                while i < chars.count, chars[i] == "+" || chars[i] == "#" || chars[i] == "-" {
                    semitone = semitone.map { $0 + (chars[i] == "-" ? -1 : 1) }
                    i += 1
                }
                let ticks = dotted(number().map { ticksPerWhole / max($0, 1) } ?? defaultTicks)
                notes.append(MMLNote(midi: semitone.map { (octave + 1) * 12 + $0 }, ticks: ticks))
            default:
                continue
            }
        }
        return notes
    }
}

/// 波形の合成。結果はモノラル Float（-1...1）で、`sampleRate` のサンプル列。
enum Synth {
    static let sampleRate = 22_050.0

    static func samplesPerTick(tempo: Int) -> Double {
        sampleRate * 60 / (Double(tempo) * Double(MML.ticksPerWhole / 4))
    }

    static func ticks(of voice: Voice) -> Int {
        MML.parse(voice.notes).reduce(0) { $0 + $1.ticks }
    }

    static func render(_ score: Score) -> [Float] {
        let parsed = score.voices.map { MML.parse($0.notes) }
        let totalTicks = parsed.map { $0.reduce(0) { $0 + $1.ticks } }.max() ?? 0
        let perTick = samplesPerTick(tempo: score.tempo)
        var out = [Float](repeating: 0, count: Int((Double(totalTicks) * perTick).rounded()))

        for (voice, notes) in zip(score.voices, parsed) {
            var tick = 0
            var phase = 0.0
            var noise = NoiseGenerator()
            for note in notes {
                let start = Int((Double(tick) * perTick).rounded())
                tick += note.ticks
                let end = min(out.count, Int((Double(tick) * perTick).rounded()))
                guard let frequency = note.frequency, end > start else { continue }
                let length = end - start
                // 音と音の間に少し隙間を空けて、同じ高さが続いても粒が聞こえるようにする。
                let gate = voice.wave == .noise ? min(length, Int(0.06 * sampleRate)) : Int(Double(length) * 0.88)
                for n in 0..<length {
                    let level = envelope(n: n, gate: gate, isNoise: voice.wave == .noise)
                    phase += frequency / sampleRate
                    phase -= phase.rounded(.down)
                    guard level > 0 else { continue }
                    out[start + n] += Float(sample(voice.wave, phase: phase, noise: &noise) * level) * voice.volume
                }
            }
        }
        clamp(&out)
        return out
    }

    static func render(_ segments: [Segment]) -> [Float] {
        var out: [Float] = []
        var phase = 0.0
        var noise = NoiseGenerator()
        for segment in segments {
            let length = Int(segment.duration * sampleRate)
            out.reserveCapacity(out.count + length)
            for n in 0..<length {
                let progress = Double(n) / Double(max(length, 1))
                let frequency = segment.from + (segment.to - segment.from) * progress
                phase += frequency / sampleRate
                phase -= phase.rounded(.down)
                let attack = min(1, Double(n) / (0.002 * sampleRate))
                let release = min(1, Double(length - n) / (0.008 * sampleRate))
                let fade = segment.wave == .noise ? 1 - progress : 1
                let level = attack * release * fade
                out.append(Float(sample(segment.wave, phase: phase, noise: &noise) * level) * segment.volume)
            }
        }
        clamp(&out)
        return out
    }

    private static func envelope(n: Int, gate: Int, isNoise: Bool) -> Double {
        let t = Double(n) / sampleRate
        if isNoise { return n < gate ? exp(-t / 0.02) : 0 }
        var level = min(1, t / 0.005) * (0.65 + 0.35 * exp(-t / 0.06))
        if n >= gate {
            level *= max(0, 1 - Double(n - gate) / (0.015 * sampleRate))
        }
        return level
    }

    private static func sample(_ wave: Waveform, phase: Double, noise: inout NoiseGenerator) -> Double {
        switch wave {
        case .square(let duty): phase < duty ? 1 : -1
        case .triangle: 4 * abs(phase - 0.5) - 1
        case .noise: noise.next()
        }
    }

    private static func clamp(_ samples: inout [Float]) {
        for i in samples.indices {
            samples[i] = min(1, max(-1, samples[i]))
        }
    }
}

/// ノイズ用の軽い乱数（音の再現性のため種を固定）。
struct NoiseGenerator {
    private var state: UInt32 = 0x1234_5678

    mutating func next() -> Double {
        state = state &* 1_664_525 &+ 1_013_904_223
        return Double(state >> 8) / Double(1 << 24) * 2 - 1
    }
}
