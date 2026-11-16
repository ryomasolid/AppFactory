import SwiftUI

/// はじめての起動。まず1頭登録してもらう。
struct WelcomeScreen: View {
    @State private var adding = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Tone.apricot.opacity(0.18)).frame(width: 180, height: 180)
                PoodleFace(coat: .apricot, size: 150)
            }
            VStack(spacing: 8) {
                Text("といぷー日記").font(.largeTitle.bold()).foregroundStyle(Tone.cocoa)
                Text("トイプードルの毎日と、トリミング・予防の\nスケジュールを1冊に。")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Tone.mute)
            }
            VStack(alignment: .leading, spacing: 10) {
                point("book.closed.fill", "写真・きぶん・散歩をワンタップで日記に")
                point("scissors", "前回のカットからの日数と、次のトリミングの目安")
                point("heart.text.square.fill", "体重グラフと、ワクチン・フィラリアの予定")
            }
            .padding(.horizontal, 32)
            Spacer()
            Button { adding = true } label: {
                Text("うちの子を登録する")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tone.paper.ignoresSafeArea())
        .sheet(isPresented: $adding) { DogEditor(dog: nil) }
    }

    private func point(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text).font(.subheadline)
        } icon: {
            Image(systemName: symbol).foregroundStyle(Tone.apricot)
        }
    }
}
