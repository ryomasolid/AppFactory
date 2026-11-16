import PhotosUI
import SwiftUI
import UIKit

/// 写真1枚の欄（カメラ・アルバム・外す）。写真はアプリの中にだけ持ち、写真ライブラリには書かない。
struct PhotoSlot<Face: View>: View {
    @Binding var data: Data?
    private let face: (Data?) -> Face

    @State private var picking = false
    @State private var shooting = false
    @State private var item: PhotosPickerItem?

    init(data: Binding<Data?>, @ViewBuilder face: @escaping (Data?) -> Face) {
        _data = data
        self.face = face
    }

    var body: some View {
        Menu {
            if CameraSheet.canShoot {
                Button("カメラで撮る", systemImage: "camera") { shooting = true }
            }
            Button(data == nil ? "アルバムから選ぶ" : "アルバムから選びなおす", systemImage: "photo.on.rectangle") { picking = true }
            if data != nil {
                Button("写真を外す", systemImage: "trash", role: .destructive) { data = nil }
            }
        } label: {
            face(data)
        }
        .accessibilityIdentifier("photo-slot")
        .photosPicker(isPresented: $picking, selection: $item, matching: .images)
        .onChange(of: item) { _, picked in
            guard let picked else { return }
            Task {
                if let raw = try? await picked.loadTransferable(type: Data.self), let image = UIImage(data: raw) {
                    data = Squeeze.jpeg(image)
                }
                item = nil
            }
        }
        .fullScreenCover(isPresented: $shooting) {
            CameraSheet { data = Squeeze.jpeg($0) }.ignoresSafeArea()
        }
    }
}

extension PhotoSlot where Face == WidePhoto {
    /// 横いっぱいの写真欄。
    init(data: Binding<Data?>, height: CGFloat = 240) {
        self.init(data: data, face: { WidePhoto(data: $0, height: height) })
    }
}

struct WidePhoto: View {
    let data: Data?
    let height: CGFloat

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill").font(.title2)
                    Text("写真をのせる").font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Tone.cocoa)
                .frame(maxWidth: .infinity)
                .frame(height: height * 0.55)
                .background(Tone.apricot.opacity(0.12))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }
}

enum Squeeze {
    /// 長い辺 1600px・JPEG にして持つ（1枚 200〜400KB ほど）。
    static func jpeg(_ image: UIImage, longSide: CGFloat = 1600) -> Data? {
        let ratio = min(1, longSide / max(image.size.width, image.size.height, 1))
        let target = CGSize(width: (image.size.width * ratio).rounded(), height: (image.size.height * ratio).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format)
            .jpegData(withCompressionQuality: 0.8) { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
    }
}

/// その場で1枚撮る（UIImagePickerController を包む）。
struct CameraSheet: UIViewControllerRepresentable {
    let onShot: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    static var canShoot: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeCoordinator() -> Handler { Handler(onShot: onShot, close: { dismiss() }) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    final class Handler: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onShot: (UIImage) -> Void
        let close: () -> Void

        init(onShot: @escaping (UIImage) -> Void, close: @escaping () -> Void) {
            self.onShot = onShot
            self.close = close
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let shot = info[.originalImage] as? UIImage { onShot(shot) }
            close()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { close() }
    }
}
