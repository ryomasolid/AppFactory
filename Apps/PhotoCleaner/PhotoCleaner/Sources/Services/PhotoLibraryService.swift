import Photos
import UIKit

/// 写真ライブラリへのアクセスを担う。認可リクエストとアセットのフェッチ、
/// サムネイル供給（`PHCachingImageManager`）を一手に引き受ける。
///
/// 設計メモ:
/// - 認可は `.readWrite` で要求する。今回のスコープは読み込みだけだが、
///   次マイルストーンで `PHPhotoLibrary.deleteAssets` を使うため、ここで一度で済ませて再プロンプトを避ける。
/// - 削除は OS の確認ダイアログが必ず出るため無音削除は不可。UX は「選択 → まとめて確認」を前提にする。
/// - 削除後 30 日間は「最近削除した項目」に残り容量は即座に空かない。削除フロー実装時にこの点をユーザーへ説明する。
final class PhotoLibraryService {

    private let imageManager = PHCachingImageManager()

    // MARK: - Authorization

    /// 現在の認可状態（`.readWrite` ベース）。
    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// 認可をリクエストする。未決定なら OS ダイアログを表示し、確定後の状態を返す。
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    // MARK: - Fetch

    /// ライブラリ内の画像アセットを新しい順にフェッチする（動画などは除外）。
    func fetchImageAssets() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    // MARK: - Images

    /// ハッシュ計算用の小さな画像を**同期的に**取得する。バックグラウンドから呼ぶこと。
    /// `isSynchronous = true` のときコールバックは1回だけ呼ばれる。
    func synchronousImage(for asset: PHAsset, targetSize: CGSize) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false // 完全オンデバイス: iCloud からの取得は行わない。

        var result: UIImage?
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            result = image
        }
        return result
    }

    /// 表示用サムネイルを非同期で取得する。単一コールバックになるよう degraded を無視する。
    func thumbnail(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true // 表示は iCloud 取得を許容（処理ではない）。

        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                guard !degraded else { return }
                continuation.resume(returning: image)
            }
        }
    }
}
