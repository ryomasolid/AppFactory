import Photos
import SwiftUI

/// 画面の状態を保持するビューモデル。認可 → アセット読み込み → 類似グループ化までを駆動する。
@MainActor
@Observable
final class PhotoLibraryViewModel {

    enum Phase: Equatable {
        case idle
        case loading
        case scanning(progress: Double)
        case ready
    }

    private(set) var authorizationStatus: PHAuthorizationStatus
    private(set) var phase: Phase = .idle
    private(set) var assetCount: Int = 0
    private(set) var groups: [SimilarityGroup] = []

    let service: PhotoLibraryService
    private let engine: SimilarityEngine

    init(service: PhotoLibraryService = PhotoLibraryService()) {
        self.service = service
        self.engine = SimilarityEngine(service: service, cache: FeatureCache())
        self.authorizationStatus = service.authorizationStatus
    }

    /// 認可をリクエストし、許可されていればスキャンする。
    func requestAccessAndLoad() async {
        let status = await service.requestAuthorization()
        authorizationStatus = status
        guard status == .authorized || status == .limited else { return }
        await scan()
    }

    /// 既に許可済みの場合に呼ぶ。
    func loadIfAuthorized() async {
        authorizationStatus = service.authorizationStatus
        guard authorizationStatus == .authorized || authorizationStatus == .limited else { return }
        guard phase == .idle else { return }
        await scan()
    }

    private func scan() async {
        phase = .loading
        let assets = service.fetchImageAssets().map(PhotoAsset.init)
        assetCount = assets.count

        phase = .scanning(progress: 0)
        let result = await engine.detectSimilarGroups(from: assets) { [weak self] progress in
            // progress はバックグラウンドから呼ばれるためメインに戻して反映する。
            Task { @MainActor in
                self?.phase = .scanning(progress: progress)
            }
        }
        groups = result
        phase = .ready
    }
}
