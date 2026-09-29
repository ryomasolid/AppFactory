// App プレビュー動画（6.5インチ用・886x1920・30fps・約25秒）を 作る。
//
//     Tools/make_preview.sh
//
// `Tools/record_preview_clips.sh` で 録った 場面を つなぎ、上に 短い 見出しを 重ね、
// 場面ごとの BGM を つける。BGM は アプリと 同じ `Synth` で その場で 合成する（音源ファイルなし）。
import AVFoundation
import AppKit
import QuartzCore

/// `Sound.swift` が 地方ごとに 曲を 選ぶのに 使う。ここでは 名前だけ あれば よい。
enum Region { case hakodate, sapporo, shiretoko }

/// 1つの 場面。`start` は 録った 動画の どこから 使うか（起動の 白い画面を 飛ばす）。
struct Scene {
    let clip: String
    let start: Double
    let duration: Double
    let music: MusicTrack
    let caption: String
}

let scenes: [Scene] = [
    Scene(clip: "1_title", start: 3.6, duration: 2.0, music: .title, caption: "遊んで覚える 北海道の地理RPG"),
    Scene(clip: "2_field", start: 3.6, duration: 4.0, music: .overworld, caption: "3つの 地方を 旅しよう"),
    Scene(clip: "3_town", start: 3.6, duration: 4.0, music: .village, caption: "街の人と 名所で 地理を 知る"),
    Scene(clip: "4_quiz", start: 3.4, duration: 7.0, music: .battle, caption: "地理クイズに 正解で おいうち！"),
    Scene(clip: "5_boss", start: 3.8, duration: 8.5, music: .boss, caption: "ご当地の ぬしと 白熱バトル"),
]

let renderSize = CGSize(width: 886, height: 1920)
let outputRate = 44_100.0

@main
struct MakePreview {
    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count == 3 else {
            print("使い方: make_preview <録った動画の フォルダ> <出力 .mp4>"); exit(1)
        }
        let clips = URL(fileURLWithPath: args[1])
        let output = URL(fileURLWithPath: args[2])

        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else { fatalError("トラックを 作れない") }

        // 映像を つなぐ。
        var cursor = CMTime.zero
        var sourceSize = CGSize.zero
        for scene in scenes {
            let asset = AVURLAsset(url: clips.appendingPathComponent(scene.clip + ".mp4"))
            guard let track = try await asset.loadTracks(withMediaType: .video).first else { fatalError("映像が ない: \(scene.clip)") }
            sourceSize = try await track.load(.naturalSize)
            let range = CMTimeRange(start: CMTime(seconds: scene.start, preferredTimescale: 600),
                                    duration: CMTime(seconds: scene.duration, preferredTimescale: 600))
            try videoTrack.insertTimeRange(range, of: track, at: cursor)
            cursor = cursor + range.duration
        }
        let total = cursor

