import SwiftUI

extension Color {
    static let paper = Color("Paper")
    static let card = Color("Card")
    static let ink = Color("Ink")
    static let mustard = Color("Mustard")
    static let softOrange = Color("SoftOrange")
}

/// 白いカード。縁は細く、影は薄くして、中身（数字と写真）を主役にする。
struct Sticker: ViewModifier {
    var fill: Color = .card
    var radius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(fill, in: .rect(cornerRadius: radius))
            .overlay { RoundedRectangle(cornerRadius: radius).stroke(Color.ink.opacity(0.08), lineWidth: 1) }
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

extension View {
    func sticker(fill: Color = .card, radius: CGFloat = 16) -> some View {
        modifier(Sticker(fill: fill, radius: radius))
    }

    /// タブや記事の共通の背景。
    func paperBackground() -> some View {
        background(Color.paper.ignoresSafeArea())
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Text(text).font(.system(size: 19, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

/// 大きな数字と単位。「量と数字」がこのアプリの主役なので、数字はどの画面でも同じ見せ方にする。
struct BigNumber: View {
    let value: String
    let unit: String
    var size: CGFloat = 38
    var color: Color = .primary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(value).font(.system(size: size, weight: .black, design: .rounded)).monospacedDigit().foregroundStyle(color)
            Text(unit).font(.system(size: size * 0.42, weight: .bold)).foregroundStyle(.secondary)
        }
    }
}

struct Chip: View {
    let label: String
    var selected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background(selected ? Color.accentColor : Color.card, in: .capsule)
                .overlay { Capsule().stroke(selected ? Color.clear : Color.ink.opacity(0.15), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct PrimaryButtonLabel: View {
    let text: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text)
        }
        .font(.headline.weight(.semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.accentColor, in: .rect(cornerRadius: 14))
    }
}

struct PhotoView: View {
    let name: String
    var alt: String = ""

    var body: some View {
        Group {
            if let image = Photos.image(name) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Color.softOrange
            }
        }
        .accessibilityLabel(alt)
    }
}

extension Double {
    /// 3桁区切りの整数。
    var whole: String { Int(rounded()).formatted(.number.locale(Locale(identifier: "ja_JP"))) }
    /// 小数1桁。
    var oneDecimal: String { formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "ja_JP"))) }
}
