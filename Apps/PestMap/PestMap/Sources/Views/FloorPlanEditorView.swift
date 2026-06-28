import PhotosUI
import SwiftData
import SwiftUI

/// 間取りエディタ。背景に間取り図（写真 or 空白グリッド）を表示し、
/// タップで対策・設置マーカーを配置する。長押しで削除。
struct FloorPlanEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var plan: FloorPlan

    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var bgImage: UIImage?
    @State private var selectedMarker: PestMarker?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background

                ForEach(plan.markers) { marker in
                    pin(marker)
                        .position(x: marker.x * geo.size.width, y: marker.y * geo.size.height)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in addMarker(at: value.location, in: geo.size) }
            )
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { photoMenu }
        .photosPicker(isPresented: $showLibrary, selection: $pickedItem, matching: .images)
        .onChange(of: pickedItem) { _, item in Task { await loadPicked(item) } }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { setImage($0) }
                .ignoresSafeArea()
        }
        .onAppear(perform: decodeBackground)
        .onChange(of: plan.imageData) { _, _ in decodeBackground() }
        .overlay(alignment: .bottom) { hint }
        .sheet(item: $selectedMarker) { marker in
            MarkerEditView(marker: marker, planName: plan.name)
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        if let bgImage {
            Image(uiImage: bgImage)
                .resizable()
                .scaledToFit()
        } else {
            GridCanvas()
        }
    }

    private var hint: some View {
        Text(plan.markers.isEmpty ? "タップで対策・設置場所を追加" : "タップで追加 ・ 長押しで削除")
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 12)
    }

    private func pin(_ marker: PestMarker) -> some View {
        Image(systemName: marker.kind.symbol)
            .font(.callout)
            .foregroundStyle(.white)
            .padding(8)
            .background(marker.kind.color, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .overlay(alignment: .topTrailing) {
                if marker.nextActionDate != nil {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(.orange, in: Circle())
                        .offset(x: 4, y: -4)
                }
            }
            .shadow(radius: 2)
            .onTapGesture { selectedMarker = marker }
            .onLongPressGesture { context.delete(marker) }
    }

    // MARK: - Toolbar

    private var photoMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { showCamera = true } label: { Label("カメラで撮影", systemImage: "camera") }
                Button { showLibrary = true } label: { Label("ライブラリから選択", systemImage: "photo") }
                if plan.imageData != nil {
                    Button(role: .destructive) {
                        plan.imageData = nil
                        bgImage = nil
                    } label: {
                        Label("背景を削除", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "photo.badge.plus")
            }
        }
    }

    // MARK: - Actions

    private func addMarker(at point: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let nx = min(max(point.x / size.width, 0), 1)
        let ny = min(max(point.y / size.height, 0), 1)
        let marker = PestMarker(x: nx, y: ny)
        context.insert(marker)
        plan.markers.append(marker)
    }

    private func setImage(_ image: UIImage) {
        plan.imageData = image.jpegDataForStorage()
        decodeBackground()
    }

    private func loadPicked(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            setImage(image)
        }
        pickedItem = nil
    }

    private func decodeBackground() {
        bgImage = plan.imageData.flatMap(UIImage.init)
    }
}

/// 写真がない（一から作る）間取り用の方眼背景。
private struct GridCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 28
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)); x += step }
            var y: CGFloat = 0
            while y <= size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += step }
            ctx.stroke(path, with: .color(.gray.opacity(0.25)), lineWidth: 0.5)
        }
        .background(Color(.systemBackground))
    }
}
