import SwiftUI

/// 初回起動時の説明画面。何ができるアプリかを3点で伝える。
struct OnboardingView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "map")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("PestMap")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 20) {
                feature("photo.on.rectangle.angled", "間取りを用意", "間取り図を撮影、または白紙から作成")
                feature("mappin.circle", "対策場所を記録", "ブラックキャップなどの設置場所をマーカーで管理")
                feature("bell.badge", "次回をリマインド", "交換・対策のタイミングを通知でお知らせ")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onDone) {
                Text("はじめる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }

    private func feature(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
