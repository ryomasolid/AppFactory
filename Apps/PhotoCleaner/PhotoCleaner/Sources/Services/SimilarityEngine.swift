import CoreGraphics
import Photos
import UIKit
import Vision

/// 二段構えの類似検出パイプライン。すべてオンデバイスで処理する。
/// - 一次フィルタ: 寸法（アスペクト比）＋知覚ハッシュ（dHash）で粗くグループ化。
/// - 二次確定: 一次の候補グループ内だけ Vision 特徴量の `computeDistance` で再クラスタし、確定。
/// 計算結果（ハッシュ・特徴量）は `FeatureCache` に永続化して再計算を避ける。
final class SimilarityEngine {

    private let service: PhotoLibraryService
    private let cache: FeatureCache

    /// ハッシュ用サムネイル（小さく・高速）。
    private let hashThumbnailSize = CGSize(width: 64, height: 64)
    /// 特徴量用サムネイル（精度のためやや大きめ）。
    private let featureThumbnailSize = CGSize(width: 256, height: 256)

    /// dHash のハミング距離しきい値（一次フィルタ）。広めに取り取りこぼしを防ぐ。
    private let hammingThreshold: Int
    /// 特徴量距離のしきい値（二次確定）。これ以下を「類似」とみなす。
    private let featureDistanceThreshold: Float
    /// アスペクト比の許容差。
    private let aspectTolerance: Double = 0.2

    init(
        service: PhotoLibraryService,
        cache: FeatureCache,
        hammingThreshold: Int = 12,
        featureDistanceThreshold: Float = 0.6
    ) {
        self.service = service
        self.cache = cache
        self.hammingThreshold = hammingThreshold
        self.featureDistanceThreshold = featureDistanceThreshold
    }

    /// 二段パイプラインを実行して確定グループを返す。重いためバックグラウンドで実行。
    /// - Parameter progress: 0...1（前半=ハッシュ計算, 後半=特徴量確定）。
    func detectSimilarGroups(
        from assets: [PhotoAsset],
        progress: @escaping (Double) -> Void
    ) async -> [SimilarityGroup] {
        await Task.detached(priority: .userInitiated) { [self] in
            let coarse = firstPass(assets: assets) { p in progress(p * 0.7) }
            let refined = secondPass(groups: coarse) { p in progress(0.7 + p * 0.3) }
            cache.persistHashes()
            return refined
        }.value
    }

    // MARK: - First pass (size + perceptual hash)

    private struct Signature {
        let asset: PhotoAsset
        let hash: UInt64
        let aspect: Double
    }

    private func firstPass(
        assets: [PhotoAsset],
        progress: @escaping (Double) -> Void
    ) -> [[PhotoAsset]] {
        var signatures: [Signature] = []
        signatures.reserveCapacity(assets.count)

        let total = max(assets.count, 1)
        for (index, photo) in assets.enumerated() {
            if let hash = perceptualHash(for: photo) {
                let aspect = photo.pixelHeight > 0 ? Double(photo.pixelWidth) / Double(photo.pixelHeight) : 1
                signatures.append(Signature(asset: photo, hash: hash, aspect: aspect))
            }
            progress(Double(index + 1) / Double(total))
        }

        let uf = UnionFind(count: signatures.count)
        for i in 0..<signatures.count {
            for j in (i + 1)..<signatures.count {
                let a = signatures[i]
                let b = signatures[j]
                guard abs(a.aspect - b.aspect) <= aspectTolerance else { continue }
                if PerceptualHash.hammingDistance(a.hash, b.hash) <= hammingThreshold {
                    uf.union(i, j)
                }
            }
        }

        var buckets: [Int: [PhotoAsset]] = [:]
        for i in 0..<signatures.count {
            buckets[uf.find(i), default: []].append(signatures[i].asset)
        }
        // 2枚以上の候補グループだけ二次確定へ渡す。
        return buckets.values.filter { $0.count >= 2 }.map { $0 }
    }

