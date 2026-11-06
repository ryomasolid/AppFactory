import SwiftUI

struct SettingsScreen: View {
    @Environment(AdDirector.self) private var ads

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if ads.phase == .ready { adFree }
                info
                Text("バージョン \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                    .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .paperBackground()
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var adFree: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("広告を消す").font(.headline.weight(.bold))
            if ads.isAdFree {
                Label("\(ads.adFreeUntil.formatted(date: .omitted, time: .shortened)) まで広告を止めています", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.bold)).foregroundStyle(.green)
            } else {
                Text("短い動画広告を1本見ると、バナーや記事内の広告が2時間出なくなります。").font(.footnote).foregroundStyle(.secondary)
                RewardButton(reward: .adFree, title: "広告を見て2時間オフにする")
            }
        }
        .padding(14)
        .sticker()
    }

    private var info: some View {
        VStack(spacing: 0) {
            NavigationLink(value: Route.privacy) { row("プライバシーと広告", "hand.raised.fill") }.buttonStyle(.plain)
            Divider()
            if ads.needsPrivacyOptions {
                Button { Task { await ads.presentPrivacyOptions() } } label: { row("広告の同意を変更する", "checklist") }.buttonStyle(.plain)
                Divider()
            }
            if let url = URL(string: "https://gatsugatsu-gurume.com") {
                Link(destination: url) { row("Webサイト版を開く", "safari.fill") }.buttonStyle(.plain)
                Divider()
            }
            if let url = URL(string: "mailto:ryomasolid@yahoo.co.jp?subject=%E3%82%AC%E3%83%84%E3%82%AC%E3%83%84%E3%82%B0%E3%83%AB%E3%83%A1%20%E3%82%A2%E3%83%97%E3%83%AA") {
                Link(destination: url) { row("お問い合わせ", "envelope.fill") }.buttonStyle(.plain)
            }
        }
        .background(Color.card, in: .rect(cornerRadius: 12))
    }

    private func row(_ title: String, _ icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon).font(.subheadline.weight(.bold))
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.secondary)
        }
        .padding(14)
        .contentShape(.rect)
    }
}

struct PrivacyScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                heading("記録は端末の中だけに")
                Text("ガツログ、保存した記事、いつもの駅は、この端末の中だけに保存します。運営者のサーバーには送りません。アプリを削除すると消えます。")
                heading("広告について")
                Text("広告の配信に Google AdMob を使っています。AdMob は広告の表示や効果の測定のために、端末の広告識別子（許可された場合のみ）、おおよその位置、利用状況などを扱うことがあります。ガツログの中身を広告のために送ることはありません。")
                Text("トラッキングの許可は、端末の「設定」→「プライバシーとセキュリティ」→「トラッキング」からいつでも変更できます。許可しなくても、広告の内容が変わるだけで機能は同じです。")
                if let url = URL(string: "https://policies.google.com/technologies/partner-sites?hl=ja") {
                    Link("Google のパートナーサイトでのデータ利用", destination: url).font(.subheadline.weight(.bold))
                }
                heading("リンク先")
                Text("地図の検索や出典のリンクは、Google マップや各社のサイトなど外部のサービスを開きます。")
                heading("駅のデータ")
                Text("全国の駅の名前・路線・位置は、「\(JapanStations.shared.source)」（CC BY 4.0）をもとに、アプリ用に加工して作成しています。")
                if let url = URL(string: "https://nlftp.mlit.go.jp/ksj/") {
                    Link("国土数値情報ダウンロードサイト", destination: url).font(.subheadline.weight(.bold))
                }
                heading("運営者")
                Text("ガツガツグルメ（運営責任者: ごま）\nお問い合わせ: ryomasolid@yahoo.co.jp")
            }
            .font(.subheadline)
            .lineSpacing(5)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .paperBackground()
        .navigationTitle("プライバシーと広告")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func heading(_ text: String) -> some View {
        Text(text).font(.headline.weight(.bold)).padding(.top, 6)
    }
}
