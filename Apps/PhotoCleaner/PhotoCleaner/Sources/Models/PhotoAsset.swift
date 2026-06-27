import Photos

/// `PHAsset` の薄いラッパ。類似計算・キャッシュで使うメタデータをまとめて持つ。
/// `id` には `localIdentifier` を使う（フェッチ間で安定）。
struct PhotoAsset: Identifiable, Hashable {
    let asset: PHAsset

    var id: String { asset.localIdentifier }
    var pixelWidth: Int { asset.pixelWidth }
    var pixelHeight: Int { asset.pixelHeight }
    var creationDate: Date? { asset.creationDate }
    var modificationDate: Date? { asset.modificationDate }

    /// キャッシュキー。アセットIDと更新日時の組み合わせで、編集された写真の再計算を促す。
    var cacheKey: String {
        let mod = modificationDate?.timeIntervalSince1970 ?? 0
        return "\(asset.localIdentifier)|\(mod)"
    }

    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
