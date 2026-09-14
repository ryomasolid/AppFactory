import UIKit

/// 取り込んだ写真を保存用に縮小する。
enum ImageProcessing {
    struct Prepared: Sendable {
        var full: Data
        var thumbnail: Data
    }

    /// 長辺2000pxの JPEG と長辺300pxのサムネイル。1枚 300〜600KB に収まる。
    /// 描き直すので向き（EXIF の回転）も正規化され、文字認識にそのまま渡せる。
    static func prepare(_ image: UIImage) -> Prepared? {
        guard let full = resized(image, maxLength: 2000).jpegData(compressionQuality: 0.8),
              let thumbnail = resized(image, maxLength: 300).jpegData(compressionQuality: 0.75)
        else { return nil }
        return Prepared(full: full, thumbnail: thumbnail)
    }

    static func resized(_ image: UIImage, maxLength: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > 0 else { return image }
        let scale = min(1, maxLength / longest)
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
