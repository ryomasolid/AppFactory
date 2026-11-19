import SwiftUI

/// はじめての起動。
struct WelcomeScreen: View {
    @State private var adding = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            TurtleArt(species: .reeves)
                .frame(width: 150, height: 150)
                .padding(24)
                .background(Palette.paper, in: Circle())
            VStack(spacing: 10) {
                Text("カメ帳").font(.largeTitle.bold()).foregroundStyle(Palette.ink)
                Text("ごはん・水換え・温浴の予定、\n甲羅の長さと体重の成長、\nライトの交換時期と冬眠中の体重まで。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                adding = true
            } label: {
                Text("うちのカメを登録する")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            Text("記録はこの iPhone の中にだけ保存されます。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Palette.sand.ignoresSafeArea())
        .sheet(isPresented: $adding) { TurtleEditor(turtle: nil) }
    }
}
