import SwiftData
import SwiftUI

/// サブスク帳 Pro の案内。
///
/// 「サブスクを減らすアプリに毎月払う」のは筋が悪いので、Pro は買い切りだけにしている。
/// 画面では無料版との違いを表で見せ、いま何件登録しているかを添える（上限に当たって開いた人に理由が分かるように）。
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProUnlock.self) private var pro
    @Query(filter: #Predicate<Subscription> { !$0.isCancelled }) private var live: [Subscription]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    comparison
                    Text("支払日と無料体験のお知らせ、合計・カレンダー・見直しは無料版でもずっと使えます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) { purchaseArea }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .tint(Palette.ink)
        .task {
            if case .unavailable = pro.offer { await pro.loadOffer() }
        }
    }

    // MARK: - 見出し

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 44))
                .foregroundStyle(Palette.ink)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "infinity.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, Palette.saving)
                        .offset(x: 8, y: 6)
                }
            Text("サブスク帳 Pro")
                .font(.title.bold())
            Text("一度買えば、ずっと。月額はかかりません。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !pro.isUnlocked, live.count >= ProLimits.freeSubscriptions {
                Text("いま \(live.count)件 登録中（無料版は\(ProLimits.freeSubscriptions)件まで）")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(Palette.deadline)
                    .background(Palette.deadline.opacity(0.12), in: Capsule())
            }
        }
    }

    // MARK: - 無料版との比較

    private struct Line: Identifiable {
        let title: LocalizedStringKey
        let free: String
        let pro: String
        var id: String { "\(title)" }
    }

    private var lines: [Line] {
        [
            Line(title: "登録できるサブスク", free: String(localized: "\(ProLimits.freeSubscriptions)件"), pro: String(localized: "無制限")),
            Line(title: "支払日・無料体験のお知らせ", free: "✓", pro: "✓"),
            Line(title: "合計・カレンダー・見直し", free: "✓", pro: "✓"),
            Line(title: "カテゴリ別・支払い方法別の内訳", free: "—", pro: "✓"),
            Line(title: "CSVで書き出し", free: "—", pro: "✓"),
            Line(title: "広告", free: String(localized: "あり"), pro: String(localized: "なし")),
        ]
    }

    private var comparison: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
            GridRow {
                Text("")
                Text("無料").gridColumnAlignment(.center)
                Text("Pro").foregroundStyle(Palette.ink).gridColumnAlignment(.center)
            }
            .font(.caption.weight(.bold))
            .padding(.bottom, 8)
            ForEach(lines) { line in
                Divider().gridCellUnsizedAxes(.horizontal)
                GridRow {
                    Text(line.title)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(line.free)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 52)
                    Text(line.pro)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(minWidth: 52)
                }
                .padding(.vertical, 10)
            }
        }
        .card()
    }

    // MARK: - 購入

    private var purchaseArea: some View {
        VStack(spacing: 10) {
            if pro.isUnlocked {
                Label("Pro を利用中です。ありがとうございます。", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Palette.saving)
                    .padding(.vertical, 8)
            } else {
                Button {
                    Task { if await pro.buy() { dismiss() } }
                } label: {
                    Group {
                        if pro.isWorking {
                            ProgressView().tint(.white)
                        } else if let price = pro.price {
                            Text("\(price)（買い切り）で Pro にする")
                        } else {
                            Text("Pro の情報を読み込み中…")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 24)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(pro.price == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(Palette.ink), in: Capsule())
                }
                .disabled(pro.price == nil || pro.isWorking)

                if case .unavailable(let reason) = pro.offer {
                    VStack(spacing: 4) {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("もう一度読み込む") { Task { await pro.loadOffer() } }
                            .font(.caption.weight(.semibold))
                    }
                }

                Button("以前に購入した方はこちら（購入を復元）") {
                    Task { if await pro.restore() { dismiss() } }
                }
                .font(.footnote)
                .disabled(pro.isWorking)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }
}