    private func perceptualHash(for photo: PhotoAsset) -> UInt64? {
        if let cached = cache.hash(for: photo.cacheKey) { return cached }
        guard let image = service.synchronousImage(for: photo.asset, targetSize: hashThumbnailSize),
              let hash = PerceptualHash.dHash(from: image) else { return nil }
        cache.setHash(hash, for: photo.cacheKey)
        return hash
    }

    // MARK: - Second pass (Vision feature print)

    private func secondPass(
        groups: [[PhotoAsset]],
        progress: @escaping (Double) -> Void
    ) -> [SimilarityGroup] {
        var confirmed: [SimilarityGroup] = []
        let totalGroups = max(groups.count, 1)

        for (index, members) in groups.enumerated() {
            confirmed.append(contentsOf: refine(members))
            progress(Double(index + 1) / Double(totalGroups))
        }

        return confirmed.sorted { $0.count > $1.count }
    }

    /// 一次の候補グループを特徴量距離で再クラスタし、2枚以上の確定グループに分ける。
    private func refine(_ members: [PhotoAsset]) -> [SimilarityGroup] {
        let prints: [(asset: PhotoAsset, print: VNFeaturePrintObservation)] = members.compactMap { photo in
            guard let fp = featurePrint(for: photo) else { return nil }
            return (photo, fp)
        }

        // 特徴量が2枚分そろわない（Vision が使えない／失敗した）場合は、
        // 一次フィルタの候補をそのまま確定グループとして採用する。
        // 実機では Vision が動くためこの分岐は通らない（防御的フォールバック）。
        guard prints.count >= 2 else {
            return members.count >= 2 ? [makeGroup(members)] : []
        }

        let uf = UnionFind(count: prints.count)
        for i in 0..<prints.count {
            for j in (i + 1)..<prints.count {
                if let d = FeaturePrintService.distance(prints[i].print, prints[j].print),
                   d <= featureDistanceThreshold {
                    uf.union(i, j)
                }
            }
        }

        var buckets: [Int: [PhotoAsset]] = [:]
        for i in 0..<prints.count {
            buckets[uf.find(i), default: []].append(prints[i].asset)
        }

        return buckets.values
            .filter { $0.count >= 2 }
            .map { makeGroup($0) }
    }

    /// 高解像度かつ新しいものを先頭（残す候補の既定）にしてグループを作る。
    private func makeGroup(_ members: [PhotoAsset]) -> SimilarityGroup {
        let sorted = members.sorted { lhs, rhs in
            let lp = lhs.pixelWidth * lhs.pixelHeight
            let rp = rhs.pixelWidth * rhs.pixelHeight
            if lp != rp { return lp > rp }
            return (lhs.creationDate ?? .distantPast) > (rhs.creationDate ?? .distantPast)
        }
        return SimilarityGroup(members: sorted)
    }

    private func featurePrint(for photo: PhotoAsset) -> VNFeaturePrintObservation? {
        if let cached = cache.featurePrint(for: photo.cacheKey) { return cached }
        guard let image = service.synchronousImage(for: photo.asset, targetSize: featureThumbnailSize),
              let cgImage = image.cgImage,
              let fp = FeaturePrintService.featurePrint(from: cgImage) else { return nil }
        cache.setFeaturePrint(fp, for: photo.cacheKey)
        return fp
    }
}

/// シンプルな Union-Find（経路圧縮あり）。
private final class UnionFind {
    private var parent: [Int]

    init(count: Int) { parent = Array(0..<count) }

    func find(_ x: Int) -> Int {
        var root = x
        while parent[root] != root { root = parent[root] }
        var node = x
        while parent[node] != root {
            let next = parent[node]
            parent[node] = root
            node = next
        }
        return root
    }

    func union(_ a: Int, _ b: Int) {
        let ra = find(a), rb = find(b)
        if ra != rb { parent[ra] = rb }
    }
}
