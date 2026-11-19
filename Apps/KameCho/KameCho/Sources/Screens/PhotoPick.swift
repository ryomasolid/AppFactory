import PhotosUI
import SwiftUI

/// 写真を1枚えらんで、小さめの JPEG にしてわたす。
struct PhotoPick: View {
    let title: String
    @Binding var data: Data?
    @State private var item: PhotosPickerItem?

    var body: some View {
        HStack {
            PhotosPicker(selection: $item, matching: .images) {
                Label(data == nil ? title : "写真を変える", systemImage: "photo.on.rectangle")
            }
            if data != nil {
                Spacer()
                Button("外す", role: .destructive) { data = nil }
                    .buttonStyle(.borderless)
            }
        }
        .onChange(of: item) { _, picked in
            guard let picked else { return }
            Task {
                if let raw = try? await picked.loadTransferable(type: Data.self) {
                    data = Self.shrink(raw)
                }
                item = nil
            }
        }
    }

    static func shrink(_ raw: Data, longest: CGFloat = 1400) -> Data? {
        guard let image = UIImage(data: raw) else { return nil }
        let scale = min(1, longest / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format)
            .image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            .jpegData(compressionQuality: 0.8)
    }
}
