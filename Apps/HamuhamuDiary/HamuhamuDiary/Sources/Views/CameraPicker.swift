import SwiftUI
import UIKit

/// カメラを直接起動して1枚撮る（SwiftUI には標準のカメラ画面がないので UIImagePickerController を包む）。
///
/// 撮った写真はアプリ内（`PhotoStore`）にだけ保存し、写真ライブラリには書き込まない。
/// そのため写真ライブラリへのアクセス許可は要らず、カメラの許可（NSCameraUsageDescription）だけで済む。
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
