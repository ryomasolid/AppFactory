import SwiftData
import SwiftUI

/// カテゴリ別・支払い方法別の内訳（Pro）。契約中だけを月あたりで比べる。
struct BreakdownView: View {
    @Query(sort: \Subscription.createdAt) private var subscriptions: [Subscription]

    var body: some View {
        let today = AppClock.now
        let active = subscriptions.filter { $0.state(today: today) == .active }
        let total = CostSummary.totals(active.map(\.plan)).monthly
        let byCategory = CostSummary.breakdown(active.map { (key: $0.category, plan: $0.plan) })
        let byPayment = CostSummary.breakdown(active.map { (key: $0.paymentMethod, plan: $0.plan) })

        List {
            Section {
                ForEach(byCategory, id: \.key) { entry in
                    BarRow(
                        title: entry.key.label, count: entry.count, amount: entry.monthly, total: total,
                        color: Color(hex: entry.key.colorHex)
                    )
                }
            } header: {
                Text("カテゴリ別（月あたり）")
            }

            Section {
                ForEach(byPayment, id: \.key) { entry in
                    BarRow(title: entry.key.label, count: entry.count, amount: entry.monthly, total: total, color: Theme.accent)
                }
            } header: {
                Text("支払い方法別（月あたり）")
            } footer: {
                Text("解約する場所は支払い方法によって違います。App Store やキャリア決済のものは、サービスのサイトではなく支払い側で解約します。")
            }
        }
        .overlay {
            if active.isEmpty {
                ContentUnavailableView("契約中のサブスクはありません", systemImage: "chart.bar")
            }
        }
        .navigationTitle("内訳")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 内訳の1行。合計に対する割合を横棒で出す。
private struct BarRow: View {
    let title: String
    let count: Int
    let amount: Int
    let total: Int
    let color: Color

    private var fraction: Double { total > 0 ? Double(amount) / Double(total) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline.weight(.semibold))
                Text("\(count)件").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(Formatting.yen(amount)).font(.subheadline.weight(.semibold)).monospacedDigit()
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .trailing)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(color).frame(width: max(6, proxy.size.width * fraction))
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
