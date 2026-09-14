import PhotosUI
import SwiftData
import SwiftUI

/// 「撮影して追加」の流れ（スキャン／写真／手入力 → 読み取り → 追加画面）の状態。
@MainActor
@Observable
final class ItemAdder {
    enum Source {
        case scan
        case photos
        case manual
    }

    var showScanner = false
    var showPhotoPicker = false
    var showPaywall = false
    var photoSelection: [PhotosPickerItem] = []
    var draft: ItemDraft?
    var isReading = false

    /// 無料版の上限に達していればペイウォールを出す。
    func start(_ source: Source, itemCount: Int, isPro: Bool) {
        guard ProLimits.canAddItem(currentCount: itemCount, isPro: isPro) else {
            showPaywall = true
            return
        }
        switch source {
        case .scan: showScanner = true
        case .photos: showPhotoPicker = true
        case .manual: draft = ItemDraft()
        }
    }

    func read(_ images: [UIImage]) async {
        guard !images.isEmpty else { return }
        isReading = true
        let started = Date()
        let result = await DraftBuilder.make(from: images)
        // スキャナの画面が閉じきる前にシートを出すと表示されないので、最低限の間を空ける。
        let elapsed = Date().timeIntervalSince(started)
        if elapsed < 0.6 { try? await Task.sleep(for: .seconds(0.6 - elapsed)) }
        isReading = false
        draft = result
    }

    func loadPhotos() async {
        let selection = photoSelection
        guard !selection.isEmpty else { return }
        photoSelection = []
        isReading = true
        var images: [UIImage] = []
        for item in selection {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                images.append(image)
            }
        }
        isReading = false
        await read(images)
    }
}

extension View {
    /// 追加の流れに必要なシート類をまとめて付ける。
    func itemAdder(_ adder: ItemAdder, itemCount: Int, onSaved: @escaping (Item) -> Void) -> some View {
        modifier(ItemAdderModifier(adder: adder, onSaved: onSaved))
    }
}

private struct ItemAdderModifier: ViewModifier {
    @Bindable var adder: ItemAdder
    let onSaved: (Item) -> Void

    @Environment(StoreManager.self) private var store

    func body(content: Content) -> some View {
        content
            .photosPicker(
                isPresented: $adder.showPhotoPicker,
                selection: $adder.photoSelection,
                maxSelectionCount: 5,
                matching: .images
            )
            .onChange(of: adder.photoSelection) { _, newValue in
                guard !newValue.isEmpty else { return }
                Task { await adder.loadPhotos() }
            }
            .fullScreenCover(isPresented: $adder.showScanner) {
                DocumentScannerView { images in
                    adder.showScanner = false
                    Task { await adder.read(images) }
                } onCancel: {
                    adder.showScanner = false
                }
                .ignoresSafeArea()
            }
            .sheet(item: $adder.draft) { draft in
                ItemEditorView(item: nil, draft: draft, onSaved: onSaved)
                    .environment(store)
            }
            .sheet(isPresented: $adder.showPaywall) {
                PaywallView().environment(store)
            }
            .overlay {
                if adder.isReading {
                    ReadingOverlay()
                }
            }
    }
}

struct ReadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("読み取り中…")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .accessibilityElement(children: .combine)
    }
}
