import SwiftData
import SwiftUI

/// 初回起動時の導入。
///
/// このアプリの価値は通知でしか届かないので、オンボーディングの役目は
/// **「登録ゼロのまま終わらせない」**ことと**「通知を許可してもらう」**ことの2つに絞る。
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store

    let onDone: () -> Void

    @State private var step: Step = OnboardingView.initialStep
    @State private var selection: Set<String> = KindTemplate.defaultSelection
    @State private var notificationDenied = false

    private enum Step {
        case intro
        case templates
        case notifications
    }

    /// スクショ撮影用に、起動引数で開始ページを指定できるようにする。
    private static var initialStep: Step {
        switch Launch.onboardingStep {
        case "templates": return .templates
        case "notifications": return .notifications
        default: return .intro
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .intro: intro
            case .templates: templates
            case .notifications: notifications
            }
        }
        .padding(28)
        .tint(Theme.accent)
    }

    // MARK: - 1. 説明

    private var intro: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
                Text("ゴミの日アラーム")
                    .font(.largeTitle.bold())
                Text("出し忘れを、もうなくす。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 22) {
                feature("calendar", "曜日を登録するだけ", "毎週・隔週・第2第4など、地域のルールに合わせて登録できます。")
                feature("bell.badge.fill", "前夜と朝の2回お知らせ", "前の晩にまとめて、当日の朝に出す。2回に分けて届きます。")
                feature("lock.fill", "すべて端末内に保存", "登録内容が外部に送信されることはありません。")
            }

            Spacer()
            primaryButton("次へ") { step = .templates }
        }
    }

    // MARK: - 2. テンプレート

    private var templates: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("よくある構成から始める")
                    .font(.title2.bold())
                Text("あとから「予定」タブで曜日も名前も変更できます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(KindTemplate.all) { template in
                        templateRow(template)
                    }
                }
            }

            if !canSelectMore {
                Text("無料版で登録できるのは\(ProLimits.freeKinds)種類までです。あとから Pro で無制限にできます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                primaryButton(selection.isEmpty ? "スキップ" : "これで始める") {
                    applyTemplates()
                    step = .notifications
                }
                Button("自分で作る") {
                    selection = []
                    step = .notifications
                }
                .font(.subheadline)
            }
        }
    }

    private func templateRow(_ template: KindTemplate) -> some View {
        let isSelected = selection.contains(template.id)
        // 無料枠を超える選択は、初回から課金の壁に当てないために「選べない」ではなく「増やせない」で止める。
        let isDisabled = !isSelected && !canSelectMore
        return Button {
            if isSelected { selection.remove(template.id) } else { selection.insert(template.id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: template.symbolName)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Color(hex: template.colorHex),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name).foregroundStyle(.primary)
                    Text(template.specs.map(\.summary).joined(separator: " / "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.accent : Color.secondary)
            }
            .padding(14)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .opacity(isDisabled ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var canSelectMore: Bool {
        ProLimits.canAddKind(currentCount: selection.count, isPro: store.isPro)
    }

    // MARK: - 3. 通知の許可

    private var notifications: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                Text("通知をオンにしましょう")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("収集日の前の晩と当日の朝に、この2回だけお知らせします。\n通知が無いとアプリを開かないと気づけません。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 10) {
                notificationSample("前の晩 20:00", "明日は 燃えるゴミ の日")
                notificationSample("当日の朝 6:30", "今日は 燃えるゴミ の日")
            }

            if notificationDenied {
                Text("通知がオフになっています。設定アプリ →「ゴミの日アラーム」→「通知」で許可してください。")
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
                Button("あとで設定する") { finish() }
                    .font(.subheadline)
            }
        }
    }

    private func notificationSample(_ time: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "app.badge.fill")
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(text).font(.subheadline.weight(.semibold))
                Text(time).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
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

    private func applyTemplates() {
        let chosen = KindTemplate.all.filter { selection.contains($0.id) }
        for (index, template) in chosen.enumerated() {
            let kind = GarbageKind(name: template.name, sortOrder: index)
            modelContext.insert(kind)
            template.draft.apply(to: kind, in: modelContext)
        }
        try? modelContext.save()
    }

    private func enableNotifications() async {
        let granted = await NotificationScheduler.shared.requestAuthorizationIfNeeded()
        notificationDenied = !granted
        // 拒否されても先へ進める。設定アプリからいつでも許可でき、そのときに組み直される。
        if granted { finish() }
    }

    private func finish() {
        let container = modelContext.container
        Task { await NotificationRefresh.run(container: container) }
        onDone()
    }
}
