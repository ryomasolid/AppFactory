import Foundation
import Testing
@testable import TinyHero

struct MMLTests {

    @Test func parsesNotesLengthsAndOctaves() {
        let notes = MML.parse("o4 l8 c d4 e8. r > c < b- c+2")
        #expect(notes == [
            MMLNote(midi: 60, ticks: 24),
            MMLNote(midi: 62, ticks: 48),
            MMLNote(midi: 64, ticks: 36),
            MMLNote(midi: nil, ticks: 24),
            MMLNote(midi: 72, ticks: 24),
            MMLNote(midi: 70, ticks: 24),
            MMLNote(midi: 61, ticks: 96),
        ])
        #expect(MMLNote(midi: 69, ticks: 1).frequency == 440)
    }

    @Test func barSeparatorsAreIgnored() {
        #expect(MML.parse("c4 | d4") == MML.parse("c4 d4"))
    }
}

struct ScoreTests {

    /// 小節の数え間違いを捕まえる：どの曲も全パートがちょうど8小節（4/4）。
    @Test func everyTrackIsEightBarsInEveryVoice() {
        let eightBars = MML.ticksPerWhole * 8
        for track in MusicTrack.allCases {
            for (index, voice) in track.score.voices.enumerated() {
                #expect(Synth.ticks(of: voice) == eightBars, "\(track) のパート\(index) が \(Synth.ticks(of: voice)) tick")
            }
        }
    }

    @Test func jingleVoicesHaveSameLength() {
        for score in [Jingles.victory, Jingles.levelUp, Jingles.inn, Jingles.gameOver] {
            let lengths = Set(score.voices.map(Synth.ticks(of:)))
            #expect(lengths.count == 1)
        }
    }

    @Test func renderedMusicIsAudible() {
        let score = MusicTrack.battle.score
        let samples = Synth.render(score)
        let expected = Double(MML.ticksPerWhole * 8) * Synth.samplesPerTick(tempo: score.tempo)
        #expect(abs(Double(samples.count) - expected) < 2)
        #expect(samples.allSatisfy { $0.isFinite && abs($0) <= 1 })
        #expect((samples.map { abs($0) }.max() ?? 0) > 0.1)
    }

    @Test func everyEffectRenders() {
        for cue in SoundCue.allCases {
            let samples = cue.render()
            #expect(!samples.isEmpty, "\(cue) が無音")
            #expect(samples.allSatisfy { $0.isFinite && abs($0) <= 1 })
            #expect(cue.isJingle || !cue.segments.isEmpty)
        }
    }
}

struct BattleSoundTests {

    @Test func attackAndWinPlayCues() {
        var rng = SeededRandomSource(seed: 7)
        var hero = Hero()
        hero.receive(.steelSword)
        var battle = Battle(hero: hero, enemy: Enemy(.bigRat))
        var cues: [SoundCue] = []
        for _ in 0..<10 where battle.end == nil {
            cues += battle.take(.attack, rng: &rng).cues
        }
        #expect(cues.contains(.attack))
        #expect(cues.contains(.victory))
    }

    @Test func levelUpAndGameOverCues() {
        var rng = SeededRandomSource(seed: 3)
        var weak = Battle(hero: Hero(), enemy: Enemy(.darkDragon))
        var cues: [SoundCue] = []
        for _ in 0..<20 where weak.end == nil {
            cues += weak.take(.attack, rng: &rng).cues
        }
        #expect(cues.last == .gameOver)

        var hero = Hero()
        hero.exp = LevelTable.row(2).exp - 1
        hero.receive(.steelSword)
        var battle = Battle(hero: hero, enemy: Enemy(.bigRat))
        cues = []
        for _ in 0..<10 where battle.end == nil {
            cues += battle.take(.attack, rng: &rng).cues
        }
        #expect(cues.contains(.levelUp))
    }
}

@MainActor
struct GameSoundTests {

    @Test func fieldAndBattleEventsPlaySounds() async {
        let game = GameState()
        game.stepDuration = .zero
        game.messageInterval = .zero
        game.newGame()
        game.say([])
        var played: [SoundCue] = []
        game.playSound = { played.append($0) }

        #expect(game.musicTrack == .village)
        game.position = Point(x: 1, y: 1)
        await game.walk(.up)
        #expect(played.last == .bump)

        game.hero.receive(.steelSword)
        game.startBattle(.bigRat)
        #expect(played.last == .encounter)
        #expect(game.musicTrack == .battle)
        for _ in 0..<10 where game.battle?.end == nil {
            await game.command(.attack)
        }
        #expect(played.contains(.victory))
        // 勝利のジングルが鳴ったら戦闘の BGM は止める。
        #expect(game.musicTrack == nil)
        game.finishBattle()
        #expect(game.musicTrack == .village)
    }
}
