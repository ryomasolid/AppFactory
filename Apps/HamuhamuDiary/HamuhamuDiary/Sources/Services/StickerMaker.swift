import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// 写真からハムスター（手前の被写体）だけを切り抜き、白いフチを付けたステッカー画像にする。
///
/// 切り抜きは Vision の被写体マスク（iOS 17〜、写真アプリの「被写体を持ち上げる」と同じ仕組み）。
/// 端末内で完結し、写真を外に送らない。シミュレーターでは動かないことがある（その場合は `.failed`）。
enum StickerMaker {
    enum Failure: Error { case noSubject, failed }

    /// 処理前に縮める長辺。大きすぎるとフチ付け（膨張処理）が重くなる。
    private static let workingLength: CGFloat = 1200

    static func make(from image: UIImage) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            try makeSync(from: image)
        }.value
    }

    private static func makeSync(from image: UIImage) throws -> UIImage {
        // 縮めるついでに向きも「上」にそろう（Vision に向きを渡さずに済む）。
        guard let cgImage = PhotoStore.resized(image, maxLength: workingLength).cgImage else { throw Failure.failed }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        do { try handler.perform([request]) } catch { throw Failure.failed }
        guard let result = request.results?.first, !result.allInstances.isEmpty else { throw Failure.noSubject }

        let masked: CVPixelBuffer
        do {
            masked = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: true)
        } catch {
            throw Failure.failed
        }

        let subject = CIImage(cvPixelBuffer: masked)
        let side = max(subject.extent.width, subject.extent.height)
        guard side > 8 else { throw Failure.noSubject }
        let outline = max(6, side * 0.03)

        // フチの分だけ余白を足してから、被写体の形を太らせて白く塗る。
        let canvas = subject.extent.insetBy(dx: -outline * 1.5, dy: -outline * 1.5)
        let padded = subject.composited(over: CIImage(color: .clear).cropped(to: canvas))

        let grow = CIFilter.morphologyMaximum()
        grow.inputImage = padded
        grow.radius = Float(outline)
        guard let grown = grow.outputImage?.cropped(to: canvas) else { throw Failure.failed }

        // 太らせた輪郭のふちをわずかにぼかし、ギザギザを目立たなくする。
        let smooth = grown.applyingGaussianBlur(sigma: 1.2).cropped(to: canvas)

        let white = CIFilter.blendWithAlphaMask()
        white.inputImage = CIImage(color: .white).cropped(to: canvas)
        white.backgroundImage = CIImage(color: .clear).cropped(to: canvas)
        white.maskImage = smooth
        guard let border = white.outputImage else { throw Failure.failed }

        let sticker = padded.composited(over: border).cropped(to: canvas)
        let context = CIContext()
        guard let output = context.createCGImage(sticker, from: canvas, format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)) else {
            throw Failure.failed
        }
        return UIImage(cgImage: output)
    }

    /// 透過 PNG として一時フォルダに書き出す（UIImage のまま共有すると JPEG にされ、背景が黒くなることがある）。
    static func writePNG(_ image: UIImage, name: String) -> URL? {
        guard let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appending(path: "\(name).png")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
