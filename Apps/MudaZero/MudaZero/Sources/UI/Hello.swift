import SwiftData
import SwiftUI

/// はじめての起動：しくみの説明 → ふだんのムダ → ムダ予算。
struct Hello: View {
    @AppStorage(Plan.startedKey) private var started = false
    @AppStorage(Plan.usualKey) private var usual = Plan.usualDefault
    @AppStorage(Plan.budgetKey) private var budget = Plan.budgetDefault
    @AppStorage(Notice.onKey) private var noticeOn = false

    private let usualChoices = [300, 500, 800, 1000, 1500]
    private let budgetChoices = [5000, 10000, 20000, 30000]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack {
                        Circle().fill(Hue.gold.gradient)
                        Text("0円").font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                    }
                    .frame(width: 76, height: 76)
                    Text("ムダ遣いゼロの日を\nふやしていこう")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(Hue.ink)
                    Text("家計簿みたいに全部つけなくて大丈夫。\n「ついつい」使ったお金だけ見ていきます。")
                        .foregroundStyle(Hue.soft)
                }

                VStack(alignment: .leading, spacing: 12) {
                    point("checkmark.seal.fill", Hue.mint, "ムダ遣いしなかった日は、夜に1タップでしめるだけ。")
                    point("plus.circle.fill", Hue.salmon, "使った日は「ついつい」か「必要」かと金額をつける。")
                    point("flag.checkered", Hue.gold, "がまんした分は「浮いたお金」として、もくひょうにたまる。")
                }
                .card()

                choose(title: "ふだん、1日にどのくらいムダ遣いしている？", note: "コンビニ・カフェ・自販機など。がまんした日はこの分が浮きます。", choices: usualChoices, value: $usual, id: "usual")
                choose(title: "1か月の ついつい 予算は？", note: "あとから設定で変えられます。", choices: budgetChoices, value: $budget, id: "budget")

                Button {
                    noticeOn = false
                    started = true
                } label: {
                    Text("はじめる")
                        .font(.title3.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Hue.mint)
                .accessibilityIdentifier("start")
            }
            .padding(20)
        }
        .background(Hue.ground)
    }

    private func point(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 24)
            Text(text).foregroundStyle(Hue.ink).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func choose(title: String, note: String, choices: [Int], value: Binding<Int>, id: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundStyle(Hue.ink)
            Text(note).font(.footnote).foregroundStyle(Hue.soft)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(choices, id: \.self) { c in
                        Button {
                            value.wrappedValue = c
                        } label: {
                            Text(c.yen)
                                .font(.subheadline.weight(.bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .foregroundStyle(value.wrappedValue == c ? .white : Hue.ink)
                                .background(value.wrappedValue == c ? Hue.mint : Hue.card, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("\(id)-\(c)")
                    }
                }
            }
        }
    }
}
