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

    // ズーム/パン
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background

                ForEach(plan.markers) { marker in
                    MarkerPin(
                        marker: marker,
                        canvasSize: geo.size,
                        onTap: { selectedMarker = marker },
                        onMoved: { nx, ny in
                            marker.x = nx
                            marker.y = ny
                        }
                    )
                }
            }
            .contentShape(Rectangle())
            // 追加タップは変形前に付け、座標を content 空間で受ける（ズーム時も正しい正規化座標になる）
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in addMarker(at: value.location, in: geo.size) }
            )
            .scaleEffect(scale)
            .offset(offset)
            .gesture(panGesture)
            .simultaneousGesture(magnifyGesture)
            .clipped()
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { photoMenu }
        .toolbar { zoomResetButton }
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
        Text(plan.markers.isEmpty ? "タップで対策・設置場所を追加" : "タップで編集 ・ ドラッグで移動")
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 12)
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

    private var zoomResetButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if scale > 1 || offset != .zero {
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero
                    }
                } label: {
                    Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                }
            }
        }
    }

    // MARK: - Zoom / Pan gestures

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(lastScale * value.magnification, 1), 5)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 {
                    withAnimation(.spring(duration: 0.25)) { offset = .zero; lastOffset = .zero }
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in lastOffset = offset }
    }

    // MARK: - Actions

    private func addMarker(at point: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        // 既存マーカー付近のタップは「追加」せず編集に任せる
        // （ピンのタップ＝編集と、キャンバスのタップ＝追加が二重発火するのを防ぐ）。
        let hitRadius: CGFloat = 28
        for marker in plan.markers {
            let mp = CGPoint(x: marker.x * size.width, y: marker.y * size.height)
            if hypot(mp.x - point.x, mp.y - point.y) <= hitRadius { return }
        }
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

/// キャンバス上のマーカー。タップで編集、ドラッグで移動する。
/// 位置は正規化座標（0...1）で持ち、ドラッグ確定時にモデルへ書き戻す。
private struct MarkerPin: View {
    let marker: PestMarker
    let canvasSize: CGSize
    let onTap: () -> Void
    let onMoved: (Double, Double) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        let baseX = marker.x * canvasSize.width
        let baseY = marker.y * canvasSize.height

        symbol
            .scaleEffect(isDragging ? 1.25 : 1)
            .shadow(radius: isDragging ? 6 : 2)
            .position(x: baseX + dragOffset.width, y: baseY + dragOffset.height)
            .animation(.spring(duration: 0.2), value: isDragging)
            .onTapGesture { onTap() }
            .highPriorityGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        guard canvasSize.width > 0, canvasSize.height > 0 else {
                            dragOffset = .zero
                            isDragging = false
                            return
                        }
                        let nx = (baseX + value.translation.width) / canvasSize.width
                        let ny = (baseY + value.translation.height) / canvasSize.height
                        onMoved(min(max(nx, 0), 1), min(max(ny, 0), 1))
                        dragOffset = .zero
                        isDragging = false
                    }
            )
    }

    private var symbol: some View {
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
