import SwiftUI

/// 初回起動時の導入。
///
/// 役目は**「撮るだけで登録できる」と伝える**ことと、**「保証終了の通知を許可してもらう」**ことの2つに絞る。
struct OnboardingView: View {
    let onDone: () -> Void

    @State private var step: Step = OnboardingView.initialStep
    @State private var notificationDenied = false

    private enum Step: String {
        case intro
        case scan
        case notifications
    }

    /// スクショ撮影用に、起動引数で開始ページを指定できるようにする。
    private static var initialStep: Step {
        Launch.onboardingStep.flatMap(Step.init(rawValue:)) ?? .intro
    }

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .intro: intro
            case .scan: scan
            case .notifications: notifications
            }
        }
        .padding(28)
        .tint(Theme.accent)
        .animation(.default, value: step)
    }

    // MARK: - 1. 説明

    private var intro: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
                Text("保証書ポケット")
                    .font(.largeTitle.bold())
                Text("家電が壊れたとき、保証書がすぐに出てくる。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 22) {
                feature("camera.fill", "撮るだけで登録", "レシートや保証書を撮ると、購入日と金額を読み取ります。")
                feature("bell.badge.fill", "終わる前にお知らせ", "メーカー保証も延長保証も、切れる前に通知します。")
                feature("lock.fill", "すべて端末内に保存", "アカウント登録は不要。写真や記録が外部に送信されることはありません。")
            }

            Spacer()
            primaryButton("はじめる") { step = .scan }
        }
    }

    // MARK: - 2. 読み取りの説明

    private var scan: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 10) {
                Text("撮るだけで、入力はほぼ終わり")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("読み取りは iPhone の中だけで行います。あとは商品名を入れて保存するだけです。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(alignment: .center, spacing: 12) {
                sampleReceipt
                Image(systemName: "arrow.right")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.accent)
                sampleFields
            }

            Spacer()
            primaryButton("次へ") { step = .notifications }
        }
    }

    private var sampleReceipt: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("サンプル電機").font(.caption2.weight(.bold))
            Text("2026/9/1 14:32").font(.caption2)
            Divider()
            HStack { Text("炊飯器"); Spacer(); Text("¥24,800") }.font(.caption2)
            HStack { Text("合計").bold(); Spacer(); Text("¥24,800").bold() }.font(.caption2)
            HStack { Text("お預り"); Spacer(); Text("¥30,000") }.font(.caption2).foregroundStyle(.secondary)
        }
        .monospacedDigit()
        .padding(10)
        .frame(width: 130)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 6))
        .foregroundStyle(.black)
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        .accessibilityHidden(true)
    }

    private var sampleFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            sampleField("購入日", "2026/9/1")
            sampleField("金額", "¥24,800")
            sampleField("購入店", "サンプル電機")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }

    private func sampleField(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(title).font(.caption2).foregroundStyle(.secondary)
                ReadBadge()
            }
            Text(value).font(.subheadline.weight(.semibold)).monospacedDigit()
        }
    }

    // MARK: - 3. 通知の許可

    private var notifications: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                Text("保証が切れる前にお知らせ")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("終了の30日前と7日前に通知します。気になる不具合を、保証が使えるうちに相談できます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            notificationSample

            if notificationDenied {
                Text("通知がオフになっています。設定アプリ →「保証書ポケット」→「通知」で許可してください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            VStack(spacing: 10) {
                // 「許可」などシステムのダイアログを模した文言は審査で指摘されるため使わない。
                primaryButton("通知をオンにする") {
                    Task { await enableNotifications() }
                }
                Button("あとで設定する") { onDone() }
                    .font(.subheadline)
            }
        }
    }

    private var notificationSample: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text("エアコンの保証がまもなく終わります").font(.subheadline.weight(.semibold))
                Text("メーカー保証は 2026/10/14 まで（あと30日）。2025/10/15 購入・1年。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - 共通

    private func primaryButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
    }

    private func feature(_ icon: String, _ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Theme.accent)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func enableNotifications() async {
        let granted = await NotificationScheduler.shared.requestAuthorizationIfNeeded()
        notificationDenied = !granted
        // 拒否されても先へ進める。設定アプリからいつでも許可でき、起動時に組み直される。
        if granted { onDone() }
    }
}
