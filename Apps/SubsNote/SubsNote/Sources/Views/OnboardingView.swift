import SwiftUI

/// 初回起動時の導入。
///
/// 役目は**「毎月いくらかすぐ分かる」「無料体験のまま本契約にならない」と伝える**ことと、**通知を許可してもらう**ことに絞る。
struct OnboardingView: View {
    let onDone: () -> Void

    @State private var step: Step = OnboardingView.initialStep
    @State private var notificationDenied = false

    private enum Step: Int {
        case intro = 1
        case trial = 2
        case notifications = 3
    }

    /// スクショ撮影用に、起動引数で開始ページを指定できるようにする（"2" または "trial"）。
    private static var initialStep: Step {
        guard let raw = Launch.onboardingStep else { return .intro }
        if let number = Int(raw), let step = Step(rawValue: number) { return step }
        switch raw {
        case "trial": return .trial
        case "notifications": return .notifications
        default: return .intro
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .intro: intro
            case .trial: trial
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
                Image(systemName: "list.bullet.rectangle.portrait.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
                Text("サブスク帳")
                    .font(.largeTitle.bold())
                Text("毎月いくら払っているか、すぐ分かる。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 22) {
                feature("yensign.circle.fill", "合計がひと目で", "月払いも年払いも、月あたり・1日あたりにそろえて表示します。")
                feature("bell.badge.fill", "解約し忘れを防ぐ", "支払日と無料体験の終わりの前にお知らせします。")
                feature("lock.fill", "すべて端末内に保存", "口座やカードとの連携はなく、アカウント登録も不要です。")
            }

            Spacer()
            primaryButton("はじめる") { step = .trial }
        }
    }

    // MARK: - 2. 無料体験

    private var trial: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 10) {
                Text("無料体験のまま、\n本契約にならない")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("無料体験の最終日の3日前と前日にお知らせします。続けないサービスは、お金がかかる前に解約できます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                NotificationSample(
                    title: String(localized: "シネマパスの無料体験がまもなく終わります"),
                    message: String(localized: "無料体験は9月16日まで（あと3日）。続けない場合はそれまでに解約を。9月17日から 月 ¥990 の支払いが始まります。")
                )
                NotificationSample(
                    title: String(localized: "動画プラスの支払いが3日後です"),
                    message: String(localized: "9月17日に動画プラスの支払い（¥1,590・クレジットカード）があります。")
                )
            }
            .accessibilityElement(children: .combine)

            Spacer()
            primaryButton("次へ") { step = .notifications }
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
                Text("支払日の前にお知らせ")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("支払日の3日前と前日に、金額と支払い方法を添えて通知します。タイミングと時刻は設定で変えられます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if notificationDenied {
                Text("通知がオフになっています。設定アプリ →「サブスク帳」→「通知」で許可してください。")
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
