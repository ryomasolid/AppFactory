import SwiftUI
import VisionKit

/// 書類スキャン（VisionKit）。台形補正された複数ページを返す。
struct DocumentScannerView: UIViewControllerRepresentable {
    let onFinish: ([UIImage]) -> Void
    let onCancel: () -> Void

    /// シミュレータなど、カメラの無い環境では使えない。
    static var isAvailable: Bool { VNDocumentCameraViewController.isSupported }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    /// デリゲートのプロトコルは非分離だが、VisionKit はメインスレッドで呼ぶ。
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let onFinish: @MainActor ([UIImage]) -> Void
        private let onCancel: @MainActor () -> Void

        init(onFinish: @escaping @MainActor ([UIImage]) -> Void, onCancel: @escaping @MainActor () -> Void) {
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        nonisolated func documentCameraViewController(
            _ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan
        ) {
            MainActor.assumeIsolated {
                onFinish((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })
            }
        }

        nonisolated func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            MainActor.assumeIsolated { onCancel() }
        }

        nonisolated func documentCameraViewController(
            _ controller: VNDocumentCameraViewController, didFailWithError error: Error
        ) {
            MainActor.assumeIsolated { onCancel() }
        }
    }
}
