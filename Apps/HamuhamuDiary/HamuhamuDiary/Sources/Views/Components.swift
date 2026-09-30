import SwiftUI

/// `@AppStorage` のキー。
enum StorageKey {
    static let reviewRequestedCount = "hd.reviewRequestedCount"
    static let reviewRequestedAt = "hd.reviewRequestedAt"
}

enum AppLinks {
    static let appStoreID = "6777478295"
    static let appStoreURL = URL(string: "https://apps.apple.com/jp/app/id\(appStoreID)")!
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    static var shareMessage: String {
        String(localized: "ハムスターの体重・ごはん・お掃除をかんたん記録できるアプリ「はむはむ日記」🐹\n\(appStoreURL.absoluteString)")
    }
}

// MARK: - カード

extension View {
    /// 角丸のカード。画面はこの1種類で組む。
    func card(padding: CGFloat = 16, cornerRadius: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }

    /// 画面の地（クリーム色）。List / Form のシステム背景も置き換える。
    func creamBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
    }
}

struct SectionTitle: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) { self.title = title }

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}

/// 写真（なければ絵文字）を丸や角丸で表示する。
struct PhotoView: View {
    let path: String?
    var placeholder: String = "🐹"

    var body: some View {
        if let image = PhotoStore.image(at: path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Theme.softFill
                Text(placeholder)
                    .font(.system(size: 200))
                    .minimumScaleFactor(0.05)
                    .padding(8)
            }
        }
    }
}

/// 体重の表示（数字を大きく、単位を小さく）。
struct WeightText: View {
    let weight: Double
    var size: CGFloat = 20

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(Formatting.weight(weight))
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
                .monospacedDigit()
            Text("g")
                .font(.system(size: size * 0.6, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

/// 選択できる小さなチップ。
struct ChipLabel: View {
    let text: String
    var selected = false

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(selected ? Color.white : Color.primary)
            .background(selected ? Theme.accent : Theme.softFill, in: Capsule())
    }
}

enum Formatting {
    /// 体重は小数1桁まで。整数ならそのまま（"42" / "39.6"）。
    static func weight(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    static func signedWeight(_ value: Double) -> String {
        if value == 0 { return "±0g" }
        return (value > 0 ? "+" : "−") + weight(abs(value)) + "g"
    }

    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.month().day().weekday(.abbreviated))
    }

    static func fullDay(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day().weekday(.abbreviated))
    }
}
