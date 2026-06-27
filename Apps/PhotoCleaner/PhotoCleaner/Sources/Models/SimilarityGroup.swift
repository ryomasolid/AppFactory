import Foundation

/// 類似と判定された写真の集まり。
///
/// UX 設計メモ: 削除は「グループ内で残す1枚を選び、他をまとめて選択 → OS 確認ダイアログ」を前提にする。
/// そのため "残す候補" と "削除対象に選んだもの" の状態をモデル側に持てるようにしておく（削除UIは次マイルストーン）。
struct SimilarityGroup: Identifiable, Hashable {
    let id: String
    /// メンバー。代表（残す候補の既定）を先頭に置く想定。
    var members: [PhotoAsset]

    /// 既定で残す1枚（先頭 = 最も高解像度/新しいものを並べる想定）。
    var keepCandidateID: String?

    /// 削除対象として選択された写真のID。
    var selectedForDeletion: Set<String> = []

    var count: Int { members.count }

    init(id: String = UUID().uuidString, members: [PhotoAsset]) {
        self.id = id
        self.members = members
        self.keepCandidateID = members.first?.id
    }
}
