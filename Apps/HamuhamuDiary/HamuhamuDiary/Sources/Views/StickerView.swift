import SwiftUI

/// 記録の写真からハムスターを切り抜いて、ステッカー風の画像にしてシェアする。
///
/// シェア用の画像にはアプリ名とハッシュタグを入れ、見た人がアプリにたどり着けるようにする（インストール増やし）。
struct StickerView: View {
    let record: DiaryRecord
    let profile: HamsterProfile?
    /// シェアを最後まで済ませたとき（レビュー依頼のきっかけ）。
    var onShared: () -> Void = {}

    @State private var phase: Phase = .loading
    @State private var background = StickerBackground.all[0]

    private enum Phase {
        case loading
        case ready(UIImage)
        case failed(String)
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            switch phase {
            case .loading:
                ProgressView("ハムちゃんを切り抜いています…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView {
                    Label("うまく切り抜けませんでした", systemImage: "scissors")
                } description: {
                    Text(message)
                }
            case .ready(let sticker):
                StickerCard(sticker: sticker, name: profile?.name, date: record.date, background: background)
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                    .padding(.horizontal, 24)
                backgroundPicker
                Spacer(minLength: 0)
                actions(sticker)
            }
        }
        .creamBackground()
        .navigationTitle("ステッカー")
        .navigationBarTitleDisplayMode(.inline)
        .task { await cutOut() }
    }

    private var backgroundPicker: some View {
        HStack(spacing: 12) {
            ForEach(StickerBackground.all) { item in
                Button { background = item } label: {
                    Circle()
                        .fill(item.color)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                        .overlay(Circle().stroke(Theme.accent, lineWidth: 3).padding(-5).opacity(background == item ? 1 : 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.name)
                .sensoryFeedback(.selection, trigger: background == item)
            }
        }
    }

    private func actions(_ sticker: UIImage) -> some View {
        VStack(spacing: 8) {
            Button { shareCard(sticker) } label: {
                Label("画像をシェアする", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))

            Button { shareSticker(sticker) } label: {
                Label("ステッカーだけ保存（背景なし）", systemImage: "square.on.square.dashed")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 14))

            Text("背景なしは LINE やメッセージにそのまま貼れます")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    // MARK: - 動作

    private func cutOut() async {
        guard case .loading = phase else { return }
        guard let image = PhotoStore.image(at: record.photoPath) else {
            phase = .failed(String(localized: "この記録には写真がありません。"))
            return
        }
        do {
            phase = .ready(try await StickerMaker.make(from: image))
        } catch StickerMaker.Failure.noSubject {
            phase = .failed(String(localized: "写真からハムちゃんを見つけられませんでした。ハムちゃんが大きく写った写真で試してください。"))
        } catch {
            phase = .failed(String(localized: "この端末では切り抜けないか、処理に失敗しました。"))
        }
    }

    private func shareCard(_ sticker: UIImage) {
        // 投稿先で見栄えがそろうよう、端末がダークモードでも明るい配色で書き出す。
        let renderer = ImageRenderer(
            content: StickerCard(sticker: sticker, name: profile?.name, date: record.date, background: background)
                .frame(width: 360)
                .environment(\.colorScheme, .light)
        )
        renderer.scale = 3
        var items: [Any] = [ShareCardView.hashtags]
        if let image = renderer.uiImage { items.insert(image, at: 0) }
        ActivitySheet.present(items, onCompleted: onShared)
    }

    private func shareSticker(_ sticker: UIImage) {
        guard let url = StickerMaker.writePNG(sticker, name: "hamuhamu-sticker") else { return }
        ActivitySheet.present([url], onCompleted: onShared)
    }
}

/// ステッカーの背景色（シェア画像用）。
struct StickerBackground: Identifiable, Equatable {
    let id: String
    let name: LocalizedStringKey
    let color: Color

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }

    static let all: [StickerBackground] = [
        .init(id: "peach", name: "ピーチ", color: Color(red: 1.0, green: 0.86, blue: 0.80)),
        .init(id: "cream", name: "クリーム", color: Color(red: 1.0, green: 0.95, blue: 0.80)),
        .init(id: "mint", name: "ミント", color: Color(red: 0.82, green: 0.95, blue: 0.88)),
        .init(id: "sky", name: "そら", color: Color(red: 0.82, green: 0.91, blue: 1.0)),
        .init(id: "lavender", name: "ラベンダー", color: Color(red: 0.90, green: 0.86, blue: 1.0)),
    ]
}

/// シェアする正方形の画像（Instagram・X どちらでも切れにくい 1:1）。
struct StickerCard: View {
    let sticker: UIImage
    let name: String?
    let date: Date
    let background: StickerBackground

    private let ink = Color(red: 0.18, green: 0.14, blue: 0.13)
    private let sub = Color(red: 0.42, green: 0.36, blue: 0.31)

    var body: some View {
        ZStack {
            background.color
            // 背景に水玉を散らして、貼ったシール感を出す。
            Canvas { context, size in
                let step = size.width / 7
                for row in 0..<8 {
                    for column in 0..<8 where (row + column).isMultiple(of: 2) {
                        let rect = CGRect(x: CGFloat(column) * step - 4, y: CGFloat(row) * step - 4, width: 8, height: 8)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.55)))
                    }
                }
            }

            VStack(spacing: 6) {
                Image(uiImage: sticker)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(-4))
                    .shadow(color: .black.opacity(0.18), radius: 6, y: 4)
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .frame(maxHeight: .infinity)

                Text(name.flatMap { $0.isEmpty ? nil : $0 } ?? String(localized: "うちのハムちゃん"))
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(.white, in: Capsule())

                HStack(spacing: 6) {
                    Image("AppLogo")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    Text("はむはむ日記").font(.caption.bold()).foregroundStyle(sub)
                    Spacer()
                    Text(date.formatted(.dateTime.year().month(.defaultDigits).day()))
                        .font(.caption)
                        .foregroundStyle(sub.opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
