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
    /// グループ各メンバーのバイトサイズ（id→bytes）。スキャン後に背景で算出してキャッシュ。
    private(set) var byteSizeByID: [String: Int64] = [:]

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
        await computeByteSizes(for: result)
    }

    /// グループメンバーのファイルサイズを背景で算出してキャッシュする。
    private func computeByteSizes(for groups: [SimilarityGroup]) async {
        let members = groups.flatMap(\.members)
        guard !members.isEmpty else { return }
        let sizes = await Task.detached(priority: .utility) {
            var dict: [String: Int64] = [:]
            for photo in members { dict[photo.id] = photo.byteSize }
            return dict
        }.value
        byteSizeByID = sizes
    }

    // MARK: - Selection

    /// 全グループ合計の削除候補数。
    var selectedCount: Int {
        groups.reduce(0) { $0 + $1.selectedForDeletion.count }
    }

    /// 削除候補に選ばれている写真（プレビュー表示・削除に使う）。
    var selectedPhotos: [PhotoAsset] {
        groups.flatMap { group in
            group.members.filter { group.selectedForDeletion.contains($0.id) }
        }
    }

    /// 選択中の写真を削除した場合に削減できる見込みバイト数。
    var selectedByteSize: Int64 {
        selectedPhotos.reduce(0) { $0 + (byteSizeByID[$1.id] ?? 0) }
    }

    /// 全グループで「残す1枚」以外をすべて削除した場合の削減見込みバイト数（最大）。
    var totalFreeableByteSize: Int64 {
        groups.reduce(0) { sum, group in
            sum + group.members
                .filter { $0.id != group.keepCandidateID }
                .reduce(0) { $0 + (byteSizeByID[$1.id] ?? 0) }
        }
    }

    /// バイト数を人が読める文字列に整形（例: "12.3 MB"）。
    func formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// 「残す1枚」以外がすべて選択されているか（全選択トグルのラベル判定用）。
    var isAllSelected: Bool {
        for group in groups {
            for member in group.members where member.id != group.keepCandidateID {
                if !group.selectedForDeletion.contains(member.id) { return false }
            }
        }
        return selectedCount > 0
    }

    /// 全選択⇄全解除をトグルする。
    func toggleSelectAll() {
        if isAllSelected { deselectAll() } else { selectAllDuplicates() }
    }

    /// 各グループの「残す1枚」以外をすべて削除候補にする。
    func selectAllDuplicates() {
        for i in groups.indices {
            let keep = groups[i].keepCandidateID
            groups[i].selectedForDeletion = Set(groups[i].members.map(\.id).filter { $0 != keep })
        }
    }

    /// 全グループの削除候補を解除する。
    func deselectAll() {
        for i in groups.indices {
            groups[i].selectedForDeletion.removeAll()
        }
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
