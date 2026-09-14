import SwiftUI
import UIKit

/// 写真の全画面表示。修理窓口やお店で保証書を見せる用途なので、ピンチで拡大できるようにする。
struct PhotoViewer: View {
    let attachments: [Attachment]

    @Environment(\.dismiss) private var dismiss
    @State private var index: Int

    init(attachments: [Attachment], index: Int) {
        self.attachments = attachments
        _index = State(initialValue: index)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $index) {
                ForEach(Array(attachments.enumerated()), id: \.element.id) { offset, attachment in
                    ZoomableImageView(image: (attachment.imageData ?? attachment.thumbnailData).flatMap(UIImage.init(data:)))
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: attachments.count > 1 ? .always : .never))
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    if attachments.indices.contains(index) {
                        Text(attachments[index].kind.label)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

/// UIScrollView のズーム（ピンチ・ダブルタップ）。SwiftUI のジェスチャーだとページ送りと競合するため。
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage?

    func makeUIView(context: Context) -> ZoomingScrollView {
        ZoomingScrollView(image: image)
    }

    func updateUIView(_ view: ZoomingScrollView, context: Context) {}
}

final class ZoomingScrollView: UIScrollView, UIScrollViewDelegate {
    private let imageView = UIImageView()

    init(image: UIImage?) {
        super.init(frame: .zero)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 5
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        backgroundColor = .black
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if zoomScale == minimumZoomScale {
            imageView.frame = bounds
            contentSize = bounds.size
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        if zoomScale > minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let point = recognizer.location(in: imageView)
            let size = CGSize(width: bounds.width / 3, height: bounds.height / 3)
            zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height), animated: true)
        }
    }
}
