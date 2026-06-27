import CryptoKit
import Foundation
import Vision

/// 知覚ハッシュと Vision 特徴量のディスクキャッシュ。再起動・再スキャンでの再計算を避ける。
/// キーは `PhotoAsset.cacheKey`（localIdentifier ＋ 更新日時）。
///
/// - 知覚ハッシュ: 単一の plist にまとめて保持（`[cacheKey: UInt64]`）。
/// - 特徴量: `VNFeaturePrintObservation`（NSSecureCoding 準拠）をキーごとのファイルにアーカイブ。
///
/// すべて端末内（Caches ディレクトリ）に保存し、外部送信はしない。
final class FeatureCache {

    private let directory: URL
    private let hashStoreURL: URL
    private let lock = NSLock()

    private var hashes: [String: UInt64]
    private var featurePrintMemory: [String: VNFeaturePrintObservation] = [:]

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent("SimilarityCache", isDirectory: true)
        hashStoreURL = directory.appendingPathComponent("phashes.plist")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        if let data = try? Data(contentsOf: hashStoreURL),
           let dict = try? PropertyListDecoder().decode([String: UInt64].self, from: data) {
            hashes = dict
        } else {
            hashes = [:]
        }
    }

    // MARK: - Perceptual hash

    func hash(for key: String) -> UInt64? {
        lock.lock(); defer { lock.unlock() }
        return hashes[key]
    }

    func setHash(_ value: UInt64, for key: String) {
        lock.lock(); defer { lock.unlock() }
        hashes[key] = value
    }

    /// メモリ上のハッシュ辞書をディスクへ書き出す。スキャン終了時に1回呼ぶ。
    func persistHashes() {
        lock.lock()
        let snapshot = hashes
        lock.unlock()
        if let data = try? PropertyListEncoder().encode(snapshot) {
            try? data.write(to: hashStoreURL, options: .atomic)
        }
    }

    // MARK: - Feature print

    func featurePrint(for key: String) -> VNFeaturePrintObservation? {
        lock.lock()
        if let cached = featurePrintMemory[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let url = featurePrintURL(for: key)
        guard let data = try? Data(contentsOf: url),
              let observation = try? NSKeyedUnarchiver.unarchivedObject(
                  ofClass: VNFeaturePrintObservation.self, from: data
              ) else {
            return nil
        }
        lock.lock()
        featurePrintMemory[key] = observation
        lock.unlock()
        return observation
    }

    func setFeaturePrint(_ observation: VNFeaturePrintObservation, for key: String) {
        lock.lock()
        featurePrintMemory[key] = observation
        lock.unlock()
        if let data = try? NSKeyedArchiver.archivedData(
            withRootObject: observation, requiringSecureCoding: true
        ) {
            try? data.write(to: featurePrintURL(for: key), options: .atomic)
        }
    }

    // MARK: - Helpers

    /// キーにはスラッシュ等が含まれるため、SHA256 で安全なファイル名にする。
    private func featurePrintURL(for key: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent("fp-\(name).archive")
    }
}
