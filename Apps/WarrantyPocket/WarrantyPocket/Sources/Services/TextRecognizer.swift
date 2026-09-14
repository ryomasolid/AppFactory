import Foundation
import ImageIO
import Vision

/// 文字認識の断片1つ（Vision の正規化座標・原点は左下）。
struct RecognizedText: Equatable, Sendable {
    var text: String
    var minX: Double
    var midY: Double
    var height: Double
}

/// 同じ高さに並ぶ断片を1行にまとめる。
///
/// レシートは「合計」が左、「¥12,800」が右の別々の断片として認識されるので、
/// 行にまとめないとキーワードと金額が結びつかない。
enum TextLineGrouper {
    static func lines(from boxes: [RecognizedText]) -> [String] {
        var rows: [[RecognizedText]] = []
        for box in boxes.sorted(by: { $0.midY > $1.midY }) {
            if let anchor = rows.last?.first,
               abs(anchor.midY - box.midY) < min(anchor.height, box.height) * 0.5 {
                rows[rows.count - 1].append(box)
            } else {
                rows.append([box])
            }
        }
        return rows.map { row in
            row.sorted { $0.minX < $1.minX }.map(\.text).joined(separator: " ")
        }
    }
}

/// オンデバイスの文字認識（Vision）。画像を外部に送らない。
enum TextRecognizer {
    /// JPEG などの画像データから、上から順の行を返す。重い処理なのでメインスレッドの外で行う。
    static func lines(fromImageData data: Data) async -> [String] {
        await Task.detached(priority: .userInitiated) {
            recognize(data)
        }.value
    }

    private static func recognize(_ data: Data) -> [String] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return [] }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.usesLanguageCorrection = true

        // 保存時に向きを正規化済み（`ImageProcessing`）なので、画像はそのままの向きで読む。
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        let boxes = (request.results ?? []).compactMap { observation -> RecognizedText? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let box = observation.boundingBox
            return RecognizedText(
                text: candidate.string, minX: Double(box.minX), midY: Double(box.midY), height: Double(box.height)
            )
        }
        return TextLineGrouper.lines(from: boxes)
    }
}
