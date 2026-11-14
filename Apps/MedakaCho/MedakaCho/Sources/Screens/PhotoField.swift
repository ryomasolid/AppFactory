import PhotosUI
import SwiftUI
import UIKit

/// 記録に付ける写真1枚の欄。カメラで撮る・アルバムから選ぶ・外す。
///
/// 写真はアプリの中（SwiftData）にだけ保存し、写真ライブラリには書き込まない。
/// アルバムは PhotosPicker なので許可は要らず、カメラの許可（NSCameraUsageDescription）だけで済む。
struct PhotoField: View {
    @Binding var photo: Data?

    @State private var pickedItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        Section("写真") {
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    .accessibilityIdentifier("log-photo")
                Button("写真を外す", role: .destructive) { self.photo = nil }
            }
            if CameraPicker.isAvailable {
                Button { showCamera = true } label: {
                    Label("カメラで撮る", systemImage: "camera")
                }
            }
            PhotosPicker(selection: $pickedItem, matching: .images) {
                Label(photo == nil ? "アルバムから選ぶ" : "アルバムから選びなおす", systemImage: "photo.on.rectangle")
            }
            .accessibilityIdentifier("pick-photo")
        }
        .onChange(of: pickedItem) { _, item in
            Task { await load(item) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { photo = PhotoField.shrink($0) }
                .ignoresSafeArea()
        }
    }

    private func load(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        photo = Self.shrink(image)
        pickedItem = nil
    }

    /// 様子を見返すには十分な 1600px・JPEG に縮めて持つ（1枚およそ 200〜400KB）。
    static func shrink(_ image: UIImage, side: CGFloat = 1600) -> Data? {
        let scale = min(1, side / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.82)
    }
}

/// 一覧の行に出す小さな写真。
struct PhotoThumb: View {
    let data: Data
    var size: CGFloat = 44

    var body: some View {
        if let image = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: size * 3, height: size * 3)) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityLabel("写真あり")
        }
    }
}

/// カメラを直接起動して1枚撮る（SwiftUI には標準のカメラ画面がないので UIImagePickerController を包む）。
struct CameraPicker: UIViewControllerRepresentable {
    let onPicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    /// シミュレーターやカメラのない端末ではボタン自体を出さない。
    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker

        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onPicked(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
