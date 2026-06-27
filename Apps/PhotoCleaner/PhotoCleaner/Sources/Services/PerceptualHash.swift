import CoreGraphics
import UIKit

/// 知覚ハッシュ（dHash, 64bit）。一次フィルタ用の軽量な類似シグネチャ。
///
/// アルゴリズム: 画像を 9×8 のグレースケールに縮小し、各行で左右に隣接する
/// ピクセルの明暗を比較（左 < 右 で 1）。8×8 = 64 bit を得る。
/// リサイズで縮小スケール・軽微な明度差・JPEG ノイズに頑健になる。
enum PerceptualHash {

    private static let width = 9
    private static let height = 8

    /// 画像から dHash を計算する。失敗時は nil。
    static func dHash(from image: UIImage) -> UInt64? {
        guard let cgImage = image.cgImage else { return nil }
        return dHash(from: cgImage)
    }

    static func dHash(from cgImage: CGImage) -> UInt64? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bytesPerRow = width
        var pixels = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var hash: UInt64 = 0
        var bit: UInt64 = 0
        for row in 0..<height {
            for col in 0..<(width - 1) {
                let left = pixels[row * width + col]
                let right = pixels[row * width + col + 1]
                if left < right {
                    hash |= (1 << bit)
                }
                bit += 1
            }
        }
        return hash
    }

    /// 2 つのハッシュのハミング距離（異なるビット数, 0...64）。小さいほど類似。
    static func hammingDistance(_ a: UInt64, _ b: UInt64) -> Int {
        (a ^ b).nonzeroBitCount
    }
}
