import CoreGraphics
import Vision

/// Vision の画像特徴量（feature print）を扱う。完全オンデバイスで動作する。
/// 二次確定で `computeDistance` により候補ペアの距離を測る。
enum FeaturePrintService {

    /// 画像から特徴量を生成する。失敗時は nil。
    static func featurePrint(from cgImage: CGImage) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            return nil
        }
    }

    /// 2 つの特徴量の距離。小さいほど類似。計算不能なら nil。
    static func distance(_ a: VNFeaturePrintObservation, _ b: VNFeaturePrintObservation) -> Float? {
        var distance = Float(0)
        do {
            try a.computeDistance(&distance, to: b)
            return distance
        } catch {
            return nil
        }
    }
}