        // 音：場面ごとの 曲を 合成して 並べ、つなぎめを 短く フェードする。
        let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent("geohero_preview.caf")
        try writeMusic(to: audioURL)
        let audioAsset = AVURLAsset(url: audioURL)
        guard let music = try await audioAsset.loadTracks(withMediaType: .audio).first else { fatalError("音が ない") }
        try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: total), of: music, at: .zero)

        // 縦 2622 を 1920 に 合わせて 縮め、はみ出た 上下を 同じだけ 切る。
        let scale = renderSize.width / sourceSize.width
        let overflow = (sourceSize.height * scale - renderSize.height) / 2
        let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layer.setTransform(CGAffineTransform(scaleX: scale, y: scale).concatenating(.init(translationX: 0, y: -overflow)), at: .zero)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: total)
        instruction.layerInstructions = [layer]
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [instruction]
        videoComposition.animationTool = captionTool()

        // いったん 書き出してから、大きさを おさえて 書きなおす（ブラウザから 上げられるのは 10MB まで）。
        let draft = FileManager.default.temporaryDirectory.appendingPathComponent("geohero_preview_draft.mp4")
        try? FileManager.default.removeItem(at: draft)
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            fatalError("書き出せない")
        }
        export.videoComposition = videoComposition
        try await export.export(to: draft, as: .mp4)
        try? FileManager.default.removeItem(at: output)
        try await transcode(draft, to: output, videoBitRate: 2_600_000)
        print("  \(output.path)（\(String(format: "%.1f", total.seconds))秒）")
    }

    /// H.264（指定の ビットレート）＋ AAC ステレオ で 書きなおす。App プレビューは H.264 で 出す。
    static func transcode(_ input: URL, to output: URL, videoBitRate: Int) async throws {
        let asset = AVURLAsset(url: input)
        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
        guard let video = try await asset.loadTracks(withMediaType: .video).first,
              let audio = try await asset.loadTracks(withMediaType: .audio).first else { fatalError("トラックが ない") }

        let videoOut = AVAssetReaderTrackOutput(track: video, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ])
        let audioOut = AVAssetReaderTrackOutput(track: audio, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
        reader.add(videoOut)
        reader.add(audioOut)

        let videoIn = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(renderSize.width),
            AVVideoHeightKey: Int(renderSize.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: videoBitRate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: 30,
            ],
        ])
        let audioIn = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: outputRate,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 192_000,
        ])
        videoIn.expectsMediaDataInRealTime = false
        audioIn.expectsMediaDataInRealTime = false
        writer.add(videoIn)
        writer.add(audioIn)

        reader.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        // 映像と 音を 並行して 流しこむ（片方ずつだと 書き手が もう片方を 待って 止まる）。
        await withTaskGroup(of: Void.self) { group in
            for (index, (input, output)) in [(videoIn, videoOut), (audioIn, audioOut)].enumerated() {
                group.addTask {
                    await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                        input.requestMediaDataWhenReady(on: DispatchQueue(label: "preview.\(index)")) {
                            while input.isReadyForMoreMediaData {
                                guard let sample = output.copyNextSampleBuffer() else {
                                    input.markAsFinished()
                                    done.resume()
                                    return
                                }
                                input.append(sample)
                            }
                        }
                    }
                }
            }
        }
        await writer.finishWriting()
        if writer.status != .completed { fatalError("書きなおせない: \(String(describing: writer.error))") }
    }

    /// 場面ごとの 曲を つないだ ステレオの 音を 書く。
    static func writeMusic(to url: URL) throws {
        var samples: [Float] = []
        let fade = Int(0.15 * outputRate)
        for scene in scenes {
            let song = resample(Synth.render(scene.music.score))
            let count = Int(scene.duration * outputRate)
            var part = (0..<count).map { song[$0 % song.count] }
            for i in 0..<min(fade, count) {
                let gain = Float(i) / Float(fade)
                part[i] *= gain
                part[count - 1 - i] *= gain
            }
            samples += part
        }
        let format = AVAudioFormat(standardFormatWithSampleRate: outputRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = buffer.frameCapacity
        for channel in 0..<2 {
            let data = buffer.floatChannelData![channel]
            for (i, s) in samples.enumerated() { data[i] = s }
        }
        try? FileManager.default.removeItem(at: url)
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
    }

    /// `Synth` の 22,050Hz を 44,100Hz に 直線で 引きのばす。
    static func resample(_ input: [Float]) -> [Float] {
        let ratio = Synth.sampleRate / outputRate
        let count = Int(Double(input.count) / ratio)
        return (0..<count).map { i in
            let position = Double(i) * ratio
            let index = Int(position)
            let next = min(index + 1, input.count - 1)
            let t = Float(position - Double(index))
            return input[index] * (1 - t) + input[next] * t
        }
    }

    /// 場面ごとに 上に 出す 見出し（まるい 札）。
    static func captionTool() -> AVVideoCompositionCoreAnimationTool {
        let parent = CALayer()
        parent.frame = CGRect(origin: .zero, size: renderSize)
        let video = CALayer()
        video.frame = parent.frame
        parent.addSublayer(video)

        var time = 0.0
        for scene in scenes {
            // 書き出しでは CATextLayer の 文字が 描かれないので、札を 画像にして のせる。
            let image = captionImage(scene.caption)
            let pill = CALayer()
            pill.frame = CGRect(x: (renderSize.width - CGFloat(image.width) / 2) / 2, y: renderSize.height - 190,
                                width: CGFloat(image.width) / 2, height: CGFloat(image.height) / 2)
            pill.contents = image

            // その場面の あいだだけ 見せる（はじめと おわりに 少し フェード）。
            pill.opacity = 0
            let show = CAKeyframeAnimation(keyPath: "opacity")
            show.values = [0, 1, 1, 0]
            show.keyTimes = [0, 0.08, 0.92, 1]
            show.beginTime = time == 0 ? AVCoreAnimationBeginTimeAtZero : time
            show.duration = scene.duration
            show.isRemovedOnCompletion = false
            pill.add(show, forKey: "show")
            parent.addSublayer(pill)
            time += scene.duration
        }
        return AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: video, in: parent)
    }

    /// 見出しの 札（紺の 地に 金の ふち・白い 文字）を 2倍の 細かさで 描く。
    static func captionImage(_ caption: String) -> CGImage {
        let font = NSFont(name: "HiraginoSans-W7", size: 92) ?? .boldSystemFont(ofSize: 92)
        let text = NSAttributedString(string: caption, attributes: [.font: font, .foregroundColor: NSColor.white])
        let textSize = text.size()
        let size = CGSize(width: ceil(textSize.width) + 144, height: 192)
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let pill = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4), xRadius: 92, yRadius: 92)
        NSColor(red: 0.08, green: 0.10, blue: 0.28, alpha: 0.9).setFill()
        pill.fill()
        NSColor(red: 1, green: 0.85, blue: 0.29, alpha: 1).setStroke()
        pill.lineWidth = 8
        pill.stroke()
        text.draw(at: NSPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2 + 4))
        NSGraphicsContext.restoreGraphicsState()
        return rep.cgImage!
    }
}
