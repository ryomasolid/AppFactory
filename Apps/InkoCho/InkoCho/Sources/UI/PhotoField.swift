import PhotosUI
import SwiftUI
import UIKit

/// 写真1枚。カメラかアルバムから。写真はアプリの中にだけ置き、写真ライブラリには書かない。
struct PhotoField: View {
    @Binding var data: Data?
    var round = false

    @State private var askingSource = false
    @State private var libraryOpen = false
    @State private var cameraOpen = false
    @State private var chosen: PhotosPickerItem?

    var body: some View {
        Button { askingSource = true } label: { preview }
            .buttonStyle(.plain)
            .accessibilityIdentifier("photo-field")
            .confirmationDialog("写真", isPresented: $askingSource) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("カメラで撮る") { cameraOpen = true }
                }
                Button("アルバムから選ぶ") { libraryOpen = true }
                if data != nil { Button("写真を外す", role: .destructive) { data = nil } }
            }
            .photosPicker(isPresented: $libraryOpen, selection: $chosen, matching: .images)
            .onChange(of: chosen) { _, item in
                guard let item else { return }
                Task {
                    if let raw = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: raw) {
                        data = Shrink.jpeg(img)
                    }
                    chosen = nil
                }
            }
            .fullScreenCover(isPresented: $cameraOpen) {
                Camera { data = Shrink.jpeg($0) }.ignoresSafeArea()
            }
    }

    @ViewBuilder
    private var preview: some View {
        let shape = round ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        Group {
            if let data, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "camera.fill").font(.title3)
                    if !round { Text("写真を追加").font(.footnote.weight(.semibold)) }
                }
                .foregroundStyle(Hue.sky)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Hue.sky.opacity(0.1))
            }
        }
        .frame(width: round ? 110 : nil, height: round ? 110 : 200)
        .frame(maxWidth: round ? nil : .infinity)
        .clipShape(shape)
        .contentShape(shape)
    }
}

enum Shrink {
    /// 長い辺を 1600px までにして JPEG に。
    static func jpeg(_ img: UIImage, maxSide: CGFloat = 1600) -> Data? {
        let k = min(1, maxSide / max(img.size.width, img.size.height, 1))
        let size = CGSize(width: floor(img.size.width * k), height: floor(img.size.height * k))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let out = UIGraphicsImageRenderer(size: size, format: format).image { _ in img.draw(in: CGRect(origin: .zero, size: size)) }
        return out.jpegData(compressionQuality: 0.8)
    }
}

/// カメラで1枚撮る。
struct Camera: UIViewControllerRepresentable {
    let took: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Delegate { Delegate(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    final class Delegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let owner: Camera
        init(_ owner: Camera) { self.owner = owner }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { owner.took(img) }
            owner.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { owner.dismiss() }
    }
}
