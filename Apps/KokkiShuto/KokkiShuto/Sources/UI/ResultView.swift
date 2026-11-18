import SwiftUI

struct ResultView: View {
    let total: Int
    let misses: [Question]
    let retry: () -> Void
    let close: () -> Void

    private var score: Int { total - misses.count }

    private var comment: String {
        if misses.isEmpty { return "ぜんもん正解！" }
        let rate = Double(score) / Double(max(total, 1))
        if rate >= 0.8 { return "あと少し！" }
        if rate >= 0.5 { return "いい調子" }
        return "くり返せば覚えられる"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Image(systemName: misses.isEmpty ? "trophy.fill" : "flag.checkered")
                        .font(.system(size: 48))
                        .foregroundStyle(misses.isEmpty ? Hue.gold : Hue.navy)
                    Text(comment)
                        .font(.title2.bold())
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 56, weight: .heavy).monospacedDigit())
                        Text("/ \(total) 問")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 24)

                if !misses.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("まちがえた国")
                            .font(.headline)
                        ForEach(misses) { q in
                            CountryLine(country: q.answer)
                            if q.id != misses.last?.id { Divider() }
                        }
                    }
                    .padding(16)
                    .background(Hue.card, in: .rect(cornerRadius: 16))
                }

                VStack(spacing: 10) {
                    if !misses.isEmpty {
                        Button(action: retry) {
                            Label("まちがえた問題をもう一度", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Hue.wrong)
                    }
                    Button(action: close) {
                        Text("おわる")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(16)
        }
    }
}
