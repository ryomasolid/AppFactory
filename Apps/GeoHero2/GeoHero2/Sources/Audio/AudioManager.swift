import AVFoundation
import UIKit

/// BGM と効果音の再生。音はすべて起動時にバックグラウンドで合成してメモリに持つ（音源ファイルなし）。
@MainActor
final class AudioManager {
    private let engine = AVAudioEngine()
    private let musicNode = AVAudioPlayerNode()
    /// 効果音は同時に4つまで重ねて鳴らす。
    private let effectNodes = (0..<4).map { _ in AVAudioPlayerNode() }
    private var nextEffectNode = 0
    private let format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 1)!

    private var music: [MusicTrack: AVAudioPCMBuffer] = [:]
    private var effects: [SoundCue: AVAudioPCMBuffer] = [:]
    private var lastPlayed: [SoundCue: Date] = [:]
    private var desiredTrack: MusicTrack?
    private var playingTrack: MusicTrack?
    private var restoreVolume: Task<Void, Never>?

    var isEnabled = true {
        didSet {
            guard oldValue != isEnabled else { return }
            if isEnabled {
                refreshMusic()
            } else {
                musicNode.stop()
                playingTrack = nil
                effectNodes.forEach { $0.stop() }
            }
        }
    }

    init() {
        // 消音スイッチに従い、ほかのアプリの音とも混ぜる（ゲームを開いたら音楽アプリが止まる、を避ける）。
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        engine.attach(musicNode)
        engine.connect(musicNode, to: engine.mainMixerNode, format: format)
        for node in effectNodes {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }
        engine.prepare()

        // 着信や出力先の変更でエンジンが止まったら、BGM を鳴らし直す。
        for name in [Notification.Name.AVAudioEngineConfigurationChange, AVAudioSession.interruptionNotification] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.playingTrack = nil
                    self?.refreshMusic()
                }
            }
        }

        // ホーム画面に戻ったら鳴りやませ、戻ってきたら鳴らし直す。
        // `.ambient` は前面から外れても中断の通知が来ないので、自分で止めないと
        // アプリが眠るまでのあいだ BGM が鳴り続ける。
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.suspend() }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.resume() }
        }

        Task { await loadSounds() }
    }

    func playMusic(_ track: MusicTrack?) {
        desiredTrack = track
        refreshMusic()
    }

    func play(_ cue: SoundCue) {
        guard isEnabled, let buffer = effects[cue], startEngineIfNeeded() else { return }
        let now = Date()
        if let last = lastPlayed[cue], now.timeIntervalSince(last) < cue.minInterval { return }
        lastPlayed[cue] = now

        let node = effectNodes[nextEffectNode]
        nextEffectNode = (nextEffectNode + 1) % effectNodes.count
        node.stop()
        node.scheduleBuffer(buffer, at: nil)
        node.play()

        // 宿屋とレベルアップのジングルの間は BGM を小さくする。
        if cue == .inn || cue == .levelUp {
            duckMusic(for: Double(buffer.frameLength) / Synth.sampleRate)
        }
    }

    // MARK: - 内部

    /// 効果音を先に（すぐ使うので）、曲はあとから合成する。
    private func loadSounds() async {
        let rendered = await Task.detached(priority: .userInitiated) {
            SoundCue.allCases.map { ($0, $0.render()) }
        }.value
        for (cue, samples) in rendered {
            effects[cue] = makeBuffer(samples)
        }

        for track in MusicTrack.allCases {
            let samples = await Task.detached(priority: .utility) { Synth.render(track.score) }.value
            music[track] = makeBuffer(samples)
            if track == desiredTrack { refreshMusic() }
        }
    }

    /// 前面から外れたとき。鳴っている音を止めて、エンジンとセッションを手放す。
    private func suspend() {
        restoreVolume?.cancel()
        musicNode.stop()
        effectNodes.forEach { $0.stop() }
        playingTrack = nil
        if engine.isRunning { engine.pause() }
        // ほかのアプリに音を返す。
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    /// 前面に戻ったとき。もとの曲を鳴らし直す。
    private func resume() {
        try? AVAudioSession.sharedInstance().setActive(true)
        refreshMusic()
    }

    private func refreshMusic() {
        guard isEnabled, let track = desiredTrack else {
            musicNode.stop()
            playingTrack = nil
            return
        }
        guard track != playingTrack || !musicNode.isPlaying else { return }
        guard let buffer = music[track], startEngineIfNeeded() else { return }
        musicNode.stop()
        musicNode.volume = 1
        musicNode.scheduleBuffer(buffer, at: nil, options: .loops)
        musicNode.play()
        playingTrack = track
    }

    private func duckMusic(for seconds: Double) {
        musicNode.volume = 0.15
        restoreVolume?.cancel()
        restoreVolume = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.musicNode.volume = 1
        }
    }

    private func startEngineIfNeeded() -> Bool {
        if engine.isRunning { return true }
        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    private func makeBuffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = buffer.frameCapacity
        samples.withUnsafeBufferPointer { source in
            if let base = source.baseAddress { channel.update(from: base, count: samples.count) }
        }
        return buffer
    }
}
