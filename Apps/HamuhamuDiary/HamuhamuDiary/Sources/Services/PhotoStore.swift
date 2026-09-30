import Foundation
import UIKit

/// 写真ファイルの置き場所。
///
/// 旧版と同じく `Documents/photos/` に置き、モデルには Documents からの相対パス（"photos/xxx.jpg"）だけを持つ。
/// アプリコンテナの絶対パスは更新や復元で変わるため保存しない。旧版の写真はこの規則のまま
/// 同じ場所にあるので、Swift 版になってもファイルを動かさずに表示できる。
enum PhotoStore {
    static let folder = "photos"

    static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func url(for path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return documents.appending(path: path)
    }

    static func image(at path: String?) -> UIImage? {
        guard let url = url(for: path) else { return nil }
        return UIImage(contentsOfFile: url.path(percentEncoded: false))
    }

    /// 長辺1600pxに縮めて JPEG で保存し、相対パスを返す。
    static func save(_ image: UIImage) -> String? {
        guard let data = resized(image, maxLength: 1600).jpegData(compressionQuality: 0.8) else { return nil }
        let name = "\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString.prefix(6).lowercased()).jpg"
        return write(data, name: name)
    }

    /// バックアップの写真を保存する。名前をキーで決め打ちにし、同じファイルを何度取り込んでも増えないようにする（旧版と同じ）。
    static func saveRestored(base64: String, key: String) -> String? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return write(data, name: "restored-\(key).jpg")
    }

    static func base64(at path: String?) -> String? {
        guard let url = url(for: path), let data = try? Data(contentsOf: url) else { return nil }
        return data.base64EncodedString()
    }

    static func delete(_ path: String?) {
        guard let url = url(for: path) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// 旧版の保存値を相対パスにそろえる。
    ///
    /// ごく初期の旧版は `file:///…/Documents/photos/x.jpg` のような絶対パスを保存していた。
    /// Documents 配下なら相対部分だけ取り出す。キャッシュ等を指していたもの（すでに消えている）は nil。
    static func normalizedPath(fromLegacy value: String?) -> String? {
        guard var value, !value.isEmpty else { return nil }
        guard value.hasPrefix("/") || value.contains("://") else { return value }
        value = value.removingPercentEncoding ?? value
        guard let range = value.range(of: "/Documents/", options: .backwards) else { return nil }
        let relative = String(value[range.upperBound...])
        return relative.isEmpty ? nil : relative
    }

    private static func write(_ data: Data, name: String) -> String? {
        let dir = documents.appending(path: folder)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: dir.appending(path: name), options: .atomic)
            return "\(folder)/\(name)"
        } catch {
            return nil
        }
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
