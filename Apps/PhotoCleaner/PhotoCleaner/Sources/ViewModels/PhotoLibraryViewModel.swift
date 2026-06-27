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

    // 削除フローの状態
    private(set) var isDeleting = false
    var showDeletionInfo = false
    private(set) var lastDeletionCount = 0
    var deletionError: String?

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

    /// ユーザー操作による再スキャン（削除後やライブラリ変更後）。
    func rescan() async {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else { return }
        guard !isDeleting else { return }
        if case .scanning = phase { return }
        await scan()
    }

    private func scan() async {
        phase = .loading
        let assets = service.fetchImageAssets().map(PhotoAsset.init)
        assetCount = assets.count

        phase = .scanning(progress: 0)
        var result = await engine.detectSimilarGroups(from: assets) { [weak self] progress in
            // progress はバックグラウンドから呼ばれるためメインに戻して反映する。
            Task { @MainActor in
                self?.phase = .scanning(progress: progress)
            }
        }
        // 既定で各グループの「残す1枚」以外を削除候補に選択しておく（ワンタップで整理できるように）。
        for i in result.indices {
            let keep = result[i].keepCandidateID
            result[i].selectedForDeletion = Set(result[i].members.map(\.id).filter { $0 != keep })
        }
        groups = result
        phase = .ready
    }

    // MARK: - Selection

    /// 全グループ合計の削除候補数。
    var selectedCount: Int {
        groups.reduce(0) { $0 + $1.selectedForDeletion.count }
    }

    /// 写真の削除候補選択をトグルする。「残す1枚」は削除対象にできない。
    func toggleSelection(_ assetID: String, inGroup groupID: String) {
        guard let g = groups.firstIndex(where: { $0.id == groupID }) else { return }
        guard groups[g].keepCandidateID != assetID else { return }
        if groups[g].selectedForDeletion.contains(assetID) {
            groups[g].selectedForDeletion.remove(assetID)
        } else {
            groups[g].selectedForDeletion.insert(assetID)
        }
    }

    /// 残す1枚を変更する。新しく残す写真は削除候補から外す。
    func setKeep(_ assetID: String, inGroup groupID: String) {
        guard let g = groups.firstIndex(where: { $0.id == groupID }) else { return }
        groups[g].keepCandidateID = assetID
        groups[g].selectedForDeletion.remove(assetID)
    }

    // MARK: - Deletion

    /// 選択された写真をまとめて削除する。OS の確認ダイアログが表示される。
    func deleteSelected() async {
        let targets: [PHAsset] = groups.flatMap { group in
            group.members
                .filter { group.selectedForDeletion.contains($0.id) }
                .map(\.asset)
        }
        guard !targets.isEmpty else { return }

        isDeleting = true
        defer { isDeleting = false }
        do {
            let outcome = try await service.deleteAssets(targets)
            guard outcome == .completed else { return } // キャンセル時は何もしない
            removeDeletedFromGroups()
            lastDeletionCount = targets.count
            showDeletionInfo = true
        } catch {
            deletionError = error.localizedDescription
        }
    }

    /// 削除済み（選択済み）メンバーをグループから取り除き、2枚未満になったグループは破棄する。
    private func removeDeletedFromGroups() {
        var updated: [SimilarityGroup] = []
        for var group in groups {
            group.members.removeAll { group.selectedForDeletion.contains($0.id) }
            group.selectedForDeletion.removeAll()
            if group.members.count >= 2 {
                if let keep = group.keepCandidateID, !group.members.contains(where: { $0.id == keep }) {
                    group.keepCandidateID = group.members.first?.id
                }
                updated.append(group)
            }
        }
        groups = updated
    }
}
