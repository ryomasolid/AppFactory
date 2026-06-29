import Photos
import SwiftUI

/// フラットなアセット一覧（スクショ／動画など）の選択・削除を扱う汎用ビューモデル。
@MainActor
@Observable
final class AssetGridViewModel {

    enum Phase: Equatable {
        case loading
        case ready
    }

    private(set) var phase: Phase = .loading
    private(set) var assets: [PhotoAsset] = []
    private(set) var byteSizeByID: [String: Int64] = [:]
    private(set) var selection: Set<String> = []

    private(set) var isDeleting = false
    var showDeletionInfo = false
    private(set) var lastDeletionCount = 0
    private(set) var lastDeletionSize: Int64 = 0
    var deletionError: String?

    let service: PhotoLibraryService

    init(service: PhotoLibraryService = PhotoLibraryService()) {
        self.service = service
    }

    /// アセットを取得し、サイズを算出してキャッシュする。サイズ降順の指定も可能。
    func load(sortBySize: Bool = false, fetch: @escaping () -> [PHAsset]) async {
        phase = .loading
        let result = await Task.detached(priority: .userInitiated) {
            let photos = fetch().map(PhotoAsset.init)
            var sizes: [String: Int64] = [:]
            for photo in photos { sizes[photo.id] = photo.byteSize }
            let ordered = sortBySize
                ? photos.sorted { (sizes[$0.id] ?? 0) > (sizes[$1.id] ?? 0) }
                : photos
            return (ordered, sizes)
        }.value
        assets = result.0
        byteSizeByID = result.1
        selection = []
        phase = .ready
    }

    // MARK: - Selection

    var selectedCount: Int { selection.count }
    var selectedByteSize: Int64 { selection.reduce(0) { $0 + (byteSizeByID[$1] ?? 0) } }
    var totalByteSize: Int64 { byteSizeByID.values.reduce(0, +) }
    var isAllSelected: Bool { !assets.isEmpty && selection.count == assets.count }
    var selectedPhotos: [PhotoAsset] { assets.filter { selection.contains($0.id) } }

    func toggle(_ id: String) {
        if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
    }

    func toggleSelectAll() {
        if isAllSelected { selection.removeAll() } else { selection = Set(assets.map(\.id)) }
    }

    func size(of photo: PhotoAsset) -> Int64 { byteSizeByID[photo.id] ?? 0 }

    func formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    // MARK: - Deletion

    func deleteSelected() async {
        let targets = selectedPhotos.map(\.asset)
        guard !targets.isEmpty else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            let outcome = try await service.deleteAssets(targets)
            guard outcome == .completed else { return }
            let count = targets.count
            let size = selectedByteSize
            assets.removeAll { selection.contains($0.id) }
            selection.removeAll()
            lastDeletionCount = count
            lastDeletionSize = size
            showDeletionInfo = true
        } catch {
            deletionError = error.localizedDescription
        }
    }
}
