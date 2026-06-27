import SwiftUI

/// 類似グループの一覧。各グループを横スクロールのサムネイル列で表示する。
struct SimilarityGridView: View {
    let groups: [SimilarityGroup]
    let service: PhotoLibraryService

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(group.count) 枚の類似写真")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(group.members) { photo in
                                AssetThumbnailView(photo: photo, service: service)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}
