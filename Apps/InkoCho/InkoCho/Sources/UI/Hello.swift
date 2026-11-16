import SwiftUI

/// はじめての起動。まず1羽登録する。
struct Hello: View {
    @State private var adding = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Hue.sky.opacity(0.15)).frame(width: 190, height: 190)
                BudgieFace(plumage: .blue, sex: .male, size: 160).offset(y: 10)
            }
            .clipShape(Circle())
            VStack(spacing: 8) {
                Text("インコ帳").font(.largeTitle.bold()).foregroundStyle(Hue.ink)
                Text("セキセイインコの体重を毎日つけて、\n小さな変化に早く気づく。")
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .foregroundStyle(Hue.soft)
            }
            VStack(alignment: .leading, spacing: 10) {
                row("scalemass.fill", "グラム単位の体重と、ふだんとの差")
                row("eye.fill", "ふくらみ・フン・室温・換羽をまとめて見守り")
                row("text.bubble.fill", "おぼえた言葉を日付つきで残す")
            }
            Spacer()
            Button { adding = true } label: {
                Text("うちの子を登録する").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Hue.ground.ignoresSafeArea())
        .sheet(isPresented: $adding) { BirdForm(bird: nil) }
    }

    private func row(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(Hue.lemon).frame(width: 22)
            Text(text).font(.subheadline)
        }
    }
}
