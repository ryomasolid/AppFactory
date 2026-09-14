import SwiftUI
import UIKit

/// `@AppStorage` のキー。画面をまたいで同じ値を読むので1か所にまとめる。
enum StorageKey {
    static let hasSeenOnboarding = "wp.hasSeenOnboarding"
    static let notificationTiming = "wp.notificationTiming"
    static let notifyHour = "wp.notifyHour"
    static let notifyMinute = "wp.notifyMinute"
}

// MARK: - カード

extension View {
    /// 角丸のカード。一覧以外の画面はこの1種類で組む。
    func card(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}

/// 色付きの角丸にアイコンを白抜きで置く。写真の無い商品やカテゴリの見分けに使う。
struct IconTile: View {
    let symbolName: String
    let color: Color
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// 商品のサムネイル。写真が無ければカテゴリのアイコン。
struct ThumbnailView: View {
    let data: Data?
    let category: ItemCategory
    var size: CGFloat = 52

    var body: some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08))
                )
                .accessibilityHidden(true)
        } else {
            IconTile(symbolName: category.symbolName, color: Color(hex: category.colorHex), size: size)
        }
    }
}

// MARK: - 保証の状態

extension WarrantyState {
    var color: Color {
        switch self {
        case .active: Color(hex: "#2E9D6A")
        case .soon: Color(hex: "#E08A1B")
        case .expired, .none: Color(.systemGray)
        }
    }
}

struct StatusBadge: View {
    let status: WarrantyStatus

    var body: some View {
        Text(Formatting.badge(status))
            .font(Font.caption.weight(.bold))
            .monospacedDigit()
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(status.state.color)
            .background(status.state.color.opacity(0.14), in: Capsule())
            // 横幅が足りなくても折り返さない。
            .fixedSize(horizontal: true, vertical: false)
    }
}

/// 文字認識で入れた値の目印。触ったら消す。
struct ReadBadge: View {
    var body: some View {
        Label("読み取り", systemImage: "text.viewfinder")
            .font(.caption2.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(Theme.accent)
            .background(Theme.accent.opacity(0.12), in: Capsule())
    }
}

/// 大きな主ボタン。
struct PrimaryButtonLabel: View {
    let title: LocalizedStringKey
    var systemImage: String?

    var body: some View {
        Group {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .foregroundStyle(.white)
    }
}

struct ProBadge: View {
    var body: some View {
        Label("Pro", systemImage: "crown.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.accent)
    }
}

/// 共有シート（PDF・CSV の保存先を選ぶ）。
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
