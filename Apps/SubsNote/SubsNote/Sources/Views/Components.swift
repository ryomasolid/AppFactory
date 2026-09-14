import SwiftUI
import UIKit

/// `@AppStorage` のキー。画面をまたいで同じ値を読むので1か所にまとめる。
enum StorageKey {
    static let hasSeenOnboarding = "sn.hasSeenOnboarding"
    static let reminderDays = "sn.reminderDays"
    static let notifyHour = "sn.notifyHour"
    static let notifyMinute = "sn.notifyMinute"
    static let trialAlerts = "sn.trialAlerts"
    static let yearlyWeekBefore = "sn.yearlyWeekBefore"
    static let homeSort = "sn.homeSort"
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

/// サービスの丸アイコン。ロゴは使わず（商標）、頭文字とカテゴリの色で見分ける。
struct ServiceIcon: View {
    let name: String
    let category: SubCategory
    var size: CGFloat = 40

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.first.map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color(hex: category.colorHex), in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - 状態

extension BillingState {
    var color: Color {
        switch self {
        case .trial: Color(hex: "#E8590C")
        case .active: Theme.accent
        case .cancelled: Color(.systemGray)
        }
    }
}

enum DueStyle {
    /// 支払日・体験終了までの日数の色。3日以内は目立たせる。
    static func color(daysLeft: Int) -> Color {
        daysLeft <= 3 ? Color(hex: "#E8590C") : .secondary
    }
}

/// 小さな角丸ラベル（「無料体験中」「解約済み」など）。
struct TagLabel: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
            .fixedSize(horizontal: true, vertical: false)
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

/// 通知の見本（オンボーディング用）。
struct NotificationSample: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// 共有シート（CSV の保存先を選ぶ）。
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
