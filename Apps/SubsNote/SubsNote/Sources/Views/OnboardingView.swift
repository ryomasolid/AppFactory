import SwiftUI

/// 初回起動の案内。横にめくる4ページ。
///
/// 1. 帳簿: 月払いも年払いも「月いくら」にそろう
/// 2. 無料体験: 終わる前に知らせる（通知の見本）
/// 3. 見直し: 1回あたりの値段で、やめるか決める
/// 4. 通知の許可
///
/// どのページからでも最後の「通知をオンにする」まで飛べる（読まずに始めたい人を止めない）。
struct OnboardingView: View {
    let onDone: () -> Void

    @State private var page: Page = OnboardingView.firstPage
    @State private var notificationBlocked = false

    private enum Page: Int, CaseIterable {
        case ledger = 1, trial, review, permission
    }

    /// スクショ撮影用の開始ページ（`-onboardingStep 2` または `trial` など）。
    private static var firstPage: Page {
        guard let raw = Launch.onboardingStep else { return .ledger }
        if let number = Int(raw), let page = Page(rawValue: number) { return page }
        return switch raw {
        case "trial": .trial
        case "review": .review
        case "notifications": .permission
        default: .ledger
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if page != .permission {
                    Button("スキップ") { page = .permission }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 20)

            TabView(selection: $page) {
                ledgerPage.tag(Page.ledger)
                trialPage.tag(Page.trial)
                reviewPage.tag(Page.review)
                permissionPage.tag(Page.permission)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .background(Color(.systemGroupedBackground))
        .tint(Palette.ink)
        .animation(.easeInOut, value: page)
    }

    // MARK: - ページ

    private var ledgerPage: some View {
        pageLayout(
            title: "毎月いくら払っているか、\nすぐ分かる",
            message: "週払い・月払い・年払いが混ざっていても、月あたり・年あたり・1日あたりにそろえて合計します。口座やカードとはつながず、記録はこの端末の中だけに残ります。"
        ) {
            VStack(spacing: 0) {
                ledgerLine("動画プラス", "月 ¥1,590")
                ledgerLine("クラウドボックス", "年 ¥5,400 → 月 ¥450")
                ledgerLine("フィットネスジム", "月 ¥3,278")
                HStack {
                    Text("月あたり").font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("¥5,318").font(.title3.weight(.bold)).monospacedDigit()
                }
                .padding(.top, 12)
                .foregroundStyle(Palette.ink)
            }
            .card()
        }
    }

    private var trialPage: some View {
        pageLayout(
            title: "無料体験のまま、\n本契約にならない",
            message: "無料体験の最終日の3日前と前日にお知らせします。続けないサービスは、お金がかかる前に解約できます。"
        ) {
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
        }
    }

    private var reviewPage: some View {
        pageLayout(
            title: "1回あたりの値段で\n見直す",
            message: "先月使った回数をつけると、1回あたりいくらかを出します。使っていないもの・割高なものをやめると年いくら浮くかも分かります。"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                reviewLine("フィットネスジム", "2回", "1回 ¥1,639", Palette.idle)
                reviewLine("ミュージックワン", "25回", "1回 ¥43", .primary)
                Divider()
                Label("やめると 年 ¥39,336 浮きます", systemImage: "leaf.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Palette.saving)
            }
            .card()
        }
    }

    private var permissionPage: some View {
        pageLayout(
            title: "支払日の前にお知らせ",
            message: "支払日の3日前と前日に、金額と支払い方法を添えて通知します。タイミングと時刻は設定で変えられます。"
        ) {
            VStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Palette.ink)
                    .symbolRenderingMode(.hierarchical)
                if notificationBlocked {
                    Text("通知がオフになっています。設定アプリ →「サブスク帳」→「通知」で許可してください。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - 下の操作

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(Page.allCases, id: \.self) { item in
                    Capsule()
                        .fill(item == page ? Palette.ink : Color(.systemGray4))
                        .frame(width: item == page ? 22 : 8, height: 8)
                }
            }
            .accessibilityHidden(true)

            if page == .permission {
                // 「許可」などシステムのダイアログを模した文言は審査で指摘されるため使わない。
                Button { Task { await turnOnNotifications() } } label: {
                    PrimaryButtonLabel(title: "通知をオンにする", systemImage: "bell.fill")
                }
                Button("あとで設定する", action: onDone)
                    .font(.subheadline)
            } else {
                Button {
                    page = Page(rawValue: page.rawValue + 1) ?? .permission
                } label: {
                    PrimaryButtonLabel(title: "次へ")
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
    }

    // MARK: - 部品

    private func pageLayout(
        title: LocalizedStringKey, message: LocalizedStringKey, @ViewBuilder figure: () -> some View
    ) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            figure()
            VStack(spacing: 10) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
    }

    private func ledgerLine(_ name: String, _ amount: String) -> some View {
        HStack {
            Text(name).font(.subheadline)
            Spacer()
            Text(amount).font(.subheadline).monospacedDigit().foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func reviewLine(_ name: String, _ uses: String, _ perUse: String, _ color: Color) -> some View {
        HStack {
            Text(name).font(.subheadline)
            Spacer()
            Text(uses).font(.caption).foregroundStyle(.secondary)
            Text(perUse)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .frame(minWidth: 84, alignment: .trailing)
        }
    }

    private func turnOnNotifications() async {
        let granted = await ReminderCenter.askIfNeeded()
        notificationBlocked = !granted
        // 断られても先へ進める。設定アプリからいつでも許可でき、起動時に組み直される。
        if granted { onDone() }
    }
}
