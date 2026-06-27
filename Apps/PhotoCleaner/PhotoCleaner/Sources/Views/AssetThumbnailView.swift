import SwiftUI

/// 単一アセットの非同期サムネイル。表示中のセルサイズに合わせて取得する。
struct AssetThumbnailView: View {
    let photo: PhotoAsset
    let service: PhotoLibraryService
    var size: CGFloat = 110

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay { ProgressView() }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task(id: photo.id) {
            let scale = UIScreen.main.scale
            let target = CGSize(width: size * scale, height: size * scale)
            image = await service.thumbnail(for: photo.asset, targetSize: target)
        }
    }
}
